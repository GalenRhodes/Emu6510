//
//  Emu6502.swift
//  Emu6502
//
//  Created by Galen Rhodes on 5/5/20.
//  Copyright © 2020 Project Galen. All rights reserved.
//

import Foundation
import Rubicon

///
/// Denotes which exact CPU from the MOS 6500 family is being emulated.
///
public enum MOS65xxFamily {
    case Mos6502
    case Mos6510
    case Mos8510
}

/// Denotes the interrupt type that the CPU received.
public enum InterruptType {
    /// Standard maskable interrupt.
    case IRQ
    /// Non-Maskable interrupt.
    case NMI
}

public let MaxPageCount: UInt16 = 256
public let ByteRange:    UInt16 = 256
public let AddressRange: UInt32 = UInt32(ByteRange * MaxPageCount)

public protocol AddressBusListener: AnyObject {
    var offset: UInt16 { get }
    var size:   UInt32 { get }

    subscript(address: UInt16) -> UInt8? { get set }
}

public extension AddressBusListener {
    func trueIndex(address: UInt16) -> UInt16? {
        guard address >= offset else { return nil }
        let _address: UInt16 = (address - offset)
        return ((_address < size) ? _address : nil)
    }
}

open class Memory: Hashable, AddressBusListener {
    public private(set) var offset: UInt16 = 0
    public var   size:       UInt32 { UInt32(pageCount * ByteRange) }
    public let   pageCount:  UInt16
    public let   isReadOnly: Bool
    internal var ramMemory:  [UInt8] = []

    public init(pageCount: UInt16, offset: UInt16, isReadOnly: Bool) {
        self.isReadOnly = isReadOnly
        self.offset = offset
        self.pageCount = min(pageCount, MaxPageCount)
        self.ramMemory = Array(repeating: 0, count: Int(self.size))
    }

    public subscript(address: UInt16) -> UInt8? {
        get {
            if let _address: UInt16 = trueIndex(address: address) { return ramMemory[Int(_address)] }
            else { return nil }
        }
        set {
            if !isReadOnly, let _address: UInt16 = trueIndex(address: address), let byte: UInt8 = newValue {
                ramMemory[Int(_address)] = byte
            }
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(pageCount)
        hasher.combine(ramMemory)
    }

    public static func == (lhs: Memory, rhs: Memory) -> Bool {
        ((lhs === rhs) || ((lhs.pageCount == rhs.pageCount) && (lhs.ramMemory == rhs.ramMemory)))
    }
}

open class RAMmemory: Memory {
    public init(pageCount: UInt16 = MaxPageCount, offset: UInt16 = 0) { super.init(pageCount: pageCount, offset: offset, isReadOnly: false) }
}

open class ROMmemory: Memory {
    public init(pageCount: UInt16, offset: UInt16 = 0) { super.init(pageCount: pageCount, offset: offset, isReadOnly: true) }
}
