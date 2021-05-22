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

@inlinable func diffPage(_ a: UInt16, _ b: UInt16) -> Bool { ((a & 0xff00) != (b & 0xff00)) }

@inlinable func zeroFlag<T: BinaryInteger>(_ v: T) -> UInt8 { ((v == T(0)) ? fZ : UInt8.zero) }
