/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: Memory.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 10/2/20
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

public protocol RandomAccessMemory: AnyObject {

    var readOnly:     Bool { get }
    var startAddress: Int { get }
    var endAddress:   Int { get }
    var count:        Int { get }

    func load(from data: UnsafeMutablePointer<UInt8>, offset: UInt16, length: Int) -> Int

    func load(to data: UnsafeMutablePointer<UInt8>, offset: UInt16, length: Int) -> Int

    subscript(_ addr: Int) -> UInt8 { get set }

    func isEqualTo(_ other: RandomAccessMemory) -> Bool

    func asHashable() -> AnyRandomAccessMemory

    func getHash(into hasher: inout Hasher)
}

open class RAM: RandomAccessMemory {

    public let readOnly:     Bool
    public let startAddress: Int
    public let endAddress:   Int

    @inlinable public var count: Int { endAddress - startAddress }

    let data: UnsafeMutablePointer<UInt8>

    init(readOnly: Bool, start: Int, end: Int) {
        guard start <= end else { fatalError("Starting address must be less than or equal to the ending address.") }
        self.readOnly = readOnly
        startAddress = start
        endAddress = end
        data = UnsafeMutablePointer<UInt8>.allocate(capacity: end - start)
        data.initialize(repeating: 0, count: count)
    }

    public convenience init(start: Int, end: Int) {
        self.init(readOnly: false, start: start, end: end)
    }

    deinit {
        data.deinitialize(count: count)
        data.deallocate()
    }

    open func load(from data: UnsafeMutablePointer<UInt8>, offset: UInt16 = 0, length: Int) -> Int {
        guard offset <= count else { return 0 }
        let len: Int = min((count - Int(offset)), length)
        if len > 0 { (self.data + Int(offset)).moveAssign(from: data, count: len) }
        return len
    }

    open func load(to data: UnsafeMutablePointer<UInt8>, offset: UInt16, length: Int) -> Int {
        guard offset <= count else { return 0 }
        let len: Int = min((count - Int(offset)), length)
        if len > 0 { data.moveAssign(from: (self.data + Int(offset)), count: len) }
        return len
    }

    public subscript(position: Int) -> UInt8 {
        get {
            guard position >= startAddress && position < endAddress else { fatalError("Index out of bounds") }
            return data[(position - startAddress)]
        }
        set {
            guard position >= startAddress && position < endAddress else { fatalError("Index out of bounds") }
            if !readOnly { data[(position - startAddress)] = newValue }
        }
    }
}

open class ROM: RAM {
    public convenience init(start: Int, end: Int) {
        self.init(readOnly: true, start: start, end: end)
    }
}

open class AnyRandomAccessMemory: RandomAccessMemory, Hashable {
    @usableFromInline var ram: RandomAccessMemory

    @inlinable open var readOnly:     Bool { ram.readOnly }
    @inlinable open var startAddress: Int { ram.startAddress }
    @inlinable open var endAddress:   Int { ram.endAddress }
    @inlinable open var count:        Int { ram.count }

    public init(_ ram: RandomAccessMemory) { self.ram = ram }

    @inlinable open func load(from data: UnsafeMutablePointer<UInt8>, offset: UInt16, length: Int) -> Int { ram.load(from: data, offset: offset, length: length) }

    @inlinable open func load(to data: UnsafeMutablePointer<UInt8>, offset: UInt16, length: Int) -> Int { ram.load(to: data, offset: offset, length: length) }

    @inlinable open subscript(addr: Int) -> UInt8 {
        get { ram[addr] }
        set { ram[addr] = newValue }
    }

    @inlinable open func hash(into hasher: inout Hasher) { ram.getHash(into: &hasher) }

    @inlinable public static func == (lhs: AnyRandomAccessMemory, rhs: AnyRandomAccessMemory) -> Bool { lhs.ram.isEqualTo(rhs.ram) }

    @inlinable open func asHashable() -> AnyRandomAccessMemory { self }

    @inlinable open func isEqualTo(_ other: RandomAccessMemory) -> Bool { ((self === other) || ((type(of: other) == AnyRandomAccessMemory.self) && (self == (other as! AnyRandomAccessMemory)))) }
}

extension RandomAccessMemory where Self: Equatable {
    @inlinable public func asEquatable() -> AnyRandomAccessMemory { AnyRandomAccessMemory(self) }
}

extension RandomAccessMemory where Self: Hashable {
    @inlinable public func asHashable() -> AnyRandomAccessMemory { AnyRandomAccessMemory(self) }

    @inlinable public func getHash(into hasher: inout Hasher) { hash(into: &hasher) }
}

extension Array where Element: RandomAccessMemory {
    @inlinable public static func == (lhs: [RandomAccessMemory], rhs: [RandomAccessMemory]) -> Bool { lhs.map({ $0.asHashable() }) == rhs.map({ $0.asHashable() }) }
}

extension Dictionary where Value: RandomAccessMemory {
    @inlinable public static func == (lhs: [Key: RandomAccessMemory], rhs: [Key: RandomAccessMemory]) -> Bool { lhs.mapValues({ $0.asHashable() }) == rhs.mapValues({ $0.asHashable() }) }
}

extension Set where Element: RandomAccessMemory & Hashable {
    @inlinable public static func == (lhs: Set<Element>, rhs: Set<Element>) -> Bool { lhs.map({ $0.asHashable() }) == rhs.map({ $0.asHashable() }) }
}

extension RandomAccessMemory {
    @inlinable public subscript(_ zpAddr: UInt8) -> UInt8 {
        get { self[Int(zpAddr)] }
        set { self[Int(zpAddr)] = newValue }
    }
    @inlinable public subscript(_ addr: UInt16) -> UInt8 {
        get { self[Int(addr)] }
        set { self[Int(addr)] = newValue }
    }
}

