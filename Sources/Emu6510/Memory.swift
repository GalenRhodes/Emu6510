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

public protocol RandomAccessMemory {

    var readOnly:        Bool { get }
    var startingAddress: UInt16 { get }
    var endingAddress:   UInt16 { get }
    var size:            Int { get }

    func load(from data: UnsafeMutablePointer<UInt8>, offset: UInt16, length: Int) -> Int

    func load(to data: UnsafeMutablePointer<UInt8>, offset: UInt16, length: Int) -> Int

    subscript(_ address: UInt16) -> UInt8 { get set }
}

open class RAM: RandomAccessMemory {

    public let readOnly:        Bool
    public let startingAddress: UInt16
    public let endingAddress:   UInt16
    public let size:            Int

    let data: UnsafeMutablePointer<UInt8>

    init(readOnly: Bool, start: UInt16, end: UInt16) {
        guard start <= end else { fatalError("Starting address must be less than or equal to the ending address.") }
        self.readOnly = readOnly
        startingAddress = start
        endingAddress = end
        size = Int((end - start) + 1)
        data = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        data.initialize(repeating: 0, count: size)
    }

    public convenience init(start: UInt16, end: UInt16) {
        self.init(readOnly: false, start: start, end: end)
    }

    deinit {
        data.deinitialize(count: size)
        data.deallocate()
    }

    open func load(from data: UnsafeMutablePointer<UInt8>, offset: UInt16 = 0, length: Int) -> Int {
        guard offset <= size else { return 0 }
        let len: Int = min((size - Int(offset)), length)
        if len > 0 { (self.data + Int(offset)).moveAssign(from: data, count: len) }
        return len
    }

    open func load(to data: UnsafeMutablePointer<UInt8>, offset: UInt16, length: Int) -> Int {
        guard offset <= size else { return 0 }
        let len: Int = min((size - Int(offset)), length)
        if len > 0 { data.moveAssign(from: (self.data + Int(offset)), count: len) }
        return len
    }

    open subscript(_ address: UInt16) -> UInt8 {
        get {
            guard address >= startingAddress && address <= endingAddress else { return 0 }
            return data[Int(address - startingAddress)]
        }
        set {
            if !readOnly && address >= startingAddress && address <= endingAddress {
                data[Int(address - startingAddress)] = newValue
            }
        }
    }
}

open class ROM: RAM {
    public convenience init(start: UInt16, end: UInt16) {
        self.init(readOnly: true, start: start, end: end)
    }
}
