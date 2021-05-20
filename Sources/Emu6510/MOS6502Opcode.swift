/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Emu6510
 *    FILENAME: MOS6502Opcode.swift
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

open class MOS6502Opcode: Hashable, Equatable {
    public let opcode:         UInt8
    public let mnemonic:       MOS6502Mnemonic
    public let addressingMode: MOS6502AddressingMode
    public var bytes:          UInt8 { addressingMode.bytes }
    public let cycles:         UInt8
    public let plus1:          Bool
    public let affectedFlags:  Set<MOS6502Flag>

    public init(opcode: UInt8, mnemonic: MOS6502Mnemonic, addressingMode: MOS6502AddressingMode, cycles: UInt8, plus1: Bool, illegal: Bool, affectedFlags: [MOS6502Flag]) {
        self.opcode = opcode
        self.mnemonic = mnemonic
        self.addressingMode = addressingMode
        self.cycles = cycles
        self.plus1 = plus1
        self.affectedFlags = Set<MOS6502Flag>(affectedFlags)
    }

    open func hash(into hasher: inout Hasher) {
        hasher.combine(opcode)
        hasher.combine(mnemonic)
        hasher.combine(addressingMode)
        hasher.combine(cycles)
        hasher.combine(plus1)
        hasher.combine(affectedFlags)
    }

    public static func == (lhs: MOS6502Opcode, rhs: MOS6502Opcode) -> Bool {
        lhs.opcode == rhs.opcode && lhs.mnemonic == rhs.mnemonic && lhs.addressingMode == rhs.addressingMode && lhs.cycles == rhs.cycles && lhs.plus1 == rhs.plus1 && lhs.affectedFlags == rhs.affectedFlags
    }
}
