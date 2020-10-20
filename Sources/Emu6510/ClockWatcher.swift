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

public protocol ClockWatcher {
    var skip:      UInt8 { get }
    var isRunning: Bool { get }
    var isPaused:  Bool { get set }
    var isStopped: Bool { get }

    func hardStop()

    func start() throws

    func stop() throws

    func isEqualTo(_ other: ClockWatcher) -> Bool

    func asEquatable() -> AnyClockWatcher

    func getHash(into hasher: inout Hasher)

    mutating func fire()
}

public struct AnyClockWatcher: ClockWatcher {
    @usableFromInline var watcher: ClockWatcher

    public init(_ watcher: ClockWatcher) { self.watcher = watcher }

    @inlinable public var skip:      UInt8 { watcher.skip }
    @inlinable public var isRunning: Bool { watcher.isRunning }
    @inlinable public var isStopped: Bool { watcher.isStopped }
    @inlinable public var isPaused:  Bool {
        get { watcher.isPaused }
        set { watcher.isPaused = newValue }
    }

    @inlinable public mutating func fire() { watcher.fire() }

    @inlinable public func hardStop() { watcher.hardStop() }

    @inlinable public func start() throws { try watcher.start() }

    @inlinable public func stop() throws { try watcher.stop() }
}

extension ClockWatcher where Self: Equatable {
    @inlinable public func asEquatable() -> AnyClockWatcher { AnyClockWatcher(self) }

    @inlinable public func isEqualTo(_ other: ClockWatcher) -> Bool { guard let other: Self = other as? Self else { return false }; return self == other }
}

extension ClockWatcher where Self: Hashable {
    @inlinable public func asHashable() -> AnyClockWatcher { asEquatable() }

    @inlinable public func getHash(into hasher: inout Hasher) { self.hash(into: &hasher) }
}

extension AnyClockWatcher: Hashable {
    @inlinable public static func == (lhs: AnyClockWatcher, rhs: AnyClockWatcher) -> Bool { lhs.watcher.isEqualTo(rhs.watcher) }

    @inlinable public func hash(into hasher: inout Hasher) { watcher.getHash(into: &hasher) }
}

extension Array where Element: ClockWatcher {
    @inlinable public static func == (lhs: [ClockWatcher], rhs: [ClockWatcher]) -> Bool { lhs.map({ $0.asEquatable() }) == rhs.map({ $0.asEquatable() }) }
}

extension Dictionary where Value: ClockWatcher {
    @inlinable public static func == (lhs: [Key: ClockWatcher], rhs: [Key: ClockWatcher]) -> Bool { lhs.mapValues({ $0.asEquatable() }) == rhs.mapValues({ $0.asEquatable() }) }
}

extension Set where Element: ClockWatcher {
    @inlinable public static func == (lhs: Set<Element>, rhs: Set<Element>) -> Bool { lhs.map({ $0.asHashable() }) == rhs.map({ $0.asHashable() }) }
}
