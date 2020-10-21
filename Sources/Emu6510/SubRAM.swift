/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: SubRAM.swift
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

public class SubRAM: RandomAccessMemory, Hashable, RandomAccessCollection {

    public typealias Element = UInt8
    public typealias Index = Int
    public typealias Indices = Range<Index>
    public typealias SubSequence = AnyRandomAccessMemory

    open var startAddress: Int
    open var endAddress:   Int

    @inlinable open var readOnly:   Bool { ram.readOnly }
    @inlinable open var startIndex: Int { startAddress }
    @inlinable open var endIndex:   Int { endAddress }

    @usableFromInline let ram: RandomAccessMemory

    @usableFromInline init(_ mainRam: RandomAccessMemory, start: Int, end: Int) {
        guard start < end else { fatalError("Start address must be less than end address.") }
        guard start >= mainRam.startAddress && start < mainRam.endAddress && end <= mainRam.endAddress else { fatalError("Invalid start and end address.") }

        ram = mainRam
        startAddress = start
        endAddress = end
    }

    @inlinable open func load(from data: UnsafePointer<UInt8>, offset: Int, count: Int) -> Int { ram.load(from: data, offset: (startAddress - ram.startAddress) + offset, count: count) }

    @inlinable open func load(to data: UnsafeMutablePointer<UInt8>, offset: Int, count: Int) -> Int { ram.load(to: data, offset: (startAddress - ram.startAddress) + offset, count: count) }

    @inlinable open subscript(addr: Int) -> UInt8 {
        get { ram[addr] }
        set { ram[addr] = newValue }
    }

    @inlinable open subscript(bounds: Range<Index>) -> SubSequence { AnyRandomAccessMemory(SubRAM(ram, start: bounds.lowerBound, end: bounds.upperBound)) }

    @inlinable open func hash(into hasher: inout Hasher) { ram.getHash(into: &hasher) }

    @inlinable public static func == (lhs: SubRAM, rhs: SubRAM) -> Bool { lhs === rhs || (lhs.ram.isEqualTo(rhs.ram) && lhs.startAddress == rhs.startAddress && lhs.endAddress == rhs.endAddress) }
}
