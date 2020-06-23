/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: OpcodeData.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 6/3/20
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

public enum Mos6502Flags: UInt8, CustomStringConvertible {
    case N = 1
    case V = 2
    case X = 4
    case B = 8
    case D = 16
    case I = 32
    case Z = 64
    case C = 128

    @inlinable public static func & <T: BinaryInteger>(lhs: T, rhs: Mos6502Flags) -> T { (lhs & T(rhs.rawValue)) }

    @inlinable public static func & <T: BinaryInteger>(lhs: Mos6502Flags, rhs: T) -> T { (T(lhs.rawValue) & rhs) }

    @inlinable public static func | <T: BinaryInteger>(lhs: T, rhs: Mos6502Flags) -> T { (lhs | T(rhs.rawValue)) }

    @inlinable public static func | <T: BinaryInteger>(lhs: Mos6502Flags, rhs: T) -> T { (T(lhs.rawValue) | rhs) }

    @inlinable public static prefix func ~ (oper: Mos6502Flags) -> UInt8 { (~oper.rawValue) }

    @inlinable public static func |= <T: BinaryInteger>(lhs: inout T, rhs: Mos6502Flags) { (lhs |= T(rhs.rawValue)) }

    @inlinable public static func &= <T: BinaryInteger>(lhs: inout T, rhs: Mos6502Flags) { (lhs &= T(rhs.rawValue)) }

    @inlinable public static func &! <T: BinaryInteger>(lhs: T, rhs: Mos6502Flags) -> Bool { let v: T = T(rhs.rawValue); return ((lhs & v) == v) }

    @inlinable public static func &! <T: BinaryInteger>(lhs: Mos6502Flags, rhs: T) -> Bool { let v: T = T(lhs.rawValue); return ((rhs & v) == v) }

    @inlinable public static func &? <T: BinaryInteger>(lhs: T, rhs: Mos6502Flags) -> Bool { let v: T = T(rhs.rawValue); return ((lhs & v) == 0) }

    @inlinable public static func &? <T: BinaryInteger>(lhs: Mos6502Flags, rhs: T) -> Bool { let v: T = T(lhs.rawValue); return ((rhs & v) == 0) }

    @inlinable public static func == <T: BinaryInteger>(lhs: T, rhs: Mos6502Flags) -> Bool { (lhs == rhs.rawValue) }

    @inlinable public static func == <T: BinaryInteger>(lhs: Mos6502Flags, rhs: T) -> Bool { (lhs.rawValue == rhs) }

    @inlinable public func foo(n: inout UInt8, f: Bool) { n = (f ? (n | self) : (n & ~self)) }

    public static func doSet(_ s: String) -> UInt8 {
        var f: UInt8 = 0
        for c: String.Element in s {
            switch c {
                case "N": f |= Mos6502Flags.N
                case "V": f |= Mos6502Flags.V
                case "B": f |= Mos6502Flags.B
                case "D": f |= Mos6502Flags.D
                case "I": f |= Mos6502Flags.I
                case "Z": f |= Mos6502Flags.Z
                case "C": f |= Mos6502Flags.C
                default: break
            }
        }
        return f
    }

    public var description: String {
        switch self {
            case .N: return "N"
            case .V: return "V"
            case .B: return "B"
            case .D: return "D"
            case .I: return "I"
            case .Z: return "Z"
            case .C: return "C"
            case .X: return "X"
        }
    }
}

public enum Mos6502AddressModes: UInt16, CustomStringConvertible {
    case ABS  = 0b0100000000
    case ABSX = 0b0000001100
    case ABSY = 0b0000011000
    case ACC  = 0b0000001010
    case IMM  = 0b1000000000
    case IMP  = 0b1100000000
    case IND  = 0b0000100000
    case INDX = 0b0000000001
    case INDY = 0b0000010001
    case REL  = 0b0000010000
    case ZP   = 0b0000000100
    case ZPX  = 0b0000010100
    case ZPY  = 0b0010010110

    public var bitMask:     UInt8 { UInt8(rawValue & 0xff) }
    public var description: String {
        switch self {
            case .ABS: return "Absolute"
            case .ABSX: return "Absolute,X"
            case .ABSY: return "Absolute,Y"
            case .ACC: return "Accumulator"
            case .IMM: return "Immediate"
            case .IMP: return "Implied"
            case .IND: return "Indirect"
            case .INDX: return "Indexed Indirect"
            case .INDY: return "Indirect Indexed"
            case .REL: return "Relative"
            case .ZP: return "Zero Page"
            case .ZPX: return "Zero Page,X"
            case .ZPY: return "Zero Page,Y"
        }
    }
}

