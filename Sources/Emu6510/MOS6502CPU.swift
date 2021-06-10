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

//@f:0
fileprivate let BCDTable: [UInt8] = [


]
//@f:1

open class MOS6502CPU {
    @usableFromInline typealias EfOperand = (operand: UInt8, plus: UInt8)
    @usableFromInline typealias EfAddress = (address: UInt16, plus: UInt8)

    /*===========================================================================================================================================================================*/
    /// Returns `true` if the CPU Clock is running.
    ///
    public internal(set) var isRunning: Bool = false

    public var            irq:       Bool = false
    public var            nmi:       Bool = false
    public var            reset:     Bool = false
    public let            memory:    MOS6502SystemMemoryMap
    /// The 65C02 handles BCD mode slightly different with regards to the N and Z flags.
    /// Setting this flag to true will cause the emulator to handle them the same way
    /// the 65C02 does. Setting this flag to false will cause the emulator to handle them
    /// the same way the 6502 does.
    public var            bcd65c02:  Bool = false

    /*===========================================================================================================================================================================*/
    /// The Accumulator.
    ///
    @inlinable public var regAcc:    UInt8 { _regAcc }
    /*===========================================================================================================================================================================*/
    /// The X register.
    ///
    @inlinable public var regX:      UInt8 { _regX }
    /*===========================================================================================================================================================================*/
    /// The Y register.
    ///
    @inlinable public var regY:      UInt8 { _regY }
    /*===========================================================================================================================================================================*/
    /// The program counter.
    ///
    @inlinable public var regPC:     UInt16 { _regPC }
    /*===========================================================================================================================================================================*/
    /// I've look in several places and no one really talks about what the initial value of the stack pointer is. Only one reference said it is reset to zero on startup. But it is
    /// known that the startup routine SHOULD set the stack pointer.
    ///
    @inlinable public var regSP:     UInt8 { U16toU8(_regSP) }
    /*===========================================================================================================================================================================*/
    /// The sixth bit (32 (0x20)) of the status register should always be 1 (one).
    ///
    @inlinable public var regStatus: UInt8 { (_regSt | 0x20) }

    //@f:0
    @usableFromInline var _regAcc:     UInt8           = 0x00
    @usableFromInline var _regX:       UInt8           = 0x00
    @usableFromInline var _regY:       UInt8           = 0x00
    @usableFromInline var _regPC:      UInt16          = 0x0000
    @usableFromInline var _regSP:      UInt16          = 0x0100
    @usableFromInline var _regSt:      UInt8           = 0x20
    @usableFromInline var clockPeriod: UInt64
    @usableFromInline var clockInfo:   MOS6502ClockInfo

    // These fields are used to calculate the effective address of the operand or the target address of a JMP or JSR.
    @inlinable final  var efOperand:   UInt16          { (_regPC &+ 1) }
    @inlinable final  var efAbsolute:  UInt16          { memory.getWord(address: efOperand) }
    @inlinable final  var efAbsoluteX: (UInt16, Bool)  { let a = (memory.getWord(address: efOperand) &+ U8toU16(_regX)); return (a, DiffPage(a, (efOperand &+ 1))) }
    @inlinable final  var efAbsoluteY: (UInt16, Bool)  { let a = (memory.getWord(address: efOperand) &+ U8toU16(_regY)); return (a, DiffPage(a, (efOperand &+ 1))) }
    @inlinable final  var efRelative:  (UInt16, UInt8) { let pc: UInt16 = efOperand; let ta: UInt16 = I16toU16((U16toI16(pc) &+ U8toI16(memory[pc]))); return (ta, (DiffPage(ta, pc) ? 2 : 1)) }
    @inlinable final  var efIndirectY: (UInt16, Bool)  { let a = memory.getWord(zpAddress: memory[efOperand]); let b = (a &+ U8toU16(_regY)); return (b, DiffPage(a, b)) }
    @inlinable final  var efIndirectX: UInt16          { memory.getWord(zpAddress: (memory[efOperand] &+ _regX)) }
    @inlinable final  var efIndirect:  UInt16          { memory.getWord(address: efAbsolute, fromSamePage: true) }
    @inlinable final  var efZeroPage:  UInt8           { memory[efOperand] }
    @inlinable final  var efZeroPageX: UInt8           { memory[efOperand] &+ _regX }
    @inlinable final  var efZeroPageY: UInt8           { memory[efOperand] &+ _regY }
    @inlinable final  var clrNZCV:     UInt8           { (_regSt & (~(fN | fZ | fC | fV))) }
    @inlinable final  var clrNZC:      UInt8           { (_regSt & (~(fN | fZ | fC))) }
    @inlinable final  var clrNZV:      UInt8           { (_regSt & (~(fN | fZ | fV))) }
    @inlinable final  var clrNZ:       UInt8           { (_regSt & (~(fN | fZ))) }

