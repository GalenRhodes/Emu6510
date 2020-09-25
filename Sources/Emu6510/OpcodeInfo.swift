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

public class OpcodeInfo: Equatable {
    public let opcode:         UInt8
    public let byteCount:      UInt8
    public let affectedFlags:  UInt8
    public let mnemonic:       String
    public let addressingMode: AddressModes
    public let cycleCount:     [UInt8]

    public init(opcode: UInt8, mnemonic: String, addrMode: AddressModes, byteCount: UInt8, cycleCount: [UInt8], affectedFlags: [ProcessorFlags]) {
        self.opcode = opcode
        self.byteCount = byteCount
        self.mnemonic = mnemonic
        self.addressingMode = addrMode
        self.cycleCount = cycleCount

        var af: UInt8 = 0
        for f: ProcessorFlags in affectedFlags { af = af | f.rawValue }
        self.affectedFlags = af
    }

    public static func == (lhs: OpcodeInfo, rhs: OpcodeInfo) -> Bool { lhs.opcode == rhs.opcode }
}

public let Emu6510Opcodes: [UInt8: OpcodeInfo] = [
    0x69: OpcodeInfo(opcode: 0x69, mnemonic: "ADC", addrMode: .IMM, byteCount: 2, cycleCount: [ 2 ], affectedFlags: [ .Carry, .Zero, .Overflow, .Negative, ]),
    0x65: OpcodeInfo(opcode: 0x65, mnemonic: "ADC", addrMode: .ZP, byteCount: 2, cycleCount: [ 3 ], affectedFlags: [ .Carry, .Zero, .Overflow, .Negative, ]),
    0x75: OpcodeInfo(opcode: 0x75, mnemonic: "ADC", addrMode: .ZPX, byteCount: 2, cycleCount: [ 4 ], affectedFlags: [ .Carry, .Zero, .Overflow, .Negative, ]),
    0x6d: OpcodeInfo(opcode: 0x6d, mnemonic: "ADC", addrMode: .ABS, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Carry, .Zero, .Overflow, .Negative, ]),
    0x7d: OpcodeInfo(opcode: 0x7d, mnemonic: "ADC", addrMode: .ABSX, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Carry, .Zero, .Overflow, .Negative, ]),
    0x79: OpcodeInfo(opcode: 0x79, mnemonic: "ADC", addrMode: .ABSY, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Carry, .Zero, .Overflow, .Negative, ]),
    0x61: OpcodeInfo(opcode: 0x61, mnemonic: "ADC", addrMode: .INDX, byteCount: 2, cycleCount: [ 6 ], affectedFlags: [ .Carry, .Zero, .Overflow, .Negative, ]),
    0x71: OpcodeInfo(opcode: 0x71, mnemonic: "ADC", addrMode: .INDY, byteCount: 2, cycleCount: [ 5 ], affectedFlags: [ .Carry, .Zero, .Overflow, .Negative, ]),
    0x29: OpcodeInfo(opcode: 0x29, mnemonic: "AND", addrMode: .IMM, byteCount: 2, cycleCount: [ 2 ], affectedFlags: [ .Zero, .Negative, ]),
    0x25: OpcodeInfo(opcode: 0x25, mnemonic: "AND", addrMode: .ZP, byteCount: 2, cycleCount: [ 3 ], affectedFlags: [ .Zero, .Negative, ]),
    0x35: OpcodeInfo(opcode: 0x35, mnemonic: "AND", addrMode: .ZPX, byteCount: 2, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0x2d: OpcodeInfo(opcode: 0x2d, mnemonic: "AND", addrMode: .ABS, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0x3d: OpcodeInfo(opcode: 0x3d, mnemonic: "AND", addrMode: .ABSX, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0x39: OpcodeInfo(opcode: 0x39, mnemonic: "AND", addrMode: .ABSY, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0x21: OpcodeInfo(opcode: 0x21, mnemonic: "AND", addrMode: .INDX, byteCount: 2, cycleCount: [ 6 ], affectedFlags: [ .Zero, .Negative, ]),
    0x31: OpcodeInfo(opcode: 0x31, mnemonic: "AND", addrMode: .INDY, byteCount: 2, cycleCount: [ 5 ], affectedFlags: [ .Zero, .Negative, ]),
    0x0a: OpcodeInfo(opcode: 0x0a, mnemonic: "ASL", addrMode: .ACC, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x06: OpcodeInfo(opcode: 0x06, mnemonic: "ASL", addrMode: .ZP, byteCount: 2, cycleCount: [ 5 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x16: OpcodeInfo(opcode: 0x16, mnemonic: "ASL", addrMode: .ZPX, byteCount: 2, cycleCount: [ 6 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x0e: OpcodeInfo(opcode: 0x0e, mnemonic: "ASL", addrMode: .ABS, byteCount: 3, cycleCount: [ 6 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x1e: OpcodeInfo(opcode: 0x1e, mnemonic: "ASL", addrMode: .ABSX, byteCount: 3, cycleCount: [ 7 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x90: OpcodeInfo(opcode: 0x90, mnemonic: "BCC", addrMode: .REL, byteCount: 2, cycleCount: [ 2, 3 ], affectedFlags: []),
    0xB0: OpcodeInfo(opcode: 0xB0, mnemonic: "BCS", addrMode: .REL, byteCount: 2, cycleCount: [ 2, 3 ], affectedFlags: []),
    0xF0: OpcodeInfo(opcode: 0xF0, mnemonic: "BEQ", addrMode: .REL, byteCount: 2, cycleCount: [ 2, 3 ], affectedFlags: []),
    0x30: OpcodeInfo(opcode: 0x30, mnemonic: "BMI", addrMode: .REL, byteCount: 2, cycleCount: [ 2, 3 ], affectedFlags: []),
    0xD0: OpcodeInfo(opcode: 0xD0, mnemonic: "BNE", addrMode: .REL, byteCount: 2, cycleCount: [ 2, 3 ], affectedFlags: []),
    0x10: OpcodeInfo(opcode: 0x10, mnemonic: "BPL", addrMode: .REL, byteCount: 2, cycleCount: [ 2, 3 ], affectedFlags: []),
    0x50: OpcodeInfo(opcode: 0x50, mnemonic: "BVC", addrMode: .REL, byteCount: 2, cycleCount: [ 2, 3 ], affectedFlags: []),
    0x70: OpcodeInfo(opcode: 0x70, mnemonic: "BVS", addrMode: .REL, byteCount: 2, cycleCount: [ 2, 3 ], affectedFlags: []),
    0x24: OpcodeInfo(opcode: 0x24, mnemonic: "BIT", addrMode: .ZP, byteCount: 2, cycleCount: [ 3 ], affectedFlags: [ .Zero, .Overflow, .Negative, ]),
    0x2c: OpcodeInfo(opcode: 0x2c, mnemonic: "BIT", addrMode: .ABS, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Overflow, .Negative, ]),
    0x00: OpcodeInfo(opcode: 0x00, mnemonic: "BRK", addrMode: .IMP, byteCount: 1, cycleCount: [ 7 ], affectedFlags: []),
    0x18: OpcodeInfo(opcode: 0x18, mnemonic: "CLC", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Carry, ]),
    0xd8: OpcodeInfo(opcode: 0xd8, mnemonic: "CLD", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Decimal, ]),
    0x58: OpcodeInfo(opcode: 0x58, mnemonic: "CLI", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Interrupt, ]),
    0xb8: OpcodeInfo(opcode: 0xb8, mnemonic: "CLV", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Overflow, ]),
    0xea: OpcodeInfo(opcode: 0xea, mnemonic: "NOP", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: []),
    0x48: OpcodeInfo(opcode: 0x48, mnemonic: "PHA", addrMode: .IMP, byteCount: 1, cycleCount: [ 3 ], affectedFlags: []),
    0x68: OpcodeInfo(opcode: 0x68, mnemonic: "PLA", addrMode: .IMP, byteCount: 1, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0x08: OpcodeInfo(opcode: 0x08, mnemonic: "PHP", addrMode: .IMP, byteCount: 1, cycleCount: [ 3 ], affectedFlags: []),
    0x28: OpcodeInfo(opcode: 0x28, mnemonic: "PLP", addrMode: .IMP, byteCount: 1, cycleCount: [ 4 ], affectedFlags: [ .Carry, .Zero, .Interrupt, .Decimal, .Break, .Overflow, .Negative, ]),
    0x40: OpcodeInfo(opcode: 0x40, mnemonic: "RTI", addrMode: .IMP, byteCount: 1, cycleCount: [ 6 ], affectedFlags: []),
    0x60: OpcodeInfo(opcode: 0x60, mnemonic: "RTS", addrMode: .IMP, byteCount: 1, cycleCount: [ 6 ], affectedFlags: []),
    0x38: OpcodeInfo(opcode: 0x38, mnemonic: "SEC", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Carry, ]),
    0xf8: OpcodeInfo(opcode: 0xf8, mnemonic: "SED", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Decimal, ]),
    0x78: OpcodeInfo(opcode: 0x78, mnemonic: "SEI", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Interrupt, ]),
    0xaa: OpcodeInfo(opcode: 0xaa, mnemonic: "TAX", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Zero, .Negative, ]),
    0x8a: OpcodeInfo(opcode: 0x8a, mnemonic: "TXA", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Zero, .Negative, ]),
    0xa8: OpcodeInfo(opcode: 0xa8, mnemonic: "TAY", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Zero, .Negative, ]),
    0x98: OpcodeInfo(opcode: 0x98, mnemonic: "TYA", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Zero, .Negative, ]),
    0xba: OpcodeInfo(opcode: 0xba, mnemonic: "TSX", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Zero, .Negative, ]),
    0x9a: OpcodeInfo(opcode: 0x9a, mnemonic: "TXS", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: []),
    0xc9: OpcodeInfo(opcode: 0xc9, mnemonic: "CMP", addrMode: .IMM, byteCount: 2, cycleCount: [ 2 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0xc5: OpcodeInfo(opcode: 0xc5, mnemonic: "CMP", addrMode: .ZP, byteCount: 2, cycleCount: [ 3 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0xd5: OpcodeInfo(opcode: 0xd5, mnemonic: "CMP", addrMode: .ZPX, byteCount: 2, cycleCount: [ 4 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0xcd: OpcodeInfo(opcode: 0xcd, mnemonic: "CMP", addrMode: .ABS, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0xdd: OpcodeInfo(opcode: 0xdd, mnemonic: "CMP", addrMode: .ABSX, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0xd9: OpcodeInfo(opcode: 0xd9, mnemonic: "CMP", addrMode: .ABSY, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0xc1: OpcodeInfo(opcode: 0xc1, mnemonic: "CMP", addrMode: .INDX, byteCount: 2, cycleCount: [ 6 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0xd1: OpcodeInfo(opcode: 0xd1, mnemonic: "CMP", addrMode: .INDY, byteCount: 2, cycleCount: [ 5 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0xe0: OpcodeInfo(opcode: 0xe0, mnemonic: "CPX", addrMode: .IMM, byteCount: 2, cycleCount: [ 2 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0xe4: OpcodeInfo(opcode: 0xe4, mnemonic: "CPX", addrMode: .ZP, byteCount: 2, cycleCount: [ 3 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0xec: OpcodeInfo(opcode: 0xec, mnemonic: "CPX", addrMode: .ABS, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0xc0: OpcodeInfo(opcode: 0xc0, mnemonic: "CPY", addrMode: .IMM, byteCount: 2, cycleCount: [ 2 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0xc4: OpcodeInfo(opcode: 0xc4, mnemonic: "CPY", addrMode: .ZP, byteCount: 2, cycleCount: [ 3 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0xcc: OpcodeInfo(opcode: 0xcc, mnemonic: "CPY", addrMode: .ABS, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0xc6: OpcodeInfo(opcode: 0xc6, mnemonic: "DEC", addrMode: .ZP, byteCount: 2, cycleCount: [ 5 ], affectedFlags: [ .Zero, .Negative, ]),
    0xd6: OpcodeInfo(opcode: 0xd6, mnemonic: "DEC", addrMode: .ZPX, byteCount: 2, cycleCount: [ 6 ], affectedFlags: [ .Zero, .Negative, ]),
    0xce: OpcodeInfo(opcode: 0xce, mnemonic: "DEC", addrMode: .ABS, byteCount: 3, cycleCount: [ 6 ], affectedFlags: [ .Zero, .Negative, ]),
    0xde: OpcodeInfo(opcode: 0xde, mnemonic: "DEC", addrMode: .ABSX, byteCount: 3, cycleCount: [ 7 ], affectedFlags: [ .Zero, .Negative, ]),
    0xca: OpcodeInfo(opcode: 0xca, mnemonic: "DEX", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Zero, .Negative, ]),
    0x88: OpcodeInfo(opcode: 0x88, mnemonic: "DEY", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Zero, .Negative, ]),
    0xe8: OpcodeInfo(opcode: 0xe8, mnemonic: "INX", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Zero, .Negative, ]),
    0xc8: OpcodeInfo(opcode: 0xc8, mnemonic: "INY", addrMode: .IMP, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Zero, .Negative, ]),
    0x49: OpcodeInfo(opcode: 0x49, mnemonic: "EOR", addrMode: .IMM, byteCount: 2, cycleCount: [ 2 ], affectedFlags: [ .Zero, .Negative, ]),
    0x45: OpcodeInfo(opcode: 0x45, mnemonic: "EOR", addrMode: .ZP, byteCount: 2, cycleCount: [ 3 ], affectedFlags: [ .Zero, .Negative, ]),
    0x55: OpcodeInfo(opcode: 0x55, mnemonic: "EOR", addrMode: .ZPX, byteCount: 2, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0x4d: OpcodeInfo(opcode: 0x4d, mnemonic: "EOR", addrMode: .ABS, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0x5d: OpcodeInfo(opcode: 0x5d, mnemonic: "EOR", addrMode: .ABSX, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0x59: OpcodeInfo(opcode: 0x59, mnemonic: "EOR", addrMode: .ABSY, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0x41: OpcodeInfo(opcode: 0x41, mnemonic: "EOR", addrMode: .INDX, byteCount: 2, cycleCount: [ 6 ], affectedFlags: [ .Zero, .Negative, ]),
    0x51: OpcodeInfo(opcode: 0x51, mnemonic: "EOR", addrMode: .INDY, byteCount: 2, cycleCount: [ 5 ], affectedFlags: [ .Zero, .Negative, ]),
    0xe6: OpcodeInfo(opcode: 0xe6, mnemonic: "INC", addrMode: .ZP, byteCount: 2, cycleCount: [ 5 ], affectedFlags: [ .Zero, .Negative, ]),
    0xf6: OpcodeInfo(opcode: 0xf6, mnemonic: "INC", addrMode: .ZPX, byteCount: 2, cycleCount: [ 6 ], affectedFlags: [ .Zero, .Negative, ]),
    0xee: OpcodeInfo(opcode: 0xee, mnemonic: "INC", addrMode: .ABS, byteCount: 3, cycleCount: [ 6 ], affectedFlags: [ .Zero, .Negative, ]),
    0xfe: OpcodeInfo(opcode: 0xfe, mnemonic: "INC", addrMode: .ABSX, byteCount: 3, cycleCount: [ 7 ], affectedFlags: [ .Zero, .Negative, ]),
    0x4c: OpcodeInfo(opcode: 0x4c, mnemonic: "JMP", addrMode: .ABS, byteCount: 3, cycleCount: [ 3 ], affectedFlags: []),
    0x6c: OpcodeInfo(opcode: 0x6c, mnemonic: "JMP", addrMode: .IND, byteCount: 3, cycleCount: [ 5 ], affectedFlags: []),
    0x20: OpcodeInfo(opcode: 0x20, mnemonic: "JSR", addrMode: .ABS, byteCount: 3, cycleCount: [ 6 ], affectedFlags: []),
    0xa9: OpcodeInfo(opcode: 0xa9, mnemonic: "LDA", addrMode: .IMM, byteCount: 2, cycleCount: [ 2 ], affectedFlags: [ .Zero, .Negative, ]),
    0xa5: OpcodeInfo(opcode: 0xa5, mnemonic: "LDA", addrMode: .ZP, byteCount: 2, cycleCount: [ 3 ], affectedFlags: [ .Zero, .Negative, ]),
    0xb5: OpcodeInfo(opcode: 0xb5, mnemonic: "LDA", addrMode: .ZPX, byteCount: 2, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0xad: OpcodeInfo(opcode: 0xad, mnemonic: "LDA", addrMode: .ABS, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0xbd: OpcodeInfo(opcode: 0xbd, mnemonic: "LDA", addrMode: .ABSX, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0xb9: OpcodeInfo(opcode: 0xb9, mnemonic: "LDA", addrMode: .ABSY, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0xa1: OpcodeInfo(opcode: 0xa1, mnemonic: "LDA", addrMode: .INDX, byteCount: 2, cycleCount: [ 6 ], affectedFlags: [ .Zero, .Negative, ]),
    0xb1: OpcodeInfo(opcode: 0xb1, mnemonic: "LDA", addrMode: .INDY, byteCount: 2, cycleCount: [ 5 ], affectedFlags: [ .Zero, .Negative, ]),
    0xa2: OpcodeInfo(opcode: 0xa2, mnemonic: "LDX", addrMode: .IMM, byteCount: 2, cycleCount: [ 2 ], affectedFlags: [ .Zero, .Negative, ]),
    0xa6: OpcodeInfo(opcode: 0xa6, mnemonic: "LDX", addrMode: .ZP, byteCount: 2, cycleCount: [ 3 ], affectedFlags: [ .Zero, .Negative, ]),
    0xb6: OpcodeInfo(opcode: 0xb6, mnemonic: "LDX", addrMode: .ZPY, byteCount: 2, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0xae: OpcodeInfo(opcode: 0xae, mnemonic: "LDX", addrMode: .ABS, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0xbe: OpcodeInfo(opcode: 0xbe, mnemonic: "LDX", addrMode: .ABSY, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0xa0: OpcodeInfo(opcode: 0xa0, mnemonic: "LDY", addrMode: .IMM, byteCount: 2, cycleCount: [ 2 ], affectedFlags: [ .Zero, .Negative, ]),
    0xa4: OpcodeInfo(opcode: 0xa4, mnemonic: "LDY", addrMode: .ZP, byteCount: 2, cycleCount: [ 3 ], affectedFlags: [ .Zero, .Negative, ]),
    0xb4: OpcodeInfo(opcode: 0xb4, mnemonic: "LDY", addrMode: .ZPX, byteCount: 2, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0xac: OpcodeInfo(opcode: 0xac, mnemonic: "LDY", addrMode: .ABS, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0xbc: OpcodeInfo(opcode: 0xbc, mnemonic: "LDY", addrMode: .ABSX, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0x4a: OpcodeInfo(opcode: 0x4a, mnemonic: "LSR", addrMode: .ACC, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x46: OpcodeInfo(opcode: 0x46, mnemonic: "LSR", addrMode: .ZP, byteCount: 2, cycleCount: [ 5 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x56: OpcodeInfo(opcode: 0x56, mnemonic: "LSR", addrMode: .ZPX, byteCount: 2, cycleCount: [ 6 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x4e: OpcodeInfo(opcode: 0x4e, mnemonic: "LSR", addrMode: .ABS, byteCount: 3, cycleCount: [ 6 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x5e: OpcodeInfo(opcode: 0x5e, mnemonic: "LSR", addrMode: .ABSX, byteCount: 3, cycleCount: [ 7 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x09: OpcodeInfo(opcode: 0x09, mnemonic: "ORA", addrMode: .IMM, byteCount: 2, cycleCount: [ 2 ], affectedFlags: [ .Zero, .Negative, ]),
    0x05: OpcodeInfo(opcode: 0x05, mnemonic: "ORA", addrMode: .ZP, byteCount: 2, cycleCount: [ 3 ], affectedFlags: [ .Zero, .Negative, ]),
    0x15: OpcodeInfo(opcode: 0x15, mnemonic: "ORA", addrMode: .ZPX, byteCount: 2, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0x0d: OpcodeInfo(opcode: 0x0d, mnemonic: "ORA", addrMode: .ABS, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0x1d: OpcodeInfo(opcode: 0x1d, mnemonic: "ORA", addrMode: .ABSX, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0x19: OpcodeInfo(opcode: 0x19, mnemonic: "ORA", addrMode: .ABSY, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Zero, .Negative, ]),
    0x01: OpcodeInfo(opcode: 0x01, mnemonic: "ORA", addrMode: .INDX, byteCount: 2, cycleCount: [ 6 ], affectedFlags: [ .Zero, .Negative, ]),
    0x11: OpcodeInfo(opcode: 0x11, mnemonic: "ORA", addrMode: .INDY, byteCount: 2, cycleCount: [ 5 ], affectedFlags: [ .Zero, .Negative, ]),
    0x2a: OpcodeInfo(opcode: 0x2a, mnemonic: "ROL", addrMode: .ACC, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x26: OpcodeInfo(opcode: 0x26, mnemonic: "ROL", addrMode: .ZP, byteCount: 2, cycleCount: [ 5 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x36: OpcodeInfo(opcode: 0x36, mnemonic: "ROL", addrMode: .ZPX, byteCount: 2, cycleCount: [ 6 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x2e: OpcodeInfo(opcode: 0x2e, mnemonic: "ROL", addrMode: .ABS, byteCount: 3, cycleCount: [ 6 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x3e: OpcodeInfo(opcode: 0x3e, mnemonic: "ROL", addrMode: .ABSX, byteCount: 3, cycleCount: [ 7 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x6a: OpcodeInfo(opcode: 0x6a, mnemonic: "ROR", addrMode: .ACC, byteCount: 1, cycleCount: [ 2 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x66: OpcodeInfo(opcode: 0x66, mnemonic: "ROR", addrMode: .ZP, byteCount: 2, cycleCount: [ 5 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x76: OpcodeInfo(opcode: 0x76, mnemonic: "ROR", addrMode: .ZPX, byteCount: 2, cycleCount: [ 6 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x7e: OpcodeInfo(opcode: 0x7e, mnemonic: "ROR", addrMode: .ABS, byteCount: 3, cycleCount: [ 6 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0x6e: OpcodeInfo(opcode: 0x6e, mnemonic: "ROR", addrMode: .ABSX, byteCount: 3, cycleCount: [ 7 ], affectedFlags: [ .Carry, .Zero, .Negative, ]),
    0xe9: OpcodeInfo(opcode: 0xe9, mnemonic: "SBC", addrMode: .IMM, byteCount: 2, cycleCount: [ 2 ], affectedFlags: [ .Carry, .Zero, .Overflow, .Negative, ]),
    0xe5: OpcodeInfo(opcode: 0xe5, mnemonic: "SBC", addrMode: .ZP, byteCount: 2, cycleCount: [ 3 ], affectedFlags: [ .Carry, .Zero, .Overflow, .Negative, ]),
    0xf5: OpcodeInfo(opcode: 0xf5, mnemonic: "SBC", addrMode: .ZPX, byteCount: 2, cycleCount: [ 4 ], affectedFlags: [ .Carry, .Zero, .Overflow, .Negative, ]),
    0xed: OpcodeInfo(opcode: 0xed, mnemonic: "SBC", addrMode: .ABS, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Carry, .Zero, .Overflow, .Negative, ]),
    0xfd: OpcodeInfo(opcode: 0xfd, mnemonic: "SBC", addrMode: .ABSX, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Carry, .Zero, .Overflow, .Negative, ]),
    0xf9: OpcodeInfo(opcode: 0xf9, mnemonic: "SBC", addrMode: .ABSY, byteCount: 3, cycleCount: [ 4 ], affectedFlags: [ .Carry, .Zero, .Overflow, .Negative, ]),
    0xe1: OpcodeInfo(opcode: 0xe1, mnemonic: "SBC", addrMode: .INDX, byteCount: 2, cycleCount: [ 6 ], affectedFlags: [ .Carry, .Zero, .Overflow, .Negative, ]),
    0xf1: OpcodeInfo(opcode: 0xf1, mnemonic: "SBC", addrMode: .INDY, byteCount: 2, cycleCount: [ 5 ], affectedFlags: [ .Carry, .Zero, .Overflow, .Negative, ]),
    0x85: OpcodeInfo(opcode: 0x85, mnemonic: "STA", addrMode: .ZP, byteCount: 2, cycleCount: [ 3 ], affectedFlags: []),
    0x95: OpcodeInfo(opcode: 0x95, mnemonic: "STA", addrMode: .ZPX, byteCount: 2, cycleCount: [ 4 ], affectedFlags: []),
    0x8d: OpcodeInfo(opcode: 0x8d, mnemonic: "STA", addrMode: .ABS, byteCount: 3, cycleCount: [ 4 ], affectedFlags: []),
    0x9d: OpcodeInfo(opcode: 0x9d, mnemonic: "STA", addrMode: .ABSX, byteCount: 3, cycleCount: [ 5 ], affectedFlags: []),
    0x99: OpcodeInfo(opcode: 0x99, mnemonic: "STA", addrMode: .ABSY, byteCount: 3, cycleCount: [ 5 ], affectedFlags: []),
    0x81: OpcodeInfo(opcode: 0x81, mnemonic: "STA", addrMode: .INDX, byteCount: 2, cycleCount: [ 6 ], affectedFlags: []),
    0x91: OpcodeInfo(opcode: 0x91, mnemonic: "STA", addrMode: .INDY, byteCount: 2, cycleCount: [ 6 ], affectedFlags: []),
    0x86: OpcodeInfo(opcode: 0x86, mnemonic: "STX", addrMode: .ZP, byteCount: 2, cycleCount: [ 3 ], affectedFlags: []),
    0x96: OpcodeInfo(opcode: 0x96, mnemonic: "STX", addrMode: .ZPY, byteCount: 2, cycleCount: [ 4 ], affectedFlags: []),
    0x8e: OpcodeInfo(opcode: 0x8e, mnemonic: "STX", addrMode: .ABS, byteCount: 3, cycleCount: [ 4 ], affectedFlags: []),
    0x84: OpcodeInfo(opcode: 0x84, mnemonic: "STY", addrMode: .ZP, byteCount: 2, cycleCount: [ 3 ], affectedFlags: []),
    0x94: OpcodeInfo(opcode: 0x94, mnemonic: "STY", addrMode: .ZPX, byteCount: 2, cycleCount: [ 4 ], affectedFlags: []),
    0x8c: OpcodeInfo(opcode: 0x8c, mnemonic: "STY", addrMode: .ABS, byteCount: 3, cycleCount: [ 4 ], affectedFlags: []),
]
