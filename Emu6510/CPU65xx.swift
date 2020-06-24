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
    public var stackPointer:   UInt8  = 0xff

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
                    let ops: [UInt8] = self.getOperators(opcode.bytes - 1)
                    // Set the clock for the base number of cycles this instruction takes.
                    // (It may take longer but we'll handle that later on.)
                    self.cpuClock.add(skip: UInt((opcode.cycles - 1)))
                    self.dispatch(opcode: opcode, ops: ops)
                }
                else {
                    self.handleError()
                }
            }
        }
    }

    /*===========================================================================================================================*/
    /// Called when the execution of the current instruction has failed for some reason.
    ///
    public func handleError() { panic = true }

    /*===========================================================================================================================*/
    /// Get the byte from the given address. If there is no next byte (e.g. - At the top of RAM) then the panic flag is set and
    /// zero is returned.
    ///
    /// - Parameter addr: the address to get the byte up from.
    /// - Returns: the next byte or zero if there is no next byte.
    ///
    @inlinable public subscript(_ addr: UInt16) -> UInt8 {
        get { if let b: UInt8 = addressBus[addr] { return b }; panic = true; return 0 }
        set { addressBus[addr] = newValue }
    }

    /*===========================================================================================================================*/
    /// Get the byte from the given address. If there is no next byte (e.g. - At the top of RAM) then the panic flag is set and
    /// zero is returned.
    ///
    /// - Parameter addr: the address to get the byte up from.
    /// - Returns: the next byte or zero if there is no next byte.
    ///
    @inlinable public subscript(_ addr: UInt32) -> UInt8 {
        get { if let b: UInt8 = addressBus[UInt16(addr & 0xffff)] { return b }; panic = true; return 0 }
        set { addressBus[UInt16(addr & 0xffff)] = newValue }
    }

    /*===========================================================================================================================*/
    /// Test the given value and set the (Z)ero and sig(N) flags of the status register.
    ///
    /// - Parameter value: the value to test.
    /// - Returns: the value.
    ///
    @discardableResult @inlinable func testSZ(_ value: UInt8) -> UInt8 {
        setStatus(.Z, value == 0)
        setStatus(.N, (value &! 0x80))
        return value
    }

    /*===========================================================================================================================*/
    /// Decrement the stack pointer by one.
    ///
    /// - Returns: the original stack pointer value BEFORE the decrement.
    ///
    @inlinable func decSP() -> UInt16 {
        let sp: UInt16 = (0x0100 + UInt16(stackPointer))
        stackPointer = ((stackPointer == 0) ? 0xff : (stackPointer - 1))
        return sp
    }

    /*===========================================================================================================================*/
    /// Increment the stack pointer by one.
    ///
    /// - Returns: the new stack pointer value AFTER the increment.
    ///
    @inlinable func incSP() -> UInt16 {
        stackPointer = ((stackPointer == 0xff) ? 0 : (stackPointer + 1))
        return (UInt16(stackPointer) + 0x0100)
    }

    /*===========================================================================================================================*/
    /// Push a byte onto the stack.
    ///
    /// - Parameter byte: the byte.
    ///
    @inlinable func push(byte: UInt8) {
        self[decSP()] = byte
    }

    /*===========================================================================================================================*/
    /// Push a 16-bit word onto the stack.
    ///
    /// - Parameter word: the word.
    ///
    @inlinable func push(word: UInt16) {
        push(byte: UInt8((word & 0xff00) >> 8))
        push(byte: pack8(word))
    }

    /*===========================================================================================================================*/
    /// Pop a byte from the stack.
    ///
    /// - Returns: the byte.
    ///
    @inlinable func pop() -> UInt8 {
        self[incSP()]
    }

    /*===========================================================================================================================*/
    /// Pop a 16-bit word from the stack.
    ///
    /// - Returns: the word.
    ///
    @inlinable func popWord() -> UInt16 {
        let a: UInt8 = pop()
        let b: UInt8 = pop()
        return to16(lo: a, hi: b)
    }

    /*===========================================================================================================================*/
    /// Converts two bytes into a UInt16 value.
    ///
    /// - Parameters:
    ///   - lo: the low byte
    ///   - hi: the high byte
    /// - Returns: a UInt16 value
    ///
    @inlinable func to16(lo: UInt8, hi: UInt8) -> UInt16 {
        (UInt16(lo) | (UInt16(hi) << 8))
    }

    /*===========================================================================================================================*/
    /// Converts one or two operand bytes to a 16-bit address.
    ///
    /// - Parameter ops: the operators
    /// - Returns: the address.
    ///
    @inlinable func getAddress(_ ops: [UInt8]) -> UInt16 {
        ((ops.count == 0) ? 0 : (ops.count == 1 ? UInt16(ops[0]) : to16(lo: ops[0], hi: ops[1])))
    }

    /*===========================================================================================================================*/
    /// Gets an indirect address.
    ///
    /// - Parameter ops: the operators to the opcode.
    /// - Returns: the indirect address (the address stored at the address).
    ///
    @inlinable func getIndirectAddress(_ ops: [UInt8]) -> UInt16 {
        getIndirectAddress(getAddress(ops))
    }

    /*===========================================================================================================================*/
    /// Gets an indirect address. This method is for a page zero lookup which means it wraps.
    ///
    /// - Parameter addr: the address
    /// - Returns: the indirect address (the address stored at the address).
    ///
    @inlinable func getIndirectAddress(_ addr: UInt8) -> UInt16 {
        let addr16 = UInt16(addr)
        return to16(lo: self[addr16], hi: self[(addr16 + 1) & 0xff])
    }

    /*===========================================================================================================================*/
    /// Gets an indirect address.
    ///
    /// - Parameter addr: the address
    /// - Returns: the indirect address (the address stored at the address).
    ///
    @inlinable func getIndirectAddress(_ addr: UInt16) -> UInt16 {
        let addr32: UInt32 = UInt32(addr)
        return to16(lo: self[addr32], hi: self[addr32 + 1])
    }

    /*===========================================================================================================================*/
    /// Offset an address by an amount. This method adds one to the instruction execution time if the result is in a different page
    /// of memory.
    ///
    /// - Parameters:
    ///   - a: the address
    ///   - o: the offset
    /// - Returns: the sum of the address and the offset.
    ///
    @inlinable func getIndexedAddress(_ a: UInt16, _ o: UInt8) -> UInt16 {
        let f: UInt16 = (a + UInt16(o))
        if diffPg(a, f) { cpuClock.add() }
        return f
    }

    /*===========================================================================================================================*/
    /// Offset an address by an amount. This method adds one to the instruction execution time if the result is in a different page
    /// of memory. This method differs from getIndexedAddress(_:_:) in that the offset is signed and therefore the result can be
    /// before as well as after then given address.
    ///
    /// - Parameters:
    ///   - a: the address
    ///   - o: the offset
    /// - Returns: the sum of the address and the offset.
    ///
    @inlinable func getRelativeAddress(_ a: UInt16, _ o: Int8) -> UInt16 {
        let r: UInt16 = UInt16((Int32(a) + Int32(o)) & 0xffff)
        if diffPg(a, r) { cpuClock.add() }
        return r
    }

    /*===========================================================================================================================*/
    /// Yeah. Ummm. See the discussion on Indirect Indexed here: http://www.emulator101.com/6502-addressing-modes.html As with the
    /// others this method adds one to the instruction execution time if the result is in a different page of memory.
    ///
    /// - Parameter zpAddr: the address in page zero.
    /// - Returns: the Indirect Indexed address.
    ///
    @inlinable func getIndirectYAddress(_ zpAddr: UInt8) -> UInt16 {
        let f: UInt16 = getIndirectAddress(zpAddr)
        let a: UInt16 = (f + UInt16(registerY))
        if diffPg(f, a) { cpuClock.add() }
        return a
    }

    /*===========================================================================================================================*/
    /// Add two numbers together wrapping around if needed. No overflow error will occur.
    ///
    /// - Parameters:
    ///   - a: number 1
    ///   - b: number 2
    /// - Returns: the sum of the two numbers.
    ///
    @inlinable func addWithWrap(_ a: UInt8, _ b: UInt8) -> UInt8 {
        UInt8((UInt16(a) + UInt16(b)) & 0xff)
    }

    /*===========================================================================================================================*/
    /// Return `true` if the two addresses are in different pages of memory.
    ///
    /// - Parameters:
    ///   - a: address 1
    ///   - b: address 2
    /// - Returns: `true` if the upper 8 bits of both values are not the same.
    ///
    @inlinable func diffPg(_ a: UInt16, _ b: UInt16) -> Bool {
        ((a & 0xff00) != (b & 0xff00))
    }

    /*===========================================================================================================================*/
    /// Get the operational address based on the ops and the addressing mode.
    ///
    /// - Parameters:
    ///   - mode: the addressing mode.
    ///   - ops: the ops.
    /// - Returns: the operational address.
    ///
    @inlinable func getAddress(mode: Mos6502AddressModes, ops: [UInt8]) -> UInt16 {
        switch mode {
          // One operand which is a signed offset to be applied to the program counter.
            case .REL:  return getRelativeAddress(programCounter, makeSigned(ops[0]))

          // Two ops which represent an address in which to get another address.
            case .IND:  return getIndirectAddress(ops)

          // All have one operand and use page zero.
            case .INDX: return getIndirectAddress(addWithWrap(ops[0], registerX))
            case .INDY: return getIndirectYAddress(ops[0])

          // Two ops which represent an address in memory.
            case .ABS:  return getAddress(ops)
            case .ABSX: return getIndexedAddress(getAddress(ops), registerX)
            case .ABSY: return getIndexedAddress(getAddress(ops), registerY)

          // All have one operand and use page zero.
            case .ZP:   return UInt16(ops[0])
            case .ZPX:  return UInt16(addWithWrap(ops[0], registerX))
            case .ZPY:  return UInt16(addWithWrap(ops[0], registerY))

          // Accumulator, Immediate, and Implied addressing modes. No address
            default:    return 0
        }
    }

    /*===========================================================================================================================*/
    /// Read a value. The source of the value is determined by the opcode's address mode and provided operators.
    ///
    /// - Parameters:
    ///   - mode: the address mode.
    ///   - ops: the operators.
    /// - Returns: the value.
    ///
    @inlinable func readValue(mode: Mos6502AddressModes, ops: [UInt8]) -> UInt8 {
        switch mode {
            case .IMM: return ops[0]
            case .ACC: return accumulator
            case .IMP: return 0
            default: return self[getAddress(mode: mode, ops: ops)]
        }
    }

    /*===========================================================================================================================*/
    /// Write a value back to memory or the accumulator. It's destination is determined by the opcode's address mode and provided
    /// operators.
    ///
    /// - Parameters:
    ///   - value: the value
    ///   - mode: the address mode
    ///   - ops: the operators.
    ///
    @inlinable func writeValue(value: UInt8, mode: Mos6502AddressModes, ops: [UInt8]) {
        switch mode {
            case .IMM: break
            case .IMP: break
            case .ACC: accumulator = value
            default: self[getAddress(mode: mode, ops: ops)] = value
        }
    }

    /*===========================================================================================================================*/
    /// Set or clear a flag in the status register.
    ///
    /// - Parameters:
    ///   - f: the flag to set or clear
    ///   - s: `true` if the flag should be set or `false` if it should be cleared.
    ///
    @inlinable func setStatus(_ f: Mos6502Flags, _ s: Bool = true) {
        statusRegister = (s ? (statusRegister | f) : (statusRegister & ~f))
    }

    /*===========================================================================================================================*/
    /// Check if the status register has a particular flag set.
    ///
    /// - Parameter f: the flag
    /// - Returns: `true` if that flag is set in the status register.
    ///
    @inlinable func hasStatus(_ f: Mos6502Flags) -> Bool {
        (statusRegister &! f)
    }

    /*===========================================================================================================================*/
    /// Perform a left rotation.
    ///
    /// - Parameters:
    ///   - carry: `true` if the carry flag should be moved into the low bit.
    ///   - oc: the opcode
    ///   - ops: the operators
    /// - Returns: the new value.
    ///
    @inlinable func rol(carry: Bool = false, oc: Mos6502OpcodeInfo, ops: [UInt8]) -> UInt8 {
        let v: UInt8 = readValue(mode: oc.addressMode, ops: ops)
        setStatus(.C, (v &! 0x80))
        return ((v << 1) | (carry ? 1 : 0))
    }

    /*===========================================================================================================================*/
    /// Perform a right rotation.
    ///
    /// - Parameters:
    ///   - carry: `true` if the carry flag should be moved into the high bit.
    ///   - oc: the opcode
    ///   - ops: the operators
    /// - Returns: the new value.
    ///
    @inlinable func ror(carry: Bool = false, oc: Mos6502OpcodeInfo, ops: [UInt8]) -> UInt8 {
        let v: UInt8 = readValue(mode: oc.addressMode, ops: ops)
        setStatus(.C, (v &! 1))
        return ((v >> 1) | (carry ? 0x80 : 0))
    }

    /*===========================================================================================================================*/
    /// This method takes the value and sets the (Z)ero and sig(N) status bits before writing the value back according to the
    /// opcode's address mode.
    ///
    /// - Parameters:
    ///   - b: the value
    ///   - oc: the opcode
    ///   - ops: the operators
    ///
    @inlinable func writeValueWithTest(b: UInt8, oc: Mos6502OpcodeInfo, ops: [UInt8]) {
        writeValue(value: testSZ(b), mode: oc.addressMode, ops: ops)
    }

    /*===========================================================================================================================*/
    /// Take a packed BCD value and convert it to a normal binary value.
    ///
    /// - Parameter b: the packed BCD value.
    /// - Returns: the binary value as a UInt16.
    ///
    @inlinable func unpackBCD(_ b: UInt8) -> UInt16 {
        let _b = UInt16(b)
        return ((_b & 0xf0) >> 4) * 10 + (_b & 0x0f)
    }

    /*===========================================================================================================================*/
    /// Take a value and convert it to a packed BCD value.
    ///
    /// - Parameter value: the value.
    /// - Returns: the BCD value.
    ///
    @inlinable func packBCD<T: UnsignedInteger>(_ value: T) -> UInt8 {
        let byte = UInt8((value & 0xff) % 100)
        return (((byte / 10) << 4) | (byte % 10))
    }

    /*===========================================================================================================================*/
    /// Truncate an integer value and return as a UInt8 value.
    ///
    /// - Parameter b: the integer value.
    /// - Returns: the lower 8 bits as a UInt8 value.
    ///
    @inlinable func pack8<T: BinaryInteger>(_ b: T) -> UInt8 {
        UInt8(b & 0xff)
    }

    /*===========================================================================================================================*/
    /// Get the next byte from the program counter. Increments the program counter.
    ///
    /// - Returns: the next byte from the program counter.
    ///
    @inlinable func getNextPCByte() -> UInt8 {
        if let b: UInt8 = addressBus[programCounter++] { return b }
        panic = true
        return 0
    }

    /*===========================================================================================================================*/
    /// Compare a register to a value or byte in memory and set the status flags accordingly.
    ///
    /// - Parameters:
    ///   - register: the register value.
    ///   - oc: the opcode that triggered this call.
    ///   - ops: the operators for the opcode.
    ///
    @inlinable func compare(_ register: UInt8, _ oc: Mos6502OpcodeInfo, _ ops: [UInt8]) {
        let v: UInt8 = readValue(mode: oc.addressMode, ops: ops)
        setStatus(.C, (register >= v))
        setStatus(.Z, (register == v))
        setStatus(.N, (register &! 0x80))
    }

    /*===========================================================================================================================*/
    /// Alter a byte in memory setting the (Z)ero and sig(N) flags accordingly.
    ///
    /// - Parameters:
    ///   - a: the address of the byte.
    ///   - c: the closure to perform the alteration.
    ///
    @inlinable func alterMemory(_ a: UInt16, _ c: (UInt8) -> UInt8) {
        self[a] = testSZ(c(self[a]))
    }

    /*===========================================================================================================================*/
    /// Perform `addition` or `subtraction`. For `addition` set the `mask` parameter to `0` (`zero`). For `subtraction` set the
    /// `mask` parameter to `255`. Simply put, `subtraction` is nothing but `addition` with the right-hand operand exclusive-or'd
    /// with `255`.
    ///
    /// - Parameters:
    ///   - opcode: the `opcode` that triggered this call.
    ///   - ops: the operators for the `opcode`.
    ///   - mask: the add/subtract `mask`
    ///
    @inlinable func addsub(opcode: Mos6502OpcodeInfo, ops: [UInt8], mask: UInt16) {
        if !hasStatus(.D) {
            cpuClock.add(skip: 1)
            let val: UInt16 = unpackBCD(readValue(mode: opcode.addressMode, ops: ops)) ^ mask
            accumulator = packBCD(doAdd(lhs: unpackBCD(accumulator), rhs: val) { (r: UInt16) in ((r / 100) != 0) })
        }
        else {
            let val: UInt16 = UInt16(readValue(mode: opcode.addressMode, ops: ops)) ^ mask
            accumulator = pack8(doAdd(lhs: UInt16(accumulator), rhs: val) { (r: UInt16) in ((r & 0xff00) != 0) })
        }
    }

    /*===========================================================================================================================*/
    /// Perform a basic addition and set the status register accordingly.
    ///
    /// - Parameters:
    ///   - lhs: the `left-hand` operand
    ///   - rhs: the `right-hand` operand
    ///   - testCarry: a closure used to test if the carry flag should be set after the addition.
    /// - Returns: the result as a 16-bit unsigned integer.
    ///
    @inlinable func doAdd(lhs: UInt16, rhs: UInt16, testCarry: (UInt16) -> Bool) -> UInt16 {
        let r: UInt16 = (lhs + rhs + UInt16(hasStatus(.C) ? 1 : 0))
        setStatus(.V, (((r ^ lhs) & (r ^ rhs) & 0x80) != 0))
        setStatus(.C, testCarry(r))
        testSZ(pack8(r))
        return r
    }

    /*===========================================================================================================================*/
    /// Get the next count bytes from the addressBus indexed by the programCounter. If there are not enough next bytes (e.g. - At
    /// the top of RAM) then the panic flag is set and zero are substituted for the needed bytes.
    ///
    /// - Parameter count: the number of bytes to get.
    /// - Returns: an array of the bytes.
    ///
    @inlinable func getOperators(_ count: UInt8) -> [UInt8] {
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
    ///   - ops: it's ops
    ///
    @inlinable func dispatch(opcode oc: Mos6502OpcodeInfo, ops: [UInt8]) {
        if !panic {
            switch oc.mnemonic {
              // Add & Subtract
                case .ADC: addsub(opcode: oc, ops: ops, mask: 0x0000)
                case .SBC: addsub(opcode: oc, ops: ops, mask: 0x00ff)
              // Bitwise opcodes
                case .AND: accumulator = testSZ(accumulator & readValue(mode: oc.addressMode, ops: ops))
                case .ORA: accumulator = testSZ(accumulator | readValue(mode: oc.addressMode, ops: ops))
                case .EOR: accumulator = testSZ(accumulator ^ readValue(mode: oc.addressMode, ops: ops))
                case .ROL: writeValueWithTest(b: rol(carry: hasStatus(.C), oc: oc, ops: ops), oc: oc, ops: ops)
                case .ROR: writeValueWithTest(b: ror(carry: hasStatus(.C), oc: oc, ops: ops), oc: oc, ops: ops)
                case .ASL: writeValueWithTest(b: rol(oc: oc, ops: ops), oc: oc, ops: ops)
                case .LSR: writeValueWithTest(b: ror(oc: oc, ops: ops), oc: oc, ops: ops)
              // Branch opcodes
                case .BCS: if hasStatus(.C) { programCounter = getAddress(mode: oc.addressMode, ops: ops) }
                case .BEQ: if hasStatus(.Z) { programCounter = getAddress(mode: oc.addressMode, ops: ops) }
                case .BMI: if hasStatus(.N) { programCounter = getAddress(mode: oc.addressMode, ops: ops) }
                case .BVS: if hasStatus(.V) { programCounter = getAddress(mode: oc.addressMode, ops: ops) }
                case .BCC: if !hasStatus(.C) { programCounter = getAddress(mode: oc.addressMode, ops: ops) }
                case .BNE: if !hasStatus(.Z) { programCounter = getAddress(mode: oc.addressMode, ops: ops) }
                case .BPL: if !hasStatus(.N) { programCounter = getAddress(mode: oc.addressMode, ops: ops) }
                case .BVC: if !hasStatus(.V) { programCounter = getAddress(mode: oc.addressMode, ops: ops) }
              // Return from opcodes
                case .RTI: programCounter = popWord()
                case .RTS: programCounter = (popWord() + 1)
              // Set status bits opcodes
                case .SEC: setStatus(.C)
                case .SED: setStatus(.D)
                case .SEI: setStatus(.I)
              // Clear status bits opcodes
                case .CLC: setStatus(.C, false)
                case .CLD: setStatus(.D, false)
                case .CLI: setStatus(.I, false)
                case .CLV: setStatus(.V, false)
              // Compare opcodes
                case .CMP: compare(accumulator, oc, ops)
                case .CPX: compare(registerX, oc, ops)
                case .CPY: compare(registerY, oc, ops)
              // Decrement registers opcodes
                case .DEC: alterMemory(getAddress(mode: oc.addressMode, ops: ops)) { (v: UInt8) in (v - 1) }
                case .DEX: testSZ(--registerX)
                case .DEY: testSZ(--registerY)
              // Increment registers opcodes
                case .INC: alterMemory(getAddress(mode: oc.addressMode, ops: ops)) { (v: UInt8) in (v + 1) }
                case .INX: testSZ(++registerX)
                case .INY: testSZ(++registerY)
              // Load registers opcodes
                case .LDA: accumulator = testSZ(readValue(mode: oc.addressMode, ops: ops))
                case .LDX: registerX = testSZ(readValue(mode: oc.addressMode, ops: ops))
                case .LDY: registerY = testSZ(readValue(mode: oc.addressMode, ops: ops))
              // Store registers opcodes
                case .STA: writeValue(value: accumulator, mode: oc.addressMode, ops: ops)
                case .STX: writeValue(value: registerX, mode: oc.addressMode, ops: ops)
                case .STY: writeValue(value: registerY, mode: oc.addressMode, ops: ops)
              // Stack opcodes
                case .PHA: push(byte: accumulator)
                case .PHP: push(byte: statusRegister)
                case .PLA: accumulator = testSZ(pop())
                case .PLP: statusRegister = pop()
              // Transfer opcodes
                case .TAX: registerX = testSZ(accumulator)
                case .TAY: registerY = testSZ(accumulator)
                case .TSX: registerX = testSZ(stackPointer)
                case .TXA: accumulator = testSZ(registerX)
                case .TXS: stackPointer = registerX
                case .TYA: accumulator = testSZ(registerY)
              // NOOP opcode
                case .NOP: break
              // Jump opcodes
                case .JMP: programCounter = getAddress(mode: oc.addressMode, ops: ops)
                case .JSR:
                    push(word: (programCounter - 1))
                    programCounter = getAddress(mode: oc.addressMode, ops: ops)
              // Break opcode
                case .BRK:
                    push(word: programCounter++)
                    push(byte: statusRegister | Mos6502Flags.B)
                    setStatus(.I)
                    programCounter = getIndirectAddress(UInt16(0xfffe))
              // Test status bits opcode
                case .BIT:
                    let v: UInt8 = readValue(mode: oc.addressMode, ops: ops)
                    setStatus(.Z, (v &? accumulator))
                    setStatus(.N, (v &! 0x80))
                    setStatus(.V, (v &! 0x40))
            }
        }
        else {
            handleError()
        }
    }
}
