/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Emu6510
 *    FILENAME: MOS6502AddressingMode.swift
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

public enum MOS6502AddressingMode: CustomStringConvertible, Comparable {
    case ABS
    case ABSX
    case ABSY
    case ACC
    case IMM
    case IMP
    case IND
    case INDX
    case INDY
    case REL
    case ZP
    case ZPX
    case ZPY

    public static func < (lhs: MOS6502AddressingMode, rhs: MOS6502AddressingMode) -> Bool { (lhs.order < rhs.order) }

    public var funDesc: String {
        switch self {
            case .ABS:  return "$1234"
            case .ABSX: return "$1234,X"
            case .ABSY: return "$1234,Y"
            case .ACC:  return ""
            case .IMM:  return "#$12"
            case .IMP:  return ""
            case .IND:  return "($1234)"
            case .INDX: return "($12,X)"
            case .INDY: return "($12),Y"
            case .REL:  return "±$12"
            case .ZP:   return "$12"
            case .ZPX:  return "$12,X"
            case .ZPY:  return "$12,Y"
        }
    }

    public var description: String {
        switch self {
            case .ABS:  return "ABS"
            case .ABSX: return "ABSX"
            case .ABSY: return "ABSY"
            case .ACC:  return "ACC"
            case .IMM:  return "IMM"
            case .IMP:  return "IMP"
            case .IND:  return "IND"
            case .INDX: return "INDX"
            case .INDY: return "INDY"
            case .REL:  return "REL"
            case .ZP:   return "ZP"
            case .ZPX:  return "ZPX"
            case .ZPY:  return "ZPY"
        }
    }

    public var bytes: UInt8 {
        switch self {
            case .ABS:  return 3
            case .ABSX: return 3
            case .ABSY: return 3
            case .ACC:  return 1
            case .IMM:  return 2
            case .IMP:  return 1
            case .IND:  return 3
            case .INDX: return 2
            case .INDY: return 2
            case .REL:  return 2
            case .ZP:   return 2
            case .ZPX:  return 2
            case .ZPY:  return 2
        }
    }

    public var order: UInt8 {
        switch self {
            case .IMP:  return 1
            case .ACC:  return 2
            case .IMM:  return 3
            case .REL:  return 4
            case .ZP:   return 5
            case .ZPX:  return 6
            case .ZPY:  return 7
            case .ABS:  return 8
            case .ABSX: return 9
            case .ABSY: return 10
            case .IND:  return 11
            case .INDX: return 12
            case .INDY: return 13
        }
    }
}
