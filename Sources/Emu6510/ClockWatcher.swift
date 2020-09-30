/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: ClockWatcher.swift
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

public class ClockWatcher: Hashable {

    let uuid:    String         = UUID().uuidString
    let lock:    RecursiveLock  = RecursiveLock()
    var thread:  Thread?        = nil
    var closure: PGThreadBlock? = nil

    public internal(set) var running: Bool = false
    public var trigger: Bool = false

    public init() {
    }

    public func start() throws {
        try lock.withLock {
            guard thread == nil else { throw Emu6510Errors.AlreadyRunning }
            guard closure != nil else { throw Emu6510Errors.NoClosure }
            trigger = true
            running = true
            thread = Thread { self.main() }
            thread!.start()
        }
    }

    public func stop() throws {
        try lock.withLock {
            guard thread != nil else { throw Emu6510Errors.NotRunning }
            running = false
            trigger = false
            while thread?.isExecuting ?? false {}
            thread = nil
        }
    }

    func main() {
        while running {
            while running && trigger {}
            if let closure: PGThreadBlock = closure, running {
                trigger = true
                closure()
            }
        }
    }

    public func hash(into hasher: inout Hasher) { hasher.combine(uuid) }

    public static func == (lhs: ClockWatcher, rhs: ClockWatcher) -> Bool { lhs === rhs }
}

