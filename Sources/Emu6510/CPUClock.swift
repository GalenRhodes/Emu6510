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

public protocol CPUClock: AnyObject {
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

    func asHashable() -> AnyCPUClock

    func getHash(into hasher: inout Hasher)
}

open class AnyCPUClock: CPUClock, Hashable {
    @usableFromInline var clk: CPUClock

    @inlinable open var runStatus:      RunStatus { clk.runStatus }
    @inlinable open var clockFrequency: ClockFrequencies {
        get { clk.clockFrequency }
        set { clk.clockFrequency = newValue }
    }

    public init(_ clk: CPUClock) { self.clk = clk }

    @inlinable open func start() throws { try clk.start() }

    @inlinable open func pause() throws { try clk.pause() }

    @inlinable open func unPause() throws { try clk.unPause() }

    @inlinable open func stop() throws { try clk.stop() }

    @inlinable open func addWatcher(_ watcher: ClockWatcher) { clk.addWatcher(watcher) }

    @inlinable open func removeWatcher(_ watcher: ClockWatcher) { clk.removeWatcher(watcher) }

    @inlinable open func hash(into hasher: inout Hasher) { clk.getHash(into: &hasher) }

    @inlinable public static func == (lhs: AnyCPUClock, rhs: AnyCPUClock) -> Bool { lhs.clk.isEqualTo(rhs.clk) }

    @inlinable open func asHashable() -> AnyCPUClock { self }

    @inlinable open func isEqualTo(_ other: CPUClock) -> Bool { ((self === other) || ((type(of: other) == AnyCPUClock.self) && (self == (other as! AnyCPUClock)))) }
}

extension CPUClock where Self: Equatable {
    @inlinable public func asEquatable() -> AnyCPUClock { AnyCPUClock(self) }
}

extension CPUClock where Self: Hashable {
    @inlinable public func asHashable() -> AnyCPUClock { AnyCPUClock(self) }

    @inlinable public func getHash(into hasher: inout Hasher) { hash(into: &hasher) }
}

extension Array where Element: CPUClock {
    @inlinable public static func == (lhs: [CPUClock], rhs: [CPUClock]) -> Bool { lhs.map({ $0.asHashable() }) == rhs.map({ $0.asHashable() }) }
}

extension Dictionary where Value: CPUClock {
    @inlinable public static func == (lhs: [Key: CPUClock], rhs: [Key: CPUClock]) -> Bool { lhs.mapValues({ $0.asHashable() }) == rhs.mapValues({ $0.asHashable() }) }
}

extension Set where Element: CPUClock & Hashable {
    @inlinable public static func == (lhs: Set<Element>, rhs: Set<Element>) -> Bool { lhs.map({ $0.asHashable() }) == rhs.map({ $0.asHashable() }) }
}
