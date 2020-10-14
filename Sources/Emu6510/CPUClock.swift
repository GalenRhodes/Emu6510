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

/*===============================================================================================================================*/
/// The clock run modes.
///
@frozen public enum RunStatus: Int8 {
    /*===========================================================================================================================*/
    /// The clock has not yet been started.
    ///
    case NeverStarted = -1
    /*===========================================================================================================================*/
    /// The clock has been hard stopped and cannot be restarted.
    ///
    case Stopped      = 0
    /*===========================================================================================================================*/
    /// The clock is running.
    ///
    case Running      = 1
    /*===========================================================================================================================*/
    /// The clock is paused.
    ///
    case Paused       = 2
}

public protocol CPUClock {
    /*===========================================================================================================================*/
    /// The clock frequency.
    ///
    var clockFrequency: ClockFrequencies { get set }

    /*===========================================================================================================================*/
    /// `true` if the clock is running. Read-only.
    ///
    var runStatus:      RunStatus { get }

    /*===========================================================================================================================*/
    /// Starts the clock.
    /// 
    /// - Throws: `CPUErrors.AlreadyRunning` if the clock is already running.
    /// - Throws: `CPUErrors.AlreadyStopped` if the clock has already been stopped.
    ///
    func start() throws

    /*===========================================================================================================================*/
    /// Pauses the clock.
    /// 
    /// - Throws: `CPUErrors.AlreadyPaused` if the clock is already paused.
    /// - Throws: `CPUErrors.NotStarted` if the clock has never been started.
    ///
    func pause() throws

    /*===========================================================================================================================*/
    /// Un-pauses the clock.
    /// 
    /// - Throws: `CPUErrors.NotPaused` if the clock is not paused.
    /// - Throws: `CPUErrors.NotStarted` if the clock has never been started.
    ///
    func unPause() throws

    /*===========================================================================================================================*/
    /// Stops the clock permanently. After this call all of the resources have been released, the watchers have been removed, and
    /// the clock CANNOT be restarted.
    /// 
    /// - Throws: `CPUErrors.AlreadyStopped` if the clock has already been stopped.
    /// - Throws: `CPUErrors.NotStarted` if the clock has never been started.
    ///
    func stop() throws

    /*===========================================================================================================================*/
    /// Adds a watcher to this clock.
    /// 
    /// - Parameter watcher: the watcher to add. If the watcher is already watching this clock then calling this method has no
    ///                      effect.
    ///
    func addWatcher(_ watcher: ClockWatcher)

    /*===========================================================================================================================*/
    /// Removes a watcher from this clock.
    /// 
    /// - Parameter watcher: the watcher to remove. If the watcher is not actually watching this clock then calling this method has
    ///                      no effect.
    ///
    func removeWatcher(_ watcher: ClockWatcher)

    func isEqualTo(_ other: CPUClock) -> Bool

    func asAnyCPUClock() -> AnyCPUClock
}

public extension CPUClock where Self: Equatable {
    @inlinable func asAnyCPUClock() -> AnyCPUClock { AnyCPUClock(self) }

    @inlinable func isEqualTo(_ other: CPUClock) -> Bool {
        guard let other: Self = other as? Self else { return false }
        return self == other
    }
}

public struct AnyCPUClock: CPUClock {
    @usableFromInline var clock: CPUClock

    @inlinable public var runStatus: RunStatus { clock.runStatus }

    @inlinable public var clockFrequency: ClockFrequencies {
        get { clock.clockFrequency }
        set { clock.clockFrequency = newValue }
    }

    public init(_ clock: CPUClock) {
        self.clock = clock
    }

    @inlinable public func start() throws { try clock.start() }

    @inlinable public func pause() throws { try clock.pause() }

    @inlinable public func unPause() throws { try clock.unPause() }

    @inlinable public func stop() throws { try clock.stop() }

    @inlinable public func addWatcher(_ watcher: ClockWatcher) { clock.addWatcher(watcher) }

    @inlinable public func removeWatcher(_ watcher: ClockWatcher) { clock.removeWatcher(watcher) }
}

extension AnyCPUClock: Equatable {
    public static func == (lhs: AnyCPUClock, rhs: AnyCPUClock) -> Bool { lhs.clock.isEqualTo(rhs.clock) }
}

extension Array where Element: CPUClock {
    @inlinable public static func == (lhs: [CPUClock], rhs: [CPUClock]) -> Bool { lhs.map({ $0.asAnyCPUClock() }) == rhs.map({ $0.asAnyCPUClock() }) }
}

extension Dictionary where Value: CPUClock {
    @inlinable public static func == (lhs: [Key: CPUClock], rhs: [Key: CPUClock]) -> Bool { lhs.mapValues({ $0.asAnyCPUClock() }) == rhs.mapValues({ $0.asAnyCPUClock() }) }
}
