/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: CPUClock.swift
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
import Rubicon

public class CPUClock {

    public internal (set) var running: Bool = false

    public let clock:    ClockFrequencies
    public var isPaused: Bool = false

    var watchers: Set<ClockWatcher> = []
    var thread:   Thread?           = nil
    let lock:     RecursiveLock     = RecursiveLock()

    public init(clock: ClockFrequencies = .C64_NTSC) {
        self.clock = clock
    }

    public func start() throws {
        try lock.withLock {
            guard thread == nil else { throw Emu6510Errors.AlreadyRunning }
            guard !watchers.isEmpty else { throw Emu6510Errors.NoWatchers }
            running = true
            isPaused = false
            thread = Thread { self.main() }
            thread?.start()
        }
    }

    public func stop() throws {
        try lock.withLock {
            guard thread != nil else { throw Emu6510Errors.NotRunning }
            running = false
            while thread?.isExecuting ?? false {}
            thread = nil
        }
    }

    open func main() {
        let period:   UInt64 = clock.clockTick
        var nextTick: UInt64 = (getSysTime() + period)

        while running {
            if !isPaused && getSysTime() >= nextTick {
                for watcher: ClockWatcher in watchers { watcher.trigger = false }
                nextTick += period
            }
        }
    }

    public func addWatcher(_ watcher: ClockWatcher) throws {
        try lock.withLock {
            guard !running else { throw Emu6510Errors.AlreadyRunning }
            watchers.insert(watcher)
        }
    }

    public func removeWatcher(_ watcher: ClockWatcher) throws {
        try lock.withLock {
            guard !running else { throw Emu6510Errors.AlreadyRunning }
            watchers.remove(watcher)
        }
    }
}
