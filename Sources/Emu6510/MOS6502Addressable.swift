/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Emu6510
 *    FILENAME: MOS6502Memory.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/17/21
 *
 * Copyright © 2021 Galen Rhodes. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this
 * permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *//******************************************************************************************************************************************************************************/

import Foundation
import CoreFoundation
import Rubicon

public let SixtyFourK: Int = 0x10000

open class MOS6502Addressable: BidirectionalCollection, Equatable, Hashable {
    public typealias Element = UInt8
    public typealias Index = Int
    public typealias SubSequence = MOS6502Addressable
    public typealias Indices = DefaultIndices<MOS6502Addressable>

    public fileprivate(set) var startIndex: Index = 0
    public fileprivate(set) var endIndex:   Index = SixtyFourK

    open var memoryRange: Range<Index> { (startIndex ..< endIndex) }

    public init(start: Index, count: Int) {
        let end = (start + count)
        guard start >= 0 else { fatalError("Start index is out of range: \(start) < 0") }
        guard start <= (SixtyFourK - 1) else { fatalError("Start index is out of range: \(start) >= \(SixtyFourK)") }
        guard count > 0 else { fatalError("Count is out of range: \(count) <= 0") }
        guard end <= SixtyFourK else { fatalError("Count is out of range: start (\(start)) + count (\(count)) = \(end) > \(SixtyFourK)") }

        startIndex = start
        endIndex = end
    }

    open func index(before i: Index) -> Index { ((i > startIndex) ? (i - 1) : (endIndex - 1)) }

    open func index(after i: Index) -> Index { (((i + 1) < endIndex) ? (i + 1) : startIndex) }

    open func getWord(address: UInt16) -> UInt16 { (UInt16(self[address]) | (UInt16(self[address + 1]) << 8)) }

    open subscript(position: Index) -> UInt8 {
        get { fatalError("Not Implemented") }
        set { fatalError("Not Implemented") }
    }

    open subscript(address: UInt16) -> UInt8 {
        get {
            let idx: Index = numericCast(address)
            return self[idx]
        }
        set {
            let idx: Index = numericCast(address)
            self[idx] = newValue
        }
    }

    public subscript(bounds: Range<Index>) -> SubSequence {
        guard bounds.isInside(memoryRange) else { fatalError("Range is out of bounds.") }
        return MOS6510MemorySlice(master: self, range: bounds)
    }

    public static func == (lhs: MOS6502Addressable, rhs: MOS6502Addressable) -> Bool {
        guard lhs.memoryRange == rhs.memoryRange else { return false }
        for i in (lhs.memoryRange) { guard lhs[i] == rhs[i] else { return false } }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(startIndex)
        hasher.combine(endIndex)
        for i in self { hasher.combine(i) }
    }

    @discardableResult func testIndex(position: Index) -> Index {
        guard position >= startIndex && position < endIndex else { fatalError("Index out of bounds.") }
        return position
    }
}

fileprivate class MOS6510MemorySlice: MOS6502Addressable {
    let master: MOS6502Addressable

    public init(master: MOS6502Addressable, range: Range<Index>) {
        self.master = master
        super.init(start: range.lowerBound, count: range.count)
    }

    override subscript(position: Index) -> UInt8 {
        get { master[position] }
        set { master[position] = newValue }
    }
}

open class MOS6502Ram: MOS6502Addressable {
    fileprivate lazy var memory: UnsafeMutablePointer<UInt8> = createBuffer()

    public override init(start: Index, count: Int) {
        super.init(start: start, count: count)
    }

    deinit {
        memory.deallocate()
    }

    open func load(fromFile filename: String) throws -> Int {
        try load(fromURL: URL(fileURLWithPath: filename, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)))
    }

    open func load(fromURL url: URL) throws -> Int {
        load(fromData: try Data(contentsOf: url, options: .mappedIfSafe))
    }

    open func load(fromData data: Data) -> Int {
        let acc = Swift.min(count, data.count)
        return data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> Int in
            guard let p = raw.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            memory.assign(from: p, count: acc)
            return acc
        }
    }

    open func save(toFile filename: String) throws -> Int {
        try save(toURL: URL(fileURLWithPath: filename, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)))
    }

    open func save(toURL url: URL) throws -> Int {
        var data: Data = Data()
        save(toData: &data)
        try data.write(to: url)
        return data.count
    }

    open func save(toData data: inout Data) {
        data.removeAll()
        data.append(memory, count: count)
    }

    open override subscript(position: Index) -> UInt8 {
        get { memory[testIndex(position: position) - startIndex] }
        set { memory[testIndex(position: position) - startIndex] = newValue }
    }

    private func createBuffer() -> UnsafeMutablePointer<UInt8> {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        buffer.initialize(repeating: 0, count: count)
        return buffer
    }
}

open class MOS6502Rom: MOS6502Ram {

    public override init(start: Index, count: Int) {
        super.init(start: start, count: count)
    }

    open override subscript(position: Index) -> UInt8 {
        get { super[position] }
        set {}
    }
}
