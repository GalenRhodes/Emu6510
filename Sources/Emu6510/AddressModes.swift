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

public enum AddressModes: CustomStringConvertible {
    case ABS
    case ABX
    case ABY
    case ACC
    case IMM
    case IMP
    case IND
    case IZX
    case IZY
    case REL
    case ZPG
    case ZPX
    case ZPY

    @inlinable public var description: String {
        switch self {
            case .ABS: return "ABS"
            case .ABX: return "ABX"
            case .ABY: return "ABY"
            case .ACC: return "ACC"
            case .IMM: return "IMM"
            case .IMP: return "IMP"
            case .IND: return "IND"
            case .IZX: return "IZX"
            case .IZY: return "IZY"
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
            case .IZX: return 2
            case .IZY: return 2
            case .REL: return 2
            case .ZPG: return 2
            case .ZPX: return 2
            case .ZPY: return 2
        }
    }
}
