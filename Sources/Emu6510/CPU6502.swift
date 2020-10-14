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

public class CPU6502: CPU65xx, Equatable {

    @usableFromInline @frozen enum SpinLock {
        case Free
        case Locking
        case Locked
    }

    public var addressBuss:    AnyAddressBuss
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

    @usableFromInline let _cond:         Conditional          = Conditional()
    @usableFromInline var _tickWait:     Int                  = 0
    @usableFromInline var _irqTriggered: Bool                 = false
    @usableFromInline var _nmiTriggered: Bool                 = false
    @usableFromInline var _brkTriggered: Bool                 = false
    @usableFromInline var _watchers:     Set<AnyClockWatcher> = []
    @usableFromInline var _nextOpTime:   UInt64               = 0
    @usableFromInline var _nextWTime:    UInt64               = 0
    @usableFromInline var _spinLock:     SpinLock             = .Free
    @usableFromInline var _tstime:       timespec             = timespec(tv_sec: 0, tv_nsec: 0)

    public init(clockFrequency: ClockFrequencies = .C64_NTSC, addressBuss: AddressBuss) {
        self.addressBuss = addressBuss.asEquatable()
        self.clockFrequency = clockFrequency
        _cycle = self.clockFrequency.clockCycle
    }

    deinit { _cond.withLock { runStatus = .Stopped } }

    @inlinable public func asAnyCPU65xx() -> AnyCPU65xx { AnyCPU65xx(self) }

    @inlinable public func asAnyCPUClock() -> AnyCPUClock { AnyCPUClock(self) }

    @inlinable public func isEqualTo(_ other: CPUClock) -> Bool {
        guard let other: CPU6502 = other as? CPU6502 else { return false }
        return self === other
    }

    @inlinable public func isEqualTo(_ other: CPU65xx) -> Bool {
        guard type(of: other) == CPU6502.self else { return false }
        return self == (other as! CPU6502)
    }

    @inlinable public static func == (lhs: CPU6502, rhs: CPU6502) -> Bool { lhs === rhs }

