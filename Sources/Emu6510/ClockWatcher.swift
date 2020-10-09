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

public protocol _ClockWatcher: AnyObject {

    var isRunning: Bool { get }
    var isPaused:  Bool { get set }
    var isStopped: Bool { get }
    var trigger:   Bool { get set }
    var skip:      UInt8 { get }

    func hardStop()

    func start() throws

    func stop() throws
}

open class ClockWatcher: _ClockWatcher, Hashable {

    open var isPaused:  Bool {
        get { false }
        set {}
    }
    open var trigger:   Bool {
        get { false }
        set {}
    }
    open var isRunning: Bool { false }
    open var isStopped: Bool { false }
    open var skip:      UInt8 { 0 }

    open func hardStop() {}

    open func start() throws {}

    open func stop() throws {}

    @usableFromInline let uuid: String = UUID().uuidString

    @inlinable open func hash(into hasher: inout Hasher) { hasher.combine(uuid) }

    @inlinable public static func == (lhs: ClockWatcher, rhs: ClockWatcher) -> Bool { lhs === rhs }
}
