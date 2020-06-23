/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: CPU65xx.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/5/20
 *
 * The website http://www.emulator101.com/6502-emulator.html was used as
 * a starting point for this project.
 *
 * Copyright © 2020 Project Galen. All rights reserved.
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
import Rubicon

/*===============================================================================================================================*/
/// Denotes which exact CPU from the MOS 6500 family is being emulated.
///
public enum MOS65xxFamily {
    case Mos6502
    case Mos6510
    case Mos8510
}

/*===============================================================================================================================*/
/// The clock speed of most implementations back in the day was based on the video hardware which was based on the two television
/// standards at the time - NTSC and PAL. Below are the two clock speeds for the Commodore 64 and Commodore 128 (running is 40
/// column mode).
///
public enum VideoStandard: UInt32 {
    case C64_NTSC = 1_022_727
    case C64_PAL  = 985_248
}

infix operator &?: ComparisonPrecedence
infix operator &!: ComparisonPrecedence

public enum Bits8: UInt8 {
    case b0 = 1
    case b1 = 2
    case b2 = 4
    case b3 = 8
    case b4 = 16
    case b5 = 32
    case b6 = 64
    case b7 = 128

    @inlinable public static func & <T: BinaryInteger>(lhs: T, rhs: Bits8) -> T { (lhs & T(rhs.rawValue)) }

    @inlinable public static func | <T: BinaryInteger>(lhs: T, rhs: Bits8) -> T { (lhs | T(rhs.rawValue)) }

    @inlinable public static prefix func ~ (oper: Bits8) -> UInt8 { (~oper.rawValue) }

    @inlinable public static func |= <T: BinaryInteger>(lhs: inout T, rhs: Bits8) { lhs |= T(rhs.rawValue) }

    @inlinable public static func &= <T: BinaryInteger>(lhs: inout T, rhs: Bits8) { lhs &= T(rhs.rawValue) }

    @inlinable public static func &! <T: BinaryInteger>(lhs: T, rhs: Bits8) -> Bool { let v: T = T(rhs.rawValue); return ((lhs & v) == v) }
}

/*===============================================================================================================================*/
/// Denotes the interrupt type that the CPU received.
///
public enum InterruptType {
    /*===========================================================================================================================*/
    /// Standard maskable interrupt.
    ///
    case IRQ
    /*===========================================================================================================================*/
    /// Non-Maskable interrupt.
    ///
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