public enum Mos6502Opcodes: UInt8, CustomStringConvertible {
    case ADC = 0b01100001
    case AND = 0b00100001
    case ASL = 0b00000010
    case BCC = 0b10010000
    case BCS = 0b10110000
    case BEQ = 0b11110000
    case BIT = 0b00100100
    case BMI = 0b00110000
    case BNE = 0b11010000
    case BPL = 0b00010000
    case BRK = 0b00000000
    case BVC = 0b01010000
    case BVS = 0b01110000
    case CLC = 0b00011000
    case CLD = 0b11011000
    case CLI = 0b01011000
    case CLV = 0b10111000
    case CMP = 0b11000001
    case CPX = 0b11100000
    case CPY = 0b11000000
    case DEC = 0b11000110
    case DEX = 0b11001010
    case DEY = 0b10001000
    case EOR = 0b01000001
    case INC = 0b11100110
    case INX = 0b11101000
    case INY = 0b11001000
    case JMP = 0b01001100
    case JSR = 0b00100000
    case LDA = 0b10100001
    case LDX = 0b10100010
    case LDY = 0b10100000
    case LSR = 0b01000010
    case NOP = 0b11101010
    case ORA = 0b00000001
    case PHA = 0b01001000
    case PHP = 0b00001000
    case PLA = 0b01101000
    case PLP = 0b00101000
    case ROL = 0b00100010
    case ROR = 0b01100010
    case RTI = 0b01000000
    case RTS = 0b01100000
    case SBC = 0b11100001
    case SEC = 0b00111000
    case SED = 0b11111000
    case SEI = 0b01111000
    case STA = 0b10000001
    case STX = 0b10000110
    case STY = 0b10000100
    case TAX = 0b10101010
    case TAY = 0b10101000
    case TSX = 0b10111010
    case TXA = 0b10001010
    case TXS = 0b10011010
    case TYA = 0b10011000

    public var bitMask:     UInt8 { rawValue }
    public var description: String { mnemonic }
    public var mnemonic:    String {
        switch self {
            case .ADC: return "ADC"
            case .AND: return "AND"
            case .ASL: return "ASL"
            case .BCC: return "BCC"
            case .BCS: return "BCS"
            case .BEQ: return "BEQ"
            case .BIT: return "BIT"
            case .BMI: return "BMI"
            case .BNE: return "BNE"
            case .BPL: return "BPL"
            case .BRK: return "BRK"
            case .BVC: return "BVC"
            case .BVS: return "BVS"
            case .CLC: return "CLC"
            case .CLD: return "CLD"
            case .CLI: return "CLI"
            case .CLV: return "CLV"
            case .CMP: return "CMP"
            case .CPX: return "CPX"
            case .CPY: return "CPY"
            case .DEC: return "DEC"
            case .DEX: return "DEX"
            case .DEY: return "DEY"
            case .EOR: return "EOR"
            case .INC: return "INC"
            case .INX: return "INX"
            case .INY: return "INY"
            case .JMP: return "JMP"
            case .JSR: return "JSR"
            case .LDA: return "LDA"
            case .LDX: return "LDX"
            case .LDY: return "LDY"
            case .LSR: return "LSR"
            case .NOP: return "NOP"
            case .ORA: return "ORA"
            case .PHA: return "PHA"
            case .PHP: return "PHP"
            case .PLA: return "PLA"
            case .PLP: return "PLP"
            case .ROL: return "ROL"
            case .ROR: return "ROR"
            case .RTI: return "RTI"
            case .RTS: return "RTS"
            case .SBC: return "SBC"
            case .SEC: return "SEC"
            case .SED: return "SED"
            case .SEI: return "SEI"
            case .STA: return "STA"
            case .STX: return "STX"
            case .STY: return "STY"
            case .TAX: return "TAX"
            case .TAY: return "TAY"
            case .TSX: return "TSX"
            case .TXA: return "TXA"
            case .TXS: return "TXS"
            case .TYA: return "TYA"
        }
    }
}

public class Mos6502OpcodeInfo: Equatable {

    public let opcode:      UInt8
    public let mnemonic:    Mos6502Opcodes
    public let addressMode: Mos6502AddressModes
    public let bytes:       UInt8
    public let cycles:      UInt8
    public let plus1:       Bool

    @inlinable public var negativeFlag: Bool { (_flags &! Mos6502Flags.N) }
    @inlinable public var overflowFlag: Bool { (_flags &! Mos6502Flags.V) }
    @inlinable public var breakFlag:    Bool { (_flags &! Mos6502Flags.B) }
    @inlinable public var decimalFlag:  Bool { (_flags &! Mos6502Flags.D) }
    @inlinable public var irqFlag:      Bool { (_flags &! Mos6502Flags.I) }
    @inlinable public var zeroFlag:     Bool { (_flags &! Mos6502Flags.Z) }
    @inlinable public var carryFlag:    Bool { (_flags &! Mos6502Flags.C) }

    @usableFromInline let _flags: UInt8

