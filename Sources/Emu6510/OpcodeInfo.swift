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

    public func ifAffectsFlag(flag: ProcessorFlags, _ block: () -> Void) {
        if (affectedFlags & flag.rawValue) == flag.rawValue { block() }
    }

    public static func == (lhs: OpcodeInfo, rhs: OpcodeInfo) -> Bool { lhs.opcode == rhs.opcode }

    public static func < (lhs: OpcodeInfo, rhs: OpcodeInfo) -> Bool { lhs.opcode < rhs.opcode }

    public func hash(into hasher: inout Hasher) { hasher.combine(opcode) }
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

//@f:0
public let Emu6510Opcodes: [OpcodeInfo] = [
    OpcodeInfo(opcode: 0x00, mnemonic: "BRK", addrMode: .IMP, isInvalid: false, cycleCount: 7, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x01, mnemonic: "ORA", addrMode: .INX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x02, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x03, mnemonic: "SLO", addrMode: .INX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x04, mnemonic: "NOP", addrMode: .ZPG, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x05, mnemonic: "ORA", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x06, mnemonic: "ASL", addrMode: .ZPG, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x07, mnemonic: "SLO", addrMode: .ZPG, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x08, mnemonic: "PHP", addrMode: .IMP, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x09, mnemonic: "ORA", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x0a, mnemonic: "ASL", addrMode: .ACC, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x0b, mnemonic: "ANC", addrMode: .IMM, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x0c, mnemonic: "NOP", addrMode: .ABS, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x0d, mnemonic: "ORA", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x0e, mnemonic: "ASL", addrMode: .ABS, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x0f, mnemonic: "SLO", addrMode: .ABS, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x10, mnemonic: "BPL", addrMode: .REL, isInvalid: false, cycleCount: 2, penalty: true,  affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x11, mnemonic: "ORA", addrMode: .INY, isInvalid: false, cycleCount: 5, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x12, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x13, mnemonic: "SLO", addrMode: .INY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x14, mnemonic: "NOP", addrMode: .ZPX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x15, mnemonic: "ORA", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x16, mnemonic: "ASL", addrMode: .ZPX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x17, mnemonic: "SLO", addrMode: .ZPX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x18, mnemonic: "CLC", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: ______C),
    OpcodeInfo(opcode: 0x19, mnemonic: "ORA", addrMode: .ABY, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x1a, mnemonic: "NOP", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x1b, mnemonic: "SLO", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x1c, mnemonic: "NOP", addrMode: .ABX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x1d, mnemonic: "ORA", addrMode: .ABX, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x1e, mnemonic: "ASL", addrMode: .ABX, isInvalid: false, cycleCount: 7, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x1f, mnemonic: "SLO", addrMode: .ABX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x20, mnemonic: "JSR", addrMode: .ABS, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x21, mnemonic: "AND", addrMode: .INX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x22, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x23, mnemonic: "RLA", addrMode: .INX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x24, mnemonic: "BIT", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: NO___Z_),
    OpcodeInfo(opcode: 0x25, mnemonic: "AND", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x26, mnemonic: "ROL", addrMode: .ZPG, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x27, mnemonic: "RLA", addrMode: .ZPG, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x28, mnemonic: "PLP", addrMode: .IMP, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: NOBDIZC),
    OpcodeInfo(opcode: 0x29, mnemonic: "AND", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x2a, mnemonic: "ROL", addrMode: .ACC, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x2b, mnemonic: "ANC", addrMode: .IMM, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x2c, mnemonic: "BIT", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: NO___Z_),
    OpcodeInfo(opcode: 0x2d, mnemonic: "AND", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x2e, mnemonic: "ROL", addrMode: .ABS, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x2f, mnemonic: "RLA", addrMode: .ABS, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x30, mnemonic: "BMI", addrMode: .REL, isInvalid: false, cycleCount: 2, penalty: true,  affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x31, mnemonic: "AND", addrMode: .INY, isInvalid: false, cycleCount: 5, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x32, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x33, mnemonic: "RLA", addrMode: .INY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x34, mnemonic: "NOP", addrMode: .ZPX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x35, mnemonic: "AND", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x36, mnemonic: "ROL", addrMode: .ZPX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x37, mnemonic: "RLA", addrMode: .ZPX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x38, mnemonic: "SEC", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: ______C),
    OpcodeInfo(opcode: 0x39, mnemonic: "AND", addrMode: .ABY, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x3a, mnemonic: "NOP", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x3b, mnemonic: "RLA", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x3c, mnemonic: "NOP", addrMode: .ABX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x3d, mnemonic: "AND", addrMode: .ABX, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x3e, mnemonic: "ROL", addrMode: .ABX, isInvalid: false, cycleCount: 7, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x3f, mnemonic: "RLA", addrMode: .ABX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x40, mnemonic: "RTI", addrMode: .IMP, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x41, mnemonic: "EOR", addrMode: .INX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x42, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x43, mnemonic: "SRE", addrMode: .INX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x44, mnemonic: "NOP", addrMode: .ZPG, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x45, mnemonic: "EOR", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x46, mnemonic: "LSR", addrMode: .ZPG, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x47, mnemonic: "SRE", addrMode: .ZPG, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x48, mnemonic: "PHA", addrMode: .IMP, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x49, mnemonic: "EOR", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x4a, mnemonic: "LSR", addrMode: .ACC, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x4b, mnemonic: "ALR", addrMode: .IMM, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x4c, mnemonic: "JMP", addrMode: .ABS, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x4d, mnemonic: "EOR", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x4e, mnemonic: "LSR", addrMode: .ABS, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x4f, mnemonic: "SRE", addrMode: .ABS, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x50, mnemonic: "BVC", addrMode: .REL, isInvalid: false, cycleCount: 2, penalty: true,  affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x51, mnemonic: "EOR", addrMode: .INY, isInvalid: false, cycleCount: 5, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x52, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x53, mnemonic: "SRE", addrMode: .INY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x54, mnemonic: "NOP", addrMode: .ZPX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x55, mnemonic: "EOR", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x56, mnemonic: "LSR", addrMode: .ZPX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x57, mnemonic: "SRE", addrMode: .ZPX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x58, mnemonic: "CLI", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: ____I__),
    OpcodeInfo(opcode: 0x59, mnemonic: "EOR", addrMode: .ABY, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x5a, mnemonic: "NOP", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x5b, mnemonic: "SRE", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x5c, mnemonic: "NOP", addrMode: .ABX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x5d, mnemonic: "EOR", addrMode: .ABX, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x5e, mnemonic: "LSR", addrMode: .ABX, isInvalid: false, cycleCount: 7, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x5f, mnemonic: "SRE", addrMode: .ABX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x60, mnemonic: "RTS", addrMode: .IMP, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x61, mnemonic: "ADC", addrMode: .INX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0x62, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x63, mnemonic: "RRA", addrMode: .INX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0x64, mnemonic: "NOP", addrMode: .ZPG, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x65, mnemonic: "ADC", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0x66, mnemonic: "ROR", addrMode: .ZPG, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x67, mnemonic: "RRA", addrMode: .ZPG, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0x68, mnemonic: "PLA", addrMode: .IMP, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x69, mnemonic: "ADC", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0x6a, mnemonic: "ROR", addrMode: .ACC, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x6b, mnemonic: "ARR", addrMode: .IMM, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0x6c, mnemonic: "JMP", addrMode: .IND, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x6d, mnemonic: "ADC", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0x6e, mnemonic: "ROR", addrMode: .ABX, isInvalid: false, cycleCount: 7, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x6f, mnemonic: "RRA", addrMode: .ABS, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0x70, mnemonic: "BVS", addrMode: .REL, isInvalid: false, cycleCount: 2, penalty: true,  affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x71, mnemonic: "ADC", addrMode: .INY, isInvalid: false, cycleCount: 5, penalty: true,  affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0x72, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x73, mnemonic: "RRA", addrMode: .INY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0x74, mnemonic: "NOP", addrMode: .ZPX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x75, mnemonic: "ADC", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0x76, mnemonic: "ROR", addrMode: .ZPX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x77, mnemonic: "RRA", addrMode: .ZPX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0x78, mnemonic: "SEI", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: ____I__),
    OpcodeInfo(opcode: 0x79, mnemonic: "ADC", addrMode: .ABY, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0x7a, mnemonic: "NOP", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x7b, mnemonic: "RRA", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0x7c, mnemonic: "NOP", addrMode: .ABX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x7d, mnemonic: "ADC", addrMode: .ABX, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0x7e, mnemonic: "ROR", addrMode: .ABS, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0x7f, mnemonic: "RRA", addrMode: .ABX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0x80, mnemonic: "NOP", addrMode: .IMM, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x81, mnemonic: "STA", addrMode: .INX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x82, mnemonic: "NOP", addrMode: .IMM, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x83, mnemonic: "SAX", addrMode: .INX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x84, mnemonic: "STY", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x85, mnemonic: "STA", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x86, mnemonic: "STX", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x87, mnemonic: "SAX", addrMode: .ZPG, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x88, mnemonic: "DEY", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x89, mnemonic: "NOP", addrMode: .IMM, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x8a, mnemonic: "TXA", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x8b, mnemonic: "XAA", addrMode: .IMM, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x8c, mnemonic: "STY", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x8d, mnemonic: "STA", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x8e, mnemonic: "STX", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x8f, mnemonic: "SAX", addrMode: .ABS, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x90, mnemonic: "BCC", addrMode: .REL, isInvalid: false, cycleCount: 2, penalty: true,  affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x91, mnemonic: "STA", addrMode: .INY, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x92, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x93, mnemonic: "AHX", addrMode: .INY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x94, mnemonic: "STY", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x95, mnemonic: "STA", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x96, mnemonic: "STX", addrMode: .ZPY, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x97, mnemonic: "SAX", addrMode: .ZPY, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x98, mnemonic: "TYA", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0x99, mnemonic: "STA", addrMode: .ABY, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x9a, mnemonic: "TXS", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x9b, mnemonic: "TAS", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x9c, mnemonic: "SHY", addrMode: .ABX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x9d, mnemonic: "STA", addrMode: .ABX, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x9e, mnemonic: "SHX", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0x9f, mnemonic: "AHX", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0xa0, mnemonic: "LDY", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xa1, mnemonic: "LDA", addrMode: .INX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xa2, mnemonic: "LDX", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xa3, mnemonic: "LAX", addrMode: .INX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xa4, mnemonic: "LDY", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xa5, mnemonic: "LDA", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xa6, mnemonic: "LDX", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xa7, mnemonic: "LAX", addrMode: .ZPG, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xa8, mnemonic: "TAY", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xa9, mnemonic: "LDA", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xaa, mnemonic: "TAX", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xab, mnemonic: "LAX", addrMode: .IMM, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xac, mnemonic: "LDY", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xad, mnemonic: "LDA", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xae, mnemonic: "LDX", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xaf, mnemonic: "LAX", addrMode: .ABS, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xb0, mnemonic: "BCS", addrMode: .REL, isInvalid: false, cycleCount: 2, penalty: true,  affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0xb1, mnemonic: "LDA", addrMode: .INY, isInvalid: false, cycleCount: 5, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xb2, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0xb3, mnemonic: "LAX", addrMode: .INY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xb4, mnemonic: "LDY", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xb5, mnemonic: "LDA", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xb6, mnemonic: "LDX", addrMode: .ZPY, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xb7, mnemonic: "LAX", addrMode: .ZPY, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xb8, mnemonic: "CLV", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: _O_____),
    OpcodeInfo(opcode: 0xb9, mnemonic: "LDA", addrMode: .ABY, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xba, mnemonic: "TSX", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xbb, mnemonic: "LAS", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xbc, mnemonic: "LDY", addrMode: .ABX, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xbd, mnemonic: "LDA", addrMode: .ABX, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xbe, mnemonic: "LDX", addrMode: .ABY, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xbf, mnemonic: "LAX", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xc0, mnemonic: "CPY", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xc1, mnemonic: "CMP", addrMode: .INX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xc2, mnemonic: "NOP", addrMode: .IMM, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0xc3, mnemonic: "DCP", addrMode: .INX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xc4, mnemonic: "CPY", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xc5, mnemonic: "CMP", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xc6, mnemonic: "DEC", addrMode: .ZPG, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xc7, mnemonic: "DCP", addrMode: .ZPG, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xc8, mnemonic: "INY", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xc9, mnemonic: "CMP", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xca, mnemonic: "DEX", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xcb, mnemonic: "AXS", addrMode: .IMM, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xcc, mnemonic: "CPY", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xcd, mnemonic: "CMP", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xce, mnemonic: "DEC", addrMode: .ABS, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xcf, mnemonic: "DCP", addrMode: .ABS, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xd0, mnemonic: "BNE", addrMode: .REL, isInvalid: false, cycleCount: 2, penalty: true,  affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0xd1, mnemonic: "CMP", addrMode: .INY, isInvalid: false, cycleCount: 5, penalty: true,  affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xd2, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0xd3, mnemonic: "DCP", addrMode: .INY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xd4, mnemonic: "NOP", addrMode: .ZPX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0xd5, mnemonic: "CMP", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xd6, mnemonic: "DEC", addrMode: .ZPX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xd7, mnemonic: "DCP", addrMode: .ZPX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xd8, mnemonic: "CLD", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: ___D___),
    OpcodeInfo(opcode: 0xd9, mnemonic: "CMP", addrMode: .ABY, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xda, mnemonic: "NOP", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0xdb, mnemonic: "DCP", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xdc, mnemonic: "NOP", addrMode: .ABX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0xdd, mnemonic: "CMP", addrMode: .ABX, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xde, mnemonic: "DEC", addrMode: .ABX, isInvalid: false, cycleCount: 7, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xdf, mnemonic: "DCP", addrMode: .ABX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xe0, mnemonic: "CPX", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xe1, mnemonic: "SBC", addrMode: .INX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0xe2, mnemonic: "NOP", addrMode: .IMM, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0xe3, mnemonic: "ISC", addrMode: .INX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0xe4, mnemonic: "CPX", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xe5, mnemonic: "SBC", addrMode: .ZPG, isInvalid: false, cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0xe6, mnemonic: "INC", addrMode: .ZPG, isInvalid: false, cycleCount: 5, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xe7, mnemonic: "ISC", addrMode: .ZPG, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0xe8, mnemonic: "INX", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xe9, mnemonic: "SBC", addrMode: .IMM, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0xea, mnemonic: "NOP", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0xeb, mnemonic: "SBC", addrMode: .IMM, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0xec, mnemonic: "CPX", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: N____ZC),
    OpcodeInfo(opcode: 0xed, mnemonic: "SBC", addrMode: .ABS, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0xee, mnemonic: "INC", addrMode: .ABS, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xef, mnemonic: "ISC", addrMode: .ABS, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0xf0, mnemonic: "BEQ", addrMode: .REL, isInvalid: false, cycleCount: 2, penalty: true,  affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0xf1, mnemonic: "SBC", addrMode: .INY, isInvalid: false, cycleCount: 5, penalty: true,  affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0xf2, mnemonic: "KIL", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0xf3, mnemonic: "ISC", addrMode: .INY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0xf4, mnemonic: "NOP", addrMode: .ZPX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0xf5, mnemonic: "SBC", addrMode: .ZPX, isInvalid: false, cycleCount: 4, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0xf6, mnemonic: "INC", addrMode: .ZPX, isInvalid: false, cycleCount: 6, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xf7, mnemonic: "ISC", addrMode: .ZPX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0xf8, mnemonic: "SED", addrMode: .IMP, isInvalid: false, cycleCount: 2, penalty: false, affectedFlags: ___D___),
    OpcodeInfo(opcode: 0xf9, mnemonic: "SBC", addrMode: .ABY, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0xfa, mnemonic: "NOP", addrMode: .IMP, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0xfb, mnemonic: "ISC", addrMode: .ABY, isInvalid: true,  cycleCount: 3, penalty: true,  affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0xfc, mnemonic: "NOP", addrMode: .ABX, isInvalid: true,  cycleCount: 2, penalty: false, affectedFlags: XXXXXXX),
    OpcodeInfo(opcode: 0xfd, mnemonic: "SBC", addrMode: .ABX, isInvalid: false, cycleCount: 4, penalty: true,  affectedFlags: NO___ZC),
    OpcodeInfo(opcode: 0xfe, mnemonic: "INC", addrMode: .ABX, isInvalid: false, cycleCount: 7, penalty: false, affectedFlags: N____Z_),
    OpcodeInfo(opcode: 0xff, mnemonic: "ISC", addrMode: .ABX, isInvalid: true,  cycleCount: 3, penalty: false, affectedFlags: NO___ZC),
]
//@f:1
