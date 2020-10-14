/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: Utils.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 10/8/20
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

public typealias OperandInfo = (pageBoundaryCrossed: Bool, operand: UInt8)
public typealias AddressInfo = (pageBoundaryCrossed: Bool, address: UInt16)

/*===============================================================================================================================*/
/// Takes the high and low bytes of a 16-bit word and returns the 16-bit word.
/// 
/// - Parameters:
///   - lo: the low-byte of the word
///   - hi: the high-byte of the word
/// - Returns: the 16-bit word.
///
@inlinable public func makeWord(lo: UInt8, hi: UInt8) -> UInt16 {
    ((UInt16(hi) << 8) | UInt16(lo))
}

/*===============================================================================================================================*/
/// Takes the high and low bytes of a 16-bit word and returns the 16-bit word.
/// 
/// - Parameters:
///   - lo: the low-byte of the word
///   - hi: the high-byte of the word
///   - offset: an offset to add to the resulting 16-bit word.
/// - Returns: the 16-bit word.
///
@inlinable public func makeWord(lo: UInt8, hi: UInt8, offset: UInt8) -> AddressInfo {
    let a1: UInt16 = makeWord(lo: lo, hi: hi)
    let a2: UInt16 = (a1 &+ UInt16(offset))
    return (!(((a1 ^ a2) & 0xff00) == 0), a2)
}
