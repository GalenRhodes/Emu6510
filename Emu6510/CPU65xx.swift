/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: CPU65xx.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/5/20
 *
 * Copyright © 2020 Project Galen. All rights reserved.
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

public typealias CPUIOPort = (directionRegister: UInt8, ioPort: UInt8)

public protocol IOPortListener: AnyObject {
    func ioPortStatusChanged(oldStatus: CPUIOPort, newStatus: CPUIOPort)
}

public protocol IOPortControler: AnyObject {
    func isInput(bit: Bits8) -> Bool
    subscript(bit: Bits8) -> Bool { get set }
}

open class CPU65xx {

    /*===========================================================================================================================*/
    /// The ID for the CPU. It will be one of the values in the `MOS65xxFamily` enum.
    ///
    public var cpuID:          MOS65xxFamily { .Mos6502 }

    /*===========================================================================================================================*/
    /// The status register.
    ///
    public var statusRegister: UInt8  = 0

    /*===========================================================================================================================*/
    /// The accumulator.
    ///
    public var accumulator:    UInt8  = 0

    /*===========================================================================================================================*/
    /// The X register.
    ///
    public var registerX:      UInt8  = 0

    /*===========================================================================================================================*/
    /// The Y register.
    ///
    public var registerY:      UInt8  = 0

    /*===========================================================================================================================*/
    /// The stack pointer.
    ///
    public var stackPointer:   UInt8  = 255

    /*===========================================================================================================================*/
    /// The program counter.
    ///
    public var programCounter: UInt16 = 0

    /*===========================================================================================================================*/
    /// This will be set to the last instruction (even if it is unknown or invalid) fetched from memory.
    ///
    @usableFromInline var lastOpcode: UInt8 = 0

    /*===========================================================================================================================*/
    /// If there is an issue that the emulator cannot handle (except for unknown instruction) then this flag will be set to `true`
    /// to indicate it.
    ///
    @usableFromInline var panic:      Bool  = false

    /*===========================================================================================================================*/
    /// The address bus.
    ///
    @usableFromInline var addressBus: AddressBusListener

    /*===========================================================================================================================*/
    /// The CPU clock.
    ///
    public let  cpuClock: NanoTimer

    /*===========================================================================================================================*/
    /// If this flag gets set to `true` then the CPU halts all operations.
    ///
    private var halt:     Bool = false

    /*===========================================================================================================================*/
    /// Initialize the CPU with the given `clock` and `memoryManager`.
    /// 
    /// - Parameters:
    ///   - clock: The `CPUClock` that the CPU will use for timing.
    ///   - memoryManager: The `MemoryManager` that the CPU will use for accessing memory.
    ///
    public init(clock: NanoTimer, memoryManager: MemoryManager) {
        addressBus = memoryManager
        cpuClock = clock
        cpuClock.closure = {
            if !self.halt {
                self.lastOpcode = self.getNextPCByte()

                if !self.panic, let opcode: Mos6502OpcodeInfo = MOS6502_OPCODES[self.lastOpcode] {
                    let operands: [UInt8] = self.getOperands(opcode.bytes - 1)
                    self.cpuClock.add(skip: UInt((opcode.cycles - 1)))
                    self.dispatch(opcode: opcode, operands: operands)
                }
                else {
                    self.handleError()
                }
            }
        }
    }

    /*===========================================================================================================================*/
    /// Get the byte from the given address. If there is no next byte (e.g. - At the top of RAM) then the panic flag is set and
    /// zero is returned.
    /// 
    /// - Parameter addr: the address to get the byte up from.
    /// - Returns: the next byte or zero if there is no next byte.
    ///
    @inlinable public subscript(_ addr: UInt16) -> UInt8 {
        get {
            guard let b: UInt8 = addressBus[addr] else {
                panic = true
                return 0
            }
            return b
        }
        set {
            addressBus[addr] = newValue
        }
    }

    @inlinable func testOverflow(acc: UInt8, val: UInt8, res: UInt16) { Mos6502Flags.V.foo(n: &statusRegister, f: (((res ^ UInt16(acc)) & (res ^ UInt16(val)) & 128) != 0)) }

    @inlinable func testZero(_ n: UInt8) { Mos6502Flags.Z.foo(n: &statusRegister, f: n == 0) }

