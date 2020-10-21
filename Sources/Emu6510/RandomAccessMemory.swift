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

    func load(from data: UnsafePointer<UInt8>, offset: Int, count: Int) -> Int

    func load(to data: UnsafeMutablePointer<UInt8>, offset: Int, count: Int) -> Int

    subscript(_ addr: Int) -> UInt8 { get set }
    subscript(_ addr: UInt8) -> UInt8 { get set }
    subscript(_ addr: UInt16) -> UInt8 { get set }

    func isEqualTo(_ other: RandomAccessMemory) -> Bool

    func asHashable() -> AnyRandomAccessMemory

    func asEquatable() -> AnyRandomAccessMemory

    func getHash(into hasher: inout Hasher)
}

extension RandomAccessMemory {
    @inlinable public func load(from data: UnsafePointer<UInt8>, count: Int) -> Int { load(from: data, offset: 0, count: count) }

    @inlinable public func load(to data: UnsafeMutablePointer<UInt8>, count: Int) -> Int { load(to: data, offset: 0, count: count) }

    @inlinable public subscript(_ addr: UInt8) -> UInt8 {
        get { self[Int(addr)] }
        set { self[Int(addr)] = newValue }
    }
    @inlinable public subscript(_ addr: UInt16) -> UInt8 {
        get { self[Int(addr)] }
        set { self[Int(addr)] = newValue }
    }
}

extension RandomAccessMemory where Self: RandomAccessCollection {
    @inlinable public var count:      Int { endAddress - startAddress }
    @inlinable public var startIndex: Int { (startAddress) }
    @inlinable public var endIndex:   Int { (endAddress) }

    @inlinable public subscript(bounds: Range<Int>) -> AnyRandomAccessMemory {
        guard bounds.startIndex < bounds.endIndex && bounds.startIndex >= startAddress && bounds.startIndex < endAddress && bounds.endIndex <= endAddress else { fatalError("Invalid range.") }
        return AnyRandomAccessMemory(SubRAM(self, start: bounds.lowerBound, end: bounds.upperBound))
    }
}

extension RandomAccessMemory where Self: Equatable {
    @inlinable public func asEquatable() -> AnyRandomAccessMemory { AnyRandomAccessMemory(self) }

    @inlinable public func isEqualTo(_ other: RandomAccessMemory) -> Bool { self == (other as? Self) }
}

extension RandomAccessMemory where Self: Hashable {
    @inlinable public func asHashable() -> AnyRandomAccessMemory { asEquatable() }

    @inlinable public func getHash(into hasher: inout Hasher) { hash(into: &hasher) }

    @inlinable public func hash(into hasher: inout Hasher) {
        hasher.combine(startAddress)
        hasher.combine(endAddress)
        hasher.combine(readOnly)
    }
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
