/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Emu6510
 *    FILENAME: MOS6502CPU.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/18/21
 *
 * Copyright © 2021 Galen Rhodes. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//******************************************************************************************************************************************************************************/

import Foundation
import CoreFoundation
import Rubicon

open class MOS6502CPU: ClockListener {
    public let            clock:     MOS6502Clock
    public let            memory:    MOS6502SystemMemoryMap
    public var            irq:       Bool = false
    public var            nmi:       Bool = false
    public var            reset:     Bool = false

    /// The Accumulator.
    ///
    @inlinable public var regAcc:    UInt8 { _regAcc }
    /// The X register.
    ///
    @inlinable public var regX:      UInt8 { _regX }
    /// The Y register.
    ///
    @inlinable public var regY:      UInt8 { _regY }
    /// Returns true if the CPU Clock is running.
    ///
    @inlinable public var isRunning: Bool { clock.isRunning }
    /// The program counter.
    ///
    @inlinable public var regPC:     UInt16 { _regPC }
    /// I've look in several places and no one really talks about what the initial value of the stack pointer is.  Only one reference said it is reset to zero on startup.
    /// But it is known that the startup routine SHOULD set the stack pointer.
    ///
    @inlinable public var regSP:     UInt8 { UInt8(_regSP & 0x00ff) }
    /// The sixth bit (32 (0x20)) of the status register should always be 1 (one).
    ///
    @inlinable public var regStatus: UInt8 { (_regSt | 0x20) }

    @usableFromInline var _regAcc:   UInt8     = 0x00
    @usableFromInline var _regX:     UInt8     = 0x00
    @usableFromInline var _regY:     UInt8     = 0x00
    @usableFromInline var _regPC:    UInt16    = 0x0000
    @usableFromInline var _regSP:    UInt16    = 0x0100
    @usableFromInline var _regSt:    UInt8     = 0x20
    @usableFromInline var tickCount: UInt8     = 0
    @usableFromInline var lock:      MutexLock = MutexLock()

    public init(frequency: UInt64, memory: MOS6502SystemMemoryMap) {
        self.memory = memory
        self.clock = MOS6502Clock(frequency: frequency)
        self.clock.addListener(listener: self)
    }

    public func start() {
        lock.withLock {
            if !clock.isRunning {
                tickCount = 7
                tickHold = true
                tickAdd = 0
                handleInterrupt(.Reset)
                clock.start()
            }
        }
    }

    public func stop() {
        lock.withLock {
            if clock.isRunning {
                clock.stop()
            }
        }
    }

    private var tickAdd:  UInt8 = 0
    private var tickHold: Bool  = true

    public func clockTick(sequence: UInt64) {
        if tickAdd > 0 {
            tickCount += (tickAdd - 1)
            tickAdd = 0
        }
        else if tickCount == 0 {
            tickCount = 2 // Every instruction takes at least 2 clock cycles to complete.
            tickHold = false
        }
        else {
            tickCount -= 1
        }
    }

    private func setTickAdd(_ delta: UInt8) {
        while tickAdd != 0 {}
        tickAdd = delta
    }