    @inlinable func testSign(_ n: UInt8) { Mos6502Flags.N.foo(n: &statusRegister, f: (n &! 128)) }

    @inlinable func testCarry(_ n: UInt16) { Mos6502Flags.C.foo(n: &statusRegister, f: (n &! 65280)) }

    @inlinable func decSP() -> UInt16 {
        let sp: UInt16 = (256 + UInt16(stackPointer))
        stackPointer = ((stackPointer == 0) ? 255 : (stackPointer - 1))
        return sp
    }

    @inlinable func incSP() -> UInt16 {
        stackPointer = ((stackPointer == 255) ? 0 : (stackPointer + 1))
        return (UInt16(stackPointer) + 256)
    }

    @inlinable func push(byte: UInt8) { self[decSP()] = byte }

    @inlinable func push(word: UInt16) {
        push(byte: UInt8((word & 65280) >> 8))
        push(byte: UInt8(word & 255))
    }

    @inlinable func pop() -> UInt8 { self[incSP()] }

    @inlinable func popWord() -> UInt16 {
        let word: UInt16 = UInt16(pop())
        return (word | (UInt16(pop()) << 8))
    }

    /*===========================================================================================================================*/
    /// Converts one or two operand bytes to a 16-bit address.
    /// 
    /// - Parameter bytes: the operands
    /// - Returns: the address.
    ///
    @inlinable func toAddress(bytes: [UInt8]) -> UInt16 { ((bytes.count == 0) ? 0 : ((bytes.count == 1) ? UInt16(bytes[0]) : ((UInt16(bytes[1]) << 8) | UInt16(bytes[0])))) }

    /*===========================================================================================================================*/
    /// Gets an indirect address.
    /// 
    /// - Parameters:
    ///   - addr: the address.
    ///   - zeroPage: `true` if the address is in page zero.
    /// 
    /// - Returns: the indirect address (the address stored at the address).
    ///
    @inlinable func getAddressAtAddress(addr: UInt16, zeroPage: Bool = false) -> UInt16 {
        let aLO: UInt16 = (zeroPage ? (addr & 255) : addr)
        let aHI: UInt16 = (zeroPage ? ((aLO + 1) & 255) : (addr + 1))
        let bLO: UInt16 = UInt16(self[aLO])
        let bHI: UInt16 = UInt16(self[aHI])
        return (panic ? 0 : ((bHI << 8) | bLO))
    }

    /*===========================================================================================================================*/
    /// Get the operational address based on the operands and the addressing mode.
    /// 
    /// - Parameters:
    ///   - mode: the addressing mode.
    ///   - operands: the operands.
    /// - Returns: the operational address.
    ///
    @inlinable func getAddress(mode: Mos6502AddressModes, operands: [UInt8]) -> UInt16 {
        switch mode {
          // Two operands which represent an address in memory.
            case .ABS: return toAddress(bytes: operands)
            case .ABSX: return (toAddress(bytes: operands) + UInt16(registerX))
            case .ABSY: return (toAddress(bytes: operands) + UInt16(registerY))
          // Two operands which represent an address in which to get another address.
            case .IND: return getAddressAtAddress(addr: toAddress(bytes: operands))
          // One operand which is a signed offset to be applied to the program counter.
            case .REL: return UInt16((Int32(programCounter) + Int32(makeSigned(operands[0]))) & 65535)
          // All have one operand and use page zero.
            case .INDX: return getAddressAtAddress(addr: UInt16(operands[0] + registerX), zeroPage: true)
            case .INDY: return (getAddressAtAddress(addr: toAddress(bytes: operands), zeroPage: true) + UInt16(registerY))
            case .ZP: return getAddressAtAddress(addr: UInt16(operands[0]))
            case .ZPX: return (getAddressAtAddress(addr: UInt16(operands[0])) + UInt16(registerX))
            case .ZPY: return (getAddressAtAddress(addr: UInt16(operands[0])) + UInt16(registerY))
          // Accumulator, Immediate, and Implied addressing modes. No address
            default: return 0
        }
    }

    @inlinable func getValue(mode: Mos6502AddressModes, operands: [UInt8]) -> UInt8 {
        switch mode {
            case .IMM: return operands[0]
            case .ACC: return accumulator
            case .IMP: return 0
            default: return self[getAddress(mode: mode, operands: operands)]
        }
    }