    @inlinable func getSysTime() -> UInt64 {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            return UInt64(clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW))
        #else
            clock_gettime(CLOCK_MONOTONIC_RAW, &_tstime)
            return ((UInt64(_tstime.tv_sec) * 1000000000.0) + UInt64(_tstime.tv_nsec))
        #endif
    }

    @inlinable func performInterrupt(vector: UInt16) {
        push(word: _pc &+ 1)
        push(byte: _st)
        _st &= ~(PF.Interrupt | PF.Break)
        _pc = (makeWord(lo: addressBuss[vector], hi: addressBuss[vector + 1]) &- 1)
        _nextOpTime &+= 6
    }

    @inlinable func notifyWatchers() {
        _nextWTime &+= _cycle
        for var w in _watchers { w.fire() }
    }

    @inlinable func doNextInstruction() {
        notifyWatchers()
        //
        // Non-maskable Interrupts have the highest priority...
        //
        if _nmiTriggered {
            _nmiTriggered = false
            performInterrupt(vector: 0xfffa)
        }
        //
        // ...Followed by BRK...
        //
        else if _brkTriggered {
            _brkTriggered = false
            _irqTriggered = false
            _st |= PF.Break
            performInterrupt(vector: 0xfffe)
        }
        //
        // ...Followed by IRQ.
        //
        else if _irqTriggered && !(_st &== PF.Interrupt) {
            _brkTriggered = false
            _irqTriggered = false
            performInterrupt(vector: 0xfffe)
        }
        else {
            let opcode: OpcodeInfo = opcodes[Int(addressBuss[_pc + 1])]
            _nextOpTime &+= (_cycle * opcode.cycleCount)
            dispatchOpcode(opcode: opcode)
            // Update the program counter.
            _pc &+= UInt16(opcode.addressingMode.byteCount)
        }
    }

    private func _run() {
        performReset()
        _nextOpTime = (getSysTime() + _cycle)
        _nextWTime = _nextOpTime

        while runStatus != .Stopped {
            switch _spinLock {
                case .Free:
                    if runStatus == .Paused {
                        _cond.withLockWait { runStatus != .Paused }
                    }
                    else {
                        let thisTime: UInt64 = getSysTime()
                        if thisTime >= _nextOpTime { doNextInstruction() }
                        else if thisTime >= _nextWTime { notifyWatchers() }
                    }
                case .Locking:
                    _spinLock = .Locked
                    fallthrough
                case .Locked:
                    while runStatus != .Stopped && _spinLock == .Locked {}
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
            let watcher: AnyClockWatcher = watcher.asEquatable()
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
            let watcher: AnyClockWatcher = watcher.asEquatable()
            if _watchers.contains(watcher) {
                _spinLock = .Locking
                while runStatus == .Running && _spinLock != .Locked {}
                _watchers.remove(watcher)
                _spinLock = .Free
            }
        }
    }

    open func performReset() {
        _accu = 0xaa
        _xreg = 0
        _yreg = 0
        _st = (0x16 | 0x20)
        _sp = 0xfd
        _pc = (makeWord(lo: addressBuss[0xfffc], hi: addressBuss[0xfffd]) &- 1)
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
            default:   processKIL(opcode: opcodes[0x02])
        }
    }

    @inlinable func addrFromIndirectAddr(address: UInt16) -> AddressInfo {
        let a: UInt16 = makeWord(lo: addressBuss[address], hi: addressBuss[address &+ 1])
        let b: UInt16 = ((a & 0xff00) | ((a &+ 1) & 0x00ff)) // Handle the case of wrap-around.
        return (false, makeWord(lo: addressBuss[a], hi: addressBuss[b]))
    }

    @inlinable func addrFromAddr(address: UInt16) -> AddressInfo {
        (false, makeWord(lo: addressBuss[address], hi: addressBuss[address &+ 1]))
    }

    @inlinable func addrFromAddr(address: UInt16, offset: UInt8) -> AddressInfo {
        makeWord(lo: addressBuss[address], hi: addressBuss[address &+ 1], offset: offset)
    }

    public func doWithEffectiveAddress(mode: AddressModes, block: (AddressInfo) -> Void) {
        let __ad: UInt16 = (_pc &+ 2)

        if mode == .IMM || mode == .REL {
            block((false, __ad))
        }
        else {
            switch mode {
                case .ABS: block(addrFromAddr(address: __ad))
                case .ABX: block(addrFromAddr(address: __ad, offset: _xreg))
                case .ABY: block(addrFromAddr(address: __ad, offset: _yreg))
                case .IND: block(addrFromIndirectAddr(address: __ad))
                case .INX: block(addrFromAddr(address: UInt16(addressBuss[__ad] &+ _xreg)))
                case .INY: block(addrFromAddr(address: UInt16(addressBuss[__ad]), offset: _yreg))
                case .ZPG: block((false, UInt16(addressBuss[__ad])))
                case .ZPX: block((false, UInt16(addressBuss[__ad] &+ _xreg)))
                case .ZPY: block((false, UInt16(addressBuss[__ad] &+ _yreg)))
                default:   try? stop()
            }
        }
    }

    public func doWithOperand(opcode: OpcodeInfo, block: (OperandInfo) -> Void) {
        if opcode.addressingMode == .ACC {
            block((false, _accu))
        }
        else {
            doWithEffectiveAddress(mode: opcode.addressingMode) {
                (ai: AddressInfo) in
                if opcode.mayBePenalty && ai.pageBoundaryCrossed { _nextOpTime += _cycle }
                block((ai.pageBoundaryCrossed, addressBuss[ai.address]))
            }
        }
    }

    /*===========================================================================================================================*/
    /// Called after an operation that is to be stored back into a memory location. Mainly these are the bit-shift operations and
    /// the store operations.
    /// 
    /// - Parameters:
    ///   - value: the value to store.
    ///   - mode: the addressing mode.
    ///
    @inlinable public func storeResults(value: UInt8, mode: AddressModes) {
        if mode == .ACC { _accu = value }
        else { doWithEffectiveAddress(mode: mode) { (ea: AddressInfo) in addressBuss[ea.address] = value } }
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

    @inlinable public func pullByte() -> UInt8 {
        addressBuss[_stackAddr + decSP()]
    }

    @inlinable public func pullWord() -> UInt16 {
        let lo: UInt8 = pullByte()
        let hi: UInt8 = pullByte()
        return makeWord(lo: lo, hi: hi)
    }

    @inlinable public func push(byte: UInt8) {
        addressBuss[_stackAddr + incSP()] = byte
    }

    @inlinable public func push(word: UInt16) {
        push(byte: UInt8(word >> 8))   // hi
        push(byte: UInt8(word & 0xff)) // lo
    }

    @inlinable public func doBranchOnCondition(offset: UInt8, cond: Bool) {
        if cond {
            let pc: UInt16 = (_pc &+ 2)
            let ad: UInt16 = ((offset < 128) ? (pc + UInt16(offset)) : (pc - UInt16(~~offset)))
            _nextOpTime &+= ((((pc ^ ad) & 0xff00) == 0) ? _cycle : (_cycle * 2))
        }
    }

    @inlinable @discardableResult func updateStatus(N: Bool, Z: Bool, C: Bool) -> UInt8 {
        _st = ((_st & ~(PF.Negative | PF.Zero | PF.Carry)) | (C ? PF.Carry.rawValue : 0) | (Z ? PF.Zero.rawValue : 0) | (N ? PF.Negative.rawValue : 0))
        return _st
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
    @inlinable @discardableResult func updateNZCstatus(ans: UInt8, c: Bool) -> UInt8 { updateStatus(N: ans &== 0x80, Z: ans == 0, C: c) }

    /*===========================================================================================================================*/
    /// The setting of the N and Z status register flags is something that occurs very often so I wrapped it into it's own method
    /// for convienience.
    /// 
    /// - Parameter value: the value being tested for being negative or zero.
    /// - Returns: the updated value of the status register.
    ///
    @inlinable @discardableResult func updateNZstatus(ans: UInt8) -> UInt8 { updateStatus(N: ans &== 0x80, Z: ans == 0, C: _st &== PF.Carry) }

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
        updateStatus(N: a2 &== 0x80, Z: ((lhs + rhs + c) & 0xff) == 0, C: a3 > 0xff)
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
    @inlinable func decimalSBC(lhs: Int16, rhs: Int16) {
        // REVISIT: May need to be adjusted.
        _decimalSBC(lhs: lhs, rhs: rhs, c: (_st &== PF.Carry ? 0 : -1))
    }

    @inlinable func _decimalSBC(lhs: Int16, rhs: Int16, c: Int16) {
        _decimalSBC(lhs: lhs, rhs: rhs, x: ((lhs & 0x0f) - (rhs & 0x0f) + c), c: c)
    }

    @inlinable func _decimalSBC(lhs: Int16, rhs: Int16, x: Int16, c: Int16) {
        _decimalSBC(lhs: lhs, rhs: rhs, y: ((lhs & 0xf0) - (rhs & 0xf0) + ((x < 0) ? (((x - 0x06) & 0x0f) - 0x10) : x)), c: c)
    }

    @inlinable func _decimalSBC(lhs: Int16, rhs: Int16, y: Int16, c: Int16) {
        _decimalSBC(lhs: lhs, rhs: rhs, y: y, z: (lhs - rhs + c))
    }

    @inlinable func _decimalSBC(lhs: Int16, rhs: Int16, y: Int16, z: Int16) {
        _accu = UInt8(bitPattern: Int8(((y < 0) ? (y - 0x60) : y) & 0xff))
        updateNZCstatus(ans: _accu, c: z > 255)
        updateVstatus(ans: UInt16(bitPattern: z), lhs: UInt16(bitPattern: lhs), rhs: UInt16(bitPattern: rhs))
    }

    /*===========================================================================================================================*/
    /// Handles the ADC opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processADC(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) {
            (opInfo: OperandInfo) in
            if _st &== PF.Decimal { decimalADC(lhs: UInt16(_accu), rhs: UInt16(opInfo.operand)) }
            else { binaryADC(lhs: UInt16(_accu), rhs: UInt16(opInfo.operand)) }
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
        doWithOperand(opcode: opcode) {
            (opInfo: OperandInfo) in
            _accu &= opInfo.operand
            updateNZstatus(ans: _accu)
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
        doWithOperand(opcode: opcode) {
            (opInfo: OperandInfo) in
            let r: UInt8 = (opInfo.operand << 1)
            storeResults(value: r, mode: opcode.addressingMode)
            updateNZCstatus(ans: r, c: (opInfo.operand &== 0x80))
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
        doWithOperand(opcode: opcode) { (opInfo: OperandInfo) in doBranchOnCondition(offset: opInfo.operand, cond: (_st &!= PF.Carry)) }
    }

    /*===========================================================================================================================*/
    /// Handles the BCS opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBCS(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) { (opInfo: OperandInfo) in doBranchOnCondition(offset: opInfo.operand, cond: (_st &== PF.Carry)) }
    }

    /*===========================================================================================================================*/
    /// Handles the BEQ opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBEQ(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) { (opInfo: OperandInfo) in doBranchOnCondition(offset: opInfo.operand, cond: (_st &== PF.Zero)) }
    }

    /*===========================================================================================================================*/
    /// Handles the BIT opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBIT(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) {
            (opInfo: OperandInfo) in
            PF.Zero.set(status: &_st, when: (_accu & opInfo.operand) == 0)
            _st = ((_st & ~(PF.Negative | PF.Overflow)) | (opInfo.operand & (PF.Negative | PF.Overflow)))
        }
    }

    /*===========================================================================================================================*/
    /// Handles the BMI opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBMI(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) { (opInfo: OperandInfo) in doBranchOnCondition(offset: opInfo.operand, cond: (_st &== PF.Negative)) }
    }

    /*===========================================================================================================================*/
    /// Handles the BNE opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBNE(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) { (opInfo: OperandInfo) in doBranchOnCondition(offset: opInfo.operand, cond: (_st &!= PF.Zero)) }
    }

    /*===========================================================================================================================*/
    /// Handles the BPL opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBPL(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) { (opInfo: OperandInfo) in doBranchOnCondition(offset: opInfo.operand, cond: (_st &!= PF.Negative)) }
    }

    /*===========================================================================================================================*/
    /// Handles the BRK opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBRK(opcode: OpcodeInfo) {
        _brkTriggered = true
    }

    /*===========================================================================================================================*/
    /// Handles the BVC opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBVC(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) { (opInfo: OperandInfo) in doBranchOnCondition(offset: opInfo.operand, cond: (_st &!= PF.Overflow)) }
    }

    /*===========================================================================================================================*/
    /// Handles the BVS opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processBVS(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) { (opInfo: OperandInfo) in doBranchOnCondition(offset: opInfo.operand, cond: (_st &== PF.Overflow)) }
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

    /*===========================================================================================================================*/
    /// Handles the CMP opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processCMP(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) { (opInfo: OperandInfo) in updateStatus(N: _accu &== 0x80, Z: _accu == 0, C: _accu >= opInfo.operand) }
    }

    /*===========================================================================================================================*/
    /// Handles the CPX opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processCPX(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) { (opInfo: OperandInfo) in updateStatus(N: _xreg &== 0x80, Z: _xreg == 0, C: _xreg >= opInfo.operand) }
    }

    /*===========================================================================================================================*/
    /// Handles the CPY opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processCPY(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) { (opInfo: OperandInfo) in updateStatus(N: _yreg &== 0x80, Z: _yreg == 0, C: _yreg >= opInfo.operand) }
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
        doWithOperand(opcode: opcode) {
            (opInfo: OperandInfo) in
            let r: UInt8 = (opInfo.operand &- 1)
            updateNZstatus(ans: r)
            storeResults(value: r, mode: opcode.addressingMode)
        }
    }

    /*===========================================================================================================================*/
    /// Handles the DEX opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processDEX(opcode: OpcodeInfo) {
        updateNZstatus(ans: ---_xreg)
    }

    /*===========================================================================================================================*/
    /// Handles the DEY opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processDEY(opcode: OpcodeInfo) {
        updateNZstatus(ans: ---_yreg)
    }

    /*===========================================================================================================================*/
    /// Handles the EOR opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processEOR(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) {
            (oi: OperandInfo) in
            _accu = (_accu ^ oi.operand)
            updateNZstatus(ans: _accu)
        }
    }

    /*===========================================================================================================================*/
    /// Handles the INC opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processINC(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) {
            (opInfo: OperandInfo) in
            let r: UInt8 = (opInfo.operand &+ 1)
            updateNZstatus(ans: r)
            storeResults(value: r, mode: opcode.addressingMode)
        }
    }

    /*===========================================================================================================================*/
    /// Handles the INX opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processINX(opcode: OpcodeInfo) {
        updateNZstatus(ans: +++_xreg)
    }

    /*===========================================================================================================================*/
    /// Handles the INY opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processINY(opcode: OpcodeInfo) {
        updateNZstatus(ans: +++_yreg)
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
        doWithEffectiveAddress(mode: opcode.addressingMode) {
            (ea: AddressInfo) in
            _pc = (ea.address &- 1) &- UInt16(opcode.addressingMode.byteCount)
        }
    }

    /*===========================================================================================================================*/
    /// Handles the JSR opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processJSR(opcode: OpcodeInfo) {
        doWithEffectiveAddress(mode: opcode.addressingMode) {
            (ea: AddressInfo) in
            let bc: UInt16 = UInt16(opcode.addressingMode.byteCount)
            push(word: _pc + bc)
            _pc = (ea.address &- 1 &- bc)
        }
    }

    /*===========================================================================================================================*/
    /// Handles the KIL opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    open func processKIL(opcode: OpcodeInfo) {
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
        doWithOperand(opcode: opcode) {
            (oi: OperandInfo) in
            _accu = oi.operand
            updateNZstatus(ans: _accu)
        }
    }

    /*===========================================================================================================================*/
    /// Handles the LDX opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processLDX(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) {
            (oi: OperandInfo) in
            _xreg = oi.operand
            updateNZstatus(ans: _xreg)
        }
    }

    /*===========================================================================================================================*/
    /// Handles the LDY opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processLDY(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) {
            (oi: OperandInfo) in
            _yreg = oi.operand
            updateNZstatus(ans: _yreg)
        }
    }

    /*===========================================================================================================================*/
    /// Handles the LSR opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processLSR(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) {
            (oi: OperandInfo) in
            let r: UInt8 = (oi.operand >> 1)
            updateNZCstatus(ans: r, c: oi.operand &== 1)
            storeResults(value: r, mode: opcode.addressingMode)
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
        doWithOperand(opcode: opcode) {
            (opInfo: OperandInfo) in
            _accu |= opInfo.operand
            updateNZstatus(ans: _accu)
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
        updateNZstatus(ans: _accu)
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
        doWithOperand(opcode: opcode) {
            (opInfo: OperandInfo) in
            let result: UInt8 = ((opInfo.operand << 1) | (_st & PF.Carry))
            storeResults(value: result, mode: opcode.addressingMode)
            updateNZCstatus(ans: result, c: opInfo.operand &== PF.Negative)
        }
    }

    /*===========================================================================================================================*/
    /// Handles the ROR opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processROR(opcode: OpcodeInfo) {
        doWithOperand(opcode: opcode) {
            (opInfo: OperandInfo) in
            let result: UInt8 = ((opInfo.operand >> 1) | ((_st & PF.Carry) << 7))
            storeResults(value: result, mode: opcode.addressingMode)
            updateNZCstatus(ans: result, c: opInfo.operand &== 1)
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
        doWithOperand(opcode: opcode) {
            (opInfo: OperandInfo) in
            if (_st &== PF.Decimal) { decimalSBC(lhs: Int16(bitPattern: UInt16(_accu)), rhs: Int16(bitPattern: UInt16(opInfo.operand))) }
            else { binaryADC(lhs: UInt16(_accu), rhs: UInt16(255 &- opInfo.operand)) /* Subtraction is nothing but addition with the 1's complement of operand. */ }
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
        updateNZstatus(ans: _xreg)
    }

    /*===========================================================================================================================*/
    /// Handles the TAY opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processTAY(opcode: OpcodeInfo) {
        _yreg = _accu
        updateNZstatus(ans: _yreg)
    }

    /*===========================================================================================================================*/
    /// Handles the TSX opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processTSX(opcode: OpcodeInfo) {
        _xreg = UInt8(_sp & 0xff)
        updateNZstatus(ans: _xreg)
    }

    /*===========================================================================================================================*/
    /// Handles the TXA opcode.
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processTXA(opcode: OpcodeInfo) {
        _accu = _xreg
        updateNZstatus(ans: _accu)
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
        updateNZstatus(ans: _accu)
    }

    /*===========================================================================================================================*/
    /// Handles the XAA opcode. THIS IS AN INVALID INSTRUCTION!!!
    /// 
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable open func processXAA(opcode: OpcodeInfo) {
        // TODO: processXAA opcode
    }

