/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: CPU6502.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 10/8/20
 *
 * Copyright © 2020 Galen Rhodes. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//************************************************************************/

import Foundation
import Rubicon

public class CPU6502: CPU65xx {

    @usableFromInline @frozen enum SpinLock {
        case Free
        case Locking
        case Locked
    }

    public let addressBuss:    AddressBuss
    public var clockFrequency: ClockFrequencies { willSet { _cycle = newValue.clockCycle } }

    public internal(set) var runStatus: RunStatus = .NeverStarted

    @inlinable open var accumulator:  UInt8 { _accu }
    @inlinable open var xRegister:    UInt8 { _xreg }
    @inlinable open var yRegister:    UInt8 { _yreg }
    @inlinable open var stRegister:   UInt8 { _st }
    @inlinable open var stackPointer: UInt8 { UInt8(truncatingIfNeeded: _sp) }
    @inlinable open var progCounter:  UInt16 { _pc }

    @usableFromInline var _cycle:     UInt64 = 0
    @usableFromInline let _stackAddr: UInt16 = 0x0100
    @usableFromInline var _sp:        UInt16 = 0x00ff
    @usableFromInline var _pc:        UInt16 = 0xffff
    @usableFromInline var _accu:      UInt8  = 0x00
    @usableFromInline var _xreg:      UInt8  = 0x00
    @usableFromInline var _yreg:      UInt8  = 0x00
    @usableFromInline var _st:        UInt8  = 0x20

    @usableFromInline let _cond:         Conditional       = Conditional()
    @usableFromInline var _tickWait:     Int               = 0
    @usableFromInline var _irqTriggered: Bool              = false
    @usableFromInline var _nmiTriggered: Bool              = false
    @usableFromInline var _watchers:     Set<ClockWatcher> = []
    @usableFromInline var _nextOpTime:   UInt64            = 0
    @usableFromInline var _nextWTime:    UInt64            = 0
    @usableFromInline var _spinLock:     SpinLock          = .Free
    @usableFromInline var _tstime:       timespec          = timespec(tv_sec: 0, tv_nsec: 0)

    public init(clockFrequency: ClockFrequencies = .C64_NTSC, addressBuss: AddressBuss) {
        self.addressBuss = addressBuss
        self.clockFrequency = clockFrequency
        _cycle = self.clockFrequency.clockCycle
    }

    deinit { _cond.withLock { runStatus = .Stopped } }

