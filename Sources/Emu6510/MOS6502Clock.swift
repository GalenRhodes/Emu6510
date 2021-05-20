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

public let CPUFrequencyC64NTSC: UInt64 = 1_022_727
public let CPUFrequencyC64PAL:  UInt64 = 985_248

public let CPUFrequencyC128NTSC:     UInt64 = CPUFrequencyC64NTSC
public let CPUFrequencyC128PAL:      UInt64 = CPUFrequencyC64PAL
public let CPUFrequencyC128FastNTSC: UInt64 = (CPUFrequencyC128NTSC * 2)
public let CPUFrequencyC128FastPAL:  UInt64 = (CPUFrequencyC128PAL * 2)

public protocol ClockListener {
    func clockTick(sequence: UInt64)
}

open class MOS6502Clock: Thread {
    public private(set) var isRunning: Bool   = false
    public private(set) var sequence:  UInt64 = 0
    public private(set) var frequency: UInt64
    public private(set) var period:    UInt64

    private var listeners: [ClockListener] = []

    @usableFromInline let lock:     NSLock   = NSLock()
    @usableFromInline var updating: Bool     = false
    @usableFromInline var ts:       timespec = timespec()

    public init(frequency f: UInt64) {
        frequency = f
        period = UInt64((1.0 / Double(frequency)) * 1_000_000_000.0)
    }

    open func setFrequency(_ newFrequency: UInt64) {
        whileLocked {
            frequency = newFrequency
            period = UInt64((1.0 / Double(frequency)) * 1_000_000_000.0)
        }
    }

    open func addListener(listener: ClockListener) {
        whileLocked { listeners <+ listener }
    }

    open override func start() {
        whileLocked {
            guard !isRunning else { return }
            isRunning = true
            sequence = 0
            qualityOfService = .userInteractive
            super.start()
        }
    }

    open func stop() {
        whileLocked { isRunning = false }
    }

    open override func cancel() {
        whileLocked {
            isRunning = false
            super.cancel()
        }
    }

    open override func main() {
        var now:  UInt64 = getSystemTime()
        var next: UInt64 = (now + period)

        repeat {
            now = getSystemTime()
            if next >= now {
                next += period
                if !updating { for l in listeners { l.clockTick(sequence: sequence) } }
                sequence += 1
            }
        } while isRunning
    }

    @inlinable final func getSystemTime() -> UInt64 {
        clock_gettime(CLOCK_MONOTONIC_RAW, &ts)
        return (UInt64(UInt(bitPattern: ts.tv_sec)) * 1_000_000_000) + UInt64(UInt(bitPattern: ts.tv_nsec))
    }

    @inlinable final func whileLocked<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        updating = true
        defer {
            updating = false
            lock.unlock()
        }
        return try body()
    }
}
