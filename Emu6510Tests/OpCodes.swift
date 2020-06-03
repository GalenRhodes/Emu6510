/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: OpCodes.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 6/1/20
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

let ADDRESS_MODES: [String: String] = [
    "ABS": "Absolute",
    "ABSX": "Absolute,X",
    "ABSY": "Absolute,Y",
    "ACC": "Accumulator",
    "IMM": "Immediate",
    "IMP": "Implied",
    "INDX": "Indexed Indirect",
    "INDY": "Indirect Indexed",
    "REL": "Relative",
    "ZP": "Zero Page",
    "ZPX": "Zero Page,X",
    "ZPY": "Zero Page,Y",
]

let BASICOPCODES: [String] = [
    "ADC",
    "AND",
    "ASL",
    "BCC",
    "BCS",
    "BEQ",
    "BIT",
    "BMI",
    "BNE",
    "BPL",
    "BRK",
    "BVC",
    "BVS",
    "CLC",
    "CLD",
    "CLI",
    "CLV",
    "CMP",
    "CPX",
    "CPY",
    "DEC",
    "DEX",
    "DEY",
    "EOR",
    "INC",
    "INX",
    "INY",
    "JMP",
    "JSR",
    "LDA",
    "LDX",
    "LDY",
    "LSR",
    "NOP",
    "ORA",
    "PHA",
    "PHP",
    "PLA",
    "PLP",
    "ROL",
    "ROR",
    "RTI",
    "RTS",
    "SBC",
    "SEC",
    "SED",
    "SEI",
    "STA",
    "STX",
    "STY",
    "TAX",
    "TAY",
    "TSX",
    "TXA",
    "TXS",
    "TYA",
]

public enum OpcodeEnum: UInt8 {
    case ADC_IMM  = 0x69
    case ADC_ZP   = 0x65
    case ADC_ZPX  = 0x75
    case ADC_ABS  = 0x6d
    case ADC_ABSX = 0x7d
    case ADC_ABSY = 0x79
    case ADC_INDX = 0x61
    case ADC_INDY = 0x71
    case AND_IMM  = 0x29
    case AND_ZP   = 0x25
    case AND_ZPX  = 0x35
    case AND_ABS  = 0x2d
    case AND_ABSX = 0x3d
    case AND_ABSY = 0x39
    case AND_INDX = 0x21
    case AND_INDY = 0x31
    case ASL_ACC  = 0x0a
    case ASL_ZP   = 0x06
    case ASL_ZPX  = 0x16
    case ASL_ABS  = 0x0e
    case ASL_ABSX = 0x1e
    case BCC_REL  = 0x90
    case BCS_REL  = 0xb0
    case BEQ_REL  = 0xf0
    case BMI_REL  = 0x30
    case BNE_REL  = 0xd0
    case BPL_REL  = 0x10
    case BVC_REL  = 0x50
    case BVS_REL  = 0x70
    case BIT_ZP   = 0x24
    case BIT_ABS  = 0x2c
    case BRK_IMP  = 0x00
    case CLC_IMP  = 0x18
    case CLD_IMP  = 0xd8
    case CLI_IMP  = 0x58
    case CLV_IMP  = 0xb8
    case NOP_IMP  = 0xea
    case PHA_IMP  = 0x48
    case PLA_IMP  = 0x68
    case PHP_IMP  = 0x08
    case PLP_IMP  = 0x28
    case RTI_IMP  = 0x40
    case RTS_IMP  = 0x60
    case SEC_IMP  = 0x38
    case SED_IMP  = 0xf8
    case SEI_IMP  = 0x78
    case TAX_IMP  = 0xaa
    case TXA_IMP  = 0x8a
    case TAY_IMP  = 0xa8
    case TYA_IMP  = 0x98
    case TSX_IMP  = 0xba
    case TXS_IMP  = 0x9a
    case CMP_IMM  = 0xc9
    case CMP_ZP   = 0xc5
    case CMP_ZPX  = 0xd5
    case CMP_ABS  = 0xcd
    case CMP_ABSX = 0xdd
    case CMP_ABSY = 0xd9
    case CMP_INDX = 0xc1
    case CMP_INDY = 0xd1
    case CPX_IMM  = 0xe0
    case CPX_ZP   = 0xe4
    case CPX_ABS  = 0xec
    case CPY_IMM  = 0xc0
    case CPY_ZP   = 0xc4
    case CPY_ABS  = 0xcc
    case DEC_ZP   = 0xc6
    case DEC_ZPX  = 0xd6
    case DEC_ABS  = 0xce
    case DEC_ABSX = 0xde
    case DEX_IMP  = 0xca
    case DEY_IMP  = 0x88
    case INX_IMP  = 0xe8
    case INY_IMP  = 0xc8
    case EOR_IMM  = 0x49
    case EOR_ZP   = 0x45
    case EOR_ZPX  = 0x55
    case EOR_ABS  = 0x4d
    case EOR_ABSX = 0x5d
    case EOR_ABSY = 0x59
    case EOR_INDX = 0x41
    case EOR_INDY = 0x51
    case INC_ZP   = 0xe6
    case INC_ZPX  = 0xf6
    case INC_ABS  = 0xee
    case INC_ABSX = 0xfe
    case JMP_ABS  = 0x4c
    case JMP_IND  = 0x6c
    case JSR_ABS  = 0x20
    case LDA_IMM  = 0xa9
    case LDA_ZP   = 0xa5
    case LDA_ZPX  = 0xb5
    case LDA_ABS  = 0xad
    case LDA_ABSX = 0xbd
    case LDA_ABSY = 0xb9
    case LDA_INDX = 0xa1
    case LDA_INDY = 0xb1
    case LDX_IMM  = 0xa2
    case LDX_ZP   = 0xa6
    case LDX_ZPY  = 0xb6
    case LDX_ABS  = 0xae
    case LDX_ABSY = 0xbe
    case LDY_IMM  = 0xa0
    case LDY_ZP   = 0xa4
    case LDY_ZPX  = 0xb4
    case LDY_ABS  = 0xac
    case LDY_ABSX = 0xbc
    case LSR_ACC  = 0x4a
    case LSR_ZP   = 0x46
    case LSR_ZPX  = 0x56
    case LSR_ABS  = 0x4e
    case LSR_ABSX = 0x5e
    case ORA_IMM  = 0x09
    case ORA_ZP   = 0x05
    case ORA_ZPX  = 0x15
    case ORA_ABS  = 0x0d
    case ORA_ABSX = 0x1d
    case ORA_ABSY = 0x19
    case ORA_INDX = 0x01
    case ORA_INDY = 0x11
    case ROL_ACC  = 0x2a
    case ROL_ZP   = 0x26
    case ROL_ZPX  = 0x36
    case ROL_ABS  = 0x2e
    case ROL_ABSX = 0x3e
    case ROR_ACC  = 0x6a
    case ROR_ZP   = 0x66
    case ROR_ZPX  = 0x76
    case ROR_ABS  = 0x7e
    case ROR_ABSX = 0x6e
    case SBC_IMM  = 0xe9
    case SBC_ZP   = 0xe5
    case SBC_ZPX  = 0xf5
    case SBC_ABS  = 0xed
    case SBC_ABSX = 0xfd
    case SBC_ABSY = 0xf9
    case SBC_INDX = 0xe1
    case SBC_INDY = 0xf1
    case STA_ZP   = 0x85
    case STA_ZPX  = 0x95
    case STA_ABS  = 0x8d
    case STA_ABSX = 0x9d
    case STA_ABSY = 0x99
    case STA_INDX = 0x81
    case STA_INDY = 0x91
    case STX_ZP   = 0x86
    case STX_ZPY  = 0x96
    case STX_ABS  = 0x8e
    case STY_ZP   = 0x84
    case STY_ZPX  = 0x94
    case STY_ABS  = 0x8c
}