    @inlinable func getSysTime() -> UInt64 {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            return UInt64(clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW))
        #else
            clock_gettime(CLOCK_MONOTONIC_RAW, &_tstime)
            return ((UInt64(_tstime.tv_sec) * 1000000000.0) + UInt64(_tstime.tv_nsec))
        #endif
    }

    @inlinable func notifyWatchers() {
        _nextWTime &+= _cycle
        for w: ClockWatcher in _watchers { w.trigger = true }
    }

    @inlinable func doNextInstruction() {
        let opcode: OpcodeInfo = Emu6510Opcodes[Int(addressBuss[_pc + 1])]
        _nextOpTime &+= (_cycle * opcode.cycleCount)
        dispatchOpcode(opcode: opcode)
    }

    @inlinable func handleNextTick(_ thisTime: UInt64) {
        if thisTime >= _nextOpTime {
            notifyWatchers()
            doNextInstruction()
        }
        else if thisTime >= _nextWTime {
            notifyWatchers()
        }
    }

    private func _run() {
        _nextOpTime = (getSysTime() + _cycle)
        _nextWTime = _nextOpTime

        while runStatus != .Stopped {
            if _spinLock == .Free {
                if runStatus == .Paused { _cond.withLockWait { runStatus != .Paused } }
                else { handleNextTick(getSysTime()) }
            }
            else if _spinLock == .Locking {
                _spinLock = .Locked
            }
        }
    }

    open func run() {
        _cond.lock()

        if runStatus == .NeverStarted {
            runStatus = .Running
            _cond.broadcast()
            _cond.unlock()
            _run()
        }
        else {
            _cond.unlock()
        }
    }

    open func start() throws {
        try _cond.withLock {
            switch runStatus {
                case .Stopped: throw CPUErrors.AlreadyStopped
                case .Running: throw CPUErrors.AlreadyRunning
                case .Paused: throw CPUErrors.AlreadyRunning
                case .NeverStarted:
                    runStatus = .Running
                    DispatchQueue(label: "Emu6510.CPU6510.Worker", qos: .userInteractive, attributes: [ DispatchQueue.Attributes.concurrent ], autoreleaseFrequency: .workItem).async {
                        [weak self] in
                        if let s: CPU6502 = self { s._run() }
                    }
            }
        }
    }

    open func pause() throws {
        try _cond.withLock { () -> Void in
            switch runStatus {
                case .NeverStarted: throw CPUErrors.NotStarted
                case .Paused: throw CPUErrors.AlreadyPaused
                case .Stopped: throw CPUErrors.AlreadyStopped
                case .Running: runStatus = .Paused
            }
        }
    }

    open func unPause() throws {
        try _cond.withLock { () -> Void in
            switch runStatus {
                case .NeverStarted: throw CPUErrors.NotStarted
                case .Stopped: throw CPUErrors.AlreadyStopped
                case .Running: throw CPUErrors.NotPaused
                case .Paused: runStatus = .Running
            }
        }
    }

    open func stop() throws {
        try _cond.withLock {
            switch runStatus {
                case .NeverStarted: throw CPUErrors.NotStarted
                case .Stopped: throw CPUErrors.AlreadyStopped
                case .Paused: runStatus = .Stopped
                case .Running: runStatus = .Stopped
            }
        }
    }

    open func addWatcher(_ watcher: ClockWatcher) {
        _cond.withLock {
            if !_watchers.contains(watcher) {
                _spinLock = .Locking
                while runStatus == .Running && _spinLock != .Locked {}
                _watchers.insert(watcher)
                _spinLock = .Free
            }
        }
    }

    open func removeWatcher(_ watcher: ClockWatcher) {
        _cond.withLock {
            if _watchers.contains(watcher) {
                _spinLock = .Locking
                while runStatus == .Running && _spinLock != .Locked {}
                _watchers.remove(watcher)
                _spinLock = .Free
            }
        }
    }

    open func dispatchOpcode(opcode: OpcodeInfo) {
        switch opcode.opcode {
            case 0x00: processBRK(opcode: opcode)
            case 0x01: processORA(opcode: opcode)
            case 0x02: processKIL(opcode: opcode)
            case 0x03: processSLO(opcode: opcode)
            case 0x04: processNOP(opcode: opcode)
            case 0x05: processORA(opcode: opcode)
            case 0x06: processASL(opcode: opcode)
            case 0x07: processSLO(opcode: opcode)
            case 0x08: processPHP(opcode: opcode)
            case 0x09: processORA(opcode: opcode)
            case 0x0a: processASL(opcode: opcode)
            case 0x0b: processANC(opcode: opcode)
            case 0x0c: processNOP(opcode: opcode)
            case 0x0d: processORA(opcode: opcode)
            case 0x0e: processASL(opcode: opcode)
            case 0x0f: processSLO(opcode: opcode)
            case 0x10: processBPL(opcode: opcode)
            case 0x11: processORA(opcode: opcode)
            case 0x12: processKIL(opcode: opcode)
            case 0x13: processSLO(opcode: opcode)
            case 0x14: processNOP(opcode: opcode)
            case 0x15: processORA(opcode: opcode)
            case 0x16: processASL(opcode: opcode)
            case 0x17: processSLO(opcode: opcode)
            case 0x18: processCLC(opcode: opcode)
            case 0x19: processORA(opcode: opcode)
            case 0x1a: processNOP(opcode: opcode)
            case 0x1b: processSLO(opcode: opcode)
            case 0x1c: processNOP(opcode: opcode)
            case 0x1d: processORA(opcode: opcode)
            case 0x1e: processASL(opcode: opcode)
            case 0x1f: processSLO(opcode: opcode)
            case 0x20: processJSR(opcode: opcode)
            case 0x21: processAND(opcode: opcode)
            case 0x22: processKIL(opcode: opcode)
            case 0x23: processRLA(opcode: opcode)
            case 0x24: processBIT(opcode: opcode)
            case 0x25: processAND(opcode: opcode)
            case 0x26: processROL(opcode: opcode)
            case 0x27: processRLA(opcode: opcode)
            case 0x28: processPLP(opcode: opcode)
            case 0x29: processAND(opcode: opcode)
            case 0x2a: processROL(opcode: opcode)
            case 0x2b: processANC(opcode: opcode)
            case 0x2c: processBIT(opcode: opcode)
            case 0x2d: processAND(opcode: opcode)
            case 0x2e: processROL(opcode: opcode)
            case 0x2f: processRLA(opcode: opcode)
            case 0x30: processBMI(opcode: opcode)
            case 0x31: processAND(opcode: opcode)
            case 0x32: processKIL(opcode: opcode)
            case 0x33: processRLA(opcode: opcode)
            case 0x34: processNOP(opcode: opcode)
            case 0x35: processAND(opcode: opcode)
            case 0x36: processROL(opcode: opcode)
            case 0x37: processRLA(opcode: opcode)
            case 0x38: processSEC(opcode: opcode)
            case 0x39: processAND(opcode: opcode)
            case 0x3a: processNOP(opcode: opcode)
            case 0x3b: processRLA(opcode: opcode)
            case 0x3c: processNOP(opcode: opcode)
            case 0x3d: processAND(opcode: opcode)
            case 0x3e: processROL(opcode: opcode)
            case 0x3f: processRLA(opcode: opcode)
            case 0x40: processRTI(opcode: opcode)
            case 0x41: processEOR(opcode: opcode)
            case 0x42: processKIL(opcode: opcode)
            case 0x43: processSRE(opcode: opcode)
            case 0x44: processNOP(opcode: opcode)
            case 0x45: processEOR(opcode: opcode)
            case 0x46: processLSR(opcode: opcode)
            case 0x47: processSRE(opcode: opcode)
            case 0x48: processPHA(opcode: opcode)
            case 0x49: processEOR(opcode: opcode)
            case 0x4a: processLSR(opcode: opcode)
            case 0x4b: processALR(opcode: opcode)
            case 0x4c: processJMP(opcode: opcode)
            case 0x4d: processEOR(opcode: opcode)
            case 0x4e: processLSR(opcode: opcode)
            case 0x4f: processSRE(opcode: opcode)
            case 0x50: processBVC(opcode: opcode)
            case 0x51: processEOR(opcode: opcode)
            case 0x52: processKIL(opcode: opcode)
            case 0x53: processSRE(opcode: opcode)
            case 0x54: processNOP(opcode: opcode)
            case 0x55: processEOR(opcode: opcode)
            case 0x56: processLSR(opcode: opcode)
            case 0x57: processSRE(opcode: opcode)
            case 0x58: processCLI(opcode: opcode)
            case 0x59: processEOR(opcode: opcode)
            case 0x5a: processNOP(opcode: opcode)
            case 0x5b: processSRE(opcode: opcode)
            case 0x5c: processNOP(opcode: opcode)
            case 0x5d: processEOR(opcode: opcode)
            case 0x5e: processLSR(opcode: opcode)
            case 0x5f: processSRE(opcode: opcode)
            case 0x60: processRTS(opcode: opcode)
            case 0x61: processADC(opcode: opcode)
            case 0x62: processKIL(opcode: opcode)
            case 0x63: processRRA(opcode: opcode)
            case 0x64: processNOP(opcode: opcode)
            case 0x65: processADC(opcode: opcode)
            case 0x66: processROR(opcode: opcode)
            case 0x67: processRRA(opcode: opcode)
            case 0x68: processPLA(opcode: opcode)
            case 0x69: processADC(opcode: opcode)
            case 0x6a: processROR(opcode: opcode)
            case 0x6b: processARR(opcode: opcode)
            case 0x6c: processJMP(opcode: opcode)
            case 0x6d: processADC(opcode: opcode)
            case 0x6e: processROR(opcode: opcode)
            case 0x6f: processRRA(opcode: opcode)
            case 0x70: processBVS(opcode: opcode)
            case 0x71: processADC(opcode: opcode)
            case 0x72: processKIL(opcode: opcode)
            case 0x73: processRRA(opcode: opcode)
            case 0x74: processNOP(opcode: opcode)
            case 0x75: processADC(opcode: opcode)
            case 0x76: processROR(opcode: opcode)
            case 0x77: processRRA(opcode: opcode)
            case 0x78: processSEI(opcode: opcode)
            case 0x79: processADC(opcode: opcode)
            case 0x7a: processNOP(opcode: opcode)
            case 0x7b: processRRA(opcode: opcode)
            case 0x7c: processNOP(opcode: opcode)
            case 0x7d: processADC(opcode: opcode)
            case 0x7e: processROR(opcode: opcode)
            case 0x7f: processRRA(opcode: opcode)
            case 0x80: processNOP(opcode: opcode)
            case 0x81: processSTA(opcode: opcode)
            case 0x82: processNOP(opcode: opcode)
            case 0x83: processSAX(opcode: opcode)
            case 0x84: processSTY(opcode: opcode)
            case 0x85: processSTA(opcode: opcode)
            case 0x86: processSTX(opcode: opcode)
            case 0x87: processSAX(opcode: opcode)
            case 0x88: processDEY(opcode: opcode)
            case 0x89: processNOP(opcode: opcode)
            case 0x8a: processTXA(opcode: opcode)
            case 0x8b: processXAA(opcode: opcode)
            case 0x8c: processSTY(opcode: opcode)
            case 0x8d: processSTA(opcode: opcode)
            case 0x8e: processSTX(opcode: opcode)
            case 0x8f: processSAX(opcode: opcode)
            case 0x90: processBCC(opcode: opcode)
            case 0x91: processSTA(opcode: opcode)
            case 0x92: processKIL(opcode: opcode)
            case 0x93: processAHX(opcode: opcode)
            case 0x94: processSTY(opcode: opcode)
            case 0x95: processSTA(opcode: opcode)
            case 0x96: processSTX(opcode: opcode)
            case 0x97: processSAX(opcode: opcode)
            case 0x98: processTYA(opcode: opcode)
            case 0x99: processSTA(opcode: opcode)
            case 0x9a: processTXS(opcode: opcode)
            case 0x9b: processTAS(opcode: opcode)
            case 0x9c: processSHY(opcode: opcode)
            case 0x9d: processSTA(opcode: opcode)
            case 0x9e: processSHX(opcode: opcode)
            case 0x9f: processAHX(opcode: opcode)
            case 0xa0: processLDY(opcode: opcode)
            case 0xa1: processLDA(opcode: opcode)
            case 0xa2: processLDX(opcode: opcode)
            case 0xa3: processLAX(opcode: opcode)
            case 0xa4: processLDY(opcode: opcode)
            case 0xa5: processLDA(opcode: opcode)
            case 0xa6: processLDX(opcode: opcode)
            case 0xa7: processLAX(opcode: opcode)
            case 0xa8: processTAY(opcode: opcode)
            case 0xa9: processLDA(opcode: opcode)
            case 0xaa: processTAX(opcode: opcode)
            case 0xab: processLAX(opcode: opcode)
            case 0xac: processLDY(opcode: opcode)
            case 0xad: processLDA(opcode: opcode)
            case 0xae: processLDX(opcode: opcode)
            case 0xaf: processLAX(opcode: opcode)
            case 0xb0: processBCS(opcode: opcode)
            case 0xb1: processLDA(opcode: opcode)
            case 0xb2: processKIL(opcode: opcode)
            case 0xb3: processLAX(opcode: opcode)
            case 0xb4: processLDY(opcode: opcode)
            case 0xb5: processLDA(opcode: opcode)
            case 0xb6: processLDX(opcode: opcode)
            case 0xb7: processLAX(opcode: opcode)
            case 0xb8: processCLV(opcode: opcode)
            case 0xb9: processLDA(opcode: opcode)
            case 0xba: processTSX(opcode: opcode)
            case 0xbb: processLAS(opcode: opcode)
            case 0xbc: processLDY(opcode: opcode)
            case 0xbd: processLDA(opcode: opcode)
            case 0xbe: processLDX(opcode: opcode)
            case 0xbf: processLAX(opcode: opcode)
            case 0xc0: processCPY(opcode: opcode)
            case 0xc1: processCMP(opcode: opcode)
            case 0xc2: processNOP(opcode: opcode)
            case 0xc3: processDCP(opcode: opcode)
            case 0xc4: processCPY(opcode: opcode)
            case 0xc5: processCMP(opcode: opcode)
            case 0xc6: processDEC(opcode: opcode)
            case 0xc7: processDCP(opcode: opcode)
            case 0xc8: processINY(opcode: opcode)
            case 0xc9: processCMP(opcode: opcode)
            case 0xca: processDEX(opcode: opcode)
            case 0xcb: processAXS(opcode: opcode)
            case 0xcc: processCPY(opcode: opcode)
            case 0xcd: processCMP(opcode: opcode)
            case 0xce: processDEC(opcode: opcode)
            case 0xcf: processDCP(opcode: opcode)
            case 0xd0: processBNE(opcode: opcode)
            case 0xd1: processCMP(opcode: opcode)
            case 0xd2: processKIL(opcode: opcode)
            case 0xd3: processDCP(opcode: opcode)
            case 0xd4: processNOP(opcode: opcode)
            case 0xd5: processCMP(opcode: opcode)
            case 0xd6: processDEC(opcode: opcode)
            case 0xd7: processDCP(opcode: opcode)
            case 0xd8: processCLD(opcode: opcode)
            case 0xd9: processCMP(opcode: opcode)
            case 0xda: processNOP(opcode: opcode)
            case 0xdb: processDCP(opcode: opcode)
            case 0xdc: processNOP(opcode: opcode)
            case 0xdd: processCMP(opcode: opcode)
            case 0xde: processDEC(opcode: opcode)
            case 0xdf: processDCP(opcode: opcode)
            case 0xe0: processCPX(opcode: opcode)
            case 0xe1: processSBC(opcode: opcode)
            case 0xe2: processNOP(opcode: opcode)
            case 0xe3: processISC(opcode: opcode)
            case 0xe4: processCPX(opcode: opcode)
            case 0xe5: processSBC(opcode: opcode)
            case 0xe6: processINC(opcode: opcode)
            case 0xe7: processISC(opcode: opcode)
            case 0xe8: processINX(opcode: opcode)
            case 0xe9: processSBC(opcode: opcode)
            case 0xea: processNOP(opcode: opcode)
            case 0xeb: processSBC(opcode: opcode)
            case 0xec: processCPX(opcode: opcode)
            case 0xed: processSBC(opcode: opcode)
            case 0xee: processINC(opcode: opcode)
            case 0xef: processISC(opcode: opcode)
            case 0xf0: processBEQ(opcode: opcode)
            case 0xf1: processSBC(opcode: opcode)
            case 0xf2: processKIL(opcode: opcode)
            case 0xf3: processISC(opcode: opcode)
            case 0xf4: processNOP(opcode: opcode)
            case 0xf5: processSBC(opcode: opcode)
            case 0xf6: processINC(opcode: opcode)
            case 0xf7: processISC(opcode: opcode)
            case 0xf8: processSED(opcode: opcode)
            case 0xf9: processSBC(opcode: opcode)
            case 0xfa: processNOP(opcode: opcode)
            case 0xfb: processISC(opcode: opcode)
            case 0xfc: processNOP(opcode: opcode)
            case 0xfd: processSBC(opcode: opcode)
            case 0xfe: processINC(opcode: opcode)
            case 0xff: processISC(opcode: opcode)
            default:   processKIL(opcode: Emu6510Opcodes[0x02])
        }

        // Update the program counter.
        _pc &+= UInt16(opcode.addressingMode.byteCount)
    }

    @inlinable func addrFromIndirectAddr(address: UInt16) -> AddressInfo {
        let a: UInt16 = makeWord(lo: addressBuss[address], hi: addressBuss[address &+ 1])
        let b: UInt16 = ((a & 0xff00) | ((a &+ 1) & 0x00ff)) // Handle the case of wrap-around.
        return (false, makeWord(lo: addressBuss[a], hi: addressBuss[b]))
    }

    @inlinable func addrFromAddr(address: UInt16, offset: UInt8) -> AddressInfo {
        makeWord(lo: addressBuss[address], hi: addressBuss[address &+ 1], offset: offset)
    }

    @inlinable func addrFromAddr(address: UInt16) -> AddressInfo {
        (false, makeWord(lo: addressBuss[address], hi: addressBuss[address &+ 1]))
    }

    @inlinable func addrFromAddr(address: UInt8) -> AddressInfo {
        (false, makeWord(lo: addressBuss[address], hi: addressBuss[address &+ 1]))
    }

    @inlinable func addrFromAddr(address: UInt8, offset: UInt8) -> AddressInfo {
        makeWord(lo: addressBuss[address], hi: addressBuss[address &+ 1], offset: offset)
    }

    /*===========================================================================================================================*/
    /// This method calculates the effective address based on the opcode's addressing mode. Also, if the address mode is valid, it
    /// advances the program counter to the next opcode.
    /// 
    /// - Parameter mode: the addressing mode.
    /// - Returns: returns `nil` if the address mode is either `AddressModes.ACC` or `AddressModes.IMP` or it returns `AddressInfo`
    ///            with the address and whether or not the operation might suffer a clock cycle penalty.
    ///
    @inlinable func getEffectiveAddress(mode: AddressModes) -> AddressInfo? {
        let __ad: UInt16 = (_pc &+ 2)

        if mode == .IMM || mode == .REL {
            return (false, __ad)
        }
        else {
            switch mode {
                case .ABS: return addrFromAddr(address: __ad)
                case .ABX: return addrFromAddr(address: __ad, offset: _xreg)
                case .ABY: return addrFromAddr(address: __ad, offset: _yreg)
                case .IND: return addrFromIndirectAddr(address: __ad)
                case .INX: return addrFromAddr(address: addressBuss[__ad] &+ _xreg)
                case .INY: return addrFromAddr(address: addressBuss[__ad], offset: _yreg)
                case .ZPG: return (false, UInt16(addressBuss[__ad]))
                case .ZPX: return (false, UInt16(addressBuss[__ad] &+ _xreg))
                case .ZPY: return (false, UInt16(addressBuss[__ad] &+ _yreg))
                default:   return nil
            }
        }
    }

    /*===========================================================================================================================*/
    /// This method is for opcodes that take a single byte operand.
    /// 
    /// - Parameters:
    ///   - mode: the addressing mode.
    /// - Returns: `OperandInfo` containing the single byte operand or `nil` if the addressing mode is `AddressModes.IMP` (Implied).
    ///
    @inlinable func getOperand(mode: AddressModes) -> OperandInfo? {
        if mode == .ACC { return (false, _accu) }
        else if let ea: AddressInfo = getEffectiveAddress(mode: mode) { return (ea.pageBoundaryCrossed, addressBuss[ea.address]) }
        else { return nil }
    }

    @inlinable func getOperand(opcode: OpcodeInfo) -> OperandInfo? {
        if let opInfo: OperandInfo = getOperand(mode: opcode.addressingMode) {
            if opcode.mayBePenalty && opInfo.pageBoundaryCrossed { _nextOpTime += _cycle }
            return opInfo
        }
        return nil
    }

    /*===========================================================================================================================*/
    /// Called after an operation that is to be stored back into a memory location. Mainly these are the bit-shift operations and
    /// the store operations.
    /// 
    /// - Parameters:
    ///   - value: the value to store.
    ///   - mode: the addressing mode.
    /// - Returns: `OperandInfo` or `nil` if the addressing mode is `AddressModes.IMP` (Implied).
    ///
    @inlinable @discardableResult func storeResults(value: UInt8, mode: AddressModes) -> OperandInfo? {
        switch mode {
            case .ACC:
                _accu = value
                return (false, value)
            case .ABS, .ABX, .ABY, .IND, .INX, .INY, .ZPG, .ZPX, .ZPY:
                if let ea: AddressInfo = getEffectiveAddress(mode: mode) {
                    addressBuss[ea.address] = value
                    return (ea.pageBoundaryCrossed, value)
                }
            default:
                break
        }
        return nil
    }

    @inlinable func decSP() -> UInt16 {
        _sp = ((_sp + 1) & 0x00ff)
        return _sp
    }

    @inlinable func incSP() -> UInt16 {
        let v: UInt16 = _sp
        _sp = ((_sp &- 1) & 0x00ff)
        return v
    }

    @inlinable func pullByte() -> UInt8 {
        addressBuss[_stackAddr + decSP()]
    }

    @inlinable func pullWord() -> UInt16 {
        let lo: UInt8 = pullByte()
        let hi: UInt8 = pullByte()
        return makeWord(lo: lo, hi: hi)
    }

    @inlinable func push(byte: UInt8) {
        addressBuss[_stackAddr + incSP()] = byte
    }

    @inlinable func push(word: UInt16) {
        push(byte: UInt8(word >> 8))   // hi
        push(byte: UInt8(word & 0xff)) // lo
    }

    @inlinable func doBranchOnCondition(offset: UInt8, cond: Bool) {
        if cond {
            let pc: UInt16 = (_pc &+ 2)
            let ad: UInt16 = ((offset < 128) ? (pc + UInt16(offset)) : (pc - UInt16(~(offset - 1))))
            _nextOpTime &+= (onSamePage(pc, ad) ? _cycle : (_cycle * 2))
        }
    }

    @inlinable func doJump(mode: AddressModes) {
        if (mode == .IND || mode == .ABS), let eAddr: AddressInfo = getEffectiveAddress(mode: mode) { _pc = (eAddr.address &- 1) }
        else { processKIL(opcode: Emu6510Opcodes[0x02]) }
    }

    /*===========================================================================================================================*/
    /// The setting of the N, Z, and C status register flags is something that occurs very often so I wrapped it into it's own
    /// method for convienience.
    /// 
    /// - Parameters:
    ///   - value: the value being tested for being negative or zero.
    ///   - carrySet: If `true` the carry flag will be set. If `false` the carry flag will be cleared. If `nil` (default) the carry
    ///               flag will be let as is.
    /// - Returns: the updated value of the status register.
    ///
    @inlinable @discardableResult func updateNZCstatus(ans: UInt8, c: Bool? = nil) -> UInt8 {
        PF.Negative.set(status: &_st, when: (ans &== PF.Negative))
        PF.Zero.set(status: &_st, when: (ans == 0))
        if let c: Bool = c { PF.Carry.set(status: &_st, when: c) }
        return _st
    }

    /*===========================================================================================================================*/
    /// Convienience method for setting or clearing the carry flag.
    /// 
    /// - Parameter carrySet: `true` to set the carry flag or `false` to clear it.
    /// - Returns: the updated value of the status register.
    ///
    @inlinable @discardableResult func updateCStatus(carrySet: Bool) -> UInt8 { PF.Carry.set(status: &_st, when: carrySet) }

    /*===========================================================================================================================*/
    /// Update the overflow flag. See: [The 6502 overflow flag explained
    /// mathematically](http://www.righto.com/2012/12/the-6502-overflow-flag-explained.html)
    /// 
    /// - Parameters:
    ///   - ans: The result of the addition or subtraction.
    ///   - lhs: The value of the accumulator before the addition or subtraction.
    ///   - rhs: The value that was added to the accumulator.
    /// - Returns: the updated status register.
    ///
    @inlinable @discardableResult func updateVstatus(ans: UInt16, lhs: UInt16, rhs: UInt16) -> UInt8 {
        PF.Overflow.set(status: &_st, when: ((ans ^ lhs) & (ans ^ rhs)) &== 0x80)
    }

    /*===========================================================================================================================*/
    /// Binary addition/subtraction. (Subtraction is simply addition with the 1's compliment of the right-hand operand.)
    /// 
    /// - Parameters:
    ///   - lhs: left-hand operand.
    ///   - rhs: right-hand operand.
    /// - Returns: the result of the addition.
    ///
    @inlinable @discardableResult func binaryADC(lhs: UInt16, rhs: UInt16) -> UInt8 {
        let ans: UInt16 = (lhs + rhs + UInt16(_st & PF.Carry))
        _accu = UInt8(ans & 0xff)
        updateVstatus(ans: ans, lhs: lhs, rhs: rhs)
        updateNZCstatus(ans: _accu, c: ans &== 0x0100)
        return _accu
    }

    /*===========================================================================================================================*/
    /// Decimal mode addition. See: [6502.org Tutorials: Decimal Mode](http://www.6502.org/tutorials/decimal_mode.html)
    /// 
    /// - Parameters:
    ///   - lhs: The left-hand operand in BCD.
    ///   - rhs: The right-hand operand in BCD.
    /// - Returns: The result of the addition in BCD.
    ///
    @inlinable @discardableResult func decimalADC(lhs: UInt16, rhs: UInt16) -> UInt8 {
        let c:  UInt16 = UInt16(_st & PF.Carry)
        let a1: UInt16 = ((lhs & 0x0f) &+ (rhs & 0x0f) &+ c)
        let a2: UInt16 = ((lhs & 0xf0) &+ (rhs & 0xf0) &+ ((a1 > 0x09) ? (((a1 &+ 0x06) & 0x0f) &+ 0x10) : a1))
        let a3: UInt16 = ((a2 > 0x90) ? (a2 &+ 0x60) : a2)

        _accu = UInt8(a3 & 0xff)

        updateVstatus(ans: a2, lhs: lhs, rhs: rhs)
        PF.Negative.set(status: &_st, when: a2 &== 0x80)
        PF.Zero.set(status: &_st, when: ((lhs + rhs + c) & 0xff) == 0)
        PF.Carry.set(status: &_st, when: a3 > 0xff)

        return _accu
    }

    /*===========================================================================================================================*/
    /// Decimal mode subtraction. See: [6502.org Tutorials: Decimal Mode](http://www.6502.org/tutorials/decimal_mode.html)
    /// 
    /// - Parameters:
    ///   - lhs: The left-hand operand in BCD.
    ///   - rhs: The right-hand operand in BCD.
    /// - Returns: The result of the subtraction in BCD.
    ///
    @inlinable @discardableResult func decimalSBC(lhs: Int16, rhs: Int16) -> UInt8 {
        // REVISIT: May need to be adjusted.
        let c: Int16 = (Int16(_st & PF.Carry) - 1)
        let x: Int16 = ((lhs & 0x0f) - (rhs & 0x0f) + c)
        let y: Int16 = ((lhs & 0xf0) - (rhs & 0xf0) + ((x < 0) ? (((x - 0x06) & 0x0f) - 0x10) : x))
        let z: Int16 = (lhs - rhs + c)

        _accu = UInt8(bitPattern: Int8(((y < 0) ? (y - 0x60) : y) & 0xff))
        updateNZCstatus(ans: _accu, c: z > 255)
        updateVstatus(ans: UInt16(bitPattern: z), lhs: UInt16(bitPattern: lhs), rhs: UInt16(bitPattern: rhs))
        return _accu
    }

    /*===========================================================================================================================*/
    /// Handles the ADC opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processADC(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(opcode: opcode) {
            if _st &== PF.Decimal { decimalADC(lhs: UInt16(_accu), rhs: UInt16(opInfo.operand)) }
            else { binaryADC(lhs: UInt16(_accu), rhs: UInt16(opInfo.operand)) }
        }
        else {
            processKIL()
        }
    }

    /*===========================================================================================================================*/
    /// Handles the AHX opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processAHX(opcode: OpcodeInfo) {
        // TODO: processAHX opcode
    }

    /*===========================================================================================================================*/
    /// Handles the ALR opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processALR(opcode: OpcodeInfo) {
        // TODO: processALR opcode
    }

    /*===========================================================================================================================*/
    /// Handles the ANC opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processANC(opcode: OpcodeInfo) {
        // TODO: processANC opcode
    }

    /*===========================================================================================================================*/
    /// Handles the AND opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processAND(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(opcode: opcode) {
            _accu &= opInfo.operand
            updateNZCstatus(ans: _accu)
        }
        else {
            processKIL()
        }
    }

    /*===========================================================================================================================*/
    /// Handles the ARR opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processARR(opcode: OpcodeInfo) {
        // TODO: processARR opcode
    }

    /*===========================================================================================================================*/
    /// Handles the ASL opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processASL(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(opcode: opcode) {
            let r: UInt8 = (opInfo.operand << 1)
            storeResults(value: r, mode: opcode.addressingMode)
            updateNZCstatus(ans: r, c: (opInfo.operand &== 0x80))
        }
        else {
            processKIL()
        }
    }

    /*===========================================================================================================================*/
    /// Handles the AXS opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processAXS(opcode: OpcodeInfo) {
        // TODO: processAXS opcode
    }

    /*===========================================================================================================================*/
    /// Handles the BCC opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBCC(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(mode: opcode.addressingMode) { doBranchOnCondition(offset: opInfo.operand, cond: (_st &!= PF.Carry)) }
        else { processKIL() }
    }

    /*===========================================================================================================================*/
    /// Handles the BCS opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBCS(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(mode: opcode.addressingMode) { doBranchOnCondition(offset: opInfo.operand, cond: (_st &== PF.Carry)) }
        else { processKIL() }
    }

    /*===========================================================================================================================*/
    /// Handles the BEQ opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBEQ(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(mode: opcode.addressingMode) { doBranchOnCondition(offset: opInfo.operand, cond: (_st &== PF.Zero)) }
        else { processKIL() }
    }

    /*===========================================================================================================================*/
    /// Handles the BIT opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBIT(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(mode: opcode.addressingMode) {
            PF.Zero.set(status: &_st, when: (_accu & opInfo.operand) == 0)
            let f: UInt8 = (PF.Negative | PF.Overflow)
            _st = ((_st & ~f) | (opInfo.operand & f))
        }
        else {
            processKIL()
        }
    }

    /*===========================================================================================================================*/
    /// Handles the BMI opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBMI(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(mode: opcode.addressingMode) { doBranchOnCondition(offset: opInfo.operand, cond: (_st &== PF.Negative)) }
        else { processKIL() }
    }

    /*===========================================================================================================================*/
    /// Handles the BNE opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBNE(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(mode: opcode.addressingMode) { doBranchOnCondition(offset: opInfo.operand, cond: (_st &!= PF.Zero)) }
        else { processKIL() }
    }

    /*===========================================================================================================================*/
    /// Handles the BPL opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBPL(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(mode: opcode.addressingMode) { doBranchOnCondition(offset: opInfo.operand, cond: (_st &!= PF.Negative)) }
        else { processKIL() }
    }

    /*===========================================================================================================================*/
    /// Handles the BRK opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBRK(opcode: OpcodeInfo) {
        _pc++
        _nmiTriggered = true
    }

    /*===========================================================================================================================*/
    /// Handles the BVC opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBVC(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(mode: opcode.addressingMode) { doBranchOnCondition(offset: opInfo.operand, cond: (_st &!= PF.Overflow)) }
        else { processKIL() }
    }

    /*===========================================================================================================================*/
    /// Handles the BVS opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBVS(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(mode: opcode.addressingMode) { doBranchOnCondition(offset: opInfo.operand, cond: (_st &== PF.Overflow)) }
        else { processKIL() }
    }

    /*===========================================================================================================================*/
    /// Handles the CLC opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processCLC(opcode: OpcodeInfo) {
        _st &= ~PF.Carry
    }

    /*===========================================================================================================================*/
    /// Handles the CLD opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processCLD(opcode: OpcodeInfo) {
        _st &= ~PF.Decimal
    }

    /*===========================================================================================================================*/
    /// Handles the CLI opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processCLI(opcode: OpcodeInfo) {
        _st &= ~PF.Interrupt
    }

    /*===========================================================================================================================*/
    /// Handles the CLV opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processCLV(opcode: OpcodeInfo) {
        _st &= ~PF.Overflow
    }

    @inlinable func compare(_ r: UInt8, _ o: UInt8) {
        PF.Carry.set(status: &_st, when: r >= o)
        PF.Negative.set(status: &_st, when: r >= 128)
        PF.Zero.set(status: &_st, when: r == o)
    }

    /*===========================================================================================================================*/
    /// Handles the CMP opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processCMP(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(opcode: opcode) {
            compare(_accu, opInfo.operand)
        }
        else { processKIL() }
    }

    /*===========================================================================================================================*/
    /// Handles the CPX opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processCPX(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(opcode: opcode) {
            compare(_xreg, opInfo.operand)
        }
        else { processKIL() }
    }

    /*===========================================================================================================================*/
    /// Handles the CPY opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processCPY(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(opcode: opcode) {
            compare(_yreg, opInfo.operand)
        }
        else { processKIL() }
    }

    /*===========================================================================================================================*/
    /// Handles the DCP opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processDCP(opcode: OpcodeInfo) {
        // TODO: processDCP opcode
    }

    /*===========================================================================================================================*/
    /// Handles the DEC opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processDEC(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(opcode: opcode) {
            let r: UInt8 = (opInfo.operand &- 1)
            updateNZCstatus(ans: r)
            storeResults(value: r, mode: opcode.addressingMode)
        }
        else {
            processKIL()
        }
    }

    /*===========================================================================================================================*/
    /// Handles the DEX opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processDEX(opcode: OpcodeInfo) {
        updateNZCstatus(ans: ---_xreg)
    }

    /*===========================================================================================================================*/
    /// Handles the DEY opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processDEY(opcode: OpcodeInfo) {
        updateNZCstatus(ans: ---_yreg)
    }

    /*===========================================================================================================================*/
    /// Handles the EOR opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processEOR(opcode: OpcodeInfo) {
        if let oi: OperandInfo = getOperand(opcode: opcode) {
            _accu = (_accu ^ oi.operand)
            updateNZCstatus(ans: _accu)
        }
        else {
            processKIL()
        }
    }

    /*===========================================================================================================================*/
    /// Handles the INC opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processINC(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(opcode: opcode) {
            let r: UInt8 = (opInfo.operand &+ 1)
            updateNZCstatus(ans: r)
            storeResults(value: r, mode: opcode.addressingMode)
        }
        else {
            processKIL()
        }
    }

    /*===========================================================================================================================*/
    /// Handles the INX opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processINX(opcode: OpcodeInfo) {
        updateNZCstatus(ans: +++_xreg)
    }

    /*===========================================================================================================================*/
    /// Handles the INY opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processINY(opcode: OpcodeInfo) {
        updateNZCstatus(ans: +++_yreg)
    }

    /*===========================================================================================================================*/
    /// Handles the ISC opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processISC(opcode: OpcodeInfo) {
        // TODO: processISC opcode
    }

    /*===========================================================================================================================*/
    /// Handles the JMP opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processJMP(opcode: OpcodeInfo) {
        doJump(mode: opcode.addressingMode)
    }

    /*===========================================================================================================================*/
    /// Handles the JSR opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processJSR(opcode: OpcodeInfo) {
        push(word: _pc + 2)
        doJump(mode: opcode.addressingMode)
    }

    /*===========================================================================================================================*/
    /// Handles the KIL opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    open func processKIL(opcode: OpcodeInfo) {
        processKIL()
    }

    @inlinable open func processKIL() {
        try? stop()
    }

    /*===========================================================================================================================*/
    /// Handles the LAS opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processLAS(opcode: OpcodeInfo) {
        // TODO: processLAS opcode
    }

    /*===========================================================================================================================*/
    /// Handles the LAX opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processLAX(opcode: OpcodeInfo) {
        // TODO: processLAX opcode
    }

    /*===========================================================================================================================*/
    /// Handles the LDA opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processLDA(opcode: OpcodeInfo) {
        if let oi: OperandInfo = getOperand(opcode: opcode) {
            _accu = oi.operand
            updateNZCstatus(ans: _accu)
        }
        else {
            processKIL()
        }
    }

    /*===========================================================================================================================*/
    /// Handles the LDX opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processLDX(opcode: OpcodeInfo) {
        if let oi: OperandInfo = getOperand(opcode: opcode) {
            _xreg = oi.operand
            updateNZCstatus(ans: _xreg)
        }
        else {
            processKIL()
        }
    }

    /*===========================================================================================================================*/
    /// Handles the LDY opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processLDY(opcode: OpcodeInfo) {
        if let oi: OperandInfo = getOperand(opcode: opcode) {
            _yreg = oi.operand
            updateNZCstatus(ans: _yreg)
        }
        else {
            processKIL()
        }
    }

    /*===========================================================================================================================*/
    /// Handles the LSR opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processLSR(opcode: OpcodeInfo) {
        if let oi: OperandInfo = getOperand(opcode: opcode) {
            let r: UInt8 = (oi.operand >> 1)
            updateNZCstatus(ans: r, c: oi.operand &== 1)
            storeResults(value: r, mode: opcode.addressingMode)
        }
        else {
            processKIL()
        }
    }

    /*===========================================================================================================================*/
    /// Handles the NOP opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processNOP(opcode: OpcodeInfo) {
        // Don't do a damn thing!!!!
    }

    /*===========================================================================================================================*/
    /// Handles the ORA opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processORA(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(opcode: opcode) {
            _accu |= opInfo.operand
            updateNZCstatus(ans: _accu)
        }
        else {
            processKIL()
        }
    }

    /*===========================================================================================================================*/
    /// Handles the PHA opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processPHA(opcode: OpcodeInfo) {
        push(byte: _accu)
    }

    /*===========================================================================================================================*/
    /// Handles the PHP opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processPHP(opcode: OpcodeInfo) {
        push(byte: _st)
    }

    /*===========================================================================================================================*/
    /// Handles the PLA opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processPLA(opcode: OpcodeInfo) {
        _accu = pullByte()
        updateNZCstatus(ans: _accu)
    }

    /*===========================================================================================================================*/
    /// Handles the PLP opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processPLP(opcode: OpcodeInfo) {
        _st = pullByte()
    }

    /*===========================================================================================================================*/
    /// Handles the RLA opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processRLA(opcode: OpcodeInfo) {
        // TODO: processRLA opcode
    }

    /*===========================================================================================================================*/
    /// Handles the ROL opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processROL(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(opcode: opcode) {
            let result: UInt8 = ((opInfo.operand << 1) | (_st & PF.Carry))
            storeResults(value: result, mode: opcode.addressingMode)
            updateNZCstatus(ans: result, c: opInfo.operand &== PF.Negative)
        }
        else {
            processKIL()
        }
    }

    /*===========================================================================================================================*/
    /// Handles the ROR opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processROR(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(opcode: opcode) {
            let result: UInt8 = ((opInfo.operand >> 1) | ((_st & PF.Carry) << 7))
            storeResults(value: result, mode: opcode.addressingMode)
            updateNZCstatus(ans: result, c: opInfo.operand &== 1)
        }
        else {
            processKIL()
        }
    }

    /*===========================================================================================================================*/
    /// Handles the RRA opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processRRA(opcode: OpcodeInfo) {
        // TODO: processRRA opcode
    }

    /*===========================================================================================================================*/
    /// Handles the RTI opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processRTI(opcode: OpcodeInfo) {
        _st = pullByte()
        _pc = (pullWord() &- 1)
    }

    /*===========================================================================================================================*/
    /// Handles the RTS opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processRTS(opcode: OpcodeInfo) {
        _pc = pullWord()
    }

    /*===========================================================================================================================*/
    /// Handles the SAX opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processSAX(opcode: OpcodeInfo) {
        // TODO: processSAX opcode
    }

    /*===========================================================================================================================*/
    /// Handles the SBC opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processSBC(opcode: OpcodeInfo) {
        if let opInfo: OperandInfo = getOperand(opcode: opcode) {
            if (_st &== PF.Decimal) { decimalSBC(lhs: Int16(bitPattern: UInt16(_accu)), rhs: Int16(bitPattern: UInt16(opInfo.operand))) }
            else { binaryADC(lhs: UInt16(_accu), rhs: UInt16(255 &- opInfo.operand)) /* Subtraction is nothing but addition with the 1's complement of operand. */ }
        }
        else {
            processKIL()
        }
    }

    /*===========================================================================================================================*/
    /// Handles the SEC opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processSEC(opcode: OpcodeInfo) {
        _st |= PF.Carry
    }

    /*===========================================================================================================================*/
    /// Handles the SED opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processSED(opcode: OpcodeInfo) {
        _st |= PF.Decimal
    }

    /*===========================================================================================================================*/
    /// Handles the SEI opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processSEI(opcode: OpcodeInfo) {
        _st |= PF.Interrupt
    }

    /*===========================================================================================================================*/
    /// Handles the SHX opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processSHX(opcode: OpcodeInfo) {
        // TODO: processSHX opcode
    }

    /*===========================================================================================================================*/
    /// Handles the SHY opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processSHY(opcode: OpcodeInfo) {
        // TODO: processSHY opcode
    }

    /*===========================================================================================================================*/
    /// Handles the SLO opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processSLO(opcode: OpcodeInfo) {
        // TODO: processSLO opcode
    }

    /*===========================================================================================================================*/
    /// Handles the SRE opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processSRE(opcode: OpcodeInfo) {
        // TODO: processSRE opcode
    }

    /*===========================================================================================================================*/
    /// Handles the STA opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processSTA(opcode: OpcodeInfo) {
        storeResults(value: _accu, mode: opcode.addressingMode)
    }

    /*===========================================================================================================================*/
    /// Handles the STX opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processSTX(opcode: OpcodeInfo) {
        storeResults(value: _xreg, mode: opcode.addressingMode)
    }

    /*===========================================================================================================================*/
    /// Handles the STY opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processSTY(opcode: OpcodeInfo) {
        storeResults(value: _yreg, mode: opcode.addressingMode)
    }

    /*===========================================================================================================================*/
    /// Handles the TAS opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processTAS(opcode: OpcodeInfo) {
        _sp = UInt16(_accu)
    }

    /*===========================================================================================================================*/
    /// Handles the TAX opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processTAX(opcode: OpcodeInfo) {
        _xreg = _accu
        updateNZCstatus(ans: _xreg)
    }

    /*===========================================================================================================================*/
    /// Handles the TAY opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processTAY(opcode: OpcodeInfo) {
        _yreg = _accu
        updateNZCstatus(ans: _yreg)
    }

    /*===========================================================================================================================*/
    /// Handles the TSX opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processTSX(opcode: OpcodeInfo) {
        _xreg = UInt8(_sp & 0xff)
        updateNZCstatus(ans: _xreg)
    }

    /*===========================================================================================================================*/
    /// Handles the TXA opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processTXA(opcode: OpcodeInfo) {
        _accu = _xreg
        updateNZCstatus(ans: _accu)
    }

    /*===========================================================================================================================*/
    /// Handles the TXS opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processTXS(opcode: OpcodeInfo) {
        _sp = UInt16(_xreg)
    }

    /*===========================================================================================================================*/
    /// Handles the TYA opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processTYA(opcode: OpcodeInfo) {
        _accu = _yreg
        updateNZCstatus(ans: _accu)
    }

    /*===========================================================================================================================*/
    /// Handles the XAA opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processXAA(opcode: OpcodeInfo) {
        // TODO: processXAA opcode
    }
}
