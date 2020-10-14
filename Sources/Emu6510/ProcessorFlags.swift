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

infix operator &==: ComparisonPrecedence
infix operator &!=: ComparisonPrecedence

@usableFromInline typealias PF = ProcessorFlags

@frozen public enum ProcessorFlags: UInt8 {
    case Carry     = 1
    case Zero      = 2
    case Interrupt = 4
    case Decimal   = 8
    case Break     = 16
    case Overflow  = 64
    case Negative  = 128

//@f:0
    @inlinable public static prefix func ~ <T: BinaryInteger>(flg: ProcessorFlags) -> T                { ~T(flg.rawValue)                                                 }

    @inlinable public static func |= <T: BinaryInteger>(lhs: inout T, rhs: ProcessorFlags)             { lhs = (lhs | rhs)                                                }

    @inlinable public static func &= <T: BinaryInteger>(lhs: inout T, rhs: ProcessorFlags)             { lhs = (lhs & rhs)                                                }

    @inlinable public static func | <T: BinaryInteger>(lhs: T, rhs: ProcessorFlags) -> T               { (lhs | T(rhs.rawValue))                                          }

    @inlinable public static func & <T: BinaryInteger>(lhs: T, rhs: ProcessorFlags) -> T               { (lhs & T(rhs.rawValue))                                          }

    @inlinable public static func | <T: BinaryInteger>(lhs: ProcessorFlags, rhs: T) -> T               { (T(lhs.rawValue) | rhs)                                          }

    @inlinable public static func & <T: BinaryInteger>(lhs: ProcessorFlags, rhs: T) -> T               { (T(lhs.rawValue) & rhs)                                          }

    @inlinable public static func | <T: BinaryInteger>(lhs: ProcessorFlags, rhs: ProcessorFlags) -> T  { T(lhs.rawValue | rhs.rawValue)                                   }

    @inlinable public static func & <T: BinaryInteger>(lhs: ProcessorFlags, rhs: ProcessorFlags) -> T  { T(lhs.rawValue & rhs.rawValue)                                   }

    @inlinable public static func == <T: BinaryInteger>(lhs: T, rhs: ProcessorFlags) -> Bool           { (lhs == T(rhs.rawValue))                                         }

    @inlinable public static func == <T: BinaryInteger>(lhs: ProcessorFlags, rhs: T) -> Bool           { (T(lhs.rawValue) == rhs)                                         }

    @inlinable public static func != <T: BinaryInteger>(lhs: T, rhs: ProcessorFlags) -> Bool           { (lhs != T(rhs.rawValue))                                         }

    @inlinable public static func != <T: BinaryInteger>(lhs: ProcessorFlags, rhs: T) -> Bool           { (T(lhs.rawValue) != rhs)                                         }

    @inlinable public static func &== <T: BinaryInteger>(lhs: T, rhs: ProcessorFlags) -> Bool          { let f: T = T(rhs.rawValue); return ((lhs & f) == f)              }

    @inlinable public static func &!= <T: BinaryInteger>(lhs: T, rhs: ProcessorFlags) -> Bool          { return ((lhs & T(rhs.rawValue)) == 0)                            }

    @inlinable @discardableResult public func set(status: inout UInt8, when f: Bool) -> UInt8          { status = (f ? (status | self) : (status & ~self)); return status }

    @inlinable @discardableResult public func setIf(status: inout UInt8, _ block: () -> Bool) -> UInt8 { set(status: &status, when: block())                              }

    @inlinable var idChar: String {
        switch self {
            case .Carry:     return "C"
            case .Zero:      return "Z"
            case .Interrupt: return "I"
            case .Decimal:   return "D"
            case .Break:     return "B"
            case .Overflow:  return "O"
            case .Negative:  return "N"
        }
    }
//@f:1
    @inlinable func s(_ flags: UInt8) -> String { ((flags &== self) ? idChar : "_") }

    @inlinable public static func flagsList(flags: UInt8) -> String {
        PF.Negative.s(flags) + PF.Overflow.s(flags) + PF.Break.s(flags) + PF.Decimal.s(flags) + PF.Interrupt.s(flags) + PF.Zero.s(flags) + PF.Carry.s(flags)
    }
}

@inlinable public func &== <T1: BinaryInteger, T2: BinaryInteger>(lhs: T1, rhs: T2) -> Bool { ((lhs.bitWidth > rhs.bitWidth) ? ((lhs & T1(rhs)) == T1(rhs)) : ((T2(lhs) & rhs) == rhs)) }

@inlinable public func &!= <T1: BinaryInteger, T2: BinaryInteger>(lhs: T1, rhs: T2) -> Bool { ((lhs.bitWidth > rhs.bitWidth) ? ((lhs & T1(rhs)) != T1(rhs)) : ((T2(lhs) & rhs) != rhs)) }