func getMax() -> Int {
    var m: Int = 0
    for (_, value) in ADDRESS_MODES { m = max(m, value.count) }
    return m
}

let MAXW: Int = (getMax() + 2)

final class OpcodeData {
    public let opcodeEnum:  OpcodeEnum
    public let instruction: String
    public let addressMode: String
    public let bytes:       UInt8
    public let cycles:      UInt8
    public let plus1:       Bool

    public var negativeFlag: Bool { ((flags & 1) == 1) }
    public var overflowFlag: Bool { ((flags & 2) == 2) }
    public var breakFlag:    Bool { ((flags & 8) == 8) }
    public var decimalFlag:  Bool { ((flags & 16) == 16) }
    public var irqFlag:      Bool { ((flags & 32) == 32) }
    public var zeroFlag:     Bool { ((flags & 64) == 64) }
    public var carryFlag:    Bool { ((flags & 128) == 128) }

    public var strFlags:        String { f(negativeFlag, "N") + f(overflowFlag, "V") + f(breakFlag, "B") + f(decimalFlag, "D") + f(irqFlag, "I") + f(zeroFlag, "Z") + f(carryFlag, "C") }
    public var longAddressMode: String { (ADDRESS_MODES[addressMode] ?? addressMode) }
    public var opcode:          UInt8 { opcodeEnum.rawValue }

    private let flags: UInt8

    public convenience init(opcode: UInt8, instruction: String, addressMode: String, bytes: UInt8, cycles: UInt8, plus1: Bool = false, flags: String) {
        self.init(opcodeEnum: (OpcodeData.opcodeEnum(opcode) ?? .BRK_IMP), instruction: instruction, addressMode: addressMode, bytes: bytes, cycles: cycles, plus1: plus1, flags: flags)
    }

    public init(opcodeEnum: OpcodeEnum, instruction: String, addressMode: String, bytes: UInt8, cycles: UInt8, plus1: Bool = false, flags: String) {
        self.opcodeEnum = opcodeEnum
        self.instruction = instruction
        self.addressMode = addressMode
        self.bytes = bytes
        self.cycles = cycles
        self.plus1 = plus1

        var f: UInt8 = 0
        for ch: String.Element in flags {
            switch ch {
                case "N": f |= 1
                case "V": f |= 2
                case "B": f |= 8
                case "D": f |= 16
                case "I": f |= 32
                case "Z": f |= 64
                case "C": f |= 128
                default: break
            }
        }
        self.flags = f
    }