    @inlinable public static func == (lhs: Mos6502OpcodeInfo, rhs: Mos6502OpcodeInfo) -> Bool { lhs.opcode == rhs.opcode }

    public init(opcode: UInt8, mnemonic: Mos6502Opcodes, addressMode: Mos6502AddressModes, bytes: UInt8, cycles: UInt8, plus1: Bool = false, flags: String = "-------") {
        self.opcode = opcode
        self.mnemonic = mnemonic
        self.addressMode = addressMode
        self.bytes = bytes
        self.cycles = cycles
        self.plus1 = plus1
        self._flags = Mos6502Flags.doSet(flags)
    }
}

public let MOS6502_OPCODES: [UInt8: Mos6502OpcodeInfo] = [
    0x69: Mos6502OpcodeInfo(opcode: 0x69, mnemonic: .ADC, addressMode: .IMM, bytes: 2, cycles: 2, flags: "NV---ZC"),
    0x65: Mos6502OpcodeInfo(opcode: 0x65, mnemonic: .ADC, addressMode: .ZP, bytes: 2, cycles: 3, flags: "NV---ZC"),
    0x75: Mos6502OpcodeInfo(opcode: 0x75, mnemonic: .ADC, addressMode: .ZPX, bytes: 2, cycles: 4, flags: "NV---ZC"),
    0x6d: Mos6502OpcodeInfo(opcode: 0x6d, mnemonic: .ADC, addressMode: .ABS, bytes: 3, cycles: 4, flags: "NV---ZC"),
    0x7d: Mos6502OpcodeInfo(opcode: 0x7d, mnemonic: .ADC, addressMode: .ABSX, bytes: 3, cycles: 4, flags: "NV---ZC"),
    0x79: Mos6502OpcodeInfo(opcode: 0x79, mnemonic: .ADC, addressMode: .ABSY, bytes: 3, cycles: 4, flags: "NV---ZC"),
    0x61: Mos6502OpcodeInfo(opcode: 0x61, mnemonic: .ADC, addressMode: .INDX, bytes: 2, cycles: 6, flags: "NV---ZC"),
    0x71: Mos6502OpcodeInfo(opcode: 0x71, mnemonic: .ADC, addressMode: .INDY, bytes: 2, cycles: 5, flags: "NV---ZC"),
    0x29: Mos6502OpcodeInfo(opcode: 0x29, mnemonic: .AND, addressMode: .IMM, bytes: 2, cycles: 2, flags: "N----Z-"),
    0x25: Mos6502OpcodeInfo(opcode: 0x25, mnemonic: .AND, addressMode: .ZP, bytes: 2, cycles: 3, flags: "N----Z-"),
    0x35: Mos6502OpcodeInfo(opcode: 0x35, mnemonic: .AND, addressMode: .ZPX, bytes: 2, cycles: 4, flags: "N----Z-"),
    0x2d: Mos6502OpcodeInfo(opcode: 0x2d, mnemonic: .AND, addressMode: .ABS, bytes: 3, cycles: 4, flags: "N----Z-"),
    0x3d: Mos6502OpcodeInfo(opcode: 0x3d, mnemonic: .AND, addressMode: .ABSX, bytes: 3, cycles: 4, flags: "N----Z-"),
    0x39: Mos6502OpcodeInfo(opcode: 0x39, mnemonic: .AND, addressMode: .ABSY, bytes: 3, cycles: 4, flags: "N----Z-"),
    0x21: Mos6502OpcodeInfo(opcode: 0x21, mnemonic: .AND, addressMode: .INDX, bytes: 2, cycles: 6, flags: "N----Z-"),
    0x31: Mos6502OpcodeInfo(opcode: 0x31, mnemonic: .AND, addressMode: .INDY, bytes: 2, cycles: 5, flags: "N----Z-"),
    0x0a: Mos6502OpcodeInfo(opcode: 0x0a, mnemonic: .ASL, addressMode: .ACC, bytes: 1, cycles: 2, flags: "N----ZC"),
    0x06: Mos6502OpcodeInfo(opcode: 0x06, mnemonic: .ASL, addressMode: .ZP, bytes: 2, cycles: 5, flags: "N----ZC"),
    0x16: Mos6502OpcodeInfo(opcode: 0x16, mnemonic: .ASL, addressMode: .ZPX, bytes: 2, cycles: 6, flags: "N----ZC"),
    0x0e: Mos6502OpcodeInfo(opcode: 0x0e, mnemonic: .ASL, addressMode: .ABS, bytes: 3, cycles: 6, flags: "N----ZC"),
    0x1e: Mos6502OpcodeInfo(opcode: 0x1e, mnemonic: .ASL, addressMode: .ABSX, bytes: 3, cycles: 7, flags: "N----ZC"),
    0x90: Mos6502OpcodeInfo(opcode: 0x90, mnemonic: .BCC, addressMode: .REL, bytes: 2, cycles: 2, plus1: true),
    0xb0: Mos6502OpcodeInfo(opcode: 0xb0, mnemonic: .BCS, addressMode: .REL, bytes: 2, cycles: 2, plus1: true),
    0xf0: Mos6502OpcodeInfo(opcode: 0xf0, mnemonic: .BEQ, addressMode: .REL, bytes: 2, cycles: 2, plus1: true),
    0x30: Mos6502OpcodeInfo(opcode: 0x30, mnemonic: .BMI, addressMode: .REL, bytes: 2, cycles: 2, plus1: true),
    0xd0: Mos6502OpcodeInfo(opcode: 0xd0, mnemonic: .BNE, addressMode: .REL, bytes: 2, cycles: 2, plus1: true),
    0x10: Mos6502OpcodeInfo(opcode: 0x10, mnemonic: .BPL, addressMode: .REL, bytes: 2, cycles: 2, plus1: true),
    0x50: Mos6502OpcodeInfo(opcode: 0x50, mnemonic: .BVC, addressMode: .REL, bytes: 2, cycles: 2, plus1: true),
    0x70: Mos6502OpcodeInfo(opcode: 0x70, mnemonic: .BVS, addressMode: .REL, bytes: 2, cycles: 2, plus1: true),
    0x24: Mos6502OpcodeInfo(opcode: 0x24, mnemonic: .BIT, addressMode: .ZP, bytes: 2, cycles: 3, flags: "NV---Z-"),
    0x2c: Mos6502OpcodeInfo(opcode: 0x2c, mnemonic: .BIT, addressMode: .ABS, bytes: 3, cycles: 4, flags: "NV---Z-"),
    0x00: Mos6502OpcodeInfo(opcode: 0x00, mnemonic: .BRK, addressMode: .IMP, bytes: 1, cycles: 7),
    0x18: Mos6502OpcodeInfo(opcode: 0x18, mnemonic: .CLC, addressMode: .IMP, bytes: 1, cycles: 2, flags: "------C"),
    0xd8: Mos6502OpcodeInfo(opcode: 0xd8, mnemonic: .CLD, addressMode: .IMP, bytes: 1, cycles: 2, flags: "---D---"),
    0x58: Mos6502OpcodeInfo(opcode: 0x58, mnemonic: .CLI, addressMode: .IMP, bytes: 1, cycles: 2, flags: "----I--"),
    0xb8: Mos6502OpcodeInfo(opcode: 0xb8, mnemonic: .CLV, addressMode: .IMP, bytes: 1, cycles: 2, flags: "-V-----"),
    0xea: Mos6502OpcodeInfo(opcode: 0xea, mnemonic: .NOP, addressMode: .IMP, bytes: 1, cycles: 2),
    0x48: Mos6502OpcodeInfo(opcode: 0x48, mnemonic: .PHA, addressMode: .IMP, bytes: 1, cycles: 3),
    0x68: Mos6502OpcodeInfo(opcode: 0x68, mnemonic: .PLA, addressMode: .IMP, bytes: 1, cycles: 4, flags: "N----Z-"),
    0x08: Mos6502OpcodeInfo(opcode: 0x08, mnemonic: .PHP, addressMode: .IMP, bytes: 1, cycles: 3),
    0x28: Mos6502OpcodeInfo(opcode: 0x28, mnemonic: .PLP, addressMode: .IMP, bytes: 1, cycles: 4, flags: "NVBDIZC"),
    0x40: Mos6502OpcodeInfo(opcode: 0x40, mnemonic: .RTI, addressMode: .IMP, bytes: 1, cycles: 6),
    0x60: Mos6502OpcodeInfo(opcode: 0x60, mnemonic: .RTS, addressMode: .IMP, bytes: 1, cycles: 6),
    0x38: Mos6502OpcodeInfo(opcode: 0x38, mnemonic: .SEC, addressMode: .IMP, bytes: 1, cycles: 2, flags: "------C"),
    0xf8: Mos6502OpcodeInfo(opcode: 0xf8, mnemonic: .SED, addressMode: .IMP, bytes: 1, cycles: 2, flags: "---D---"),
    0x78: Mos6502OpcodeInfo(opcode: 0x78, mnemonic: .SEI, addressMode: .IMP, bytes: 1, cycles: 2, flags: "----I--"),
    0xaa: Mos6502OpcodeInfo(opcode: 0xaa, mnemonic: .TAX, addressMode: .IMP, bytes: 1, cycles: 2, flags: "N----Z-"),
    0x8a: Mos6502OpcodeInfo(opcode: 0x8a, mnemonic: .TXA, addressMode: .IMP, bytes: 1, cycles: 2, flags: "N----Z-"),
    0xa8: Mos6502OpcodeInfo(opcode: 0xa8, mnemonic: .TAY, addressMode: .IMP, bytes: 1, cycles: 2, flags: "N----Z-"),
    0x98: Mos6502OpcodeInfo(opcode: 0x98, mnemonic: .TYA, addressMode: .IMP, bytes: 1, cycles: 2, flags: "N----Z-"),
    0xba: Mos6502OpcodeInfo(opcode: 0xba, mnemonic: .TSX, addressMode: .IMP, bytes: 1, cycles: 2, flags: "N----Z-"),
    0x9a: Mos6502OpcodeInfo(opcode: 0x9a, mnemonic: .TXS, addressMode: .IMP, bytes: 1, cycles: 2),
    0xc9: Mos6502OpcodeInfo(opcode: 0xc9, mnemonic: .CMP, addressMode: .IMM, bytes: 2, cycles: 2, flags: "N----ZC"),
    0xc5: Mos6502OpcodeInfo(opcode: 0xc5, mnemonic: .CMP, addressMode: .ZP, bytes: 2, cycles: 3, flags: "N----ZC"),
    0xd5: Mos6502OpcodeInfo(opcode: 0xd5, mnemonic: .CMP, addressMode: .ZPX, bytes: 2, cycles: 4, flags: "N----ZC"),
    0xcd: Mos6502OpcodeInfo(opcode: 0xcd, mnemonic: .CMP, addressMode: .ABS, bytes: 3, cycles: 4, flags: "N----ZC"),
    0xdd: Mos6502OpcodeInfo(opcode: 0xdd, mnemonic: .CMP, addressMode: .ABSX, bytes: 3, cycles: 4, flags: "N----ZC"),
    0xd9: Mos6502OpcodeInfo(opcode: 0xd9, mnemonic: .CMP, addressMode: .ABSY, bytes: 3, cycles: 4, flags: "N----ZC"),
    0xc1: Mos6502OpcodeInfo(opcode: 0xc1, mnemonic: .CMP, addressMode: .INDX, bytes: 2, cycles: 6, flags: "N----ZC"),
    0xd1: Mos6502OpcodeInfo(opcode: 0xd1, mnemonic: .CMP, addressMode: .INDY, bytes: 2, cycles: 5, flags: "N----ZC"),
    0xe0: Mos6502OpcodeInfo(opcode: 0xe0, mnemonic: .CPX, addressMode: .IMM, bytes: 2, cycles: 2, flags: "N----ZC"),
    0xe4: Mos6502OpcodeInfo(opcode: 0xe4, mnemonic: .CPX, addressMode: .ZP, bytes: 2, cycles: 3, flags: "N----ZC"),
    0xec: Mos6502OpcodeInfo(opcode: 0xec, mnemonic: .CPX, addressMode: .ABS, bytes: 3, cycles: 4, flags: "N----ZC"),
    0xc0: Mos6502OpcodeInfo(opcode: 0xc0, mnemonic: .CPY, addressMode: .IMM, bytes: 2, cycles: 2, flags: "N----ZC"),
    0xc4: Mos6502OpcodeInfo(opcode: 0xc4, mnemonic: .CPY, addressMode: .ZP, bytes: 2, cycles: 3, flags: "N----ZC"),
    0xcc: Mos6502OpcodeInfo(opcode: 0xcc, mnemonic: .CPY, addressMode: .ABS, bytes: 3, cycles: 4, flags: "N----ZC"),
    0xc6: Mos6502OpcodeInfo(opcode: 0xc6, mnemonic: .DEC, addressMode: .ZP, bytes: 2, cycles: 5, flags: "N----Z-"),
    0xd6: Mos6502OpcodeInfo(opcode: 0xd6, mnemonic: .DEC, addressMode: .ZPX, bytes: 2, cycles: 6, flags: "N----Z-"),
    0xce: Mos6502OpcodeInfo(opcode: 0xce, mnemonic: .DEC, addressMode: .ABS, bytes: 3, cycles: 6, flags: "N----Z-"),
    0xde: Mos6502OpcodeInfo(opcode: 0xde, mnemonic: .DEC, addressMode: .ABSX, bytes: 3, cycles: 7, flags: "N----Z-"),
    0xca: Mos6502OpcodeInfo(opcode: 0xca, mnemonic: .DEX, addressMode: .IMP, bytes: 1, cycles: 2, flags: "N----Z-"),
    0x88: Mos6502OpcodeInfo(opcode: 0x88, mnemonic: .DEY, addressMode: .IMP, bytes: 1, cycles: 2, flags: "N----Z-"),
    0xe8: Mos6502OpcodeInfo(opcode: 0xe8, mnemonic: .INX, addressMode: .IMP, bytes: 1, cycles: 2, flags: "N----Z-"),
    0xc8: Mos6502OpcodeInfo(opcode: 0xc8, mnemonic: .INY, addressMode: .IMP, bytes: 1, cycles: 2, flags: "N----Z-"),
    0x49: Mos6502OpcodeInfo(opcode: 0x49, mnemonic: .EOR, addressMode: .IMM, bytes: 2, cycles: 2, flags: "N----Z-"),
    0x45: Mos6502OpcodeInfo(opcode: 0x45, mnemonic: .EOR, addressMode: .ZP, bytes: 2, cycles: 3, flags: "N----Z-"),
    0x55: Mos6502OpcodeInfo(opcode: 0x55, mnemonic: .EOR, addressMode: .ZPX, bytes: 2, cycles: 4, flags: "N----Z-"),
    0x4d: Mos6502OpcodeInfo(opcode: 0x4d, mnemonic: .EOR, addressMode: .ABS, bytes: 3, cycles: 4, flags: "N----Z-"),
    0x5d: Mos6502OpcodeInfo(opcode: 0x5d, mnemonic: .EOR, addressMode: .ABSX, bytes: 3, cycles: 4, flags: "N----Z-"),
    0x59: Mos6502OpcodeInfo(opcode: 0x59, mnemonic: .EOR, addressMode: .ABSY, bytes: 3, cycles: 4, flags: "N----Z-"),
    0x41: Mos6502OpcodeInfo(opcode: 0x41, mnemonic: .EOR, addressMode: .INDX, bytes: 2, cycles: 6, flags: "N----Z-"),
    0x51: Mos6502OpcodeInfo(opcode: 0x51, mnemonic: .EOR, addressMode: .INDY, bytes: 2, cycles: 5, flags: "N----Z-"),
    0xe6: Mos6502OpcodeInfo(opcode: 0xe6, mnemonic: .INC, addressMode: .ZP, bytes: 2, cycles: 5, flags: "N----Z-"),
    0xf6: Mos6502OpcodeInfo(opcode: 0xf6, mnemonic: .INC, addressMode: .ZPX, bytes: 2, cycles: 6, flags: "N----Z-"),
    0xee: Mos6502OpcodeInfo(opcode: 0xee, mnemonic: .INC, addressMode: .ABS, bytes: 3, cycles: 6, flags: "N----Z-"),
    0xfe: Mos6502OpcodeInfo(opcode: 0xfe, mnemonic: .INC, addressMode: .ABSX, bytes: 3, cycles: 7, flags: "N----Z-"),
    0x4c: Mos6502OpcodeInfo(opcode: 0x4c, mnemonic: .JMP, addressMode: .ABS, bytes: 3, cycles: 3),
    0x6c: Mos6502OpcodeInfo(opcode: 0x6c, mnemonic: .JMP, addressMode: .IND, bytes: 3, cycles: 5),
    0x20: Mos6502OpcodeInfo(opcode: 0x20, mnemonic: .JSR, addressMode: .ABS, bytes: 3, cycles: 6),
    0xa9: Mos6502OpcodeInfo(opcode: 0xa9, mnemonic: .LDA, addressMode: .IMM, bytes: 2, cycles: 2, flags: "N----Z-"),
    0xa5: Mos6502OpcodeInfo(opcode: 0xa5, mnemonic: .LDA, addressMode: .ZP, bytes: 2, cycles: 3, flags: "N----Z-"),
    0xb5: Mos6502OpcodeInfo(opcode: 0xb5, mnemonic: .LDA, addressMode: .ZPX, bytes: 2, cycles: 4, flags: "N----Z-"),
    0xad: Mos6502OpcodeInfo(opcode: 0xad, mnemonic: .LDA, addressMode: .ABS, bytes: 3, cycles: 4, flags: "N----Z-"),
    0xbd: Mos6502OpcodeInfo(opcode: 0xbd, mnemonic: .LDA, addressMode: .ABSX, bytes: 3, cycles: 4, flags: "N----Z-"),
    0xb9: Mos6502OpcodeInfo(opcode: 0xb9, mnemonic: .LDA, addressMode: .ABSY, bytes: 3, cycles: 4, flags: "N----Z-"),
    0xa1: Mos6502OpcodeInfo(opcode: 0xa1, mnemonic: .LDA, addressMode: .INDX, bytes: 2, cycles: 6, flags: "N----Z-"),
    0xb1: Mos6502OpcodeInfo(opcode: 0xb1, mnemonic: .LDA, addressMode: .INDY, bytes: 2, cycles: 5, flags: "N----Z-"),
    0xa2: Mos6502OpcodeInfo(opcode: 0xa2, mnemonic: .LDX, addressMode: .IMM, bytes: 2, cycles: 2, flags: "N----Z-"),
    0xa6: Mos6502OpcodeInfo(opcode: 0xa6, mnemonic: .LDX, addressMode: .ZP, bytes: 2, cycles: 3, flags: "N----Z-"),
    0xb6: Mos6502OpcodeInfo(opcode: 0xb6, mnemonic: .LDX, addressMode: .ZPY, bytes: 2, cycles: 4, flags: "N----Z-"),
    0xae: Mos6502OpcodeInfo(opcode: 0xae, mnemonic: .LDX, addressMode: .ABS, bytes: 3, cycles: 4, flags: "N----Z-"),
    0xbe: Mos6502OpcodeInfo(opcode: 0xbe, mnemonic: .LDX, addressMode: .ABSY, bytes: 3, cycles: 4, flags: "N----Z-"),
    0xa0: Mos6502OpcodeInfo(opcode: 0xa0, mnemonic: .LDY, addressMode: .IMM, bytes: 2, cycles: 2, flags: "N----Z-"),
    0xa4: Mos6502OpcodeInfo(opcode: 0xa4, mnemonic: .LDY, addressMode: .ZP, bytes: 2, cycles: 3, flags: "N----Z-"),
    0xb4: Mos6502OpcodeInfo(opcode: 0xb4, mnemonic: .LDY, addressMode: .ZPX, bytes: 2, cycles: 4, flags: "N----Z-"),
    0xac: Mos6502OpcodeInfo(opcode: 0xac, mnemonic: .LDY, addressMode: .ABS, bytes: 3, cycles: 4, flags: "N----Z-"),
    0xbc: Mos6502OpcodeInfo(opcode: 0xbc, mnemonic: .LDY, addressMode: .ABSX, bytes: 3, cycles: 4, flags: "N----Z-"),
    0x4a: Mos6502OpcodeInfo(opcode: 0x4a, mnemonic: .LSR, addressMode: .ACC, bytes: 1, cycles: 2, flags: "N----ZC"),
    0x46: Mos6502OpcodeInfo(opcode: 0x46, mnemonic: .LSR, addressMode: .ZP, bytes: 2, cycles: 5, flags: "N----ZC"),
    0x56: Mos6502OpcodeInfo(opcode: 0x56, mnemonic: .LSR, addressMode: .ZPX, bytes: 2, cycles: 6, flags: "N----ZC"),
    0x4e: Mos6502OpcodeInfo(opcode: 0x4e, mnemonic: .LSR, addressMode: .ABS, bytes: 3, cycles: 6, flags: "N----ZC"),
    0x5e: Mos6502OpcodeInfo(opcode: 0x5e, mnemonic: .LSR, addressMode: .ABSX, bytes: 3, cycles: 7, flags: "N----ZC"),
    0x09: Mos6502OpcodeInfo(opcode: 0x09, mnemonic: .ORA, addressMode: .IMM, bytes: 2, cycles: 2, flags: "N----Z-"),
    0x05: Mos6502OpcodeInfo(opcode: 0x05, mnemonic: .ORA, addressMode: .ZP, bytes: 2, cycles: 3, flags: "N----Z-"),
    0x15: Mos6502OpcodeInfo(opcode: 0x15, mnemonic: .ORA, addressMode: .ZPX, bytes: 2, cycles: 4, flags: "N----Z-"),
    0x0d: Mos6502OpcodeInfo(opcode: 0x0d, mnemonic: .ORA, addressMode: .ABS, bytes: 3, cycles: 4, flags: "N----Z-"),
    0x1d: Mos6502OpcodeInfo(opcode: 0x1d, mnemonic: .ORA, addressMode: .ABSX, bytes: 3, cycles: 4, flags: "N----Z-"),
    0x19: Mos6502OpcodeInfo(opcode: 0x19, mnemonic: .ORA, addressMode: .ABSY, bytes: 3, cycles: 4, flags: "N----Z-"),
    0x01: Mos6502OpcodeInfo(opcode: 0x01, mnemonic: .ORA, addressMode: .INDX, bytes: 2, cycles: 6, flags: "N----Z-"),
    0x11: Mos6502OpcodeInfo(opcode: 0x11, mnemonic: .ORA, addressMode: .INDY, bytes: 2, cycles: 5, flags: "N----Z-"),
    0x2a: Mos6502OpcodeInfo(opcode: 0x2a, mnemonic: .ROL, addressMode: .ACC, bytes: 1, cycles: 2, flags: "N----ZC"),
    0x26: Mos6502OpcodeInfo(opcode: 0x26, mnemonic: .ROL, addressMode: .ZP, bytes: 2, cycles: 5, flags: "N----ZC"),
    0x36: Mos6502OpcodeInfo(opcode: 0x36, mnemonic: .ROL, addressMode: .ZPX, bytes: 2, cycles: 6, flags: "N----ZC"),
    0x2e: Mos6502OpcodeInfo(opcode: 0x2e, mnemonic: .ROL, addressMode: .ABS, bytes: 3, cycles: 6, flags: "N----ZC"),
    0x3e: Mos6502OpcodeInfo(opcode: 0x3e, mnemonic: .ROL, addressMode: .ABSX, bytes: 3, cycles: 7, flags: "N----ZC"),
    0x6a: Mos6502OpcodeInfo(opcode: 0x6a, mnemonic: .ROR, addressMode: .ACC, bytes: 1, cycles: 2, flags: "N----ZC"),
    0x66: Mos6502OpcodeInfo(opcode: 0x66, mnemonic: .ROR, addressMode: .ZP, bytes: 2, cycles: 5, flags: "N----ZC"),
    0x76: Mos6502OpcodeInfo(opcode: 0x76, mnemonic: .ROR, addressMode: .ZPX, bytes: 2, cycles: 6, flags: "N----ZC"),
    0x7e: Mos6502OpcodeInfo(opcode: 0x7e, mnemonic: .ROR, addressMode: .ABS, bytes: 3, cycles: 6, flags: "N----ZC"),
    0x6e: Mos6502OpcodeInfo(opcode: 0x6e, mnemonic: .ROR, addressMode: .ABSX, bytes: 3, cycles: 7, flags: "N----ZC"),
    0xe9: Mos6502OpcodeInfo(opcode: 0xe9, mnemonic: .SBC, addressMode: .IMM, bytes: 2, cycles: 2, flags: "NV---ZC"),
    0xe5: Mos6502OpcodeInfo(opcode: 0xe5, mnemonic: .SBC, addressMode: .ZP, bytes: 2, cycles: 3, flags: "NV---ZC"),
    0xf5: Mos6502OpcodeInfo(opcode: 0xf5, mnemonic: .SBC, addressMode: .ZPX, bytes: 2, cycles: 4, flags: "NV---ZC"),
    0xed: Mos6502OpcodeInfo(opcode: 0xed, mnemonic: .SBC, addressMode: .ABS, bytes: 3, cycles: 4, flags: "NV---ZC"),
    0xfd: Mos6502OpcodeInfo(opcode: 0xfd, mnemonic: .SBC, addressMode: .ABSX, bytes: 3, cycles: 4, flags: "NV---ZC"),
    0xf9: Mos6502OpcodeInfo(opcode: 0xf9, mnemonic: .SBC, addressMode: .ABSY, bytes: 3, cycles: 4, flags: "NV---ZC"),
    0xe1: Mos6502OpcodeInfo(opcode: 0xe1, mnemonic: .SBC, addressMode: .INDX, bytes: 2, cycles: 6, flags: "NV---ZC"),
    0xf1: Mos6502OpcodeInfo(opcode: 0xf1, mnemonic: .SBC, addressMode: .INDY, bytes: 2, cycles: 5, flags: "NV---ZC"),
    0x85: Mos6502OpcodeInfo(opcode: 0x85, mnemonic: .STA, addressMode: .ZP, bytes: 2, cycles: 3),
    0x95: Mos6502OpcodeInfo(opcode: 0x95, mnemonic: .STA, addressMode: .ZPX, bytes: 2, cycles: 4),
    0x8d: Mos6502OpcodeInfo(opcode: 0x8d, mnemonic: .STA, addressMode: .ABS, bytes: 3, cycles: 4),
    0x9d: Mos6502OpcodeInfo(opcode: 0x9d, mnemonic: .STA, addressMode: .ABSX, bytes: 3, cycles: 5),
    0x99: Mos6502OpcodeInfo(opcode: 0x99, mnemonic: .STA, addressMode: .ABSY, bytes: 3, cycles: 5),
    0x81: Mos6502OpcodeInfo(opcode: 0x81, mnemonic: .STA, addressMode: .INDX, bytes: 2, cycles: 6),
    0x91: Mos6502OpcodeInfo(opcode: 0x91, mnemonic: .STA, addressMode: .INDY, bytes: 2, cycles: 6),
    0x86: Mos6502OpcodeInfo(opcode: 0x86, mnemonic: .STX, addressMode: .ZP, bytes: 2, cycles: 3),
    0x96: Mos6502OpcodeInfo(opcode: 0x96, mnemonic: .STX, addressMode: .ZPY, bytes: 2, cycles: 4),
    0x8e: Mos6502OpcodeInfo(opcode: 0x8e, mnemonic: .STX, addressMode: .ABS, bytes: 3, cycles: 4),
    0x84: Mos6502OpcodeInfo(opcode: 0x84, mnemonic: .STY, addressMode: .ZP, bytes: 2, cycles: 3),
    0x94: Mos6502OpcodeInfo(opcode: 0x94, mnemonic: .STY, addressMode: .ZPX, bytes: 2, cycles: 4),
    0x8c: Mos6502OpcodeInfo(opcode: 0x8c, mnemonic: .STY, addressMode: .ABS, bytes: 3, cycles: 4),
]
