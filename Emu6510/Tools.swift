/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: Tools.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 6/2/20
 *
 * Copyright © 2020 Project Galen. All rights reserved.
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

@inlinable public func &!<T: BinaryInteger>(lhs: T, rhs: T) -> Bool { ((lhs & rhs) == rhs) }

@inlinable public func &?<T: BinaryInteger>(lhs: T, rhs: T) -> Bool { ((lhs & rhs) != rhs) }

public enum Alignment {
    case Left, Right, Center
}

fileprivate let SPCPAD: String = "                                                                                                                                                                     "

public extension String {
    @inlinable func padding<T>(align: Alignment = .Left, toLength newLength: Int, withPad padString: T) -> String where T: StringProtocol {
        padding(align: align, toLength: newLength, withPad: padString, startingAt: 0)
    }

    func padding(align: Alignment = .Left, toLength newLength: Int) -> String { padding(align: align, toLength: newLength, withPad: SPCPAD, startingAt: 0) }

    func padding<T>(align: Alignment, toLength newLength: Int, withPad padString: T, startingAt padIndex: Int) -> String where T: StringProtocol {
        let c: Int = self.count
        let r: Int = (newLength - c)
        guard c < newLength else { return self }

        switch align {
            case .Left: return padding(toLength: newLength, withPad: padString, startingAt: padIndex)
            case .Right: return padString.rep(toLength: r, startingAt: padIndex) + self
            case .Center:
                let i: Int    = (r / 2)
                let p: String = padString.rep(toLength: newLength, startingAt: padIndex)
                return p[0 ..< i] + self + p[(i + c) ..< newLength]
        }
    }
}

public extension StringProtocol {

    @inlinable subscript(_ idx: Int) -> Character { self[self.index(utf16Offset: idx)] }
    @inlinable subscript(_ range: Range<Int>) -> String { range.isEmpty ? "" : String(self[index(utf16Offset: range.startIndex) ..< index(utf16Offset: range.endIndex)]) }

    @inlinable func index(utf16Offset idx: Int) -> String.Index { String.Index(utf16Offset: idx, in: self) }

    func rep(toLength l: Int, startingAt i: Int = 0) -> String {
        if l == 0 { return "" }
        let sc: Int = self.count
        if sc == 0 || l < 0 || i < 0 { fatalError() }
        var str: String = self[(i % sc) ..< sc]
        while str.count < l { str += self }
        return (str.count > l ? str[0 ..< l] : str)
    }
}

@usableFromInline let SignedByte: [Int8] = [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
                                             16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
                                             32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
                                             48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63,
                                             64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
                                             80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,
                                             96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111,
                                             112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127,
                                             -128, -127, -126, -125, -124, -123, -122, -121, -120, -119, -118, -117, -116, -115, -114, -113,
                                             -112, -111, -110, -109, -108, -107, -106, -105, -104, -103, -102, -101, -100, -99, -98, -97,
                                             -96, -95, -94, -93, -92, -91, -90, -89, -88, -87, -86, -85, -84, -83, -82, -81,
                                             -80, -79, -78, -77, -76, -75, -74, -73, -72, -71, -70, -69, -68, -67, -66, -65,
                                             -64, -63, -62, -61, -60, -59, -58, -57, -56, -55, -54, -53, -52, -51, -50, -49,
                                             -48, -47, -46, -45, -44, -43, -42, -41, -40, -39, -38, -37, -36, -35, -34, -33,
                                             -32, -31, -30, -29, -28, -27, -26, -25, -24, -23, -22, -21, -20, -19, -18, -17,
                                             -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1 ]

@inlinable public func makeSigned(_ ui: UInt8) -> Int8 { SignedByte[Int(ui)] }