    public static func opcodeEnum(_ opcode: UInt8) -> OpcodeEnum? {
        switch opcode {
            case 0x69: return .ADC_IMM
            case 0x65: return .ADC_ZP
            case 0x75: return .ADC_ZPX
            case 0x6d: return .ADC_ABS
            case 0x7d: return .ADC_ABSX
            case 0x79: return .ADC_ABSY
            case 0x61: return .ADC_INDX
            case 0x71: return .ADC_INDY
            case 0x29: return .AND_IMM
            case 0x25: return .AND_ZP
            case 0x35: return .AND_ZPX
            case 0x2d: return .AND_ABS
            case 0x3d: return .AND_ABSX
            case 0x39: return .AND_ABSY
            case 0x21: return .AND_INDX
            case 0x31: return .AND_INDY
            case 0x0a: return .ASL_ACC
            case 0x06: return .ASL_ZP
            case 0x16: return .ASL_ZPX
            case 0x0e: return .ASL_ABS
            case 0x1e: return .ASL_ABSX
            case 0x90: return .BCC_REL
            case 0xb0: return .BCS_REL
            case 0xf0: return .BEQ_REL
            case 0x30: return .BMI_REL
            case 0xd0: return .BNE_REL
            case 0x10: return .BPL_REL
            case 0x50: return .BVC_REL
            case 0x70: return .BVS_REL
            case 0x24: return .BIT_ZP
            case 0x2c: return .BIT_ABS
            case 0x00: return .BRK_IMP
            case 0x18: return .CLC_IMP
            case 0xd8: return .CLD_IMP
            case 0x58: return .CLI_IMP
            case 0xb8: return .CLV_IMP
            case 0xea: return .NOP_IMP
            case 0x48: return .PHA_IMP
            case 0x68: return .PLA_IMP
            case 0x08: return .PHP_IMP
            case 0x28: return .PLP_IMP
            case 0x40: return .RTI_IMP
            case 0x60: return .RTS_IMP
            case 0x38: return .SEC_IMP
            case 0xf8: return .SED_IMP
            case 0x78: return .SEI_IMP
            case 0xaa: return .TAX_IMP
            case 0x8a: return .TXA_IMP
            case 0xa8: return .TAY_IMP
            case 0x98: return .TYA_IMP
            case 0xba: return .TSX_IMP
            case 0x9a: return .TXS_IMP
            case 0xc9: return .CMP_IMM
            case 0xc5: return .CMP_ZP
            case 0xd5: return .CMP_ZPX
            case 0xcd: return .CMP_ABS
            case 0xdd: return .CMP_ABSX
            case 0xd9: return .CMP_ABSY
            case 0xc1: return .CMP_INDX
            case 0xd1: return .CMP_INDY
            case 0xe0: return .CPX_IMM
            case 0xe4: return .CPX_ZP
            case 0xec: return .CPX_ABS
            case 0xc0: return .CPY_IMM
            case 0xc4: return .CPY_ZP
            case 0xcc: return .CPY_ABS
            case 0xc6: return .DEC_ZP
            case 0xd6: return .DEC_ZPX
            case 0xce: return .DEC_ABS
            case 0xde: return .DEC_ABSX
            case 0xca: return .DEX_IMP
            case 0x88: return .DEY_IMP
            case 0xe8: return .INX_IMP
            case 0xc8: return .INY_IMP
            case 0x49: return .EOR_IMM
            case 0x45: return .EOR_ZP
            case 0x55: return .EOR_ZPX
            case 0x4d: return .EOR_ABS
            case 0x5d: return .EOR_ABSX
            case 0x59: return .EOR_ABSY
            case 0x41: return .EOR_INDX
            case 0x51: return .EOR_INDY
            case 0xe6: return .INC_ZP
            case 0xf6: return .INC_ZPX
            case 0xee: return .INC_ABS
            case 0xfe: return .INC_ABSX
            case 0x4c: return .JMP_ABS
            case 0x6c: return .JMP_IND
            case 0x20: return .JSR_ABS
            case 0xa9: return .LDA_IMM
            case 0xa5: return .LDA_ZP
            case 0xb5: return .LDA_ZPX
            case 0xad: return .LDA_ABS
            case 0xbd: return .LDA_ABSX
            case 0xb9: return .LDA_ABSY
            case 0xa1: return .LDA_INDX
            case 0xb1: return .LDA_INDY
            case 0xa2: return .LDX_IMM
            case 0xa6: return .LDX_ZP
            case 0xb6: return .LDX_ZPY
            case 0xae: return .LDX_ABS
            case 0xbe: return .LDX_ABSY
            case 0xa0: return .LDY_IMM
            case 0xa4: return .LDY_ZP
            case 0xb4: return .LDY_ZPX
            case 0xac: return .LDY_ABS
            case 0xbc: return .LDY_ABSX
            case 0x4a: return .LSR_ACC
            case 0x46: return .LSR_ZP
            case 0x56: return .LSR_ZPX
            case 0x4e: return .LSR_ABS
            case 0x5e: return .LSR_ABSX
            case 0x09: return .ORA_IMM
            case 0x05: return .ORA_ZP
            case 0x15: return .ORA_ZPX
            case 0x0d: return .ORA_ABS
            case 0x1d: return .ORA_ABSX
            case 0x19: return .ORA_ABSY
            case 0x01: return .ORA_INDX
            case 0x11: return .ORA_INDY
            case 0x2a: return .ROL_ACC
            case 0x26: return .ROL_ZP
            case 0x36: return .ROL_ZPX
            case 0x2e: return .ROL_ABS
            case 0x3e: return .ROL_ABSX
            case 0x6a: return .ROR_ACC
            case 0x66: return .ROR_ZP
            case 0x76: return .ROR_ZPX
            case 0x7e: return .ROR_ABS
            case 0x6e: return .ROR_ABSX
            case 0xe9: return .SBC_IMM
            case 0xe5: return .SBC_ZP
            case 0xf5: return .SBC_ZPX
            case 0xed: return .SBC_ABS
            case 0xfd: return .SBC_ABSX
            case 0xf9: return .SBC_ABSY
            case 0xe1: return .SBC_INDX
            case 0xf1: return .SBC_INDY
            case 0x85: return .STA_ZP
            case 0x95: return .STA_ZPX
            case 0x8d: return .STA_ABS
            case 0x9d: return .STA_ABSX
            case 0x99: return .STA_ABSY
            case 0x81: return .STA_INDX
            case 0x91: return .STA_INDY
            case 0x86: return .STX_ZP
            case 0x96: return .STX_ZPY
            case 0x8e: return .STX_ABS
            case 0x84: return .STY_ZP
            case 0x94: return .STY_ZPX
            case 0x8c: return .STY_ABS
            default: return nil
        }
    }

    private func f(_ f: Bool, _ s: String) -> String { (f ? s : "-") }
}