    @inlinable final  var fCarry:      UInt8           { (_regSt & fC) }
    @inlinable final  var fDecimal:    Bool            { ((_regSt & MOS6502Flag.Decimal) == MOS6502Flag.Decimal) }
    //@f:1

    public init(clockInfo c: MOS6502ClockInfo, memory: MOS6502SystemMemoryMap) {
        self.clockInfo = c
        self.clockPeriod = c.period
        self.memory = memory
        guard mos6502OpcodeList.count == 256 else { fatalError("Incorrect opcode list count: \(mos6502OpcodeList.count) != 256") }
    }

    open func setClock(clockInfo c: MOS6502ClockInfo) -> MOS6502ClockInfo {
        let old = self.clockInfo
        self.clockInfo = c
        self.clockPeriod = c.period
        return old
    }

    @inlinable final func doWithOperand(_ opcode: MOS6502Opcode, _ proc: (UInt8) -> Void) -> UInt8 {
        let o = getOperand(opcode)
        proc(o.operand)
        _regPC += U8toU16(opcode.bytes)
        return o.plus
    }

    @inlinable final func doWithAddress(_ opcode: MOS6502Opcode, _ proc: (UInt16) -> Void) -> UInt8 {
        let a = getTargetAddress(opcode)
        proc(a.address)
        _regPC += U8toU16(opcode.bytes)
        return a.plus
    }

    @inlinable final func doWithRegister(_ opcode: MOS6502Opcode, _ proc: () -> Void) -> UInt8 {
        proc()
        _regPC += U8toU16(opcode.bytes)
        return 0 // Register actions never incur a cycle penalty.
    }

    @inlinable final func setSP(_ sp: UInt8) { _regSP = (0x0100 | U8toU16(sp)) }

    @discardableResult @inlinable final func setNZFlags(value v: UInt8) -> UInt8 {
        _regSt = (clrNZ | (v & fN) | ZeroFlag(v))
        return v
    }

    @discardableResult @inlinable final func setNZCFlags(value v: UInt8, carryOut c: UInt8) -> UInt8 {
        _regSt = (clrNZC | (v & fN) | ZeroFlag(v) | (c & fC))
        return v
    }

    @discardableResult @inlinable final func setNZVFlags(value v: UInt8) -> UInt8 {
        _regSt = (clrNZV | (v & fN) | ZeroFlag(v) | (v & fV))
        return v
    }

    @inlinable final func stackPush(byte: UInt8) {
        memory[_regSP] = byte; _regSP = ((_regSP == 0x0100) ? 0x01ff : (_regSP - 1))
    }

    @inlinable final func stackPushAddress(address a: UInt16) {
        stackPush(byte: U16toU8((a & 0xff00) >> 8)); stackPush(byte: U16toU8(a))
    }

    @inlinable final func stackPop() -> UInt8 {
        _regSP = ((_regSP == 0x01ff) ? 0x0100 : (_regSP + 1)); return memory[_regSP]
    }

    @inlinable final func stackPopAddress() -> UInt16 {
        let bLo = stackPop(); let bHi = stackPop(); return (U8toU16(bLo) | (U8toU16(bHi) << 8))
    }