    @inlinable func setValue(value: UInt8, mode: Mos6502AddressModes, operands: [UInt8]) {
        switch mode {
            case .IMM: break
            case .IMP: break
            case .ACC: accumulator = value
            default: self[getAddress(mode: mode, operands: operands)] = value
        }
    }

    /*===========================================================================================================================*/
    /// Called when the execution of the current instruction has failed for some reason.
    ///
    public func handleError() { panic = true }

    @inlinable func getNextPCByte() -> UInt8 {
        if let b: UInt8 = addressBus[programCounter++] { return b }
        panic = true
        return 0
    }

    /*===========================================================================================================================*/
    /// Get the next count bytes from the addressBus indexed by the programCounter. If there are not enough next bytes (e.g. - At
    /// the top of RAM) then the panic flag is set and zero are substituted for the needed bytes.
    /// 
    /// - Parameter count: the number of bytes to get.
    /// - Returns: an array of the bytes.
    ///
    @inlinable func getOperands(_ count: UInt8) -> [UInt8] {
        switch count {
            case 1:
                return [ getNextPCByte() ]
            case 2:
                let b1: UInt8 = getNextPCByte()
                let b2: UInt8 = getNextPCByte()
                return [ b1, b2 ]
            default:
                return []
        }
    }

    /*===========================================================================================================================*/
    /// Dispatch the opcode to its handler.
    /// 
    /// - Parameters:
    ///   - opcode: the opcode
    ///   - operands: it's operands
    ///
    @inlinable func dispatch(opcode: Mos6502OpcodeInfo, operands: [UInt8]) {
        if !panic {
            switch opcode.mnemonic {
              // Add & Subtract
                case .ADC: opcodeADC(opcode, operands)
                case .SBC: opcodeSBC(opcode, operands)
              // Bitwise opcodes
                case .AND: opcodeAND(opcode, operands)
                case .ORA: opcodeORA(opcode, operands)
                case .EOR: opcodeEOR(opcode, operands)
                case .ROL: opcodeROL(opcode, operands)
                case .ROR: opcodeROR(opcode, operands)
                case .ASL: opcodeASL(opcode, operands)
                case .LSR: opcodeLSR(opcode, operands)
              // Branch opcodes
                case .BCC: opcodeBCC(opcode, operands)
                case .BCS: opcodeBCS(opcode, operands)
                case .BEQ: opcodeBEQ(opcode, operands)
                case .BMI: opcodeBMI(opcode, operands)
                case .BNE: opcodeBNE(opcode, operands)
                case .BPL: opcodeBPL(opcode, operands)
                case .BVC: opcodeBVC(opcode, operands)
                case .BVS: opcodeBVS(opcode, operands)
              // Jump opcodes
                case .JMP: opcodeJMP(opcode, operands)
                case .JSR: opcodeJSR(opcode, operands)
              // Return from opcodes
                case .RTI: opcodeRTI(opcode, operands)
                case .RTS: opcodeRTS(opcode, operands)
              // Test status bits opcode
                case .BIT: opcodeBIT(opcode, operands) /**/
              // Set status bits opcodes
                case .SEC: opcodeSEC(opcode, operands)
                case .SED: opcodeSED(opcode, operands)
                case .SEI: opcodeSEI(opcode, operands)
              // Clear status bits opcodes
                case .CLC: opcodeCLC(opcode, operands)
                case .CLD: opcodeCLD(opcode, operands)
                case .CLI: opcodeCLI(opcode, operands)
                case .CLV: opcodeCLV(opcode, operands)
              // Compare opcodes
                case .CMP: opcodeCMP(opcode, operands)
                case .CPX: opcodeCPX(opcode, operands)
                case .CPY: opcodeCPY(opcode, operands)
              // Decrement registers opcodes
                case .DEC: opcodeDEC(opcode, operands)
                case .DEX: opcodeDEX(opcode, operands)
                case .DEY: opcodeDEY(opcode, operands)
              // Increment registers opcodes
                case .INC: opcodeINC(opcode, operands)
                case .INX: opcodeINX(opcode, operands)
                case .INY: opcodeINY(opcode, operands)
              // Load registers opcodes
                case .LDA: opcodeLDA(opcode, operands)
                case .LDX: opcodeLDX(opcode, operands)
                case .LDY: opcodeLDY(opcode, operands)
              // Store registers opcodes
                case .STA: opcodeSTA(opcode, operands)
                case .STX: opcodeSTX(opcode, operands)
                case .STY: opcodeSTY(opcode, operands)
              // Stack opcodes
                case .PHA: opcodePHA(opcode, operands)
                case .PHP: opcodePHP(opcode, operands)
                case .PLA: opcodePLA(opcode, operands)
                case .PLP: opcodePLP(opcode, operands)
              // Transfer opcodes
                case .TAX: opcodeTAX(opcode, operands)
                case .TAY: opcodeTAY(opcode, operands)
                case .TXA: opcodeTXA(opcode, operands)
                case .TYA: opcodeTYA(opcode, operands)
                case .TSX: opcodeTSX(opcode, operands)
                case .TXS: opcodeTXS(opcode, operands)
              // Break opcode
                case .BRK: opcodeBRK(opcode, operands) /**/
              // NOOP opcode
                case .NOP: opcodeNOP(opcode, operands)
            }
        }
        else {
            handleError()
        }
    }