var OPCODES: [OpcodeData] = [
    OpcodeData(opcodeEnum: .ADC_IMM, instruction: "ADC", addressMode: "IMM", bytes: 2, cycles: 2, flags: "NV---ZC"),
    OpcodeData(opcodeEnum: .ADC_ZP, instruction: "ADC", addressMode: "ZP", bytes: 2, cycles: 3, flags: "NV---ZC"),
    OpcodeData(opcodeEnum: .ADC_ZPX, instruction: "ADC", addressMode: "ZPX", bytes: 2, cycles: 4, flags: "NV---ZC"),
    OpcodeData(opcodeEnum: .ADC_ABS, instruction: "ADC", addressMode: "ABS", bytes: 3, cycles: 4, flags: "NV---ZC"),
    OpcodeData(opcodeEnum: .ADC_ABSX, instruction: "ADC", addressMode: "ABSX", bytes: 3, cycles: 4, flags: "NV---ZC"),
    OpcodeData(opcodeEnum: .ADC_ABSY, instruction: "ADC", addressMode: "ABSY", bytes: 3, cycles: 4, flags: "NV---ZC"),
    OpcodeData(opcodeEnum: .ADC_INDX, instruction: "ADC", addressMode: "INDX", bytes: 2, cycles: 6, flags: "NV---ZC"),
    OpcodeData(opcodeEnum: .ADC_INDY, instruction: "ADC", addressMode: "INDY", bytes: 2, cycles: 5, flags: "NV---ZC"),
    OpcodeData(opcodeEnum: .AND_IMM, instruction: "AND", addressMode: "IMM", bytes: 2, cycles: 2, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .AND_ZP, instruction: "AND", addressMode: "ZP", bytes: 2, cycles: 3, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .AND_ZPX, instruction: "AND", addressMode: "ZPX", bytes: 2, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .AND_ABS, instruction: "AND", addressMode: "ABS", bytes: 3, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .AND_ABSX, instruction: "AND", addressMode: "ABSX", bytes: 3, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .AND_ABSY, instruction: "AND", addressMode: "ABSY", bytes: 3, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .AND_INDX, instruction: "AND", addressMode: "INDX", bytes: 2, cycles: 6, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .AND_INDY, instruction: "AND", addressMode: "INDY", bytes: 2, cycles: 5, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .ASL_ACC, instruction: "ASL", addressMode: "ACC", bytes: 1, cycles: 2, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .ASL_ZP, instruction: "ASL", addressMode: "ZP", bytes: 2, cycles: 5, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .ASL_ZPX, instruction: "ASL", addressMode: "ZPX", bytes: 2, cycles: 6, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .ASL_ABS, instruction: "ASL", addressMode: "ABS", bytes: 3, cycles: 6, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .ASL_ABSX, instruction: "ASL", addressMode: "ABSX", bytes: 3, cycles: 7, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .BCC_REL, instruction: "BCC", addressMode: "REL", bytes: 2, cycles: 2, plus1: true, flags: "-------"),
    OpcodeData(opcodeEnum: .BCS_REL, instruction: "BCS", addressMode: "REL", bytes: 2, cycles: 2, plus1: true, flags: "-------"),
    OpcodeData(opcodeEnum: .BEQ_REL, instruction: "BEQ", addressMode: "REL", bytes: 2, cycles: 2, plus1: true, flags: "-------"),
    OpcodeData(opcodeEnum: .BMI_REL, instruction: "BMI", addressMode: "REL", bytes: 2, cycles: 2, plus1: true, flags: "-------"),
    OpcodeData(opcodeEnum: .BNE_REL, instruction: "BNE", addressMode: "REL", bytes: 2, cycles: 2, plus1: true, flags: "-------"),
    OpcodeData(opcodeEnum: .BPL_REL, instruction: "BPL", addressMode: "REL", bytes: 2, cycles: 2, plus1: true, flags: "-------"),
    OpcodeData(opcodeEnum: .BVC_REL, instruction: "BVC", addressMode: "REL", bytes: 2, cycles: 2, plus1: true, flags: "-------"),
    OpcodeData(opcodeEnum: .BVS_REL, instruction: "BVS", addressMode: "REL", bytes: 2, cycles: 2, plus1: true, flags: "-------"),
    OpcodeData(opcodeEnum: .BIT_ZP, instruction: "BIT", addressMode: "ZP", bytes: 2, cycles: 3, flags: "NV---Z-"),
    OpcodeData(opcodeEnum: .BIT_ABS, instruction: "BIT", addressMode: "ABS", bytes: 3, cycles: 4, flags: "NV---Z-"),
    OpcodeData(opcodeEnum: .BRK_IMP, instruction: "BRK", addressMode: "IMP", bytes: 1, cycles: 7, flags: "-------"),
    OpcodeData(opcodeEnum: .CLC_IMP, instruction: "CLC", addressMode: "IMP", bytes: 1, cycles: 2, flags: "------C"),
    OpcodeData(opcodeEnum: .CLD_IMP, instruction: "CLD", addressMode: "IMP", bytes: 1, cycles: 2, flags: "---D---"),
    OpcodeData(opcodeEnum: .CLI_IMP, instruction: "CLI", addressMode: "IMP", bytes: 1, cycles: 2, flags: "----I--"),
    OpcodeData(opcodeEnum: .CLV_IMP, instruction: "CLV", addressMode: "IMP", bytes: 1, cycles: 2, flags: "-V-----"),
    OpcodeData(opcodeEnum: .NOP_IMP, instruction: "NOP", addressMode: "IMP", bytes: 1, cycles: 2, flags: "-------"),
    OpcodeData(opcodeEnum: .PHA_IMP, instruction: "PHA", addressMode: "IMP", bytes: 1, cycles: 3, flags: "-------"),
    OpcodeData(opcodeEnum: .PLA_IMP, instruction: "PLA", addressMode: "IMP", bytes: 1, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .PHP_IMP, instruction: "PHP", addressMode: "IMP", bytes: 1, cycles: 3, flags: "-------"),
    OpcodeData(opcodeEnum: .PLP_IMP, instruction: "PLP", addressMode: "IMP", bytes: 1, cycles: 4, flags: "NVBDIZC"),
    OpcodeData(opcodeEnum: .RTI_IMP, instruction: "RTI", addressMode: "IMP", bytes: 1, cycles: 6, flags: "-------"),
    OpcodeData(opcodeEnum: .RTS_IMP, instruction: "RTS", addressMode: "IMP", bytes: 1, cycles: 6, flags: "-------"),
    OpcodeData(opcodeEnum: .SEC_IMP, instruction: "SEC", addressMode: "IMP", bytes: 1, cycles: 2, flags: "------C"),
    OpcodeData(opcodeEnum: .SED_IMP, instruction: "SED", addressMode: "IMP", bytes: 1, cycles: 2, flags: "---D---"),
    OpcodeData(opcodeEnum: .SEI_IMP, instruction: "SEI", addressMode: "IMP", bytes: 1, cycles: 2, flags: "----I--"),
    OpcodeData(opcodeEnum: .TAX_IMP, instruction: "TAX", addressMode: "IMP", bytes: 1, cycles: 2, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .TXA_IMP, instruction: "TXA", addressMode: "IMP", bytes: 1, cycles: 2, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .TAY_IMP, instruction: "TAY", addressMode: "IMP", bytes: 1, cycles: 2, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .TYA_IMP, instruction: "TYA", addressMode: "IMP", bytes: 1, cycles: 2, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .TSX_IMP, instruction: "TSX", addressMode: "IMP", bytes: 1, cycles: 2, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .TXS_IMP, instruction: "TXS", addressMode: "IMP", bytes: 1, cycles: 2, flags: "-------"),
    OpcodeData(opcodeEnum: .CMP_IMM, instruction: "CMP", addressMode: "IMM", bytes: 2, cycles: 2, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .CMP_ZP, instruction: "CMP", addressMode: "ZP", bytes: 2, cycles: 3, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .CMP_ZPX, instruction: "CMP", addressMode: "ZPX", bytes: 2, cycles: 4, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .CMP_ABS, instruction: "CMP", addressMode: "ABS", bytes: 3, cycles: 4, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .CMP_ABSX, instruction: "CMP", addressMode: "ABSX", bytes: 3, cycles: 4, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .CMP_ABSY, instruction: "CMP", addressMode: "ABSY", bytes: 3, cycles: 4, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .CMP_INDX, instruction: "CMP", addressMode: "INDX", bytes: 2, cycles: 6, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .CMP_INDY, instruction: "CMP", addressMode: "INDY", bytes: 2, cycles: 5, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .CPX_IMM, instruction: "CPX", addressMode: "IMM", bytes: 2, cycles: 2, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .CPX_ZP, instruction: "CPX", addressMode: "ZP", bytes: 2, cycles: 3, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .CPX_ABS, instruction: "CPX", addressMode: "ABS", bytes: 3, cycles: 4, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .CPY_IMM, instruction: "CPY", addressMode: "IMM", bytes: 2, cycles: 2, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .CPY_ZP, instruction: "CPY", addressMode: "ZP", bytes: 2, cycles: 3, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .CPY_ABS, instruction: "CPY", addressMode: "ABS", bytes: 3, cycles: 4, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .DEC_ZP, instruction: "DEC", addressMode: "ZP", bytes: 2, cycles: 5, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .DEC_ZPX, instruction: "DEC", addressMode: "ZPX", bytes: 2, cycles: 6, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .DEC_ABS, instruction: "DEC", addressMode: "ABS", bytes: 3, cycles: 6, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .DEC_ABSX, instruction: "DEC", addressMode: "ABSX", bytes: 3, cycles: 7, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .DEX_IMP, instruction: "DEX", addressMode: "IMP", bytes: 1, cycles: 2, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .DEY_IMP, instruction: "DEY", addressMode: "IMP", bytes: 1, cycles: 2, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .INX_IMP, instruction: "INX", addressMode: "IMP", bytes: 1, cycles: 2, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .INY_IMP, instruction: "INY", addressMode: "IMP", bytes: 1, cycles: 2, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .EOR_IMM, instruction: "EOR", addressMode: "IMM", bytes: 2, cycles: 2, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .EOR_ZP, instruction: "EOR", addressMode: "ZP", bytes: 2, cycles: 3, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .EOR_ZPX, instruction: "EOR", addressMode: "ZPX", bytes: 2, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .EOR_ABS, instruction: "EOR", addressMode: "ABS", bytes: 3, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .EOR_ABSX, instruction: "EOR", addressMode: "ABSX", bytes: 3, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .EOR_ABSY, instruction: "EOR", addressMode: "ABSY", bytes: 3, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .EOR_INDX, instruction: "EOR", addressMode: "INDX", bytes: 2, cycles: 6, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .EOR_INDY, instruction: "EOR", addressMode: "INDY", bytes: 2, cycles: 5, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .INC_ZP, instruction: "INC", addressMode: "ZP", bytes: 2, cycles: 5, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .INC_ZPX, instruction: "INC", addressMode: "ZPX", bytes: 2, cycles: 6, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .INC_ABS, instruction: "INC", addressMode: "ABS", bytes: 3, cycles: 6, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .INC_ABSX, instruction: "INC", addressMode: "ABSX", bytes: 3, cycles: 7, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .JMP_ABS, instruction: "JMP", addressMode: "ABS", bytes: 3, cycles: 3, flags: "-------"),
    OpcodeData(opcodeEnum: .JMP_IND, instruction: "JMP", addressMode: "IND", bytes: 3, cycles: 5, flags: "-------"),
    OpcodeData(opcodeEnum: .JSR_ABS, instruction: "JSR", addressMode: "ABS", bytes: 3, cycles: 6, flags: "-------"),
    OpcodeData(opcodeEnum: .LDA_IMM, instruction: "LDA", addressMode: "IMM", bytes: 2, cycles: 2, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDA_ZP, instruction: "LDA", addressMode: "ZP", bytes: 2, cycles: 3, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDA_ZPX, instruction: "LDA", addressMode: "ZPX", bytes: 2, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDA_ABS, instruction: "LDA", addressMode: "ABS", bytes: 3, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDA_ABSX, instruction: "LDA", addressMode: "ABSX", bytes: 3, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDA_ABSY, instruction: "LDA", addressMode: "ABSY", bytes: 3, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDA_INDX, instruction: "LDA", addressMode: "INDX", bytes: 2, cycles: 6, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDA_INDY, instruction: "LDA", addressMode: "INDY", bytes: 2, cycles: 5, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDX_IMM, instruction: "LDX", addressMode: "IMM", bytes: 2, cycles: 2, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDX_ZP, instruction: "LDX", addressMode: "ZP", bytes: 2, cycles: 3, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDX_ZPY, instruction: "LDX", addressMode: "ZPY", bytes: 2, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDX_ABS, instruction: "LDX", addressMode: "ABS", bytes: 3, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDX_ABSY, instruction: "LDX", addressMode: "ABSY", bytes: 3, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDY_IMM, instruction: "LDY", addressMode: "IMM", bytes: 2, cycles: 2, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDY_ZP, instruction: "LDY", addressMode: "ZP", bytes: 2, cycles: 3, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDY_ZPX, instruction: "LDY", addressMode: "ZPX", bytes: 2, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDY_ABS, instruction: "LDY", addressMode: "ABS", bytes: 3, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LDY_ABSX, instruction: "LDY", addressMode: "ABSX", bytes: 3, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .LSR_ACC, instruction: "LSR", addressMode: "ACC", bytes: 1, cycles: 2, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .LSR_ZP, instruction: "LSR", addressMode: "ZP", bytes: 2, cycles: 5, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .LSR_ZPX, instruction: "LSR", addressMode: "ZPX", bytes: 2, cycles: 6, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .LSR_ABS, instruction: "LSR", addressMode: "ABS", bytes: 3, cycles: 6, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .LSR_ABSX, instruction: "LSR", addressMode: "ABSX", bytes: 3, cycles: 7, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .ORA_IMM, instruction: "ORA", addressMode: "IMM", bytes: 2, cycles: 2, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .ORA_ZP, instruction: "ORA", addressMode: "ZP", bytes: 2, cycles: 3, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .ORA_ZPX, instruction: "ORA", addressMode: "ZPX", bytes: 2, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .ORA_ABS, instruction: "ORA", addressMode: "ABS", bytes: 3, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .ORA_ABSX, instruction: "ORA", addressMode: "ABSX", bytes: 3, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .ORA_ABSY, instruction: "ORA", addressMode: "ABSY", bytes: 3, cycles: 4, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .ORA_INDX, instruction: "ORA", addressMode: "INDX", bytes: 2, cycles: 6, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .ORA_INDY, instruction: "ORA", addressMode: "INDY", bytes: 2, cycles: 5, flags: "N----Z-"),
    OpcodeData(opcodeEnum: .ROL_ACC, instruction: "ROL", addressMode: "ACC", bytes: 1, cycles: 2, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .ROL_ZP, instruction: "ROL", addressMode: "ZP", bytes: 2, cycles: 5, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .ROL_ZPX, instruction: "ROL", addressMode: "ZPX", bytes: 2, cycles: 6, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .ROL_ABS, instruction: "ROL", addressMode: "ABS", bytes: 3, cycles: 6, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .ROL_ABSX, instruction: "ROL", addressMode: "ABSX", bytes: 3, cycles: 7, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .ROR_ACC, instruction: "ROR", addressMode: "ACC", bytes: 1, cycles: 2, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .ROR_ZP, instruction: "ROR", addressMode: "ZP", bytes: 2, cycles: 5, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .ROR_ZPX, instruction: "ROR", addressMode: "ZPX", bytes: 2, cycles: 6, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .ROR_ABS, instruction: "ROR", addressMode: "ABS", bytes: 3, cycles: 6, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .ROR_ABSX, instruction: "ROR", addressMode: "ABSX", bytes: 3, cycles: 7, flags: "N----ZC"),
    OpcodeData(opcodeEnum: .SBC_IMM, instruction: "SBC", addressMode: "IMM", bytes: 2, cycles: 2, flags: "NV---ZC"),
    OpcodeData(opcodeEnum: .SBC_ZP, instruction: "SBC", addressMode: "ZP", bytes: 2, cycles: 3, flags: "NV---ZC"),
    OpcodeData(opcodeEnum: .SBC_ZPX, instruction: "SBC", addressMode: "ZPX", bytes: 2, cycles: 4, flags: "NV---ZC"),
    OpcodeData(opcodeEnum: .SBC_ABS, instruction: "SBC", addressMode: "ABS", bytes: 3, cycles: 4, flags: "NV---ZC"),
    OpcodeData(opcodeEnum: .SBC_ABSX, instruction: "SBC", addressMode: "ABSX", bytes: 3, cycles: 4, flags: "NV---ZC"),
    OpcodeData(opcodeEnum: .SBC_ABSY, instruction: "SBC", addressMode: "ABSY", bytes: 3, cycles: 4, flags: "NV---ZC"),
    OpcodeData(opcodeEnum: .SBC_INDX, instruction: "SBC", addressMode: "INDX", bytes: 2, cycles: 6, flags: "NV---ZC"),
    OpcodeData(opcodeEnum: .SBC_INDY, instruction: "SBC", addressMode: "INDY", bytes: 2, cycles: 5, flags: "NV---ZC"),
    OpcodeData(opcodeEnum: .STA_ZP, instruction: "STA", addressMode: "ZP", bytes: 2, cycles: 3, flags: "-------"),
    OpcodeData(opcodeEnum: .STA_ZPX, instruction: "STA", addressMode: "ZPX", bytes: 2, cycles: 4, flags: "-------"),
    OpcodeData(opcodeEnum: .STA_ABS, instruction: "STA", addressMode: "ABS", bytes: 3, cycles: 4, flags: "-------"),
    OpcodeData(opcodeEnum: .STA_ABSX, instruction: "STA", addressMode: "ABSX", bytes: 3, cycles: 5, flags: "-------"),
    OpcodeData(opcodeEnum: .STA_ABSY, instruction: "STA", addressMode: "ABSY", bytes: 3, cycles: 5, flags: "-------"),
    OpcodeData(opcodeEnum: .STA_INDX, instruction: "STA", addressMode: "INDX", bytes: 2, cycles: 6, flags: "-------"),
    OpcodeData(opcodeEnum: .STA_INDY, instruction: "STA", addressMode: "INDY", bytes: 2, cycles: 6, flags: "-------"),
    OpcodeData(opcodeEnum: .STX_ZP, instruction: "STX", addressMode: "ZP", bytes: 2, cycles: 3, flags: "-------"),
    OpcodeData(opcodeEnum: .STX_ZPY, instruction: "STX", addressMode: "ZPY", bytes: 2, cycles: 4, flags: "-------"),
    OpcodeData(opcodeEnum: .STX_ABS, instruction: "STX", addressMode: "ABS", bytes: 3, cycles: 4, flags: "-------"),
    OpcodeData(opcodeEnum: .STY_ZP, instruction: "STY", addressMode: "ZP", bytes: 2, cycles: 3, flags: "-------"),
    OpcodeData(opcodeEnum: .STY_ZPX, instruction: "STY", addressMode: "ZPX", bytes: 2, cycles: 4, flags: "-------"),
    OpcodeData(opcodeEnum: .STY_ABS, instruction: "STY", addressMode: "ABS", bytes: 3, cycles: 4, flags: "-------"),
]

