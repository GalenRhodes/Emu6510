/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: ProcessorFlags.swift
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

infix operator ?=: ComparisonPrecedence

@usableFromInline typealias PF = ProcessorFlags

public enum ProcessorFlags: UInt8 {
    case Carry     = 1
    case Zero      = 2
    case Interrupt = 4
    case Decimal   = 8
    case Break     = 16
    case Overflow  = 64
    case Negative  = 128

    @inlinable public static func ?= <T: BinaryInteger>(lhs: T, rhs: ProcessorFlags) -> Bool {
        ((UInt8(truncatingIfNeeded: lhs) & rhs.rawValue) == rhs.rawValue)
    }

    @inlinable var idChar: String {
        switch self {
            case .Carry: return "C"
            case .Zero: return "Z"
            case .Interrupt: return "I"
            case .Decimal: return "D"
            case .Break: return "B"
            case .Overflow: return "O"
            case .Negative: return "N"
        }
    }

    @inlinable func s(_ flags: UInt8) -> String { ((flags ?= self) ? idChar : "_") }

    @inlinable public static func flagsList(flags: UInt8) -> String {
        PF.Negative.s(flags) + PF.Overflow.s(flags) + PF.Break.s(flags) + PF.Decimal.s(flags) + PF.Interrupt.s(flags) + PF.Zero.s(flags) + PF.Carry.s(flags)
    }
}
