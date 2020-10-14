/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: AddressBuss.swift
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

public protocol AddressBuss {

    subscript(position: Int) -> UInt8 { get set }

    func isEqualTo(_ other: AddressBuss) -> Bool

    func asEquatable() -> AnyAddressBuss

    func getHash(into hasher: inout Hasher)
}

extension AddressBuss where Self: Equatable {
    @inlinable public func asEquatable() -> AnyAddressBuss { AnyAddressBuss(self) }

    @inlinable public func isEqualTo(_ other: AddressBuss) -> Bool { guard let other: Self = other as? Self else { return false }; return self == other }

    @inlinable public subscript(_ zpAddr: UInt8) -> UInt8 {
        get { self[Int(zpAddr)] }
        set { self[Int(zpAddr)] = newValue }
    }
    @inlinable public subscript(_ addr: UInt16) -> UInt8 {
        get { self[Int(addr)] }
        set { self[Int(addr)] = newValue }
    }
}

extension AddressBuss where Self: Hashable {
    @inlinable public func getHash(into hasher: inout Hasher) { self.hash(into: &hasher) }
}

public struct AnyAddressBuss: AddressBuss {
    @usableFromInline var addrBuss: AddressBuss

    public init(_ addrBuss: AddressBuss) { self.addrBuss = addrBuss }

    public subscript(position: Int) -> UInt8 {
        get { addrBuss[position] }
        set { addrBuss[position] = newValue }
    }
}

extension AnyAddressBuss: Equatable {
    public static func == (lhs: AnyAddressBuss, rhs: AnyAddressBuss) -> Bool { lhs.addrBuss.isEqualTo(rhs.addrBuss) }
}

extension AnyAddressBuss: Hashable {
    @inlinable public func hash(into hasher: inout Hasher) { addrBuss.getHash(into: &hasher) }
}

extension Array where Element: AddressBuss {
    @inlinable public static func == (lhs: [AddressBuss], rhs: [AddressBuss]) -> Bool { lhs.map({ $0.asEquatable() }) == rhs.map({ $0.asEquatable() }) }
}

extension Dictionary where Value: AddressBuss {
    @inlinable public static func == (lhs: [Key: AddressBuss], rhs: [Key: AddressBuss]) -> Bool { lhs.mapValues({ $0.asEquatable() }) == rhs.mapValues({ $0.asEquatable() }) }
}