func doIt5() {
    print("var OPCODES: [OpcodeData] = [")
    for od: OpcodeData in OPCODES {
        print("    OpcodeData(opcodeEnum: \(od.instruction)_\(od.addressMode), instruction: \"\(od.instruction)\", addressMode: \"\(od.addressMode)\", bytes: \(od.bytes), cycles: \(od.cycles), \(od.plus1 ? "plus1: true, " : "")flags: \"\(od.strFlags)\"),")
    }
    print("]")
}

public let BINSTR: [String] = [
    "0000",
    "0001",
    "0010",
    "0011",
    "0100",
    "0101",
    "0110",
    "0111",
    "1000",
    "1001",
    "1010",
    "1011",
    "1100",
    "1101",
    "1110",
    "1111",
]

public let BBINSTR: [String] = [
    "00000000", "00000001", "00000010", "00000011", "00000100", "00000101", "00000110", "00000111", "00001000", "00001001", "00001010", "00001011", "00001100", "00001101", "00001110", "00001111",
    "00010000", "00010001", "00010010", "00010011", "00010100", "00010101", "00010110", "00010111", "00011000", "00011001", "00011010", "00011011", "00011100", "00011101", "00011110", "00011111",
    "00100000", "00100001", "00100010", "00100011", "00100100", "00100101", "00100110", "00100111", "00101000", "00101001", "00101010", "00101011", "00101100", "00101101", "00101110", "00101111",
    "00110000", "00110001", "00110010", "00110011", "00110100", "00110101", "00110110", "00110111", "00111000", "00111001", "00111010", "00111011", "00111100", "00111101", "00111110", "00111111",
    "01000000", "01000001", "01000010", "01000011", "01000100", "01000101", "01000110", "01000111", "01001000", "01001001", "01001010", "01001011", "01001100", "01001101", "01001110", "01001111",
    "01010000", "01010001", "01010010", "01010011", "01010100", "01010101", "01010110", "01010111", "01011000", "01011001", "01011010", "01011011", "01011100", "01011101", "01011110", "01011111",
    "01100000", "01100001", "01100010", "01100011", "01100100", "01100101", "01100110", "01100111", "01101000", "01101001", "01101010", "01101011", "01101100", "01101101", "01101110", "01101111",
    "01110000", "01110001", "01110010", "01110011", "01110100", "01110101", "01110110", "01110111", "01111000", "01111001", "01111010", "01111011", "01111100", "01111101", "01111110", "01111111",
    "10000000", "10000001", "10000010", "10000011", "10000100", "10000101", "10000110", "10000111", "10001000", "10001001", "10001010", "10001011", "10001100", "10001101", "10001110", "10001111",
    "10010000", "10010001", "10010010", "10010011", "10010100", "10010101", "10010110", "10010111", "10011000", "10011001", "10011010", "10011011", "10011100", "10011101", "10011110", "10011111",
    "10100000", "10100001", "10100010", "10100011", "10100100", "10100101", "10100110", "10100111", "10101000", "10101001", "10101010", "10101011", "10101100", "10101101", "10101110", "10101111",
    "10110000", "10110001", "10110010", "10110011", "10110100", "10110101", "10110110", "10110111", "10111000", "10111001", "10111010", "10111011", "10111100", "10111101", "10111110", "10111111",
    "11000000", "11000001", "11000010", "11000011", "11000100", "11000101", "11000110", "11000111", "11001000", "11001001", "11001010", "11001011", "11001100", "11001101", "11001110", "11001111",
    "11010000", "11010001", "11010010", "11010011", "11010100", "11010101", "11010110", "11010111", "11011000", "11011001", "11011010", "11011011", "11011100", "11011101", "11011110", "11011111",
    "11100000", "11100001", "11100010", "11100011", "11100100", "11100101", "11100110", "11100111", "11101000", "11101001", "11101010", "11101011", "11101100", "11101101", "11101110", "11101111",
    "11110000", "11110001", "11110010", "11110011", "11110100", "11110101", "11110110", "11110111", "11111000", "11111001", "11111010", "11111011", "11111100", "11111101", "11111110", "11111111",
]