    /*===========================================================================================================================================================================*/
    /// This method is for opcodes that operate only on memory. In other words, no IMPlied, ACCumulator, or IMMediate addressing modes.
    ///
    /// - Parameter opcode: The opcode.
    /// - Returns: The target address of the operand.
    ///
    @usableFromInline final func getTargetAddress(_ opcode: MOS6502Opcode) -> EfAddress {
        switch opcode.addressingMode {
            case .ACC, .IMM, .IMP:           fatalError("Invalid addressing mode.")
            case .ABS:                       return (efAbsolute, 0)
            case .ABSX: let r = efAbsoluteX; return (r.0, ((opcode.plus1 && r.1) ? 1 : 0))
            case .ABSY: let r = efAbsoluteY; return (r.0, ((opcode.plus1 && r.1) ? 1 : 0))
            case .IND:                       return (efIndirect, 0)
            case .INDX:                      return (efIndirectX, 0)
            case .INDY: let r = efIndirectY; return (r.0, ((opcode.plus1 && r.1) ? 1 : 0))
            case .REL:                       return efRelative
            case .ZP:                        return (U8toU16(efZeroPage), 0)
            case .ZPX:                       return (U8toU16(efZeroPageX), 0)
            case .ZPY:                       return (U8toU16(efZeroPageY), 0)
        }
    }

    @discardableResult @usableFromInline final func getOperand(_ opcode: MOS6502Opcode) -> EfOperand {
        switch opcode.addressingMode {
            case .IMP:                       fatalError("Invalid addressing mode.")
            case .REL:   let r = efRelative; return (memory[r.0], r.1)
            case .IND:                       return (memory[efIndirect], 0)
            case .ACC:                       return (_regAcc, 0)
            case .ABS:                       return (memory[efAbsolute], 0)
            case .ABSX: let r = efAbsoluteX; return (memory[r.0], ((opcode.plus1 && r.1) ? 1 : 0))
            case .ABSY: let r = efAbsoluteY; return (memory[r.0], ((opcode.plus1 && r.1) ? 1 : 0))
            case .IMM:                       return (memory[efOperand], 0)
            case .INDX:                      return (memory[efIndirectX], 0)
            case .INDY: let r = efIndirectY; return (memory[r.0], ((opcode.plus1 && r.1) ? 1 : 0))
            case .ZP:                        return (memory[efZeroPage], 0)
            case .ZPX:                       return (memory[efZeroPageX], 0)
            case .ZPY:                       return (memory[efZeroPageY], 0)
        }
    }

    @discardableResult @usableFromInline final func setOperand(_ opcode: MOS6502Opcode, value: UInt8) -> UInt8 {
        var r: (UInt16, Bool) = (0, false)

        switch opcode.addressingMode {
            case .IMM, .IMP: fatalError("Invalid addressing mode.")
            case .REL: let x = efRelative; r = (x.0, (x.1 != 0))
            case .IND:                     r = (efIndirect, false)
            case .ABS:                     r = (efAbsolute, false)
            case .ABSX:                    r = efAbsoluteX
            case .ABSY:                    r = efAbsoluteY
            case .INDX:                    r = (efIndirectX, false)
            case .INDY:                    r = efIndirectY
            case .ZP:                      r = (U8toU16(efZeroPage), false)
            case .ZPX:                     r = (U8toU16(efZeroPageX), false)
            case .ZPY:                     r = (U8toU16(efZeroPageY), false)
            case .ACC:                     _regAcc = value; return 0 // The exception to the rule.
        }

        memory[r.0] = value
        return ((opcode.plus1 && r.1) ? 1 : 0)
    }

    @usableFromInline typealias MathResultA = (A: UInt8, S: UInt8)

    @usableFromInline typealias MathResultB = (A: UInt8, V: UInt8, C: UInt8, N: UInt8, Z: UInt8)

    @inlinable final func addWithCarry(leftOperand opL: UInt8, rightOperand opR: UInt8, carryIn: UInt8, decimalMode bcd: Bool = false) -> MathResultA {
        (bcd ? addWithCarryBCD(opL: opL, opR: opR, carryIn: carryIn) : addWithCarryBinary(leftOperand: opL, rightOperand: opR, carryIn: carryIn))
    }