    @inlinable func rol(carry: Bool = false, od: Mos6502OpcodeInfo, oprands: [UInt8]) -> UInt8 {
        let v: UInt8 = getValue(mode: od.addressMode, operands: oprands)
        Mos6502Flags.C.foo(n: &statusRegister, f: (v &! 128))
        return ((v << 1) | (carry ? 1 : 0))
    }

    @inlinable func ror(carry: Bool = false, od: Mos6502OpcodeInfo, oprands: [UInt8]) -> UInt8 {
        let v: UInt8 = getValue(mode: od.addressMode, operands: oprands)
        Mos6502Flags.C.foo(n: &statusRegister, f: (v &! 1))
        return ((v >> 1) | (carry ? 128 : 0))
    }

    @inlinable func supertramp(v: UInt8, od: Mos6502OpcodeInfo, oprands: [UInt8]) {
        testSZ(v)
        setValue(value: v, mode: od.addressMode, operands: oprands)
    }

    @inlinable func testSZ(_ v: UInt8) {
        testSign(v)
        testZero(v)
    }

    /*===========================================================================================================================*/
    /// Process the ADC opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeADC(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        let a: UInt8  = accumulator
        let v: UInt8  = getValue(mode: od.addressMode, operands: oprands)
        let r: UInt16 = (((statusRegister &? Mos6502Flags.D) ? (UInt16(v) + UInt16(a)) : (UInt16(v) + UInt16(a))) + (statusRegister & 1))