public let HEXSTR: [String] = [
    "0x00", "0x01", "0x02", "0x03", "0x04", "0x05", "0x06", "0x07", "0x08", "0x09", "0x0a", "0x0b", "0x0c", "0x0d", "0x0e", "0x0f",
    "0x10", "0x11", "0x12", "0x13", "0x14", "0x15", "0x16", "0x17", "0x18", "0x19", "0x1a", "0x1b", "0x1c", "0x1d", "0x1e", "0x1f",
    "0x20", "0x21", "0x22", "0x23", "0x24", "0x25", "0x26", "0x27", "0x28", "0x29", "0x2a", "0x2b", "0x2c", "0x2d", "0x2e", "0x2f",
    "0x30", "0x31", "0x32", "0x33", "0x34", "0x35", "0x36", "0x37", "0x38", "0x39", "0x3a", "0x3b", "0x3c", "0x3d", "0x3e", "0x3f",
    "0x40", "0x41", "0x42", "0x43", "0x44", "0x45", "0x46", "0x47", "0x48", "0x49", "0x4a", "0x4b", "0x4c", "0x4d", "0x4e", "0x4f",
    "0x50", "0x51", "0x52", "0x53", "0x54", "0x55", "0x56", "0x57", "0x58", "0x59", "0x5a", "0x5b", "0x5c", "0x5d", "0x5e", "0x5f",
    "0x60", "0x61", "0x62", "0x63", "0x64", "0x65", "0x66", "0x67", "0x68", "0x69", "0x6a", "0x6b", "0x6c", "0x6d", "0x6e", "0x6f",
    "0x70", "0x71", "0x72", "0x73", "0x74", "0x75", "0x76", "0x77", "0x78", "0x79", "0x7a", "0x7b", "0x7c", "0x7d", "0x7e", "0x7f",
    "0x80", "0x81", "0x82", "0x83", "0x84", "0x85", "0x86", "0x87", "0x88", "0x89", "0x8a", "0x8b", "0x8c", "0x8d", "0x8e", "0x8f",
    "0x90", "0x91", "0x92", "0x93", "0x94", "0x95", "0x96", "0x97", "0x98", "0x99", "0x9a", "0x9b", "0x9c", "0x9d", "0x9e", "0x9f",
    "0xa0", "0xa1", "0xa2", "0xa3", "0xa4", "0xa5", "0xa6", "0xa7", "0xa8", "0xa9", "0xaa", "0xab", "0xac", "0xad", "0xae", "0xaf",
    "0xb0", "0xb1", "0xb2", "0xb3", "0xb4", "0xb5", "0xb6", "0xb7", "0xb8", "0xb9", "0xba", "0xbb", "0xbc", "0xbd", "0xbe", "0xbf",
    "0xc0", "0xc1", "0xc2", "0xc3", "0xc4", "0xc5", "0xc6", "0xc7", "0xc8", "0xc9", "0xca", "0xcb", "0xcc", "0xcd", "0xce", "0xcf",
    "0xd0", "0xd1", "0xd2", "0xd3", "0xd4", "0xd5", "0xd6", "0xd7", "0xd8", "0xd9", "0xda", "0xdb", "0xdc", "0xdd", "0xde", "0xdf",
    "0xe0", "0xe1", "0xe2", "0xe3", "0xe4", "0xe5", "0xe6", "0xe7", "0xe8", "0xe9", "0xea", "0xeb", "0xec", "0xed", "0xee", "0xef",
    "0xf0", "0xf1", "0xf2", "0xf3", "0xf4", "0xf5", "0xf6", "0xf7", "0xf8", "0xf9", "0xfa", "0xfb", "0xfc", "0xfd", "0xfe", "0xff",
]

