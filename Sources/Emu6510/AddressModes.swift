/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: AddressModes.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/24/20
 *
 * Copyright © 2020 Galen Rhodes. All rights reserved.
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

/*===============================================================================================================================*/
/// Here are some notes on the addressing modes.
/// 
/// 1) The instructions that are implied (IMP) or relative (REL) have no other addressing mode. 2) ROL, ROR, ASL, and LSR are the
/// only opcodes that have the Accumulator (ACC) addressing mode. 3) JMP is the only instruction to have the Absolute Indirect
/// (IND) addressing mode. 4) LDX and STX are the only instructions that have the ZeroPage,Y (ZPY) addressing mode.
///
@frozen public enum AddressModes: CustomStringConvertible {
    case ABS
    case ABX
    case ABY
    case ACC
    case IMM
    case IMP
    case IND
    case INX
    case INY
    case REL
    case ZPG
    case ZPX
    case ZPY

    @inlinable public var longDescription: String {
        switch self {
            case .ABS: return "Absolute"
            case .ABX: return "Absolute,X"
            case .ABY: return "Absolute,Y"
            case .ACC: return "Accumulator"
            case .IMM: return "Immediate"
            case .IMP: return "Implied"
            case .IND: return "(Indirect)"
            case .INX: return "(Indirect,X)"
            case .INY: return "(Indirect),Y"
            case .REL: return "±Relative"
            case .ZPG: return "ZeroPage"
            case .ZPX: return "ZeroPage,X"
            case .ZPY: return "ZeroPage,Y"
        }
    }

    @inlinable public var description: String {
        switch self {
            case .ABS: return "ABS"
            case .ABX: return "ABX"
            case .ABY: return "ABY"
            case .ACC: return "ACC"
            case .IMM: return "IMM"
            case .IMP: return "IMP"
            case .IND: return "IND"
            case .INX: return "INX"
            case .INY: return "INY"
            case .REL: return "REL"
            case .ZPG: return "ZPG"
            case .ZPX: return "ZPX"
            case .ZPY: return "ZPY"
        }
    }

    @inlinable public var byteCount: UInt8 {
        switch self {
            case .ABS: return 3
            case .ABX: return 3
            case .ABY: return 3
            case .ACC: return 1
            case .IMM: return 2
            case .IMP: return 1
            case .IND: return 3
            case .INX: return 2
            case .INY: return 2
            case .REL: return 2
            case .ZPG: return 2
            case .ZPX: return 2
            case .ZPY: return 2
        }
    }
}
