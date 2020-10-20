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

public protocol CPU65xx: AnyObject {
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

    func asHashable() -> AnyCPU65xx

    func getHash(into hasher: inout Hasher)
}

open class AnyCPU65xx: CPU65xx, Hashable {
    @usableFromInline var cpu: CPU65xx

    @inlinable open var addressBuss:  AnyAddressBuss { cpu.addressBuss }
    @inlinable open var accumulator:  UInt8 { cpu.accumulator }
    @inlinable open var xRegister:    UInt8 { cpu.xRegister }
    @inlinable open var yRegister:    UInt8 { cpu.yRegister }
    @inlinable open var stRegister:   UInt8 { cpu.stRegister }
    @inlinable open var stackPointer: UInt8 { cpu.stackPointer }
    @inlinable open var progCounter:  UInt16 { cpu.progCounter }

    public init(_ cpu: CPU65xx) { self.cpu = cpu }

    @inlinable open func run() { cpu.run() }

    @inlinable open func dispatchOpcode(opcode: OpcodeInfo) { cpu.dispatchOpcode(opcode: opcode) }

    @inlinable open func hash(into hasher: inout Hasher) { cpu.getHash(into: &hasher) }

    @inlinable public static func == (lhs: AnyCPU65xx, rhs: AnyCPU65xx) -> Bool { lhs.cpu.isEqualTo(rhs.cpu) }

    @inlinable open func asHashable() -> AnyCPU65xx { self }

    @inlinable open func isEqualTo(_ other: CPU65xx) -> Bool { ((self === other) || ((type(of: other) == AnyCPU65xx.self) && (self == (other as! AnyCPU65xx)))) }
}

extension CPU65xx where Self: Equatable {
    @inlinable public func asEquatable() -> AnyCPU65xx { asHashable() }

    @inlinable public static func == (lhs: CPU65xx, rhs: CPU65xx) -> Bool { lhs === rhs }
}

extension CPU65xx where Self: Hashable {
    @inlinable public func asHashable() -> AnyCPU65xx { AnyCPU65xx(self) }

    @inlinable public func getHash(into hasher: inout Hasher) { hash(into: &hasher) }
}

extension Array where Element: CPU65xx {
    @inlinable public static func == (lhs: [CPU65xx], rhs: [CPU65xx]) -> Bool { lhs.map({ $0.asHashable() }) == rhs.map({ $0.asHashable() }) }
}

extension Dictionary where Value: CPU65xx {
    @inlinable public static func == (lhs: [Key: CPU65xx], rhs: [Key: CPU65xx]) -> Bool { lhs.mapValues({ $0.asHashable() }) == rhs.mapValues({ $0.asHashable() }) }
}

extension Set where Element: CPU65xx & Hashable {
    @inlinable public static func == (lhs: Set<Element>, rhs: Set<Element>) -> Bool { lhs.map({ $0.asHashable() }) == rhs.map({ $0.asHashable() }) }
}