    public func run() {
        start()
        while clock.isRunning {
            while tickHold {}
            tickHold = true

            if reset {
                handleInterrupt(.Reset)
            }
            if nmi {
                handleInterrupt(.NMI)
            }
            else if irq && !isStatus(flag: .IRQ) {
                handleInterrupt(.IRQ)
            }

            let opcode = mos6502OpcodeList[Int(memory[_regPC])]
            setTickAdd(opcode.cycles - 2)

            switch opcode.mnemonic {
                case .ADC: setTickAdd(processADC(opcode: opcode))
                case .AHX: setTickAdd(processAHX(opcode: opcode))
                case .ALR: setTickAdd(processALR(opcode: opcode))
                case .ANC: setTickAdd(processANC(opcode: opcode))
                case .AND: setTickAdd(processAND(opcode: opcode))
                case .ARR: setTickAdd(processARR(opcode: opcode))
                case .ASL: setTickAdd(processASL(opcode: opcode))
                case .AXS: setTickAdd(processAXS(opcode: opcode))
                case .BCC: setTickAdd(processBCC(opcode: opcode))
                case .BCS: setTickAdd(processBCS(opcode: opcode))
                case .BEQ: setTickAdd(processBEQ(opcode: opcode))
                case .BIT: setTickAdd(processBIT(opcode: opcode))
                case .BMI: setTickAdd(processBMI(opcode: opcode))
                case .BNE: setTickAdd(processBNE(opcode: opcode))
                case .BPL: setTickAdd(processBPL(opcode: opcode))
                case .BRK: setTickAdd(processBRK(opcode: opcode))
                case .BVC: setTickAdd(processBVC(opcode: opcode))
                case .BVS: setTickAdd(processBVS(opcode: opcode))
                case .CLC: setTickAdd(processCLC(opcode: opcode))
                case .CLD: setTickAdd(processCLD(opcode: opcode))
                case .CLI: setTickAdd(processCLI(opcode: opcode))
                case .CLV: setTickAdd(processCLV(opcode: opcode))
                case .CMP: setTickAdd(processCMP(opcode: opcode))
                case .CPX: setTickAdd(processCPX(opcode: opcode))
                case .CPY: setTickAdd(processCPY(opcode: opcode))
                case .DCP: setTickAdd(processDCP(opcode: opcode))
                case .DEC: setTickAdd(processDEC(opcode: opcode))
                case .DEX: setTickAdd(processDEX(opcode: opcode))
                case .DEY: setTickAdd(processDEY(opcode: opcode))
                case .EOR: setTickAdd(processEOR(opcode: opcode))
                case .INC: setTickAdd(processINC(opcode: opcode))
                case .INX: setTickAdd(processINX(opcode: opcode))
                case .INY: setTickAdd(processINY(opcode: opcode))
                case .ISC: setTickAdd(processISC(opcode: opcode))
                case .JMP: setTickAdd(processJMP(opcode: opcode))
                case .JSR: setTickAdd(processJSR(opcode: opcode))
                case .KIL: setTickAdd(processKIL(opcode: opcode))
                case .LAS: setTickAdd(processLAS(opcode: opcode))
                case .LAX: setTickAdd(processLAX(opcode: opcode))
                case .LDA: setTickAdd(processLDA(opcode: opcode))
                case .LDX: setTickAdd(processLDX(opcode: opcode))
                case .LDY: setTickAdd(processLDY(opcode: opcode))
                case .LSR: setTickAdd(processLSR(opcode: opcode))
                case .NOP: setTickAdd(processNOP(opcode: opcode))
                case .ORA: setTickAdd(processORA(opcode: opcode))
                case .PHA: setTickAdd(processPHA(opcode: opcode))
                case .PHP: setTickAdd(processPHP(opcode: opcode))
                case .PLA: setTickAdd(processPLA(opcode: opcode))
                case .PLP: setTickAdd(processPLP(opcode: opcode))
                case .RLA: setTickAdd(processRLA(opcode: opcode))
                case .ROL: setTickAdd(processROL(opcode: opcode))
                case .ROR: setTickAdd(processROR(opcode: opcode))
                case .RRA: setTickAdd(processRRA(opcode: opcode))
                case .RTI: setTickAdd(processRTI(opcode: opcode))
                case .RTS: setTickAdd(processRTS(opcode: opcode))
                case .SAX: setTickAdd(processSAX(opcode: opcode))
                case .SBC: setTickAdd(processSBC(opcode: opcode))
                case .SEC: setTickAdd(processSEC(opcode: opcode))
                case .SED: setTickAdd(processSED(opcode: opcode))
                case .SEI: setTickAdd(processSEI(opcode: opcode))
                case .SHX: setTickAdd(processSHX(opcode: opcode))
                case .SHY: setTickAdd(processSHY(opcode: opcode))
                case .SLO: setTickAdd(processSLO(opcode: opcode))
                case .SRE: setTickAdd(processSRE(opcode: opcode))
                case .STA: setTickAdd(processSTA(opcode: opcode))
                case .STX: setTickAdd(processSTX(opcode: opcode))
                case .STY: setTickAdd(processSTY(opcode: opcode))
                case .TAS: setTickAdd(processTAS(opcode: opcode))
                case .TAX: setTickAdd(processTAX(opcode: opcode))
                case .TAY: setTickAdd(processTAY(opcode: opcode))
                case .TSX: setTickAdd(processTSX(opcode: opcode))
                case .TXA: setTickAdd(processTXA(opcode: opcode))
                case .TXS: setTickAdd(processTXS(opcode: opcode))
                case .TYA: setTickAdd(processTYA(opcode: opcode))
                case .XAA: setTickAdd(processXAA(opcode: opcode))
            }
        }
    }

    func handleInterrupt(_ type: MOS6502Interrupt) {
        switch type {
            case .IRQ, .NMI:
                pushIRQInfo()
                statusSet(flags: .IRQ)
            case .Reset:
                statusSet(flags: .IRQ)
            default:
                break
        }
        _regPC = memory.getWord(address: type.vector)
    }

    @inlinable final func pushIRQInfo() {
        stackPushAddress(address: _regPC)
        stackPush(byte: _regSt)
    }

