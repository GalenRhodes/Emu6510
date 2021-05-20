/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Emu6510
 *    FILENAME: MOS6502Mnemonic.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 05/14/2021
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

public enum MOS6502Mnemonic: CustomStringConvertible {
    case ADC
    case AHX
    case ALR
    case ANC
    case AND
    case ARR
    case ASL
    case AXS
    case BCC
    case BCS
    case BEQ
    case BIT
    case BMI
    case BNE
    case BPL
    case BRK
    case BVC
    case BVS
    case CLC
    case CLD
    case CLI
    case CLV
    case CMP
    case CPX
    case CPY
    case DCP
    case DEC
    case DEX
    case DEY
    case EOR
    case INC
    case INX
    case INY
    case ISC
    case JMP
    case JSR
    case KIL
    case LAS
    case LAX
    case LDA
    case LDX
    case LDY
    case LSR
    case NOP
    case ORA
    case PHA
    case PHP
    case PLA
    case PLP
    case RLA
    case ROL
    case ROR
    case RRA
    case RTI
    case RTS
    case SAX
    case SBC
    case SEC
    case SED
    case SEI
    case SHX
    case SHY
    case SLO
    case SRE
    case STA
    case STX
    case STY
    case TAS
    case TAX
    case TAY
    case TSX
    case TXA
    case TXS
    case TYA
    case XAA

    public var description: String {
        switch self {
            case .ADC: return "ADC"
            case .AHX: return "AHX"
            case .ALR: return "ALR"
            case .ANC: return "ANC"
            case .AND: return "AND"
            case .ARR: return "ARR"
            case .ASL: return "ASL"
            case .AXS: return "AXS"
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
            case .DCP: return "DCP"
            case .DEC: return "DEC"
            case .DEX: return "DEX"
            case .DEY: return "DEY"
            case .EOR: return "EOR"
            case .INC: return "INC"
            case .INX: return "INX"
            case .INY: return "INY"
            case .ISC: return "ISC"
            case .JMP: return "JMP"
            case .JSR: return "JSR"
            case .KIL: return "KIL"
            case .LAS: return "LAS"
            case .LAX: return "LAX"
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
            case .RLA: return "RLA"
            case .ROL: return "ROL"
            case .ROR: return "ROR"
            case .RRA: return "RRA"
            case .RTI: return "RTI"
            case .RTS: return "RTS"
            case .SAX: return "SAX"
            case .SBC: return "SBC"
            case .SEC: return "SEC"
            case .SED: return "SED"
            case .SEI: return "SEI"
            case .SHX: return "SHX"
            case .SHY: return "SHY"
            case .SLO: return "SLO"
            case .SRE: return "SRE"
            case .STA: return "STA"
            case .STX: return "STX"
            case .STY: return "STY"
            case .TAS: return "TAS"
            case .TAX: return "TAX"
            case .TAY: return "TAY"
            case .TSX: return "TSX"
            case .TXA: return "TXA"
            case .TXS: return "TXS"
            case .TYA: return "TYA"
            case .XAA: return "XAA"
        }
    }

