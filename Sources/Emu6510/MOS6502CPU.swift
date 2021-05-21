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

@usableFromInline let fZ: UInt8  = MOS6502Flag.Zero.rawValue
@usableFromInline let fV: UInt8  = MOS6502Flag.Overflow.rawValue
@usableFromInline let fN: UInt8  = MOS6502Flag.Negative.rawValue
@usableFromInline let fC: UInt8  = MOS6502Flag.Carry.rawValue
@usableFromInline let NZ: UInt8  = (fZ | fN)
@usableFromInline let CV: UInt8  = (fC | fV)
@usableFromInline let zC: UInt16 = 0x0100

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

    //@f:0
    @usableFromInline var _regAcc:     UInt8          = 0x00
    @usableFromInline var _regX:       UInt8          = 0x00
    @usableFromInline var _regY:       UInt8          = 0x00
    @usableFromInline var _regPC:      UInt16         = 0x0000
    @usableFromInline var _regSP:      UInt16         = 0x0100
    @usableFromInline var _regSt:      UInt8          = 0x20
    @usableFromInline var tickCount:   UInt8          = 0
    @usableFromInline var lock:        MutexLock      = MutexLock()

    @inlinable final  var efOperand:   UInt16         { (_regPC &+ 1) }
    @inlinable final  var efAbsolute:  UInt16         { memory.getWord(address: efOperand) }
    @inlinable final  var efAbsoluteX: (UInt16, Bool) { let a = (memory.getWord(address: efOperand) &+ UInt16(_regX)); return (a, diffPage(a, (efOperand &+ 1))) }
    @inlinable final  var efAbsoluteY: (UInt16, Bool) { let a = (memory.getWord(address: efOperand) &+ UInt16(_regY)); return (a, diffPage(a, (efOperand &+ 1))) }
    @inlinable final  var efIndirectY: (UInt16, Bool) { let a = memory.getWord(zpAddress: memory[efOperand]); let b = (a &+ UInt16(_regY)); return (b, diffPage(a, b)) }
    @inlinable final  var efZeroPage:  UInt8          { memory[efOperand] }
    @inlinable final  var efZeroPageX: UInt8          { memory[efOperand] &+ _regX }
    @inlinable final  var efZeroPageY: UInt8          { memory[efOperand] &+ _regY }
    @inlinable final  var efIndirectX: UInt16         { memory.getWord(zpAddress: (memory[efOperand] &+ _regX)) }
    //@f:1

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

            if reset { handleInterrupt(.Reset) }
            if nmi { handleInterrupt(.NMI) }
            else if irq && _regSt ?!= .IRQ { handleInterrupt(.IRQ) }

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
                stackPushAddress(address: _regPC)
                stackPush(byte: _regSt)
                _regSt <+= .IRQ
            case .Reset:
                _regSt <+= .IRQ
            case .Break:
                break
        }
        _regPC = memory.getWord(address: type.vector)
    }

    @inlinable final func setNZFlags(value v: UInt8) {
        _regSt = ((_regSt & (~NZ)) | (v & fN) | ((v == 0) ? UInt8.zero : fZ))
    }

    @inlinable final func setCFlag(carryValue v: UInt8) {
        _regSt = ((_regSt & ~1) | (v & 1))
    }

    @inlinable final func stackPush(byte: UInt8) {
        memory[_regSP] = byte; _regSP = ((_regSP == 0x0100) ? 0x01ff : (_regSP - 1))
    }

    @inlinable final func stackPushAddress(address a: UInt16) {
        stackPush(byte: UInt8((a & 0xff00) >> 8)); stackPush(byte: UInt8(a & 0x00ff))
    }

    @inlinable final func stackPop() -> UInt8 {
        _regSP = ((_regSP == 0x01ff) ? 0x0100 : (_regSP - 1)); return memory[_regSP]
    }

    @inlinable final func stackPopAddress() -> UInt16 {
        let bLo = stackPop(); let bHi = stackPop(); return (UInt16(bLo) | (UInt16(bHi) << 8))
    }

    final func getOperand(_ opcode: MOS6502Opcode) -> (operand: UInt8, plus: UInt8) {
        switch opcode.addressingMode {
            case .IMP, .REL, .IND:                return (0, 0)
            case .ACC:                            return (_regAcc, 0)
            case .ABS:                            return (memory[efAbsolute], 0)
            case .ABSX: let (a, p) = efAbsoluteX; return (memory[a], ((opcode.plus1 && p) ? 1 : 0))
            case .ABSY: let (a, p) = efAbsoluteY; return (memory[a], ((opcode.plus1 && p) ? 1 : 0))
            case .IMM:                            return (memory[efOperand], 0)
            case .INDX:                           return (memory[efIndirectX], 0)
            case .INDY: let (a, p) = efIndirectY; return (memory[a], ((opcode.plus1 && p) ? 1 : 0))
            case .ZP:                             return (memory[efZeroPage], 0)
            case .ZPX:                            return (memory[efZeroPageX], 0)
            case .ZPY:                            return (memory[efZeroPageY], 0)
        }
    }

    @discardableResult final func setOperand(_ opcode: MOS6502Opcode, value: UInt8) -> UInt8 {
        var a: UInt16 = 0
        var p: Bool   = false

        switch opcode.addressingMode {
            case .IMM, .IMP, .REL, .IND: return 0
            case .ACC:                   _regAcc = value; return 0
            case .ABS:                   a = efAbsolute
            case .ABSX:                  (a, p) = efAbsoluteX
            case .ABSY:                  (a, p) = efAbsoluteY
            case .INDX:                  a = efIndirectX
            case .INDY:                  (a, p) = efIndirectY
            case .ZP:                    a = UInt16(efZeroPage)
            case .ZPX:                   a = UInt16(efZeroPageX)
            case .ZPY:                   a = UInt16(efZeroPageY)
        }

        memory[a] = value
        return ((opcode.plus1 && p) ? 1 : 0)
    }

    @inlinable final func addWithCarry(operand op: UInt8) {
        let res: UInt16 = (UInt16(_regAcc) + UInt16(op) + UInt16(_regSt & fC))
        let rs8: UInt8  = UInt8(res & 0xff)
        let v:   UInt8  = (((_regAcc ^ rs8) & (op ^ rs8) & 0x80) >> 1)
        let c:   UInt8  = UInt8((res & zC) >> 8)
        let z:   UInt8  = ((rs8 == 0) ? UInt8.zero : fZ)
        let n:   UInt8  = (rs8 & fN)
        let m:   UInt8  = ~(NZ | CV)

        _regAcc = rs8
        _regSt = ((_regSt & m) | n | z | c | v)
    }

    @inlinable final func handleBranch(opcode: MOS6502Opcode, branchOn: Bool) -> UInt8 {
        guard branchOn else { _regPC &+= UInt16(opcode.bytes); return 0 }
        let oa: UInt16 = (efOperand)
        _regPC = UInt16(bitPattern: (Int16(bitPattern: oa) + Int16(Int8(bitPattern: memory[oa]))))
        return (diffPage(_regPC, oa) ? 2 : 1)
    }

    open func processBCS(opcode: MOS6502Opcode) -> UInt8 { handleBranch(opcode: opcode, branchOn: _regSt ?== .Carry) }

    open func processBCC(opcode: MOS6502Opcode) -> UInt8 { handleBranch(opcode: opcode, branchOn: _regSt ?!= .Carry) }

    open func processBEQ(opcode: MOS6502Opcode) -> UInt8 { handleBranch(opcode: opcode, branchOn: _regSt ?== .Zero) }

    open func processBNE(opcode: MOS6502Opcode) -> UInt8 { handleBranch(opcode: opcode, branchOn: _regSt ?!= .Zero) }

    open func processBMI(opcode: MOS6502Opcode) -> UInt8 { handleBranch(opcode: opcode, branchOn: _regSt ?== .Negative) }

    open func processBPL(opcode: MOS6502Opcode) -> UInt8 { handleBranch(opcode: opcode, branchOn: _regSt ?!= .Negative) }

    open func processBVS(opcode: MOS6502Opcode) -> UInt8 { handleBranch(opcode: opcode, branchOn: _regSt ?== .Overflow) }

    open func processBVC(opcode: MOS6502Opcode) -> UInt8 { handleBranch(opcode: opcode, branchOn: _regSt ?!= .Overflow) }

    open func processADC(opcode: MOS6502Opcode) -> UInt8 {
        let (op, p1) = getOperand(opcode)
        addWithCarry(operand: op)
        _regPC += UInt16(opcode.bytes)
        return p1
    }

    open func processAHX(opcode: MOS6502Opcode) -> UInt8 {
        let a = (opcode.opcode == 0x9f)
        memory[(a ? efAbsoluteY : efIndirectY).0] = (_regAcc & _regX & ((a ? memory[efOperand] : memory[memory[efOperand]]) &+ 1))
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processALR(opcode: MOS6502Opcode) -> UInt8 {
        let (op, _) = getOperand(opcode)
        _regAcc = (_regAcc & op)
        _regSt = ((_regSt & ~1) | (_regAcc & 1))
        _regAcc = (_regAcc >> 1)
        setNZFlags(value: _regAcc)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processANC(opcode: MOS6502Opcode) -> UInt8 {
        let op = memory[efOperand]
        _regAcc = (_regAcc & op)
        _regSt = ((_regSt & ~1) | (_regAcc >> 7))
        setNZFlags(value: _regAcc)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processAND(opcode: MOS6502Opcode) -> UInt8 {
        let (op, p1) = getOperand(opcode)
        _regAcc = (_regAcc & op)
        setNZFlags(value: _regAcc)
        _regPC += UInt16(opcode.bytes)
        return p1
    }

    open func processARR(opcode: MOS6502Opcode) -> UInt8 {
        let (op, _)   = getOperand(opcode)
        let r1: UInt8 = (_regAcc & op)
        let r2: UInt8 = ((r1 >> 1) | ((_regSt & 1) << 7))

        setCFlag(carryValue: r1)
        setNZFlags(value: r2)
        _regAcc = r2
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processASL(opcode: MOS6502Opcode) -> UInt8 {
        let (op, p1) = getOperand(opcode)
        let r: UInt8 = (op << 1)

        setOperand(opcode, value: r)
        setCFlag(carryValue: (op >> 7))
        setNZFlags(value: r)
        _regPC += UInt16(opcode.bytes)
        return p1
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
        _regSt <-= .Carry
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processCLD(opcode: MOS6502Opcode) -> UInt8 {
        _regSt <-= .Decimal
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processCLI(opcode: MOS6502Opcode) -> UInt8 {
        _regSt <-= .IRQ
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processCLV(opcode: MOS6502Opcode) -> UInt8 {
        _regSt <-= .Overflow
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
        let abs = memory.getWord(address: efOperand)
        _regPC = ((opcode.addressingMode == .IND) ? memory.getWord(address: abs, fromSamePage: true) : abs)
        return 0
    }

    open func processJSR(opcode: MOS6502Opcode) -> UInt8 {
        stackPushAddress(address: (_regPC &+ UInt16(opcode.bytes - 1)))
        _regPC = memory.getWord(address: efOperand)
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
        let (op, p1) = getOperand(opcode)
        addWithCarry(operand: (255 - op))
        _regPC += UInt16(opcode.bytes)
        return p1
    }

    open func processSEC(opcode: MOS6502Opcode) -> UInt8 {
        _regSt <+= .Carry
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processSED(opcode: MOS6502Opcode) -> UInt8 {
        _regSt <+= .Decimal
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processSEI(opcode: MOS6502Opcode) -> UInt8 {
        _regSt <+= .IRQ
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
        setNZFlags(value: _regX)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processTAY(opcode: MOS6502Opcode) -> UInt8 {
        _regY = _regAcc
        setNZFlags(value: _regY)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processTSX(opcode: MOS6502Opcode) -> UInt8 {
        _regX = regSP
        setNZFlags(value: _regX)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processTXA(opcode: MOS6502Opcode) -> UInt8 {
        _regAcc = _regX
        setNZFlags(value: _regAcc)
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
        setNZFlags(value: _regAcc)
        _regPC += UInt16(opcode.bytes)
        return 0
    }

    open func processXAA(opcode: MOS6502Opcode) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return 0
    }
}
