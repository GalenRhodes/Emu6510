/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: CPUClock.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/29/20
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

public typealias ClockClosure = () -> Void

public let NANOS_PER_SECOND: UInt64 = 1_000_000_000

///
/// Get the system monotonic time (CPU time) in nanoseconds.
///
/// - Returns: monotonic time in nanoseconds.
///
@inlinable public func getMonotonic() -> UInt64 {
    var ts: timespec = timespec()
    clock_gettime(CLOCK_MONOTONIC_RAW, &ts)
    return ((UInt64(ts.tv_sec) * NANOS_PER_SECOND) + UInt64(ts.tv_nsec))
}

fileprivate final class ClosureHolder {
    let closure: ClockClosure
    var gate:    Int32 = 0

    init(closure: @escaping ClockClosure) {
        self.closure = closure
    }
}

///
/// A timer that calls the provided closure once every timer `tick`.
///
public class CPUClock {

    private var closures: [ClosureHolder] = []
    private var gate:     Int32           = 0
    private let queue:    DispatchQueue   = DispatchQueue(label: "ClockQueue",
                                                          qos: DispatchQoS.userInteractive,
                                                          attributes: [ DispatchQueue.Attributes.concurrent ],
                                                          autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.workItem)

    /// The `frequency` of the clock in Hz. Due to CPU speed limitations there exists an effective high frequency.  For example, on a 3.2GHz MacBookPro+Retna with 16GB of RAM it takes about 30-40ns
    /// to get the system monotonic raw time. This means that, not counting any other overhead like actually doing anything but directly returning from the closure, the effective max frequency is
    /// about 20-22 MHz.
    public let  freqency: UInt32

    /// The `period` of the frequency in nanoseconds. Calculated as ((1 / frequency) * 1_000_000_000)
    public let  period:   UInt64

    public private(set) var running:  Bool = false
    public private(set) var finished: Bool = true

    ///
    /// Initialize the CPUClock.
    ///
    /// - Parameters:
    ///   - frequency: The frequency of the clock.
    ///
    public init(frequency: UInt32) {
        self.freqency = frequency
        self.period = UInt64(((1.0 / Double(self.freqency)) * Double(NANOS_PER_SECOND)) + 0.5)
    }

    ///
    /// Initialize the CPUClock.
    ///
    /// - Parameters:
    ///   - frequency: The frequency of the clock.
    ///   - closure: the closure to execute every clock tick.
    ///
    public convenience init(frequency: UInt32, closure: @escaping ClockClosure) {
        self.init(frequency: frequency)
        addClosure(closure: closure)
    }

    ///
    ///
    /// - Parameter block:
    ///
    public func addClosure(closure: @escaping ClockClosure) { closures.append(ClosureHolder(closure: closure)) }

    ///
    ///
    deinit { stop() }

    private func incGate(_ amt: Int32 = 1) { gate = ((gate + amt) % INT32_MAX) }

    ///
    ///
    public func start() {
        if !running {
            while !finished { /*spin-lock*/ }
            running = true
            finished = false

            for closure: ClosureHolder in closures {
                queue.async {
                    closure.gate = self.gate
                    while self.running {
                        while closure.gate == self.gate { /*spin-lock*/ }
                        if self.running {
                            closure.closure()
                            closure.gate = self.gate
                        }
                    }
                }
            }

            queue.async {
                let p: UInt64 = self.period
                var t: UInt64 = (getMonotonic() + p)

                while self.running {
                    while getMonotonic() < t { /*spin-lock*/ }
                    self.incGate()
                    t += p
                }

                self.finished = true
            }
        }
    }

    ///
    ///
    public func stop() {
        if running {
            running = false
            incGate(Int32(closures.count))
        }
        while !finished { /*spin-lock*/ }
    }
}