    public var addressingModes: Set<MOS6502AddressingMode> {
        switch self {
            case .ADC: return Set<MOS6502AddressingMode>([ .INDX, .ZP, .IMM, .ABS, .INDY, .ZPX, .ABSY, .ABSX, ])
            case .AHX: return Set<MOS6502AddressingMode>([ .INDY, .ABSY, ])
            case .ALR: return Set<MOS6502AddressingMode>([ .IMM, ])
            case .ANC: return Set<MOS6502AddressingMode>([ .IMM, .IMM, ])
            case .AND: return Set<MOS6502AddressingMode>([ .INDX, .ZP, .IMM, .ABS, .INDY, .ZPX, .ABSY, .ABSX, ])
            case .ARR: return Set<MOS6502AddressingMode>([ .IMM, ])
            case .ASL: return Set<MOS6502AddressingMode>([ .ZP, .ACC, .ABS, .ZPX, .ABSX, ])
            case .AXS: return Set<MOS6502AddressingMode>([ .IMM, ])
            case .BCC: return Set<MOS6502AddressingMode>([ .REL, ])
            case .BCS: return Set<MOS6502AddressingMode>([ .REL, ])
            case .BEQ: return Set<MOS6502AddressingMode>([ .REL, ])
            case .BIT: return Set<MOS6502AddressingMode>([ .ZP, .ABS, ])
            case .BMI: return Set<MOS6502AddressingMode>([ .REL, ])
            case .BNE: return Set<MOS6502AddressingMode>([ .REL, ])
            case .BPL: return Set<MOS6502AddressingMode>([ .REL, ])
            case .BRK: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .BVC: return Set<MOS6502AddressingMode>([ .REL, ])
            case .BVS: return Set<MOS6502AddressingMode>([ .REL, ])
            case .CLC: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .CLD: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .CLI: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .CLV: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .CMP: return Set<MOS6502AddressingMode>([ .INDX, .ZP, .IMM, .ABS, .INDY, .ZPX, .ABSY, .ABSX, ])
            case .CPX: return Set<MOS6502AddressingMode>([ .IMM, .ZP, .ABS, ])
            case .CPY: return Set<MOS6502AddressingMode>([ .IMM, .ZP, .ABS, ])
            case .DCP: return Set<MOS6502AddressingMode>([ .INDX, .ZP, .ABS, .INDY, .ZPX, .ABSY, .ABSX, ])
            case .DEC: return Set<MOS6502AddressingMode>([ .ZP, .ABS, .ZPX, .ABSX, ])
            case .DEX: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .DEY: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .EOR: return Set<MOS6502AddressingMode>([ .INDX, .ZP, .IMM, .ABS, .INDY, .ZPX, .ABSY, .ABSX, ])
            case .INC: return Set<MOS6502AddressingMode>([ .ZP, .ABS, .ZPX, .ABSX, ])
            case .INX: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .INY: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .ISC: return Set<MOS6502AddressingMode>([ .INDX, .ZP, .ABS, .INDY, .ZPX, .ABSY, .ABSX, ])
            case .JMP: return Set<MOS6502AddressingMode>([ .ABS, .IND, ])
            case .JSR: return Set<MOS6502AddressingMode>([ .ABS, ])
            case .KIL: return Set<MOS6502AddressingMode>([ .IMP, .IMP, .IMP, .IMP, .IMP, .IMP, .IMP, .IMP, .IMP, .IMP, .IMP, .IMP, .IMP, ])
            case .LAS: return Set<MOS6502AddressingMode>([ .ABSY, ])
            case .LAX: return Set<MOS6502AddressingMode>([ .INDX, .ZP, .IMM, .ABS, .INDY, .ZPY, .ABSY, .ABC, ])
            case .LDA: return Set<MOS6502AddressingMode>([ .INDX, .ZP, .IMM, .ABS, .INDY, .ZPX, .ABSY, .ABSX, ])
            case .LDX: return Set<MOS6502AddressingMode>([ .IMM, .ZP, .ABS, .ZPY, .ABSY, ])
            case .LDY: return Set<MOS6502AddressingMode>([ .IMM, .ZP, .ABS, .ZPX, .ABSX, ])
            case .LSR: return Set<MOS6502AddressingMode>([ .ZP, .ACC, .ABS, .ZPX, .ABSX, ])
            case .NOP: return Set<MOS6502AddressingMode>([ .ZP, .ABS, .ZPX, .IMP, .ABSX, .ZPX, .IMP, .ABSX, .ZP, .ZPX, .IMP, .ABSX, .ZP, .ZPX, .IMP, .ABSX, .IMM, .IMM, .IMM, .ZPX, .IMP, .ABSX, .IMM, .IMP, .ZPX, .ABS, ])
            case .ORA: return Set<MOS6502AddressingMode>([ .INDX, .ZP, .IMM, .ABS, .INDY, .ZPX, .ABSY, .ABSX, ])
            case .PHA: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .PHP: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .PLA: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .PLP: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .RLA: return Set<MOS6502AddressingMode>([ .INDX, .ZP, .ABS, .INDY, .ZPX, .ABSY, .ABSX, ])
            case .ROL: return Set<MOS6502AddressingMode>([ .ZP, .ACC, .ABS, .ZPX, .ABSX, ])
            case .ROR: return Set<MOS6502AddressingMode>([ .ZP, .ACC, .ABSX, .ZPX, .ABS, ])
            case .RRA: return Set<MOS6502AddressingMode>([ .INDX, .ZP, .ABS, .INDY, .ZPX, .ABSY, .ABSX, ])
            case .RTI: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .RTS: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .SAX: return Set<MOS6502AddressingMode>([ .INDX, .ZP, .ABS, .ZPY, ])
            case .SBC: return Set<MOS6502AddressingMode>([ .INDX, .ZP, .IMM, .IMM, .ABS, .INDY, .ZPX, .ABSY, .ABSX, ])
            case .SEC: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .SED: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .SEI: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .SHX: return Set<MOS6502AddressingMode>([ .ABSY, ])
            case .SHY: return Set<MOS6502AddressingMode>([ .ABSX, ])
            case .SLO: return Set<MOS6502AddressingMode>([ .INDX, .ZP, .ABS, .INDY, .ZPX, .ABSY, .ABSX, ])
            case .SRE: return Set<MOS6502AddressingMode>([ .INDX, .ZP, .ABS, .INDY, .ZPX, .ABSY, .ABSX, ])
            case .STA: return Set<MOS6502AddressingMode>([ .INDX, .ZP, .ABS, .INDY, .ZPX, .ABSY, .ABSX, ])
            case .STX: return Set<MOS6502AddressingMode>([ .ZP, .ABS, .ZPY, ])
            case .STY: return Set<MOS6502AddressingMode>([ .ZP, .ABS, .ZPX, ])
            case .TAS: return Set<MOS6502AddressingMode>([ .ABSY, ])
            case .TAX: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .TAY: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .TSX: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .TXA: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .TXS: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .TYA: return Set<MOS6502AddressingMode>([ .IMP, ])
            case .XAA: return Set<MOS6502AddressingMode>([ .IMM, ])
        }
    }
}