public enum Nibble {
    case Hi
    case Lo
    case Both
}

var HOPCODES: [UInt8: OpcodeData] = [:]
let LINES:    String              = "\("-".rep(toLength: MAXW))+"
let ECELL:    String              = "\(" ".rep(toLength: MAXW))|"
let HEXRANGE: Range<Int>          = (0 ..< 16)

func asBin(_ b: Int, _ n: Nibble = .Both) -> String {
    switch n {
        case .Hi: return BINSTR[(b & 0xf0) >> 4] + "xxxx"
        case .Lo: return "xxxx" + (BINSTR[b & 0x0f])
        case .Both: return BBINSTR[b]
    }
}

func OC(_ x: Int, _ y: Int) -> UInt8 { UInt8(x * 16 + y) }

func crlf() { print("") }

func printx(_ str: String) { print(str, terminator: "") }

func lines(_ first: String = "+\(LINES)") { printx(first); for _ in HEXRANGE { printx(LINES) }; crlf() }

func ecell(_ str: String = ECELL) { printx(str) }

func cell(_ str: String) { printx("\(str.padding(align: .Center, toLength: MAXW))|") }

typealias XCellClsr = (OpcodeData) -> String

func row(first: String = " ", x: Int, closure: XCellClsr) {
    printx("|\(first.padding(align: .Center, toLength: MAXW))|")
    for y: Int in HEXRANGE {
        if let od: OpcodeData = HOPCODES[OC(x, y)] { cell(closure(od)) }
        else { ecell() }
    }
    crlf()
}

