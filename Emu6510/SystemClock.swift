/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: SystemClock.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/18/20
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
import Rubicon

infix operator !>: AssignmentPrecedence
infix operator ?>: AssignmentPrecedence

public protocol ClockListener: AnyObject {
    func clockSignal(tick: UInt64)
}

///
/// NTSC Master Clock Frequency Info.
/// Roughly one clock tick every 978ns.
///
public let NtscCpuClockFreq: UInt64 = 1_022_727

///
/// PAL Master Clock Frequency Info.
/// Roughly one clock tick every 1,015ns.
///
public let PalCpuClockFreq:  UInt64 = 985_248

open class SystemClock {

    public enum VideoStandard {
        case NTSC
        case PAL
    }

    public enum State {
        case Suspended
        case Resumed
    }

    public internal(set) var cpuClockFreq: UInt64
    public internal(set) var cpuClockNano: UInt64
    public internal(set) var cpuClockTick: UInt64
    public private(set) var  state:        State

    private var cpuClockListeners: [ClockListener] = []
    private let timer:             DispatchSourceTimer
    private let queue:             DispatchQueue
    private let timeInterval:      TimeInterval

    public init(videoStandard: VideoStandard) {
        switch videoStandard {
            case .NTSC:
                self.cpuClockFreq = NtscCpuClockFreq
            case .PAL:
                self.cpuClockFreq = PalCpuClockFreq
        }

        self.timeInterval = (1.0 / Double(self.cpuClockFreq))
        self.cpuClockNano = UInt64(self.timeInterval * 1_000_000_000.0 + 0.5) // Round up to the nearest nanosecond.
        self.cpuClockTick = 0
        self.queue = createQueue(label: "CPU_CLOCK")
        self.state = .Resumed
        self.timer = DispatchSource.makeTimerSource(flags: [ DispatchSource.TimerFlags.strict ], queue: createQueue(label: "CPU_TIMER"))
        self.timer.setEventHandler(handler: { [weak self] in self?.handleCpuClockTick() })
        self.timer.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval, leeway: .nanoseconds(0))
        self.timer.activate()
    }

    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /* If the timer is suspended, calling cancel without resuming triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902 */
        resume()
    }

    func resume() {
        if state != .Resumed {
            state = .Resumed
            timer.resume()
        }
    }

    func suspend() {
        if state != .Suspended {
            state = .Suspended
            timer.suspend()
        }
    }

    ///
    /// Called every time the CPU clock `ticks`.
    ///
    internal func handleCpuClockTick() {
        cpuClockTick += 1
        for l: ClockListener in cpuClockListeners { queue.async { l.clockSignal(tick: self.cpuClockTick) } }
    }

    public static func <+ (clock: SystemClock, listener: ClockListener) { if clock ?> listener { clock.cpuClockListeners.append(listener) } }

    public static func !> (clock: SystemClock, listener: ClockListener) { clock.cpuClockListeners.removeAll { (l: ClockListener) in l === listener } }

    public static func ?> (clock: SystemClock, listener: ClockListener) -> Bool { clock.cpuClockListeners.contains { (l: ClockListener) in l === listener } }
}

internal func createQueue(label: String) -> DispatchQueue {
    DispatchQueue(label: label, attributes: [ DispatchQueue.Attributes.concurrent ])
}