    @inlinable final func subtractWithCary(leftOperand opL: UInt8, rightOperand opR: UInt8, carryIn: UInt8) -> MathResultA {
        (fDecimal ? subtractWithCarryBCD(opL: opL, opR: opR, carryIn: carryIn) : addWithCarryBinary(leftOperand: opL, rightOperand: ~opR, carryIn: carryIn))
    }

    @inlinable final func addWithCarryBinary(leftOperand opL: UInt8, rightOperand opR: UInt8, carryIn: UInt8) -> MathResultA {
        let res: UInt16 = (U8toU16(opL) + U8toU16(opR) + U8toU16(carryIn)) // There is no chance of overflow here.
        let rs8: UInt8  = U16toU8(res)
        return (A: rs8, S: (clrNZCV | (rs8 & fN) | ZeroFlag(rs8) | CarryFlag(res) | (((opL ^ rs8) & (opR ^ rs8) & fN) >> 1)))
    }

    @inlinable func addWithCarryBCD(opL: UInt8, opR: UInt8, carryIn c: UInt8) -> MathResultA {
        //@f:0
        // http://6502.org/tutorials/decimal_mode.html#A
        /* 1a. AL = (A & $0F) + (B & $0F) + C                           */ var al1 = (U8toU16(opL & 0x0f) + U8toU16(opR & 0x0f) + U8toU16(c))
        /* 1b. If AL >= $0A, then AL = ((AL + $06) & $0F) + $10         */ if al1 >= 0x0a { al1 = (((al1 + 0x06) & 0x0f) + 0x10) }
        /* 1c. A = (A & $F0) + (B & $F0) + AL                           */ al1 = (U8toU16(opL & 0xf0) + U8toU16(opR & 0xf0) + al1)
        /* 1d. Note that A can be >= $100 at this point                 */
        /* 1e. If (A >= $A0), then A = A + $60                          */ let al2 = ((al1 < 0xa0) ? al1 : (al1 + 0x60))
        /* 1f. The accumulator result is the lower 8 bits of A          */ let a8 = U16toU8(al2)
        /* 1g. The carry result is 1 if A >= $100, and is 0 if A < $100 */
        //@f:1

        let ali  = (U8toI16(opL & 0xf0) + U8toI16(opR & 0xf0) + U16toI16(al2))
        let f    = (clrNZCV | CarryFlag(al2) | OverflowFlag(ali))
        return (A: a8, S: (f | (bcd65c02 ? ((a8 & fN) | ZeroFlag(a8)) : ((I16toU8(ali) & fN) | ZeroFlag(al1 & 0xff)))))
    }

    @inlinable func subtractWithCarryBCD(opL: UInt8, opR: UInt8, carryIn: UInt8) -> MathResultA {
        let r = (bcd65c02 ? sbcBCD65C02(opL, opR, U8toI16(carryIn)) : sbcBCD6502(opL, opR, U8toI16(carryIn)))
        return (A: r.A, S: (clrNZCV | r.N | r.Z | r.C | r.V))
    }

    @inlinable final func sbcBCD6502(_ opL: UInt8, _ opR: UInt8, _ c: Int16) -> MathResultB {
        //@f:0
        // http://6502.org/tutorials/decimal_mode.html#A
        /* 3a. AL = (A & $0F) - (B & $0F) + C - 1              */ var al = (U8toI16(opL & 0x0f) - U8toI16(opR & 0x0f) + c - 1)
        /* 3b. If AL < 0, then AL = ((AL - $06) & $0F) - $10   */ if al < 0 { al = (((al - 0x06) & 0x0f) - 0x10) }
        /* 3c. A = (A & $F0) - (B & $F0) + AL                  */ let aa:  Int16  = (U8toI16(opL & 0xf0) - U8toI16(opR & 0xf0) + al)
        /* 3d. If A < 0, then A = A - $60                      */ let a16: UInt16 = I16toU16(((aa < 0) ? (aa - 0x60) : aa))
        /* 3e. The accumulator result is the lower 8 bits of A */ let a8:  UInt8  = U16toU8(a16)
        //@f:1

        return (A: a8, V: ((aa < -128 || aa > 127) ? fV : 0), C: CarryFlag(a16), N: I16toU8(aa), Z: (((aa & 0xff) == 0) ? fZ : 0))
    }

