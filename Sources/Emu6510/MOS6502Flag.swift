/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Emu6510
 *    FILENAME: MOS6502Flag.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/13/21
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

infix operator <+=: AssignmentPrecedence
infix operator <-=: AssignmentPrecedence
infix operator ?==: ComparisonPrecedence
infix operator ?!=: ComparisonPrecedence

public enum MOS6502Flag: UInt8 {
    case Carry    = 1
    case Zero     = 2
    case IRQ      = 4
    case Decimal  = 8
    case Break    = 16
    // Bit 5 is unused.
    case Overflow = 64
    case Negative = 128

    @inlinable public static prefix func ~ (flag: MOS6502Flag) -> UInt8 { ~flag.rawValue }

    @inlinable public static func | (lhs: MOS6502Flag, rhs: MOS6502Flag) -> UInt8 { (lhs.rawValue | rhs.rawValue) }

    @inlinable public static func & (lhs: MOS6502Flag, rhs: MOS6502Flag) -> UInt8 { (lhs.rawValue & rhs.rawValue) }

    @inlinable public static func | (lhs: UInt8, rhs: MOS6502Flag) -> UInt8 { (lhs | rhs.rawValue) }

    @inlinable public static func & (lhs: UInt8, rhs: MOS6502Flag) -> UInt8 { (lhs & rhs.rawValue) }

    @inlinable public static func | (lhs: MOS6502Flag, rhs: UInt8) -> UInt8 { (lhs.rawValue | rhs) }

    @inlinable public static func & (lhs: MOS6502Flag, rhs: UInt8) -> UInt8 { (lhs.rawValue & rhs) }

    @inlinable public static func <-= (lhs: inout UInt8, rhs: MOS6502Flag) { lhs = (lhs & ~rhs) }

    @inlinable public static func <+= (lhs: inout UInt8, rhs: MOS6502Flag) { lhs = (lhs | rhs) }

    @inlinable public static func == (lhs: UInt8, rhs: MOS6502Flag) -> Bool { (lhs == rhs.rawValue) }

    @inlinable public static func == (lhs: MOS6502Flag, rhs: UInt8) -> Bool { (lhs.rawValue == rhs) }

    @inlinable public static func != (lhs: UInt8, rhs: MOS6502Flag) -> Bool { (lhs != rhs.rawValue) }

    @inlinable public static func != (lhs: MOS6502Flag, rhs: UInt8) -> Bool { (lhs.rawValue != rhs) }

    @inlinable public static func ?== (lhs: UInt8, rhs: MOS6502Flag) -> Bool { ((lhs & rhs) == rhs) }

    @inlinable public static func ?== (lhs: MOS6502Flag, rhs: UInt8) -> Bool { ((lhs & rhs) == lhs) }

    @inlinable public static func ?!= (lhs: UInt8, rhs: MOS6502Flag) -> Bool { ((lhs & rhs) == 0) }

    @inlinable public static func ?!= (lhs: MOS6502Flag, rhs: UInt8) -> Bool { ((lhs & rhs) == 0) }
}

extension UInt8 {
    @inlinable static func <+= (lhs: inout UInt8, rhs: UInt8) { lhs = (lhs | rhs) }

    @inlinable static func <-= (lhs: inout UInt8, rhs: UInt8) { lhs = (lhs & ~rhs) }
}
