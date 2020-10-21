/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: RAM.swift
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

@usableFromInline func copy(data: UnsafePointer<UInt8>, count: Int) -> UnsafeMutablePointer<UInt8> {
    let _data: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
    _data.initialize(from: data, count: count)
    return _data
}

open class RAM: RandomAccessMemory, Hashable, RandomAccessCollection {

    public typealias Element = UInt8
    public typealias Index = Int
    public typealias Indices = Range<Index>
    public typealias SubSequence = AnyRandomAccessMemory

    public let readOnly:     Bool
    public let startAddress: Int
    public let endAddress:   Int

    @usableFromInline let data: UnsafeMutablePointer<UInt8>

    @usableFromInline init(readOnly ro: Bool, start: Int, end: Int, data initData: UnsafePointer<UInt8>? = nil) {
        guard start <= end else { fatalError("Starting address must be less than or equal to the ending address.") }
        readOnly = ro
        startAddress = start
        endAddress = end

        let cc: Int = (end - start)

        if let initData: UnsafePointer<UInt8> = initData {
            data = copy(data: initData, count: cc)
        }
        else {
            data = UnsafeMutablePointer<UInt8>.allocate(capacity: cc)
            data.initialize(repeating: 0, count: cc)
        }
    }

    public convenience init(start: Int, end: Int) {
        guard end > start else { fatalError("Invalid arguments. End must be > start.") }
        self.init(readOnly: false, start: start, end: end)
    }

    public convenience init(start: Int, count: Int) {
        guard count >= 0 else { fatalError("Invalid arguments. Count must be >= 0.") }
        self.init(readOnly: false, start: start, end: start + count)
    }

    deinit {
        data.deinitialize(count: count)
        data.deallocate()
    }

    open func load(from data: UnsafePointer<UInt8>, offset: Int, count c: Int) -> Int {
        guard offset < self.count else { fatalError("Invalid offset") }
        guard c <= (self.count - offset) else { fatalError("Invalid count") }
        if c > 0 { memcpy((self.data + offset), data, c) }
        return c
    }

    open func load(to data: UnsafeMutablePointer<UInt8>, offset: Int, count c: Int) -> Int {
        guard offset < count else { fatalError("Invalid offset") }
        guard c <= (count - offset) else { fatalError("Invalid length") }
        if c > 0 { memcpy(data, (self.data + offset), c) }
        return c
    }

    @inlinable open subscript(position: Int) -> UInt8 {
        get {
            guard position >= startAddress && position < endAddress else { fatalError("Index out of bounds") }
            return data[(position - startAddress)]
        }
        set {
            guard position >= startAddress && position < endAddress else { fatalError("Index out of bounds") }
            if !readOnly { data[(position - startAddress)] = newValue }
        }
    }

    public static func == (lhs: RAM, rhs: RAM) -> Bool { lhs === rhs }
}