    @inlinable final func setFlagsFrom(value: UInt8, opcode: MOS6502Opcode) {
        for f in opcode.affectedFlags {
            switch f {
                case .Negative: statusUpdate((value & 0x80) == 0x80, flags: f)
                case .Zero:     statusUpdate(value == 0, flags: f)
                default: break
            }
        }
    }

    @inlinable final func statusSet(flags: MOS6502Flag...) { for f in flags { _regSt = (_regSt | f.rawValue) } }

    @inlinable final func statusClear(flags: MOS6502Flag...) { for f in flags { _regSt = (_regSt & ~f.rawValue) } }

    @inlinable final func statusUpdate(_ fl: Bool, flags: MOS6502Flag...) { for f in flags { statusUpdate(fl, flag: f) } }

    @inlinable final func statusUpdate(_ fl: Bool, flag: MOS6502Flag) { _regSt = (fl ? (_regSt | flag.rawValue) : (_regSt & ~flag.rawValue)) }

    @inlinable final func isStatus(flag: MOS6502Flag) -> Bool { ((_regSt & flag.rawValue) == flag.rawValue) }

    @inlinable final func stackPush(byte: UInt8) { memory[_regSP] = byte; _regSP = ((_regSP == 0x0100) ? 0x01ff : (_regSP - 1)) }

    @inlinable final func stackPushAddress(address a: UInt16) { stackPush(byte: UInt8((a & 0xff00) >> 8)); stackPush(byte: UInt8(a & 0x00ff)) }

    @inlinable final func stackPop() -> UInt8 { _regSP = ((_regSP == 0x01ff) ? 0x0100 : (_regSP - 1)); return memory[_regSP] }

    @inlinable final func stackPopAddress() -> UInt16 { let bLo = stackPop(); let bHi = stackPop(); return (UInt16(bLo) | (UInt16(bHi) << 8)) }

    @inlinable final var operandAddress: UInt16 { (_regPC &+ 1) }
    @inlinable final var efAbsolute:     UInt16 { memory.getWord(address: operandAddress) }
    @inlinable final var efAbsoluteX:    UInt16 { (efAbsolute &+ UInt16(_regX)) }
    @inlinable final var efAbsoluteY:    UInt16 { (efAbsolute &+ UInt16(_regY)) }
    @inlinable final var efIndirect:     UInt16 { noPageCross(address: efAbsolute) }
    @inlinable final var efIndirectX:    UInt16 { noPageCross(address: efZeroPageX) }
    @inlinable final var efIndirectY:    UInt16 { noPageCross(address: UInt16(memory[efZeroPage] &+ _regY)) }
    @inlinable final var efZeroPage:     UInt16 { UInt16(memory[operandAddress]) }
    @inlinable final var efZeroPageX:    UInt16 { UInt16(memory[operandAddress] &+ _regX) }
    @inlinable final var efZeroPageY:    UInt16 { UInt16(memory[operandAddress] &+ _regY) }

    final func getOperand(_ opcode: MOS6502Opcode) -> (operand: UInt8?, plus: Bool) {
        var operand: UInt8? = nil
        var plus:    Bool   = false

        switch opcode.addressingMode {
            case .ACC, .IMP: break
            case .ABS: break
            case .ABSX: break
            case .ABSY: break
            case .IMM: break
            case .IND: break
            case .INDX: break
            case .INDY: break
            case .REL: break
            case .ZP: break
            case .ZPX: break
            case .ZPY: break
        }

        return (operand: operand, plus: plus)
    }

    final func setOperand(_ opcode: MOS6502Opcode, value: UInt8) -> Bool {
        var plus: Bool = false

        switch opcode.addressingMode {
            case .ACC, .IMP: break
            case .ABS: break
            case .ABSX: break
            case .ABSY: break
            case .IMM: break
            case .IND: break
            case .INDX: break
            case .INDY: break
            case .REL: break
            case .ZP: break
            case .ZPX: break
            case .ZPY: break
        }

        return plus
    }

    @inlinable final func noPageCross(address a: UInt16) -> UInt16 { (UInt16(memory[a]) | (UInt16(memory[(a & 0xff00) | ((a &+ 1) & 0x00ff)]) << 8)) }

    @inlinable final func inNextPage(efAddress a: UInt16) -> Bool { ((a & 0xff00) != (_regPC & 0xff00)) }

    @inlinable final func handleBranch(opcode: MOS6502Opcode, flag: Bool) -> UInt8 {
        guard flag else { _regPC &+= UInt16(opcode.bytes); return 0 }
        let oa: UInt16 = operandAddress
        let ef: UInt16 = UInt16(bitPattern: (Int16(bitPattern: oa) + Int16(Int8(bitPattern: memory[oa]))))
        let cc: UInt8  = (inNextPage(efAddress: ef) ? 2 : 1)
        _regPC = ef
        return cc
    }

