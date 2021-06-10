/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Emu6510
 *    FILENAME: main.swift
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

parseTemplate(filename: "BCDTables.swift") { (out: inout String, key: String) -> Bool in
    out = "    "
    var idx: Int = 0

    if key == "INSERT:A" {
        for c: UInt8 in (0 ..< 2) {
            for x: UInt8 in (0 ... 255) {
                let xl: UInt8 = (x & 0x0f)
                let xh: UInt8 = (x & 0xf0)

                for y: UInt8 in (0 ... 255) {
                    //@f:0
                    let yl:UInt8 = (y & 0x0f)
                    let yh:UInt8 = (y & 0xf0)

                    /* 1a. AL = (A & $0F) + (B & $0F) + C                           */ var al: UInt16 = UInt16((xl) + (yl) + c)
                    /* 1b. If AL >= $0A, then AL = ((AL + $06) & $0F) + $10         */ if al >= 0x0a { al = (((al + 0x06) & 0x0f) + 0x10) }
                    /* 1c. A = (A & $F0) + (B & $F0) + AL                           */ al = (UInt16(xh) + UInt16(yh) + al)
                    /* 1d. Note that A can be >= $100 at this point                 */ let bin: Int16 = (Int16(Int8(bitPattern: xh)) + Int16(Int8(bitPattern: yh)) + Int16(bitPattern: al))
                    /* 1e. If (A >= $A0), then A = A + $60                          */ if al >= 0xa0 { al = (al + 0x60) }
                    /* 1f. The accumulator result is the lower 8 bits of A          */ let a8 = UInt8(al & 0xff)
                    /* 1g. The carry result is 1 if A >= $100, and is 0 if A < $100 */ let c8 = UInt8((al >= 0x100) ? 1 : 0)
                    //@f:1

                    let neg:  UInt8  = (a8 & 0x80)
                    let zero: UInt8  = UInt8(((al & 0xff) == 0) ? 2 : 0)
                    let ovfl: UInt8  = UInt8((bin < -128 || bin > 127) ? 64 : 0)
                    let res:  UInt16 = ((UInt16(c8 | neg | zero | ovfl) << 8) | UInt16(a8))

                    var str = String(res, radix: 16, uppercase: false)
                    while str.count < 4 { str.insert("0", at: str.startIndex) }
                    idx += 1
                    out.append("0x\(str),\(((idx % 16) == 0) ? "\n    " : " ")")
                }
            }
        }
    }
    else if key == "INSERT:B" {
        for c: Int8 in (0 ..< 2) {
            for x: UInt8 in (0 ... 255) {
                let xl: UInt8 = (x & 0x0f)
                let xh: UInt8 = (x & 0xf0)

                for y: UInt8 in (0 ... 255) {
                    //@f:0
                    let yl: UInt8 = (y & 0x0f)
                    let yh: UInt8 = (y & 0xf0)

                    /* 3a. AL = (A & $0F) - (B & $0F) + C-1                */ var al: Int16 = (Int16(Int8(bitPattern: xl)) - Int16(Int8(bitPattern: yl)) + Int16(c) - 1)
                    /* 3b. If AL < 0, then AL = ((AL - $06) & $0F) - $10   */ if al < 0 { al = (((al - 0x06) & 0x0f) - 0x10) }
                    /* 3c. A = (A & $F0) - (B & $F0) + AL                  */ var a: Int16 = (Int16(Int8(bitPattern: xh)) - Int16(Int8(bitPattern: yh)) + al)
                    /*                                                     */ let bin: Int16 = a
                    /* 3d. If A < 0, then A = A - $60                      */ if a < 0 { a -= 0x60 }
                    /* 3e. The accumulator result is the lower 8 bits of A */ let a8: UInt8 = UInt8(UInt16(bitPattern: a) & 0xff)
                    /*                                                     */ let c8 = UInt8((UInt16(bitPattern: al) >= 0x100) ? 1 : 0)
                    //@f:1

                    let neg:  UInt8  = (a8 & 0x80)
                    let zero: UInt8  = UInt8(((UInt16(bitPattern: al) & 0xff) == 0) ? 2 : 0)
                    let ovfl: UInt8  = UInt8((bin < -128 || bin > 127) ? 64 : 0)
                    let res:  UInt16 = ((UInt16(c8 | neg | zero | ovfl) << 8) | UInt16(a8))

                    var str = String(res, radix: 16, uppercase: false)
                    while str.count < 4 { str.insert("0", at: str.startIndex) }
                    idx += 1
                    out.append("0x\(str),\(((idx % 16) == 0) ? "\n    " : " ")")
                }
            }
        }
    }
    else if key == "INSERT:C" {
        for x: UInt8 in (0 ... 255) {
            let xl = (x & 0x0f)
            let xh = ((x & 0xf0) >> 4)
            let rs = ((xh &* 10) &+ xl)
            var st = String(rs, radix: 16, uppercase: false)
            while st.count < 2 { st.insert("0", at: st.startIndex) }
            idx += 1
            out.append("0x\(st),\(((idx % 16) == 0) ? "\n    " : " ")")
        }
    }
    else {
        return false
    }

    return true
}

