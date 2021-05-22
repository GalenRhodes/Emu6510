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
    @usableFromInline typealias EfOperand = (operand: UInt8, plus: UInt8)
    @usableFromInline typealias EfAddress = (address: UInt16, plus: UInt8)

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

    // These fields are used to calculate the effective address of the operand or the target address of a JMP or JSR.
    @inlinable final  var efOperand:   UInt16         { (_regPC &+ 1) }
    @inlinable final  var efAbsolute:  UInt16         { memory.getWord(address: efOperand) }
    @inlinable final  var efAbsoluteX: (UInt16, Bool) { let a = (memory.getWord(address: efOperand) &+ UInt16(_regX)); return (a, diffPage(a, (efOperand &+ 1))) }
    @inlinable final  var efAbsoluteY: (UInt16, Bool) { let a = (memory.getWord(address: efOperand) &+ UInt16(_regY)); return (a, diffPage(a, (efOperand &+ 1))) }
    @inlinable final  var efIndirectY: (UInt16, Bool) { let a = memory.getWord(zpAddress: memory[efOperand]); let b = (a &+ UInt16(_regY)); return (b, diffPage(a, b)) }
    @inlinable final  var efIndirectX: UInt16         { memory.getWord(zpAddress: (memory[efOperand] &+ _regX)) }
    @inlinable final  var efIndirect:  UInt16         { memory.getWord(address: efAbsolute, fromSamePage: true) }
    @inlinable final  var efZeroPage:  UInt8          { memory[efOperand] }
    @inlinable final  var efZeroPageX: UInt8          { memory[efOperand] &+ _regX }
    @inlinable final  var efZeroPageY: UInt8          { memory[efOperand] &+ _regY }
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

    @inlinable final func exitOpcode(_ opcode: MOS6502Opcode, plusCycle: UInt8 = 0) -> UInt8 {
        _regPC += UInt16(opcode.bytes)
        return plusCycle
    }

    @discardableResult @inlinable final func setNZFlags(value v: UInt8) -> UInt8 {
        _regSt = ((_regSt & (~NZ)) | (v & fN) | zeroFlag(v))
        return v
    }

    @discardableResult @inlinable final func setNZCFlags(value v: UInt8, carryOut c: UInt8) -> UInt8 {
        _regSt = ((_regSt & (~(fC | fN | fZ))) | (v & fN) | zeroFlag(v) | (c & fC))
        return v
    }

    @discardableResult @inlinable final func setNZVFlags(value v: UInt8) -> UInt8 {
        _regSt = ((_regSt & (~(fV | fN | fZ))) | (v & fN) | zeroFlag(v) | (v & fV))
        return v
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

    /// This method is for opcodes that operate only on memory. In other words, no IMPlied, ACCumulator, or IMMediate addressing modes.
    ///
    /// - Parameter opcode: The opcode.
    /// - Returns: The target address of the operand.
    ///
    @usableFromInline final func getTargetAddress(_ opcode: MOS6502Opcode) -> EfAddress {
        switch opcode.addressingMode {
            case .ACC, .IMM, .IMP:                fatalError("Invalid addressing mode.")
            case .ABS:                            return (efAbsolute, 0)
            case .ABSX: let (a, p) = efAbsoluteX; return (a, ((opcode.plus1 && p) ? 1 : 0))
            case .ABSY: let (a, p) = efAbsoluteY; return (a, ((opcode.plus1 && p) ? 1 : 0))
            case .IND:                            return (efIndirect, 0)
            case .INDX:                           return (efIndirectX, 0)
            case .INDY: let (a, p) = efIndirectY; return (a, ((opcode.plus1 && p) ? 1 : 0))
            case .REL:                            return efRelative
            case .ZP:                             return (UInt16(efZeroPage), 0)
            case .ZPX:                            return (UInt16(efZeroPageX), 0)
            case .ZPY:                            return (UInt16(efZeroPageY), 0)
        }
    }

    @discardableResult @usableFromInline final func getOperand(_ opcode: MOS6502Opcode) -> EfOperand {
        switch opcode.addressingMode {
            case .IMP, .REL, .IND:                fatalError("Invalid addressing mode.")
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

    @discardableResult @usableFromInline final func setOperand(_ opcode: MOS6502Opcode, value: UInt8) -> UInt8 {
        var a: UInt16 = 0
        var p: Bool   = false

        switch opcode.addressingMode {
            case .IMM, .IMP, .REL, .IND: fatalError("Invalid addressing mode.")
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

    @inlinable final func addWithCarry(leftOperand opL: UInt8, rightOperand opR: UInt8, carryIn: UInt8) -> (UInt8, UInt8) {
        let res: UInt16 = (UInt16(opL) + UInt16(opR) + UInt16(carryIn)) // There is no chance of overflow here.
        let rs8: UInt8  = UInt8(res & 0xff)
        return (rs8, ((_regSt & (~(NZ | CV))) | (rs8 & fN) | zeroFlag(rs8) | UInt8((res & zC) >> 8) | (((opL ^ rs8) & (opR ^ rs8) & fN) >> 1)))
    }

    @inlinable final func shiftLeft(opcode: MOS6502Opcode, carryIn c: UInt8) -> UInt8 {
        shiftRight(opcode: opcode, operand: getOperand(opcode), carryIn: c)
    }

    @inlinable final func shiftRight(opcode: MOS6502Opcode, carryIn c: UInt8) -> UInt8 {
        shiftLeft(opcode: opcode, operand: getOperand(opcode), carryIn: c)
    }

    @inlinable final func shiftLeft(opcode: MOS6502Opcode, operand o: EfOperand, carryIn c: UInt8) -> UInt8 {
        let r: UInt8 = ((o.operand >> 1) | (c << 7))
        setOperand(opcode, value: setNZCFlags(value: r, carryOut: (o.operand & fC)))
        return exitOpcode(opcode, plusCycle: o.plus)
    }

    @inlinable final func shiftRight(opcode: MOS6502Opcode, operand o: EfOperand, carryIn c: UInt8) -> UInt8 {
        let r: UInt8 = ((o.operand << 1) | (c & fC))
        setOperand(opcode, value: setNZCFlags(value: r, carryOut: (o.operand >> 7)))
        return exitOpcode(opcode, plusCycle: o.plus)
    }

    @inlinable final func handleBranch(opcode: MOS6502Opcode, branchOn: Bool) -> UInt8 {
        guard branchOn else { _regPC &+= UInt16(opcode.bytes); return 0 }
        let (ta, p1) = efRelative
        _regPC = ta
        return p1
    }

    @inlinable final var efRelative: (UInt16, UInt8) {
        let pc: UInt16 = (efOperand)
        let ta: UInt16 = UInt16(bitPattern: (Int16(bitPattern: pc) + Int16(Int8(bitPattern: memory[pc]))))
        return (ta, (diffPage(ta, pc) ? 2 : 1))
    }

    @inlinable final func handleCompare(opcode: MOS6502Opcode, register reg: UInt8) -> UInt8 {
        let (op, p1) = getOperand(opcode)
        let (_, st)  = addWithCarry(leftOperand: reg, rightOperand: op, carryIn: 1)
        _regSt = ((_regSt & (~(fN | fC | fZ))) | (st & ~fV))
        return exitOpcode(opcode, plusCycle: p1)
    }

    @inlinable final func handleInterrupt(_ type: MOS6502Interrupt) {
        switch type {
            case .IRQ, .NMI:
                stackPushAddress(address: (_regPC &- 1))
                stackPush(byte: _regSt)
                _regSt <+= .IRQ
            case .Break:
                stackPushAddress(address: _regPC)
                stackPush(byte: _regSt)
                _regSt <+= .IRQ
            case .Reset:
                _regSt <+= .IRQ
        }
        _regPC = memory.getWord(address: type.vector)
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
        let o: EfOperand = getOperand(opcode)
        (_regAcc, _regSt) = addWithCarry(leftOperand: _regAcc, rightOperand: o.operand, carryIn: (_regSt & fC))
        return exitOpcode(opcode, plusCycle: o.plus)
    }

    open func processAHX(opcode: MOS6502Opcode) -> UInt8 {
        let o: Bool = (opcode.opcode == 0x9f)
        memory[(o ? efAbsoluteY : efIndirectY).0] = (_regAcc & _regX & ((o ? memory[efOperand] : memory[memory[efOperand]]) &+ 1))
        return exitOpcode(opcode)
    }

    open func processALR(opcode: MOS6502Opcode) -> UInt8 {
        let o: EfOperand = getOperand(opcode)
        let r: UInt8     = (_regAcc & o.operand)
        _regAcc = setNZCFlags(value: (r >> 1), carryOut: (r & fC))
        return exitOpcode(opcode, plusCycle: o.plus)
    }

    open func processANC(opcode: MOS6502Opcode) -> UInt8 {
        let o: EfOperand = getOperand(opcode)
        let r: UInt8     = (_regAcc & o.operand)
        _regAcc = setNZCFlags(value: r, carryOut: (r >> 7))
        return exitOpcode(opcode, plusCycle: o.plus)
    }

    open func processAND(opcode: MOS6502Opcode) -> UInt8 {
        let o: EfOperand = getOperand(opcode)
        _regAcc = setNZFlags(value: (_regAcc & o.operand))
        return exitOpcode(opcode, plusCycle: o.plus)
    }

    open func processARR(opcode: MOS6502Opcode) -> UInt8 {
        let o: EfOperand = getOperand(opcode)
        return shiftRight(opcode: opcode, operand: ((_regAcc & o.operand), o.plus), carryIn: (_regSt & fC))
    }

    open func processASL(opcode: MOS6502Opcode) -> UInt8 {
        shiftLeft(opcode: opcode, carryIn: 0)
    }

    open func processAXS(opcode: MOS6502Opcode) -> UInt8 {

        return exitOpcode(opcode)
    }

    open func processBIT(opcode: MOS6502Opcode) -> UInt8 {
        let o: EfOperand = getOperand(opcode)
        setNZVFlags(value: (_regAcc & o.operand))
        return exitOpcode(opcode, plusCycle: o.plus)
    }

    open func processBRK(opcode: MOS6502Opcode) -> UInt8 {
        handleInterrupt(.Break)
        return 0
    }

    open func processCLC(opcode: MOS6502Opcode) -> UInt8 {
        _regSt <-= .Carry
        return exitOpcode(opcode)
    }

    open func processCLD(opcode: MOS6502Opcode) -> UInt8 {
        _regSt <-= .Decimal
        return exitOpcode(opcode)
    }

    open func processCLI(opcode: MOS6502Opcode) -> UInt8 {
        _regSt <-= .IRQ
        return exitOpcode(opcode)
    }

    open func processCLV(opcode: MOS6502Opcode) -> UInt8 {
        _regSt <-= .Overflow
        return exitOpcode(opcode)
    }

    open func processCMP(opcode: MOS6502Opcode) -> UInt8 {
        handleCompare(opcode: opcode, register: _regAcc)
    }

    open func processCPX(opcode: MOS6502Opcode) -> UInt8 {
        handleCompare(opcode: opcode, register: _regX)
    }

    open func processCPY(opcode: MOS6502Opcode) -> UInt8 {
        handleCompare(opcode: opcode, register: _regY)
    }

    open func processDCP(opcode: MOS6502Opcode) -> UInt8 {
        return exitOpcode(opcode)
    }

    open func processDEC(opcode: MOS6502Opcode) -> UInt8 {
        let a: EfAddress = getTargetAddress(opcode)
        memory[a.address] = setNZFlags(value: (memory[a.address] &- 1))
        return exitOpcode(opcode, plusCycle: a.plus)
    }

    open func processDEX(opcode: MOS6502Opcode) -> UInt8 {
        _regX = setNZFlags(value: _regX &- 1)
        return exitOpcode(opcode)
    }

    open func processDEY(opcode: MOS6502Opcode) -> UInt8 {
        _regY = setNZFlags(value: _regY &- 1)
        return exitOpcode(opcode)
    }

    open func processEOR(opcode: MOS6502Opcode) -> UInt8 {
        let o: EfOperand = getOperand(opcode)
        _regAcc = setNZFlags(value: (_regAcc ^ o.operand))
        return exitOpcode(opcode, plusCycle: o.plus)
    }

    open func processINC(opcode: MOS6502Opcode) -> UInt8 {
        let a: EfAddress = getTargetAddress(opcode)
        memory[a.address] = setNZFlags(value: (memory[a.address] &+ 1))
        return exitOpcode(opcode, plusCycle: a.plus)
    }

    open func processINX(opcode: MOS6502Opcode) -> UInt8 {
        _regX = setNZFlags(value: _regX &+ 1)
        return exitOpcode(opcode)
    }

    open func processINY(opcode: MOS6502Opcode) -> UInt8 {
        _regY = setNZFlags(value: _regY &+ 1)
        return exitOpcode(opcode)
    }

    open func processISC(opcode: MOS6502Opcode) -> UInt8 {
        return exitOpcode(opcode)
    }

    open func processJMP(opcode: MOS6502Opcode) -> UInt8 {
        let a: EfAddress = getTargetAddress(opcode)
        _regPC = a.address
        return a.plus
    }

    open func processJSR(opcode: MOS6502Opcode) -> UInt8 {
        stackPushAddress(address: (_regPC &+ UInt16(opcode.bytes - 1)))
        return processJMP(opcode: opcode)
    }

    open func processKIL(opcode: MOS6502Opcode) -> UInt8 {
        clock.stop()
        return 0
    }

    open func processLAS(opcode: MOS6502Opcode) -> UInt8 {
        return exitOpcode(opcode)
    }

    open func processLAX(opcode: MOS6502Opcode) -> UInt8 {
        return exitOpcode(opcode)
    }

    open func processLDA(opcode: MOS6502Opcode) -> UInt8 {
        let o: EfOperand = getOperand(opcode)
        _regAcc = setNZFlags(value: o.operand)
        return exitOpcode(opcode, plusCycle: o.plus)
    }

    open func processLDX(opcode: MOS6502Opcode) -> UInt8 {
        let o: EfOperand = getOperand(opcode)
        _regX = setNZFlags(value: o.operand)
        return exitOpcode(opcode, plusCycle: o.plus)
    }

    open func processLDY(opcode: MOS6502Opcode) -> UInt8 {
        let o: EfOperand = getOperand(opcode)
        _regY = setNZFlags(value: o.operand)
        return exitOpcode(opcode, plusCycle: o.plus)
    }

    open func processLSR(opcode: MOS6502Opcode) -> UInt8 {
        shiftRight(opcode: opcode, carryIn: 0)
    }

    open func processNOP(opcode: MOS6502Opcode) -> UInt8 {
        exitOpcode(opcode)
    }

    open func processORA(opcode: MOS6502Opcode) -> UInt8 {
        let o: EfOperand = getOperand(opcode)
        _regAcc = setNZFlags(value: _regAcc | o.operand)
        return exitOpcode(opcode, plusCycle: o.plus)
    }

    open func processPHA(opcode: MOS6502Opcode) -> UInt8 {
        stackPush(byte: _regAcc)
        return exitOpcode(opcode)
    }

    open func processPHP(opcode: MOS6502Opcode) -> UInt8 {
        stackPush(byte: _regSt)
        return exitOpcode(opcode)
    }

    open func processPLA(opcode: MOS6502Opcode) -> UInt8 {
        _regAcc = setNZFlags(value: stackPop())
        return exitOpcode(opcode)
    }

    open func processPLP(opcode: MOS6502Opcode) -> UInt8 {
        _regSt = stackPop()
        return exitOpcode(opcode)
    }

    open func processRLA(opcode: MOS6502Opcode) -> UInt8 {
        return exitOpcode(opcode)
    }

    open func processROL(opcode: MOS6502Opcode) -> UInt8 {
        shiftLeft(opcode: opcode, carryIn: (_regSt & fC))
    }

    open func processROR(opcode: MOS6502Opcode) -> UInt8 {
        shiftRight(opcode: opcode, carryIn: (_regSt & fC))
    }

    open func processRRA(opcode: MOS6502Opcode) -> UInt8 {
        return exitOpcode(opcode)
    }

    open func processRTI(opcode: MOS6502Opcode) -> UInt8 {
        _regSt = stackPop()
        return processRTS(opcode: opcode)
    }

    open func processRTS(opcode: MOS6502Opcode) -> UInt8 {
        _regPC = (stackPopAddress() &+ 1)
        return 0
    }

    open func processSAX(opcode: MOS6502Opcode) -> UInt8 {
        return exitOpcode(opcode)
    }

    open func processSBC(opcode: MOS6502Opcode) -> UInt8 {
        let o: EfOperand = getOperand(opcode)
        (_regAcc, _regSt) = addWithCarry(leftOperand: _regAcc, rightOperand: ~o.operand, carryIn: (_regSt & fC))
        return exitOpcode(opcode, plusCycle: o.plus)
    }

    open func processSEC(opcode: MOS6502Opcode) -> UInt8 {
        _regSt <+= .Carry
        return exitOpcode(opcode)
    }

    open func processSED(opcode: MOS6502Opcode) -> UInt8 {
        _regSt <+= .Decimal
        return exitOpcode(opcode)
    }

    open func processSEI(opcode: MOS6502Opcode) -> UInt8 {
        _regSt <+= .IRQ
        return exitOpcode(opcode)
    }

    open func processSHX(opcode: MOS6502Opcode) -> UInt8 {
        return exitOpcode(opcode)
    }

    open func processSHY(opcode: MOS6502Opcode) -> UInt8 {
        return exitOpcode(opcode)
    }

    open func processSLO(opcode: MOS6502Opcode) -> UInt8 {
        return exitOpcode(opcode)
    }

    open func processSRE(opcode: MOS6502Opcode) -> UInt8 {
        return exitOpcode(opcode)
    }

    open func processSTA(opcode: MOS6502Opcode) -> UInt8 {
        exitOpcode(opcode, plusCycle: setOperand(opcode, value: _regAcc))
    }

    open func processSTX(opcode: MOS6502Opcode) -> UInt8 {
        exitOpcode(opcode, plusCycle: setOperand(opcode, value: _regX))
    }

    open func processSTY(opcode: MOS6502Opcode) -> UInt8 {
        exitOpcode(opcode, plusCycle: setOperand(opcode, value: _regY))
    }

    open func processTAS(opcode: MOS6502Opcode) -> UInt8 {
        return exitOpcode(opcode)
    }

    open func processTAX(opcode: MOS6502Opcode) -> UInt8 {
        _regX = setNZFlags(value: _regAcc)
        return exitOpcode(opcode)
    }

    open func processTAY(opcode: MOS6502Opcode) -> UInt8 {
        _regY = setNZFlags(value: _regAcc)
        return exitOpcode(opcode)
    }

    open func processTSX(opcode: MOS6502Opcode) -> UInt8 {
        _regX = setNZFlags(value: regSP)
        return exitOpcode(opcode)
    }

    open func processTXA(opcode: MOS6502Opcode) -> UInt8 {
        _regAcc = setNZFlags(value: _regX)
        return exitOpcode(opcode)
    }

    open func processTXS(opcode: MOS6502Opcode) -> UInt8 {
        _regSP = (0x0100 | UInt16(_regX))
        return exitOpcode(opcode)
    }

    open func processTYA(opcode: MOS6502Opcode) -> UInt8 {
        _regAcc = setNZFlags(value: _regY)
        return exitOpcode(opcode)
    }

    open func processXAA(opcode: MOS6502Opcode) -> UInt8 {
        return exitOpcode(opcode)
    }

    private var tickAdd:  UInt8 = 0
    private var tickHold: Bool  = true

    private func setTickAdd(_ delta: UInt8) {
        while tickAdd != 0 {}
        tickAdd = delta
    }
}
