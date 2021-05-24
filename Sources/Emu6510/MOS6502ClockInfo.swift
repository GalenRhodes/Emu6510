/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Emu6510
 *    FILENAME: MOS6502Clock.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/18/21
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

public protocol MOS6502ClockInfo {
    var frequency: UInt64 { get }
    var period:    UInt64 { get }
}

public enum CommodoreCPUClock: MOS6502ClockInfo {
    case C64NTSC, C64PAL, C128NTSCSlow, C128PALSlow, C128NTSCFast, C128PALFast
}

extension CommodoreCPUClock {
    @inlinable public var frequency: UInt64 {
        switch self {
            case .C64NTSC:      return 1_022_727
            case .C64PAL:       return 985_248
            case .C128NTSCSlow: return CommodoreCPUClock.C64NTSC.frequency
            case .C128PALSlow:  return CommodoreCPUClock.C64PAL.frequency
            case .C128NTSCFast: return (CommodoreCPUClock.C128NTSCSlow.frequency * 2)
            case .C128PALFast:  return (CommodoreCPUClock.C128PALSlow.frequency * 2)
        }
    }

    @inlinable public var period: UInt64 { UInt64((1.0 / Double(frequency)) * 1_000_000_000.0) }
}