func hrow(closure: (Int) -> String) {
    printx(" \(ECELL)"); for i: Int in HEXRANGE { cell(closure(i)) }; crlf()
}

func header() {
    lines(" \("".padding(toLength: MAXW))+")
    hrow { (i: Int) -> String in HEXSTR[i] }
    hrow { (i: Int) -> String in asBin(i, .Lo) }
    lines()
}

func doIt1() {
    OPCODES.sort { (a: OpcodeData, b: OpcodeData) -> Bool in a.opcode < b.opcode }
    for od: OpcodeData in OPCODES { HOPCODES[od.opcode] = od }
    header()

    for x: Int in HEXRANGE {
        row(x: x) { (od: OpcodeData) in od.instruction }
        row(first: HEXSTR[x << 4], x: x) { (od: OpcodeData) in od.longAddressMode }
        row(first: asBin(x << 4, .Hi), x: x) { (od: OpcodeData) in "Flags: \(od.strFlags)" }
        row(x: x) { (od: OpcodeData) in "Bytes: \(od.bytes)" }
        row(x: x) { (od: OpcodeData) in "Cycles: \(od.cycles)\(od.plus1 ? "*" : " ")" }
        lines()
    }
}

func doIt2() {
    OPCODES.sort { (a: OpcodeData, b: OpcodeData) -> Bool in a.opcode < b.opcode }
    print("public enum OpcodeEnum: UInt8 {")
    for od: OpcodeData in OPCODES { print("    case \(od.instruction)_\(od.addressMode) = \(HEXSTR[Int(od.opcode)])") }
    print("}")
}

func doIt3() {
    OPCODES.sort { (a: OpcodeData, b: OpcodeData) -> Bool in a.opcode < b.opcode }
    print("    public var opcodeEnum: OpcodeEnum? {")
    print("        switch opcode {")

    for od: OpcodeData in OPCODES { print("            case \(HEXSTR[Int(od.opcode)]): return .\(od.instruction)_\(od.addressMode)") }

    print("            default: return nil")
    print("        }")
    print("    }")
}

func doIt4() {
    print("public let BBINSTR: [String] = [")
    for y: Int in HEXRANGE {
        printx("   ")
        for x: Int in HEXRANGE {
            printx(" \"\(BINSTR[y])\(BINSTR[x])\",")
        }
        crlf()
    }
    print("]")
}

func doIt6(){
    var kull: [String: String] = [:]
    for od: OpcodeData in OPCODES { kull[od.instruction] = od.instruction }
    print("var BASICOPCODES: [String] = [")
    for (k, _) in kull { print("    \"\(k)\",")}
    print("]")
}

func commonBits(closure: (OpcodeData) -> Bool) -> UInt8 {
    var bits: UInt8 = 0xff
    for od: OpcodeData in OPCODES { if closure(od) { bits &= od.opcode } }
    return bits
}

func doIt7() {
    for o: String in BASICOPCODES {
        let bits: UInt8 = commonBits { (od: OpcodeData) in (od.instruction == o)}
        print("    case \(o) = 0b\(BBINSTR[Int(bits)])")
    }

    print()
    print()
    let am: [String] = ADDRESS_MODES.keys.sorted()
    for amode: String in am {
        let bits: UInt8 = commonBits { (od: OpcodeData) in (od.addressMode == amode) }
        print("    case \(amode) = 0b\(BBINSTR[Int(bits)])")
    }

    print()
    print()
    for (k, v) in ADDRESS_MODES {
        print("    case .\(k): return \"\(v)\"")
    }
}

func doIt8() {
    print("public let MOS6502_OPCODES: [UInt8: Mos6502OpcodeInfo] = [")
    for od: OpcodeData in OPCODES {
        print("    \(HEXSTR[Int(od.opcode)]): Mos6502OpcodeInfo(opcode: \(HEXSTR[Int(od.opcode)]), numonic: .\(od.instruction), addressMode: .\(od.addressMode), bytes: \(od.bytes), cycles: \(od.cycles), plus1: \(od.plus1 ? "true" : "false"), flags: \"\(od.strFlags)\"),")
    }
    print("]")
}


func doIt9() {
    for o: String in BASICOPCODES {
        print("    ///")
        print("    /// Process the \(o) opcode.")
        print("    ///")
        print("    /// - Parameter od: the opcode information.")
        print("    ///")
        print("    final func opcode\(o)(_ od: Mos6502OpcodeInfo) {")
        print("        let params: [UInt8] = getParams(od)")
        print("    }")
    }
}

func doIt10() {
    print("switch od.numonic {")
    for o: String in BASICOPCODES {
        print("    case .\(o): opcode\(o)(od)")
    }
    print("}")
}
