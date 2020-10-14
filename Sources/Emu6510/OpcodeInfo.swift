/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: OpcodeInfo.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/24/20
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

public class OpcodeInfo: Equatable, Comparable, Hashable {
    public let opcode:         UInt8
    public let affectedFlags:  UInt8
    public let isInvalid:      Bool
    public let mayBePenalty:   Bool
    public let mnemonic:       String
    public let addressingMode: AddressModes
    public let cycleCount:     UInt64

    public init(opcode: UInt8, mnemonic: String, addrMode: AddressModes, isInvalid: Bool = false, cycleCount: UInt8, penalty: Bool, affectedFlags: [ProcessorFlags] = []) {
        self.opcode = opcode
        self.mnemonic = mnemonic
        self.addressingMode = addrMode
        self.cycleCount = UInt64(cycleCount)
        self.isInvalid = isInvalid
        self.mayBePenalty = penalty

        var af: UInt8 = 0
        for f: ProcessorFlags in affectedFlags { af |= f.rawValue }
        self.affectedFlags = af
    }

    public func ifAffectsFlag(flag: ProcessorFlags, _ block: () -> Void) { if (affectedFlags & flag.rawValue) == flag.rawValue { block() }  }

    public static func == (lhs: OpcodeInfo, rhs: OpcodeInfo) -> Bool     { lhs.opcode == rhs.opcode                                         }

    public static func < (lhs: OpcodeInfo, rhs: OpcodeInfo) -> Bool      { lhs.opcode < rhs.opcode                                          }

    public func hash(into hasher: inout Hasher)                          { hasher.combine(opcode)                                           }
}

let XXXXXXX: [ProcessorFlags] = []
let ______C: [ProcessorFlags] = [ .Carry, ]
let ___D___: [ProcessorFlags] = [ .Decimal, ]
let _O_____: [ProcessorFlags] = [ .Overflow, ]
let ____I__: [ProcessorFlags] = [ .Interrupt, ]
let N____Z_: [ProcessorFlags] = [ .Zero, .Negative, ]
let N____ZC: [ProcessorFlags] = [ .Carry, .Zero, .Negative, ]
let NO___Z_: [ProcessorFlags] = [ .Zero, .Overflow, .Negative, ]
let NO___ZC: [ProcessorFlags] = [ .Carry, .Zero, .Overflow, .Negative, ]
let NOBDIZC: [ProcessorFlags] = [ .Carry, .Zero, .Interrupt, .Decimal, .Break, .Overflow, .Negative, ]
