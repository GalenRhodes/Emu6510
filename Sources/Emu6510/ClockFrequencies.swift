/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: ClockFrequencies.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/25/20
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

@frozen public enum ClockFrequencies {
    case C64_NTSC
    case C64_PAL
    case C128_NTSC
    case C128_PAL
    case Custom(frequencyHz: UInt)

    @inlinable public var frequency: UInt {
        switch self {
            case .C64_NTSC:  return 1022727
            case .C64_PAL:   return 985248
            case .C128_NTSC: return 2045454
            case .C128_PAL:  return 1970496
            case .Custom(frequencyHz: let frequencyHz): return frequencyHz
        }
    }

    @inlinable public var clockCycle: UInt64 { (1000000000 / UInt64(frequency)) }
}
