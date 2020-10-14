/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: CPU65xx.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 10/6/20
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

public protocol CPU65xx: CPUClock {
    var addressBuss:  AnyAddressBuss { get }
    var accumulator:  UInt8 { get }
    var xRegister:    UInt8 { get }
    var yRegister:    UInt8 { get }
    var stRegister:   UInt8 { get }
    var stackPointer: UInt8 { get }
    var progCounter:  UInt16 { get }

    /*===========================================================================================================================*/
    /// Start the CPU running.
    ///
    func run()

    /*===========================================================================================================================*/
    /// Dispatch the given opcode.
    /// 
    /// - Parameter opcode: the opcode
    ///
    func dispatchOpcode(opcode: OpcodeInfo)

    func isEqualTo(_ other: CPU65xx) -> Bool

    func asAnyCPU65xx() -> AnyCPU65xx
}

public extension CPU65xx where Self: Equatable {
    @inlinable func asAnyCPU65xx() -> AnyCPU65xx { AnyCPU65xx(self) }

    @inlinable func isEqualTo(_ other: CPU65xx) -> Bool {
        guard let other: Self = other as? Self else { return false }
        return self == other
    }
}

public struct AnyCPU65xx: CPU65xx {

    @usableFromInline var cpu: CPU65xx

    @inlinable public var addressBuss:  AnyAddressBuss { cpu.addressBuss }
    @inlinable public var accumulator:  UInt8 { cpu.accumulator }
    @inlinable public var xRegister:    UInt8 { cpu.xRegister }
    @inlinable public var yRegister:    UInt8 { cpu.yRegister }
    @inlinable public var stRegister:   UInt8 { cpu.stRegister }
    @inlinable public var stackPointer: UInt8 { cpu.stackPointer }
    @inlinable public var progCounter:  UInt16 { cpu.progCounter }
    @inlinable public var runStatus:    RunStatus { cpu.runStatus }

    @inlinable public var clockFrequency: ClockFrequencies {
        get { cpu.clockFrequency }
        set { cpu.clockFrequency = newValue }
    }

    public init(_ cpu: CPU65xx) { self.cpu = cpu }

    @inlinable public func run() { cpu.run() }

    @inlinable public func dispatchOpcode(opcode: OpcodeInfo) { cpu.dispatchOpcode(opcode: opcode) }

    @inlinable public func start() throws { try cpu.start() }

    @inlinable public func pause() throws { try cpu.pause() }

    @inlinable public func unPause() throws { try cpu.unPause() }

    @inlinable public func stop() throws { try cpu.stop() }

    @inlinable public func addWatcher(_ watcher: ClockWatcher) { cpu.addWatcher(watcher) }

    @inlinable public func removeWatcher(_ watcher: ClockWatcher) { cpu.removeWatcher(watcher) }

    @inlinable public func isEqualTo(_ other: CPU65xx) -> Bool { cpu.isEqualTo(other) }
}

extension AnyCPU65xx: Equatable {
    @inlinable public static func == (lhs: AnyCPU65xx, rhs: AnyCPU65xx) -> Bool { lhs.cpu.isEqualTo(rhs.cpu) }
}