    @inlinable final func sbcBCD65C02(_ opL: UInt8, _ opR: UInt8, _ c: Int16) -> MathResultB {
        //@f:0
        // http://6502.org/tutorials/decimal_mode.html#A
        /* 4a. AL = (A & $0F) - (B & $0F) + C - 1              */ let al = (U8toI16(opL & 0x0f) - U8toI16(opR & 0x0f) + c - 1)
        /* 4b. A = A - B + C - 1                               */ var aa = (U8toI16(opL) - U8toI16(opR) + c - 1)
        /* 4c. If A < 0, then A = A - $60                      */ if aa < 0 { aa -= 0x60 }
        /* 4d. If AL < 0, then A = A - $06                     */ if al < 0 { aa -= 0x06 }
        /*                                                     */ let a16: UInt16 = I16toU16(aa)
        /* 4e. The accumulator result is the lower 8 bits of A */ let a8:  UInt8  = U16toU8(a16)
        //@f:1

        return (A: a8, V: OverflowFlag(aa), C: CarryFlag(a16), N: (a8 & 0x80), Z: ZeroFlag(a8))
    }

    @discardableResult @inlinable final func shiftLeft(opcode: MOS6502Opcode, operand o: UInt8, carryIn c: UInt8) -> UInt8 {
        let r = setNZCFlags(value: ((o << 1) | (c & fC)), carryOut: (o >> 7))
        setOperand(opcode, value: r)
        return r
    }

    @discardableResult @inlinable final func shiftRight(opcode: MOS6502Opcode, operand o: UInt8, carryIn c: UInt8) -> UInt8 {
        let r = setNZCFlags(value: ((o >> 1) | (c << 7)), carryOut: (o & fC))
        setOperand(opcode, value: r)
        return r
    }

    @inlinable final func handleBranch(opcode: MOS6502Opcode, branchOn: Bool) -> UInt8 {
        guard branchOn else { _regPC &+= U8toU16(opcode.bytes); return 0 }
        let (ta, p1) = efRelative
        _regPC = ta
        return p1
    }

    @discardableResult @inlinable final func handleInterrupt(_ type: MOS6502Interrupt) -> UInt8 {
        _regPC = memory.getWord(address: type.vector)

        switch type {
            case .IRQ:
                stackPushAddress(address: (_regPC &- 1))
                stackPush(byte: _regSt)
                _regSt <+= .IRQ
                irq = false
                return 7
            case .NMI:
                stackPushAddress(address: (_regPC &- 1))
                stackPush(byte: _regSt)
                _regSt <+= .IRQ
                nmi = false
                return 7
            case .Break:
                stackPushAddress(address: _regPC)
                stackPush(byte: _regSt)
                _regSt <+= .IRQ
                return 7
            case .Reset:
                _regSt <+= .IRQ
                reset = false
                return 7
        }
    }

    @discardableResult @inlinable final func handleCompare(register r: UInt8, operand o: UInt8) -> UInt8 {
        let cmp = addWithCarry(leftOperand: r, rightOperand: ~o, carryIn: 1)
        _regSt = (clrNZC | (cmp.1 & ~fV))
        return cmp.0
    }

    @discardableResult @inlinable final func handleDEC(address a: UInt16) -> UInt8 {
        let o = (memory[a] &- 1)
        memory[a] = o
        return o
    }

    @discardableResult @inlinable final func handleINC(address a: UInt16) -> UInt8 {
        let o = (memory[a] &+ 1)
        memory[a] = o
        return o
    }

    @inlinable final func handleRRA(opcode o: MOS6502Opcode, address a: UInt16) {
        let o = shiftRight(opcode: o, operand: memory[a], carryIn: fCarry)
        (_regAcc, _regSt) = addWithCarry(leftOperand: _regAcc, rightOperand: o, carryIn: fCarry)
    }