        Mos6502Flags.C.foo(n: &statusRegister, f: (r &! 256))
        testOverflow(acc: a, val: v, res: r)
        accumulator = UInt8(r & 255)
        testSZ(accumulator)
    }

    /*===========================================================================================================================*/
    /// Process the SBC opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeSBC(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
    }

    /*===========================================================================================================================*/
    /// Process the ROL opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeROL(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        supertramp(v: rol(carry: (statusRegister &! Mos6502Flags.C), od: od, oprands: oprands), od: od, oprands: oprands)
    }

    /*===========================================================================================================================*/
    /// Process the ROR opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeROR(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        supertramp(v: ror(carry: (statusRegister &! Mos6502Flags.C), od: od, oprands: oprands), od: od, oprands: oprands)
    }

    /*===========================================================================================================================*/
    /// Process the ASL opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeASL(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        supertramp(v: rol(od: od, oprands: oprands), od: od, oprands: oprands)
    }

    /*===========================================================================================================================*/
    /// Process the LSR opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeLSR(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        supertramp(v: ror(od: od, oprands: oprands), od: od, oprands: oprands)
    }

    /*===========================================================================================================================*/
    /// Process the CMP opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeCMP(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        let v: UInt8 = getValue(mode: od.addressMode, operands: oprands)
        Mos6502Flags.C.foo(n: &statusRegister, f: (accumulator >= v))
        Mos6502Flags.Z.foo(n: &statusRegister, f: (accumulator == v))
        Mos6502Flags.N.foo(n: &statusRegister, f: (accumulator &! 128))
    }

    /*===========================================================================================================================*/
    /// Process the CPX opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeCPX(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        let v: UInt8 = getValue(mode: od.addressMode, operands: oprands)
        Mos6502Flags.C.foo(n: &statusRegister, f: (registerX >= v))
        Mos6502Flags.Z.foo(n: &statusRegister, f: (registerX == v))
        Mos6502Flags.N.foo(n: &statusRegister, f: (registerX &! 128))
    }

    /*===========================================================================================================================*/
    /// Process the CPY opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeCPY(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        let v: UInt8 = getValue(mode: od.addressMode, operands: oprands)
        Mos6502Flags.C.foo(n: &statusRegister, f: (registerY >= v))
        Mos6502Flags.Z.foo(n: &statusRegister, f: (registerY == v))
        Mos6502Flags.N.foo(n: &statusRegister, f: (registerY &! 128))
    }

    /*===========================================================================================================================*/
    /// Process the AND opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeAND(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        let v: UInt8 = (accumulator & getValue(mode: od.addressMode, operands: oprands))
        accumulator = v
        testSZ(v)
    }

    /*===========================================================================================================================*/
    /// Process the ORA opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeORA(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        let v: UInt8 = (accumulator | getValue(mode: od.addressMode, operands: oprands))
        accumulator = v
        testSZ(v)
    }

    /*===========================================================================================================================*/
    /// Process the EOR opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeEOR(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        let v: UInt8 = (accumulator ^ getValue(mode: od.addressMode, operands: oprands))
        accumulator = v
        testSZ(v)
    }

    /*===========================================================================================================================*/
    /// Process the BIT opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeBIT(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        let v: UInt8 = getValue(mode: od.addressMode, operands: oprands)
        Mos6502Flags.Z.foo(n: &statusRegister, f: (v &? accumulator))
        Mos6502Flags.N.foo(n: &statusRegister, f: (v &! 128))
        Mos6502Flags.V.foo(n: &statusRegister, f: (v &! 64))
    }

    /*===========================================================================================================================*/
    /// Process the BCC opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeBCC(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { if statusRegister &? Mos6502Flags.C { programCounter = getAddress(mode: od.addressMode, operands: oprands) } }

    /*===========================================================================================================================*/
    /// Process the BCS opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeBCS(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { if statusRegister &! Mos6502Flags.C { programCounter = getAddress(mode: od.addressMode, operands: oprands) } }

    /*===========================================================================================================================*/
    /// Process the BEQ opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeBEQ(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { if statusRegister &! Mos6502Flags.Z { programCounter = getAddress(mode: od.addressMode, operands: oprands) } }

    /*===========================================================================================================================*/
    /// Process the BMI opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeBMI(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { if statusRegister &! Mos6502Flags.N { programCounter = getAddress(mode: od.addressMode, operands: oprands) } }

    /*===========================================================================================================================*/
    /// Process the BNE opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeBNE(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { if statusRegister &? Mos6502Flags.Z { programCounter = getAddress(mode: od.addressMode, operands: oprands) } }

    /*===========================================================================================================================*/
    /// Process the BPL opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeBPL(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { if statusRegister &? Mos6502Flags.N { programCounter = getAddress(mode: od.addressMode, operands: oprands) } }

    /*===========================================================================================================================*/
    /// Process the BVC opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeBVC(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { if statusRegister &? Mos6502Flags.V { programCounter = getAddress(mode: od.addressMode, operands: oprands) } }

    /*===========================================================================================================================*/
    /// Process the BVS opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeBVS(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { if statusRegister &! Mos6502Flags.V { programCounter = getAddress(mode: od.addressMode, operands: oprands) } }

    /*===========================================================================================================================*/
    /// Process the BRK opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeBRK(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        push(word: programCounter++)
        push(byte: statusRegister | Mos6502Flags.B)
        statusRegister |= Mos6502Flags.I
        programCounter = getAddressAtAddress(addr: 65534)
    }

    /*===========================================================================================================================*/
    /// Process the CLC opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeCLC(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { statusRegister &= ~Mos6502Flags.C }

    /*===========================================================================================================================*/
    /// Process the CLD opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeCLD(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { statusRegister &= ~Mos6502Flags.D }

    /*===========================================================================================================================*/
    /// Process the CLI opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeCLI(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { statusRegister &= ~Mos6502Flags.I }

    /*===========================================================================================================================*/
    /// Process the CLV opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeCLV(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { statusRegister &= ~Mos6502Flags.V }

    /*===========================================================================================================================*/
    /// Process the DEC opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeDEC(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        let a: UInt16 = getAddress(mode: od.addressMode, operands: oprands)
        let r: UInt8  = (self[a] - 1)
        self[a] = r
        testSZ(r)
    }

    /*===========================================================================================================================*/
    /// Process the INC opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeINC(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        let a: UInt16 = getAddress(mode: od.addressMode, operands: oprands)
        let r: UInt8  = (self[a] + 1)
        self[a] = r
        testSZ(r)
    }

    /*===========================================================================================================================*/
    /// Process the DEX opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeDEX(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { testSZ(--registerX) }

    /*===========================================================================================================================*/
    /// Process the DEY opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeDEY(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { testSZ(--registerY) }

    /*===========================================================================================================================*/
    /// Process the INX opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeINX(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { testSZ(++registerX) }

    /*===========================================================================================================================*/
    /// Process the INY opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeINY(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { testSZ(++registerY) }

    /*===========================================================================================================================*/
    /// Process the JMP opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeJMP(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { programCounter = getAddress(mode: od.addressMode, operands: oprands) }

    /*===========================================================================================================================*/
    /// Process the JSR opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeJSR(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        push(word: (programCounter - 1))
        programCounter = getAddress(mode: od.addressMode, operands: oprands)
    }

    /*===========================================================================================================================*/
    /// Process the LDA opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeLDA(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        accumulator = getValue(mode: od.addressMode, operands: oprands)
        testSZ(accumulator)
    }

    /*===========================================================================================================================*/
    /// Process the LDX opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeLDX(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        registerX = getValue(mode: od.addressMode, operands: oprands)
        testSZ(registerX)
    }

    /*===========================================================================================================================*/
    /// Process the LDY opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeLDY(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        registerY = getValue(mode: od.addressMode, operands: oprands)
        testSZ(registerY)
    }

    /*===========================================================================================================================*/
    /// Process the NOP opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeNOP(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    /*===========================================================================================================================*/
    /// Process the PHA opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodePHA(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { push(byte: accumulator) }

    /*===========================================================================================================================*/
    /// Process the PHP opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodePHP(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { push(byte: statusRegister) }

    /*===========================================================================================================================*/
    /// Process the PLA opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodePLA(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        accumulator = pop()
        testSZ(accumulator)
    }

    /*===========================================================================================================================*/
    /// Process the PLP opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodePLP(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { statusRegister = pop() }

    /*===========================================================================================================================*/
    /// Process the RTI opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeRTI(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { programCounter = popWord() }

    /*===========================================================================================================================*/
    /// Process the RTS opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeRTS(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { programCounter = (popWord() + 1) }

    /*===========================================================================================================================*/
    /// Process the SEC opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeSEC(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { statusRegister |= Mos6502Flags.C }

    /*===========================================================================================================================*/
    /// Process the SED opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeSED(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { statusRegister |= Mos6502Flags.D }

    /*===========================================================================================================================*/
    /// Process the SEI opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeSEI(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { statusRegister |= Mos6502Flags.I }

    /*===========================================================================================================================*/
    /// Process the STA opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeSTA(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { self[getAddress(mode: od.addressMode, operands: oprands)] = accumulator }

    /*===========================================================================================================================*/
    /// Process the STX opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeSTX(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { self[getAddress(mode: od.addressMode, operands: oprands)] = registerX }

    /*===========================================================================================================================*/
    /// Process the STY opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeSTY(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { self[getAddress(mode: od.addressMode, operands: oprands)] = registerY }

    /*===========================================================================================================================*/
    /// Process the TSX opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeTSX(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        registerX = stackPointer
        testSZ(registerX)
    }

    /*===========================================================================================================================*/
    /// Process the TXS opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeTXS(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) { stackPointer = registerX }

    /*===========================================================================================================================*/
    /// Process the TXA opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeTXA(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        accumulator = registerX
        testSZ(accumulator)
    }

    /*===========================================================================================================================*/
    /// Process the TAX opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeTAX(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        registerX = accumulator
        testSZ(registerX)
    }

    /*===========================================================================================================================*/
    /// Process the TYA opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeTYA(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        accumulator = registerY
        testSZ(accumulator)
    }

    /*===========================================================================================================================*/
    /// Process the TAY opcode.
    /// 
    /// - Parameter od: the opcode information.
    ///
    public func opcodeTAY(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {
        registerY = accumulator
        testSZ(registerY)
    }
}
