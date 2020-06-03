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