    open func processBCS(opcode: MOS6502Opcode) -> UInt8 { handleBranch(opcode: opcode, flag: isStatus(flag: .Carry)) }

    open func processBCC(opcode: MOS6502Opcode) -> UInt8 { handleBranch(opcode: opcode, flag: !isStatus(flag: .Carry)) }

    open func processBEQ(opcode: MOS6502Opcode) -> UInt8 { handleBranch(opcode: opcode, flag: isStatus(flag: .Zero)) }

    open func processBNE(opcode: MOS6502Opcode) -> UInt8 { handleBranch(opcode: opcode, flag: !isStatus(flag: .Zero)) }

    open func processBMI(opcode: MOS6502Opcode) -> UInt8 { handleBranch(opcode: opcode, flag: isStatus(flag: .Negative)) }

    open func processBPL(opcode: MOS6502Opcode) -> UInt8 { handleBranch(opcode: opcode, flag: !isStatus(flag: .Negative)) }

    open func processBVS(opcode: MOS6502Opcode) -> UInt8 { handleBranch(opcode: opcode, flag: isStatus(flag: .Overflow)) }

    open func processBVC(opcode: MOS6502Opcode) -> UInt8 { handleBranch(opcode: opcode, flag: !isStatus(flag: .Overflow)) }

    open func processADC(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processAHX(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processALR(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processANC(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processAND(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processARR(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processASL(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processAXS(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processBIT(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processBRK(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processCLC(opcode: MOS6502Opcode) -> UInt8 {
        statusClear(flags: .Carry)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processCLD(opcode: MOS6502Opcode) -> UInt8 {
        statusClear(flags: .Decimal)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processCLI(opcode: MOS6502Opcode) -> UInt8 {
        statusClear(flags: .IRQ)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processCLV(opcode: MOS6502Opcode) -> UInt8 {
        statusClear(flags: .Overflow)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processCMP(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processCPX(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processCPY(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processDCP(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processDEC(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processDEX(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processDEY(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processEOR(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processINC(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processINX(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processINY(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processISC(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processJMP(opcode: MOS6502Opcode) -> UInt8 {
        _regPC = ((opcode.addressingMode == .IND) ? efIndirect : efAbsolute)
        return 0
    }

    open func processJSR(opcode: MOS6502Opcode) -> UInt8 {
        stackPushAddress(address: (_regPC &+ UInt16(opcode.bytes - 1)))
        _regPC = efAbsolute
        return 0
    }

    open func processKIL(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processLAS(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processLAX(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processLDA(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processLDX(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processLDY(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processLSR(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processNOP(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processORA(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processPHA(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processPHP(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processPLA(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processPLP(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processRLA(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processROL(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processROR(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processRRA(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processRTI(opcode: MOS6502Opcode) -> UInt8 {
        _regSt = stackPop()
        _regPC = (stackPopAddress() &+ 1)
        return 0
    }

    open func processRTS(opcode: MOS6502Opcode) -> UInt8 {
        _regPC = (stackPopAddress() &+ 1)
        return 0
    }

    open func processSAX(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processSBC(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processSEC(opcode: MOS6502Opcode) -> UInt8 {
        statusSet(flags: .Carry)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processSED(opcode: MOS6502Opcode) -> UInt8 {
        statusSet(flags: .Decimal)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processSEI(opcode: MOS6502Opcode) -> UInt8 {
        statusSet(flags: .IRQ)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processSHX(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processSHY(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processSLO(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processSRE(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processSTA(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processSTX(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processSTY(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processTAS(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processTAX(opcode: MOS6502Opcode) -> UInt8 {
        _regX = _regAcc
        setFlagsFrom(value: _regX, opcode: opcode)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processTAY(opcode: MOS6502Opcode) -> UInt8 {
        _regY = _regAcc
        setFlagsFrom(value: _regY, opcode: opcode)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processTSX(opcode: MOS6502Opcode) -> UInt8 {
        _regX = regSP
        setFlagsFrom(value: _regX, opcode: opcode)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processTXA(opcode: MOS6502Opcode) -> UInt8 {
        _regAcc = _regX
        setFlagsFrom(value: _regAcc, opcode: opcode)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processTXS(opcode: MOS6502Opcode) -> UInt8 {
        _regSP = (0x0100 | UInt16(_regX))
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processTYA(opcode: MOS6502Opcode) -> UInt8 {
        _regAcc = _regY
        setFlagsFrom(value: _regAcc, opcode: opcode)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processXAA(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }
}