    @inlinable final func foo(_ cycles: UInt8) -> UInt64 { (UInt64(cycles) &+ clockPeriod) }

    open func run() {
        var nextTick: UInt64 = (getSystemTime() &+ foo(7))
        isRunning = true
        defer { isRunning = false }

        while isRunning {
            while getSystemTime() < nextTick { /* Wait for the next clock tick. */ }

            if reset {
                nextTick += foo(handleInterrupt(.Reset))
            }
            else if nmi {
                nextTick += foo(handleInterrupt(.NMI))
            }
            else if irq && (_regSt ?!= .IRQ) {
                nextTick += foo(handleInterrupt(.IRQ))
            }
            else {
                (nextTick, isRunning) = handleOpcode(now: nextTick, opcode: mos6502OpcodeList[Int(memory[_regPC])])
            }
        }
    }

    open func handleOpcode(now: UInt64, opcode: MOS6502Opcode) -> (UInt64, Bool) {
        let nextTick = (now + foo(opcode.cycles))

        switch opcode.mnemonic {
          // Don't change the order of these next two case statements!
            case .JSR: stackPushAddress(address: (_regPC &+ U8toU16(opcode.bytes &- 1))); fallthrough
            case .JMP: _regPC = getTargetAddress(opcode).address
            case .BRK: handleInterrupt(.Break)

          // Don't change the order of these next two case statements!
            case .RTI: _regSt = stackPop(); fallthrough
            case .RTS: _regPC = (stackPopAddress() &+ 1)

          // Legal Instructions.
          // Load and Store.
            case .LDA: return ((nextTick + foo(doWithOperand(opcode) { o in _regAcc = setNZFlags(value: o) })), true)
            case .LDX: return ((nextTick + foo(doWithOperand(opcode) { o in _regX = setNZFlags(value: o) })), true)
            case .LDY: return ((nextTick + foo(doWithOperand(opcode) { o in _regY = setNZFlags(value: o) })), true)
            case .STA: return ((nextTick + foo(setOperand(opcode, value: _regAcc))), true)
            case .STX: return ((nextTick + foo(setOperand(opcode, value: _regX))), true)
            case .STY: return ((nextTick + foo(setOperand(opcode, value: _regY))), true)

          // Transfer to/from Stack
            case .PHA: return ((nextTick + foo(doWithRegister(opcode) { stackPush(byte: _regAcc) })), true)
            case .PHP: return ((nextTick + foo(doWithRegister(opcode) { stackPush(byte: _regSt) })), true)
            case .PLA: return ((nextTick + foo(doWithRegister(opcode) { _regAcc = setNZFlags(value: stackPop()) })), true)
            case .PLP: return ((nextTick + foo(doWithRegister(opcode) { _regSt = stackPop() })), true)

          // Transfer Between Regsiters.
            case .TAX: return ((nextTick + foo(doWithRegister(opcode) { _regX = setNZFlags(value: _regAcc) })), true)
            case .TAY: return ((nextTick + foo(doWithRegister(opcode) { _regY = setNZFlags(value: _regAcc) })), true)
            case .TSX: return ((nextTick + foo(doWithRegister(opcode) { _regX = setNZFlags(value: regSP) })), true)
            case .TXA: return ((nextTick + foo(doWithRegister(opcode) { _regAcc = setNZFlags(value: _regX) })), true)
            case .TXS: return ((nextTick + foo(doWithRegister(opcode) { setSP(_regX) })), true)
            case .TYA: return ((nextTick + foo(doWithRegister(opcode) { _regAcc = setNZFlags(value: _regY) })), true)

          // Status Register Manipulation.
            case .CLC: return ((nextTick + foo(doWithRegister(opcode) { _regSt <-= .Carry })), true)
            case .CLD: return ((nextTick + foo(doWithRegister(opcode) { _regSt <-= .Decimal })), true)
            case .CLI: return ((nextTick + foo(doWithRegister(opcode) { _regSt <-= .IRQ })), true)
            case .CLV: return ((nextTick + foo(doWithRegister(opcode) { _regSt <-= .Overflow })), true)
            case .SEC: return ((nextTick + foo(doWithRegister(opcode) { _regSt <+= .Carry })), true)
            case .SED: return ((nextTick + foo(doWithRegister(opcode) { _regSt <+= .Decimal })), true)
            case .SEI: return ((nextTick + foo(doWithRegister(opcode) { _regSt <+= .IRQ })), true)

          // Comparison
            case .BIT: return ((nextTick + foo(doWithOperand(opcode) { o in setNZVFlags(value: (_regAcc & o)) })), true)
            case .CMP: return ((nextTick + foo(doWithOperand(opcode) { o in handleCompare(register: _regAcc, operand: o) })), true)
            case .CPX: return ((nextTick + foo(doWithOperand(opcode) { o in handleCompare(register: _regX, operand: o) })), true)
            case .CPY: return ((nextTick + foo(doWithOperand(opcode) { o in handleCompare(register: _regY, operand: o) })), true)

          // Branching
            case .BCC: return ((nextTick + foo(handleBranch(opcode: opcode, branchOn: _regSt ?!= .Carry))), true)
            case .BCS: return ((nextTick + foo(handleBranch(opcode: opcode, branchOn: _regSt ?== .Carry))), true)
            case .BNE: return ((nextTick + foo(handleBranch(opcode: opcode, branchOn: _regSt ?!= .Zero))), true)
            case .BEQ: return ((nextTick + foo(handleBranch(opcode: opcode, branchOn: _regSt ?== .Zero))), true)
            case .BPL: return ((nextTick + foo(handleBranch(opcode: opcode, branchOn: _regSt ?!= .Negative))), true)
            case .BMI: return ((nextTick + foo(handleBranch(opcode: opcode, branchOn: _regSt ?== .Negative))), true)
            case .BVC: return ((nextTick + foo(handleBranch(opcode: opcode, branchOn: _regSt ?!= .Overflow))), true)
            case .BVS: return ((nextTick + foo(handleBranch(opcode: opcode, branchOn: _regSt ?== .Overflow))), true)

          // Math
            case .ADC: return ((nextTick + foo(doWithOperand(opcode) { o in (_regAcc, _regSt) = addWithCarry(leftOperand: _regAcc, rightOperand: o, carryIn: fCarry, decimalMode: fDecimal) })), true)
            case .SBC: return ((nextTick + foo(doWithOperand(opcode) { o in (_regAcc, _regSt) = addWithCarry(leftOperand: _regAcc, rightOperand: ~o, carryIn: fCarry, decimalMode: fDecimal) })), true)
            case .DEC: return ((nextTick + foo(doWithAddress(opcode) { a in handleDEC(address: a) })), true)
            case .INC: return ((nextTick + foo(doWithAddress(opcode) { a in handleINC(address: a) })), true)
            case .DEX: return ((nextTick + foo(doWithRegister(opcode) { _regX = setNZFlags(value: _regX &- 1) })), true)
            case .DEY: return ((nextTick + foo(doWithRegister(opcode) { _regY = setNZFlags(value: _regY &- 1) })), true)
            case .INX: return ((nextTick + foo(doWithRegister(opcode) { _regX = setNZFlags(value: _regX &+ 1) })), true)
            case .INY: return ((nextTick + foo(doWithRegister(opcode) { _regY = setNZFlags(value: _regY &+ 1) })), true)

          // Rotate and Shift
            case .ASL: return ((nextTick + foo(doWithOperand(opcode) { o in shiftLeft(opcode: opcode, operand: o, carryIn: 0) })), true)
            case .LSR: return ((nextTick + foo(doWithOperand(opcode) { o in shiftRight(opcode: opcode, operand: o, carryIn: 0) })), true)
            case .ROL: return ((nextTick + foo(doWithOperand(opcode) { o in shiftLeft(opcode: opcode, operand: o, carryIn: fCarry) })), true)
            case .ROR: return ((nextTick + foo(doWithOperand(opcode) { o in shiftRight(opcode: opcode, operand: o, carryIn: fCarry) })), true)

          // Logic
            case .AND: return ((nextTick + foo(doWithOperand(opcode) { o in _regAcc = setNZFlags(value: (_regAcc & o)) })), true)
            case .EOR: return ((nextTick + foo(doWithOperand(opcode) { o in _regAcc = setNZFlags(value: (_regAcc ^ o)) })), true)
            case .ORA: return ((nextTick + foo(doWithOperand(opcode) { o in _regAcc = setNZFlags(value: (_regAcc | o)) })), true)

          // Does nothing...
            case .NOP: _regPC += U8toU16(opcode.bytes)

          // Illegal Instructions.
            case .AHX: return ((nextTick + foo(doWithAddress(opcode) { a in memory[a] = (_regAcc & _regX & (U16HtoU8(a) &+ 1)) })), true)
            case .ALR: return ((nextTick + foo(doWithOperand(opcode) { o in let r = (_regAcc & o); _regAcc = setNZCFlags(value: (r >> 1), carryOut: (r & fC)) })), true)
            case .ANC: return ((nextTick + foo(doWithOperand(opcode) { o in let r: UInt8 = (_regAcc & o); _regAcc = setNZCFlags(value: r, carryOut: (r >> 7)) })), true)
            case .ARR: return ((nextTick + foo(doWithOperand(opcode) { o in shiftRight(opcode: opcode, operand: (_regAcc & o), carryIn: fCarry) })), true)
            case .AXS: return ((nextTick + foo(doWithOperand(opcode) { o in _regX = handleCompare(register: (_regAcc & _regX), operand: o) })), true)
            case .DCP: return ((nextTick + foo(doWithAddress(opcode) { a in handleCompare(register: _regAcc, operand: handleDEC(address: a)) })), true)
            case .ISC: return ((nextTick + foo(doWithAddress(opcode) { a in (_regAcc, _regSt) = addWithCarry(leftOperand: _regAcc, rightOperand: ~handleINC(address: a), carryIn: fCarry) })), true)
            case .LAS: return ((nextTick + foo(doWithOperand(opcode) { o in let r = setNZFlags(value: o & regSP); _regAcc = r; _regX = r; setSP(r) })), true)
            case .LAX: return ((nextTick + foo(doWithOperand(opcode) { o in _regAcc = setNZFlags(value: o); _regX = o })), true)
            case .RLA: return ((nextTick + foo(doWithAddress(opcode) { a in _regAcc = setNZFlags(value: (_regAcc & shiftRight(opcode: opcode, operand: memory[a], carryIn: fCarry))) })), true)
            case .RRA: return ((nextTick + foo(doWithAddress(opcode) { a in handleRRA(opcode: opcode, address: a) })), true)
            case .SAX: return ((nextTick + foo(doWithAddress(opcode) { a in memory[a] = (_regAcc & _regX) })), true)
            case .SHX: return ((nextTick + foo(doWithAddress(opcode) { a in memory[a] = (_regX & U16HtoU8(a)) })), true)
            case .SHY: return ((nextTick + foo(doWithAddress(opcode) { a in memory[a] = (_regY & U16HtoU8(a)) })), true)
            case .SLO: return ((nextTick + foo(doWithAddress(opcode) { a in _regAcc = setNZFlags(value: (_regAcc | shiftLeft(opcode: opcode, operand: memory[a], carryIn: 0))) })), true)
            case .SRE: return ((nextTick + foo(doWithAddress(opcode) { a in _regAcc = setNZFlags(value: (_regAcc ^ shiftRight(opcode: opcode, operand: memory[a], carryIn: 0))) })), true)
            case .TAS: return ((nextTick + foo(doWithAddress(opcode) { a in setSP(_regAcc & _regX); memory[a] = (_regAcc & _regX & memory[_regPC &+ 2]) })), true)
            case .XAA: return ((nextTick + foo(doWithOperand(opcode) { o in _regAcc = setNZFlags(value: (_regAcc & _regX)) })), true)

          // Sudden Death!
            case .KIL: return (0, false)
        }

        return (nextTick, true)
    }
}