//@f:0
    public let opcodes: [OpcodeInfo] = [
        OpcodeInfo(opcode: 0x00, mnemonic: "BRK", addrMode: .IMP, isInvalid: false, cycleCount: 7, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x01, mnemonic: "ORA", addrMode: .INX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x02, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x03, mnemonic: "SLO", addrMode: .INX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x04, mnemonic: "NOP", addrMode: .ZPG, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x05, mnemonic: "ORA", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x06, mnemonic: "ASL", addrMode: .ZPG, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x07, mnemonic: "SLO", addrMode: .ZPG, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x08, mnemonic: "PHP", addrMode: .IMP, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x09, mnemonic: "ORA", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x0a, mnemonic: "ASL", addrMode: .ACC, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x0b, mnemonic: "ANC", addrMode: .IMM, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x0c, mnemonic: "NOP", addrMode: .ABS, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x0d, mnemonic: "ORA", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x0e, mnemonic: "ASL", addrMode: .ABS, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x0f, mnemonic: "SLO", addrMode: .ABS, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x10, mnemonic: "BPL", addrMode: .REL, isInvalid: false, cycleCount: 2, penalty: true,  affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x11, mnemonic: "ORA", addrMode: .INY, isInvalid: false, cycleCount: 5, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x12, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x13, mnemonic: "SLO", addrMode: .INY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x14, mnemonic: "NOP", addrMode: .ZPX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x15, mnemonic: "ORA", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x16, mnemonic: "ASL", addrMode: .ZPX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x17, mnemonic: "SLO", addrMode: .ZPX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x18, mnemonic: "CLC", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: ______C),
        OpcodeInfo(opcode: 0x19, mnemonic: "ORA", addrMode: .ABY, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x1a, mnemonic: "NOP", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x1b, mnemonic: "SLO", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x1c, mnemonic: "NOP", addrMode: .ABX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x1d, mnemonic: "ORA", addrMode: .ABX, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x1e, mnemonic: "ASL", addrMode: .ABX, isInvalid: false, cycleCount: 7, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x1f, mnemonic: "SLO", addrMode: .ABX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x20, mnemonic: "JSR", addrMode: .ABS, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x21, mnemonic: "AND", addrMode: .INX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x22, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x23, mnemonic: "RLA", addrMode: .INX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x24, mnemonic: "BIT", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: NO___Z_),
        OpcodeInfo(opcode: 0x25, mnemonic: "AND", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x26, mnemonic: "ROL", addrMode: .ZPG, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x27, mnemonic: "RLA", addrMode: .ZPG, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x28, mnemonic: "PLP", addrMode: .IMP, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: NOBDIZC),
        OpcodeInfo(opcode: 0x29, mnemonic: "AND", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x2a, mnemonic: "ROL", addrMode: .ACC, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x2b, mnemonic: "ANC", addrMode: .IMM, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x2c, mnemonic: "BIT", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: NO___Z_),
        OpcodeInfo(opcode: 0x2d, mnemonic: "AND", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x2e, mnemonic: "ROL", addrMode: .ABS, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x2f, mnemonic: "RLA", addrMode: .ABS, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x30, mnemonic: "BMI", addrMode: .REL, isInvalid: false, cycleCount: 2, penalty: true,  affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x31, mnemonic: "AND", addrMode: .INY, isInvalid: false, cycleCount: 5, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x32, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x33, mnemonic: "RLA", addrMode: .INY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x34, mnemonic: "NOP", addrMode: .ZPX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x35, mnemonic: "AND", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x36, mnemonic: "ROL", addrMode: .ZPX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x37, mnemonic: "RLA", addrMode: .ZPX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x38, mnemonic: "SEC", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: ______C),
        OpcodeInfo(opcode: 0x39, mnemonic: "AND", addrMode: .ABY, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x3a, mnemonic: "NOP", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x3b, mnemonic: "RLA", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x3c, mnemonic: "NOP", addrMode: .ABX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x3d, mnemonic: "AND", addrMode: .ABX, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x3e, mnemonic: "ROL", addrMode: .ABX, isInvalid: false, cycleCount: 7, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x3f, mnemonic: "RLA", addrMode: .ABX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x40, mnemonic: "RTI", addrMode: .IMP, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x41, mnemonic: "EOR", addrMode: .INX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x42, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x43, mnemonic: "SRE", addrMode: .INX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x44, mnemonic: "NOP", addrMode: .ZPG, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x45, mnemonic: "EOR", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x46, mnemonic: "LSR", addrMode: .ZPG, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x47, mnemonic: "SRE", addrMode: .ZPG, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x48, mnemonic: "PHA", addrMode: .IMP, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x49, mnemonic: "EOR", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x4a, mnemonic: "LSR", addrMode: .ACC, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x4b, mnemonic: "ALR", addrMode: .IMM, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x4c, mnemonic: "JMP", addrMode: .ABS, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x4d, mnemonic: "EOR", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x4e, mnemonic: "LSR", addrMode: .ABS, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x4f, mnemonic: "SRE", addrMode: .ABS, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x50, mnemonic: "BVC", addrMode: .REL, isInvalid: false, cycleCount: 2, penalty: true,  affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x51, mnemonic: "EOR", addrMode: .INY, isInvalid: false, cycleCount: 5, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x52, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x53, mnemonic: "SRE", addrMode: .INY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x54, mnemonic: "NOP", addrMode: .ZPX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x55, mnemonic: "EOR", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x56, mnemonic: "LSR", addrMode: .ZPX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x57, mnemonic: "SRE", addrMode: .ZPX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x58, mnemonic: "CLI", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: ____I__),
        OpcodeInfo(opcode: 0x59, mnemonic: "EOR", addrMode: .ABY, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x5a, mnemonic: "NOP", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x5b, mnemonic: "SRE", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x5c, mnemonic: "NOP", addrMode: .ABX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x5d, mnemonic: "EOR", addrMode: .ABX, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x5e, mnemonic: "LSR", addrMode: .ABX, isInvalid: false, cycleCount: 7, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x5f, mnemonic: "SRE", addrMode: .ABX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x60, mnemonic: "RTS", addrMode: .IMP, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x61, mnemonic: "ADC", addrMode: .INX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0x62, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x63, mnemonic: "RRA", addrMode: .INX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0x64, mnemonic: "NOP", addrMode: .ZPG, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x65, mnemonic: "ADC", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0x66, mnemonic: "ROR", addrMode: .ZPG, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x67, mnemonic: "RRA", addrMode: .ZPG, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0x68, mnemonic: "PLA", addrMode: .IMP, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x69, mnemonic: "ADC", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0x6a, mnemonic: "ROR", addrMode: .ACC, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x6b, mnemonic: "ARR", addrMode: .IMM, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0x6c, mnemonic: "JMP", addrMode: .IND, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x6d, mnemonic: "ADC", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0x6e, mnemonic: "ROR", addrMode: .ABX, isInvalid: false, cycleCount: 7, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x6f, mnemonic: "RRA", addrMode: .ABS, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0x70, mnemonic: "BVS", addrMode: .REL, isInvalid: false, cycleCount: 2, penalty: true,  affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x71, mnemonic: "ADC", addrMode: .INY, isInvalid: false, cycleCount: 5, penalty: true,  affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0x72, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x73, mnemonic: "RRA", addrMode: .INY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0x74, mnemonic: "NOP", addrMode: .ZPX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x75, mnemonic: "ADC", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0x76, mnemonic: "ROR", addrMode: .ZPX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x77, mnemonic: "RRA", addrMode: .ZPX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0x78, mnemonic: "SEI", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: ____I__),
        OpcodeInfo(opcode: 0x79, mnemonic: "ADC", addrMode: .ABY, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0x7a, mnemonic: "NOP", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x7b, mnemonic: "RRA", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0x7c, mnemonic: "NOP", addrMode: .ABX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x7d, mnemonic: "ADC", addrMode: .ABX, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0x7e, mnemonic: "ROR", addrMode: .ABS, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0x7f, mnemonic: "RRA", addrMode: .ABX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0x80, mnemonic: "NOP", addrMode: .IMM, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x81, mnemonic: "STA", addrMode: .INX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x82, mnemonic: "NOP", addrMode: .IMM, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x83, mnemonic: "SAX", addrMode: .INX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x84, mnemonic: "STY", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x85, mnemonic: "STA", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x86, mnemonic: "STX", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x87, mnemonic: "SAX", addrMode: .ZPG, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x88, mnemonic: "DEY", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x89, mnemonic: "NOP", addrMode: .IMM, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x8a, mnemonic: "TXA", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x8b, mnemonic: "XAA", addrMode: .IMM, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x8c, mnemonic: "STY", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x8d, mnemonic: "STA", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x8e, mnemonic: "STX", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x8f, mnemonic: "SAX", addrMode: .ABS, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x90, mnemonic: "BCC", addrMode: .REL, isInvalid: false, cycleCount: 2, penalty: true,  affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x91, mnemonic: "STA", addrMode: .INY, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x92, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x93, mnemonic: "AHX", addrMode: .INY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x94, mnemonic: "STY", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x95, mnemonic: "STA", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x96, mnemonic: "STX", addrMode: .ZPY, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x97, mnemonic: "SAX", addrMode: .ZPY, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x98, mnemonic: "TYA", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0x99, mnemonic: "STA", addrMode: .ABY, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x9a, mnemonic: "TXS", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x9b, mnemonic: "TAS", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x9c, mnemonic: "SHY", addrMode: .ABX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x9d, mnemonic: "STA", addrMode: .ABX, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x9e, mnemonic: "SHX", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0x9f, mnemonic: "AHX", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0xa0, mnemonic: "LDY", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xa1, mnemonic: "LDA", addrMode: .INX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xa2, mnemonic: "LDX", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xa3, mnemonic: "LAX", addrMode: .INX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xa4, mnemonic: "LDY", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xa5, mnemonic: "LDA", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xa6, mnemonic: "LDX", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xa7, mnemonic: "LAX", addrMode: .ZPG, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xa8, mnemonic: "TAY", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xa9, mnemonic: "LDA", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xaa, mnemonic: "TAX", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xab, mnemonic: "LAX", addrMode: .IMM, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xac, mnemonic: "LDY", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xad, mnemonic: "LDA", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xae, mnemonic: "LDX", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xaf, mnemonic: "LAX", addrMode: .ABS, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xb0, mnemonic: "BCS", addrMode: .REL, isInvalid: false, cycleCount: 2, penalty: true,  affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0xb1, mnemonic: "LDA", addrMode: .INY, isInvalid: false, cycleCount: 5, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xb2, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0xb3, mnemonic: "LAX", addrMode: .INY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xb4, mnemonic: "LDY", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xb5, mnemonic: "LDA", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xb6, mnemonic: "LDX", addrMode: .ZPY, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xb7, mnemonic: "LAX", addrMode: .ZPY, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xb8, mnemonic: "CLV", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: _O_____),
        OpcodeInfo(opcode: 0xb9, mnemonic: "LDA", addrMode: .ABY, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xba, mnemonic: "TSX", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xbb, mnemonic: "LAS", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xbc, mnemonic: "LDY", addrMode: .ABX, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xbd, mnemonic: "LDA", addrMode: .ABX, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xbe, mnemonic: "LDX", addrMode: .ABY, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xbf, mnemonic: "LAX", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xc0, mnemonic: "CPY", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xc1, mnemonic: "CMP", addrMode: .INX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xc2, mnemonic: "NOP", addrMode: .IMM, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0xc3, mnemonic: "DCP", addrMode: .INX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xc4, mnemonic: "CPY", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xc5, mnemonic: "CMP", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xc6, mnemonic: "DEC", addrMode: .ZPG, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xc7, mnemonic: "DCP", addrMode: .ZPG, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xc8, mnemonic: "INY", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xc9, mnemonic: "CMP", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xca, mnemonic: "DEX", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xcb, mnemonic: "AXS", addrMode: .IMM, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xcc, mnemonic: "CPY", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xcd, mnemonic: "CMP", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xce, mnemonic: "DEC", addrMode: .ABS, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xcf, mnemonic: "DCP", addrMode: .ABS, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xd0, mnemonic: "BNE", addrMode: .REL, isInvalid: false, cycleCount: 2, penalty: true,  affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0xd1, mnemonic: "CMP", addrMode: .INY, isInvalid: false, cycleCount: 5, penalty: true,  affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xd2, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0xd3, mnemonic: "DCP", addrMode: .INY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xd4, mnemonic: "NOP", addrMode: .ZPX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0xd5, mnemonic: "CMP", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xd6, mnemonic: "DEC", addrMode: .ZPX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xd7, mnemonic: "DCP", addrMode: .ZPX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xd8, mnemonic: "CLD", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: ___D___),
        OpcodeInfo(opcode: 0xd9, mnemonic: "CMP", addrMode: .ABY, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xda, mnemonic: "NOP", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0xdb, mnemonic: "DCP", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xdc, mnemonic: "NOP", addrMode: .ABX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0xdd, mnemonic: "CMP", addrMode: .ABX, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xde, mnemonic: "DEC", addrMode: .ABX, isInvalid: false, cycleCount: 7, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xdf, mnemonic: "DCP", addrMode: .ABX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xe0, mnemonic: "CPX", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xe1, mnemonic: "SBC", addrMode: .INX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0xe2, mnemonic: "NOP", addrMode: .IMM, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0xe3, mnemonic: "ISC", addrMode: .INX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0xe4, mnemonic: "CPX", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xe5, mnemonic: "SBC", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0xe6, mnemonic: "INC", addrMode: .ZPG, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xe7, mnemonic: "ISC", addrMode: .ZPG, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0xe8, mnemonic: "INX", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xe9, mnemonic: "SBC", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0xea, mnemonic: "NOP", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0xeb, mnemonic: "SBC", addrMode: .IMM, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0xec, mnemonic: "CPX", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____ZC),
        OpcodeInfo(opcode: 0xed, mnemonic: "SBC", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0xee, mnemonic: "INC", addrMode: .ABS, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xef, mnemonic: "ISC", addrMode: .ABS, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0xf0, mnemonic: "BEQ", addrMode: .REL, isInvalid: false, cycleCount: 2, penalty: true,  affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0xf1, mnemonic: "SBC", addrMode: .INY, isInvalid: false, cycleCount: 5, penalty: true,  affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0xf2, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0xf3, mnemonic: "ISC", addrMode: .INY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0xf4, mnemonic: "NOP", addrMode: .ZPX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0xf5, mnemonic: "SBC", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0xf6, mnemonic: "INC", addrMode: .ZPX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xf7, mnemonic: "ISC", addrMode: .ZPX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0xf8, mnemonic: "SED", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: ___D___),
        OpcodeInfo(opcode: 0xf9, mnemonic: "SBC", addrMode: .ABY, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0xfa, mnemonic: "NOP", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0xfb, mnemonic: "ISC", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0xfc, mnemonic: "NOP", addrMode: .ABX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
        OpcodeInfo(opcode: 0xfd, mnemonic: "SBC", addrMode: .ABX, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: NO___ZC),
        OpcodeInfo(opcode: 0xfe, mnemonic: "INC", addrMode: .ABX, isInvalid: false, cycleCount: 7, penalty: false, affectedFlags: N____Z_),
        OpcodeInfo(opcode: 0xff, mnemonic: "ISC", addrMode: .ABX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
    ]
//@f:1
}
