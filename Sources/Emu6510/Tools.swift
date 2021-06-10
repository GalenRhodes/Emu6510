/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Emu6510
 *    FILENAME: Tools.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/19/21
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

@usableFromInline let fZ: UInt8  = MOS6502Flag.Zero.rawValue
@usableFromInline let fV: UInt8  = MOS6502Flag.Overflow.rawValue
@usableFromInline let fN: UInt8  = MOS6502Flag.Negative.rawValue
@usableFromInline let fC: UInt8  = MOS6502Flag.Carry.rawValue
@usableFromInline let NZ: UInt8  = (fZ | fN)
@usableFromInline let CV: UInt8  = (fC | fV)
@usableFromInline let zC: UInt16 = 0x0100

@inlinable func DiffPage(_ a: UInt16, _ b: UInt16) -> Bool { ((a & 0xff00) != (b & 0xff00)) }

@inlinable func CarryFlag(_ w: UInt16) -> UInt8 { UInt8((w >= 0x100) ? 1 : 0) }

@inlinable func OverflowFlag(_ a: Int16) -> UInt8 { (a < -128 || a > 127) ? fV : 0 }

@inlinable func ZeroFlag<T: BinaryInteger>(_ v: T) -> UInt8 { ((v == T.zero) ? fZ : UInt8.zero) }

@inlinable func U8toI8(_ b: UInt8) -> Int8 { Int8(bitPattern: b) }

@inlinable func I8toU8(_ b: Int8) -> UInt8 { UInt8(bitPattern: b) }

@inlinable func U16toI16(_ w: UInt16) -> Int16 { Int16(bitPattern: w) }

@inlinable func I16toU16(_ w: Int16) -> UInt16 { UInt16(bitPattern: w) }

@inlinable func U16toU8(_ w: UInt16) -> UInt8 { UInt8(w & 0xff) }

@inlinable func U8toU16(_ b: UInt8) -> UInt16 { UInt16(b) }

@inlinable func I16toI8(_ w: Int16) -> Int8 { U8toI8(U16toU8(I16toU16(w))) }

@inlinable func I8toI16(_ b: Int8) -> Int16 { Int16(b) }

@inlinable func U8toI16(_ b: UInt8) -> Int16 { I8toI16(U8toI8(b)) }

@inlinable func I8toU16(_ b: Int8) -> UInt16 { U8toU16(I8toU8(b)) }

@inlinable func U16toI8(_ w: UInt16) -> Int8 { I16toI8(U16toI16(w)) }

@inlinable func I16toU8(_ w: Int16) -> UInt8 { U16toU8(I16toU16(w)) }

@inlinable func U16HtoU8(_ w: UInt16) -> UInt8 { UInt8((w & 0xff00) >> 8) }

@inlinable func getSystemTime() -> UInt64 {
    var ts: timespec = timespec()
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts)
    return (UInt64(UInt(bitPattern: ts.tv_sec)) * 1_000_000_000) &+ UInt64(UInt(bitPattern: ts.tv_nsec))
}
