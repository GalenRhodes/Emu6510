/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: AnyRandomAccessMemory.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 10/20/20
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

open class AnyRandomAccessMemory: RandomAccessMemory, Hashable, RandomAccessCollection {

    public typealias Element = UInt8
    public typealias Index = Int
    public typealias Indices = Range<Index>
    public typealias SubSequence = AnyRandomAccessMemory

    @usableFromInline var ram: RandomAccessMemory

    @inlinable open var readOnly:     Bool { ram.readOnly }
    @inlinable open var startAddress: Int { ram.startAddress }
    @inlinable open var endAddress:   Int { ram.endAddress }

    public init(_ ram: RandomAccessMemory) { self.ram = ram }

    @inlinable open func load(from data: UnsafePointer<UInt8>, offset: Int, count: Int) -> Int { ram.load(from: data, offset: offset, count: count) }

    @inlinable open func load(to data: UnsafeMutablePointer<UInt8>, offset: Int, count: Int) -> Int { ram.load(to: data, offset: offset, count: count) }

    @inlinable open subscript(addr: Int) -> UInt8 {
        get { ram[addr] }
        set { ram[addr] = newValue }
    }

    @inlinable open func hash(into hasher: inout Hasher) { ram.getHash(into: &hasher) }

    @inlinable public static func == (lhs: AnyRandomAccessMemory, rhs: AnyRandomAccessMemory) -> Bool { lhs.ram.isEqualTo(rhs.ram) }

    @inlinable open func asEquatable() -> AnyRandomAccessMemory { self }

    @inlinable open func asHashable() -> AnyRandomAccessMemory { self }

    @inlinable open func isEqualTo(_ other: RandomAccessMemory) -> Bool { ((self === other) || ((type(of: other) == AnyRandomAccessMemory.self) && (self == (other as! AnyRandomAccessMemory)))) }
}

