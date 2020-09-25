/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: Emu6510.swift
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

public class Emu6510 {

    public init() {}

    public func handleOpcode(opcode: UInt8) {
        //@f:0
        switch opcode {
            case 0x6d: performADC_ABS(  opcodeInfo: Emu6510Opcodes[0x6d])
            case 0x7d: performADC_ABSX( opcodeInfo: Emu6510Opcodes[0x7d])
            case 0x79: performADC_ABSY( opcodeInfo: Emu6510Opcodes[0x79])
            case 0x69: performADC_IMM(  opcodeInfo: Emu6510Opcodes[0x69])
            case 0x61: performADC_INDX( opcodeInfo: Emu6510Opcodes[0x61])
            case 0x71: performADC_INDY( opcodeInfo: Emu6510Opcodes[0x71])
            case 0x65: performADC_ZP(   opcodeInfo: Emu6510Opcodes[0x65])
            case 0x75: performADC_ZPX(  opcodeInfo: Emu6510Opcodes[0x75])
            case 0x2d: performAND_ABS(  opcodeInfo: Emu6510Opcodes[0x2d])
            case 0x3d: performAND_ABSX( opcodeInfo: Emu6510Opcodes[0x3d])
            case 0x39: performAND_ABSY( opcodeInfo: Emu6510Opcodes[0x39])
            case 0x29: performAND_IMM(  opcodeInfo: Emu6510Opcodes[0x29])
            case 0x21: performAND_INDX( opcodeInfo: Emu6510Opcodes[0x21])
            case 0x31: performAND_INDY( opcodeInfo: Emu6510Opcodes[0x31])
            case 0x25: performAND_ZP(   opcodeInfo: Emu6510Opcodes[0x25])
            case 0x35: performAND_ZPX(  opcodeInfo: Emu6510Opcodes[0x35])
            case 0x0e: performASL_ABS(  opcodeInfo: Emu6510Opcodes[0x0e])
            case 0x1e: performASL_ABSX( opcodeInfo: Emu6510Opcodes[0x1e])
            case 0x0a: performASL_ACC(  opcodeInfo: Emu6510Opcodes[0x0a])
            case 0x06: performASL_ZP(   opcodeInfo: Emu6510Opcodes[0x06])
            case 0x16: performASL_ZPX(  opcodeInfo: Emu6510Opcodes[0x16])
            case 0x90: performBCC_REL(  opcodeInfo: Emu6510Opcodes[0x90])
            case 0xB0: performBCS_REL(  opcodeInfo: Emu6510Opcodes[0xB0])
            case 0xF0: performBEQ_REL(  opcodeInfo: Emu6510Opcodes[0xF0])
            case 0x2c: performBIT_ABS(  opcodeInfo: Emu6510Opcodes[0x2c])
            case 0x24: performBIT_ZP(   opcodeInfo: Emu6510Opcodes[0x24])
            case 0x30: performBMI_REL(  opcodeInfo: Emu6510Opcodes[0x30])
            case 0xD0: performBNE_REL(  opcodeInfo: Emu6510Opcodes[0xD0])
            case 0x10: performBPL_REL(  opcodeInfo: Emu6510Opcodes[0x10])
            case 0x00: performBRK_IMP(  opcodeInfo: Emu6510Opcodes[0x00])
            case 0x50: performBVC_REL(  opcodeInfo: Emu6510Opcodes[0x50])
            case 0x70: performBVS_REL(  opcodeInfo: Emu6510Opcodes[0x70])
            case 0x18: performCLC_IMP(  opcodeInfo: Emu6510Opcodes[0x18])
            case 0xd8: performCLD_IMP(  opcodeInfo: Emu6510Opcodes[0xd8])
            case 0x58: performCLI_IMP(  opcodeInfo: Emu6510Opcodes[0x58])
            case 0xb8: performCLV_IMP(  opcodeInfo: Emu6510Opcodes[0xb8])
            case 0xcd: performCMP_ABS(  opcodeInfo: Emu6510Opcodes[0xcd])
            case 0xdd: performCMP_ABSX( opcodeInfo: Emu6510Opcodes[0xdd])
            case 0xd9: performCMP_ABSY( opcodeInfo: Emu6510Opcodes[0xd9])
            case 0xc9: performCMP_IMM(  opcodeInfo: Emu6510Opcodes[0xc9])
            case 0xc1: performCMP_INDX( opcodeInfo: Emu6510Opcodes[0xc1])
            case 0xd1: performCMP_INDY( opcodeInfo: Emu6510Opcodes[0xd1])
            case 0xc5: performCMP_ZP(   opcodeInfo: Emu6510Opcodes[0xc5])
            case 0xd5: performCMP_ZPX(  opcodeInfo: Emu6510Opcodes[0xd5])
            case 0xec: performCPX_ABS(  opcodeInfo: Emu6510Opcodes[0xec])
            case 0xe0: performCPX_IMM(  opcodeInfo: Emu6510Opcodes[0xe0])
            case 0xe4: performCPX_ZP(   opcodeInfo: Emu6510Opcodes[0xe4])
            case 0xcc: performCPY_ABS(  opcodeInfo: Emu6510Opcodes[0xcc])
            case 0xc0: performCPY_IMM(  opcodeInfo: Emu6510Opcodes[0xc0])
            case 0xc4: performCPY_ZP(   opcodeInfo: Emu6510Opcodes[0xc4])
            case 0xce: performDEC_ABS(  opcodeInfo: Emu6510Opcodes[0xce])
            case 0xde: performDEC_ABSX( opcodeInfo: Emu6510Opcodes[0xde])
            case 0xc6: performDEC_ZP(   opcodeInfo: Emu6510Opcodes[0xc6])
            case 0xd6: performDEC_ZPX(  opcodeInfo: Emu6510Opcodes[0xd6])
            case 0xca: performDEX_IMP(  opcodeInfo: Emu6510Opcodes[0xca])
            case 0x88: performDEY_IMP(  opcodeInfo: Emu6510Opcodes[0x88])
            case 0x4d: performEOR_ABS(  opcodeInfo: Emu6510Opcodes[0x4d])
            case 0x5d: performEOR_ABSX( opcodeInfo: Emu6510Opcodes[0x5d])
            case 0x59: performEOR_ABSY( opcodeInfo: Emu6510Opcodes[0x59])
            case 0x49: performEOR_IMM(  opcodeInfo: Emu6510Opcodes[0x49])
            case 0x41: performEOR_INDX( opcodeInfo: Emu6510Opcodes[0x41])
            case 0x51: performEOR_INDY( opcodeInfo: Emu6510Opcodes[0x51])
            case 0x45: performEOR_ZP(   opcodeInfo: Emu6510Opcodes[0x45])
            case 0x55: performEOR_ZPX(  opcodeInfo: Emu6510Opcodes[0x55])
            case 0xee: performINC_ABS(  opcodeInfo: Emu6510Opcodes[0xee])
            case 0xfe: performINC_ABSX( opcodeInfo: Emu6510Opcodes[0xfe])
            case 0xe6: performINC_ZP(   opcodeInfo: Emu6510Opcodes[0xe6])
            case 0xf6: performINC_ZPX(  opcodeInfo: Emu6510Opcodes[0xf6])
            case 0xe8: performINX_IMP(  opcodeInfo: Emu6510Opcodes[0xe8])
            case 0xc8: performINY_IMP(  opcodeInfo: Emu6510Opcodes[0xc8])
            case 0x4c: performJMP_ABS(  opcodeInfo: Emu6510Opcodes[0x4c])
            case 0x6c: performJMP_IND(  opcodeInfo: Emu6510Opcodes[0x6c])
            case 0x20: performJSR_ABS(  opcodeInfo: Emu6510Opcodes[0x20])
            case 0xad: performLDA_ABS(  opcodeInfo: Emu6510Opcodes[0xad])
            case 0xbd: performLDA_ABSX( opcodeInfo: Emu6510Opcodes[0xbd])
            case 0xb9: performLDA_ABSY( opcodeInfo: Emu6510Opcodes[0xb9])
            case 0xa9: performLDA_IMM(  opcodeInfo: Emu6510Opcodes[0xa9])
            case 0xa1: performLDA_INDX( opcodeInfo: Emu6510Opcodes[0xa1])
            case 0xb1: performLDA_INDY( opcodeInfo: Emu6510Opcodes[0xb1])
            case 0xa5: performLDA_ZP(   opcodeInfo: Emu6510Opcodes[0xa5])
            case 0xb5: performLDA_ZPX(  opcodeInfo: Emu6510Opcodes[0xb5])
            case 0xae: performLDX_ABS(  opcodeInfo: Emu6510Opcodes[0xae])
            case 0xbe: performLDX_ABSY( opcodeInfo: Emu6510Opcodes[0xbe])
            case 0xa2: performLDX_IMM(  opcodeInfo: Emu6510Opcodes[0xa2])
            case 0xa6: performLDX_ZP(   opcodeInfo: Emu6510Opcodes[0xa6])
            case 0xb6: performLDX_ZPY(  opcodeInfo: Emu6510Opcodes[0xb6])
            case 0xac: performLDY_ABS(  opcodeInfo: Emu6510Opcodes[0xac])
            case 0xbc: performLDY_ABSX( opcodeInfo: Emu6510Opcodes[0xbc])
            case 0xa0: performLDY_IMM(  opcodeInfo: Emu6510Opcodes[0xa0])
            case 0xa4: performLDY_ZP(   opcodeInfo: Emu6510Opcodes[0xa4])
            case 0xb4: performLDY_ZPX(  opcodeInfo: Emu6510Opcodes[0xb4])
            case 0x4e: performLSR_ABS(  opcodeInfo: Emu6510Opcodes[0x4e])
            case 0x5e: performLSR_ABSX( opcodeInfo: Emu6510Opcodes[0x5e])
            case 0x4a: performLSR_ACC(  opcodeInfo: Emu6510Opcodes[0x4a])
            case 0x46: performLSR_ZP(   opcodeInfo: Emu6510Opcodes[0x46])
            case 0x56: performLSR_ZPX(  opcodeInfo: Emu6510Opcodes[0x56])
            case 0xea: performNOP_IMP(  opcodeInfo: Emu6510Opcodes[0xea])
            case 0x0d: performORA_ABS(  opcodeInfo: Emu6510Opcodes[0x0d])
            case 0x1d: performORA_ABSX( opcodeInfo: Emu6510Opcodes[0x1d])
            case 0x19: performORA_ABSY( opcodeInfo: Emu6510Opcodes[0x19])
            case 0x09: performORA_IMM(  opcodeInfo: Emu6510Opcodes[0x09])
            case 0x01: performORA_INDX( opcodeInfo: Emu6510Opcodes[0x01])
            case 0x11: performORA_INDY( opcodeInfo: Emu6510Opcodes[0x11])
            case 0x05: performORA_ZP(   opcodeInfo: Emu6510Opcodes[0x05])
            case 0x15: performORA_ZPX(  opcodeInfo: Emu6510Opcodes[0x15])
            case 0x48: performPHA_IMP(  opcodeInfo: Emu6510Opcodes[0x48])
            case 0x08: performPHP_IMP(  opcodeInfo: Emu6510Opcodes[0x08])
            case 0x68: performPLA_IMP(  opcodeInfo: Emu6510Opcodes[0x68])
            case 0x28: performPLP_IMP(  opcodeInfo: Emu6510Opcodes[0x28])
            case 0x2e: performROL_ABS(  opcodeInfo: Emu6510Opcodes[0x2e])
            case 0x3e: performROL_ABSX( opcodeInfo: Emu6510Opcodes[0x3e])
            case 0x2a: performROL_ACC(  opcodeInfo: Emu6510Opcodes[0x2a])
            case 0x26: performROL_ZP(   opcodeInfo: Emu6510Opcodes[0x26])
            case 0x36: performROL_ZPX(  opcodeInfo: Emu6510Opcodes[0x36])
            case 0x7e: performROR_ABS(  opcodeInfo: Emu6510Opcodes[0x7e])
            case 0x6e: performROR_ABSX( opcodeInfo: Emu6510Opcodes[0x6e])
            case 0x6a: performROR_ACC(  opcodeInfo: Emu6510Opcodes[0x6a])
            case 0x66: performROR_ZP(   opcodeInfo: Emu6510Opcodes[0x66])
            case 0x76: performROR_ZPX(  opcodeInfo: Emu6510Opcodes[0x76])
            case 0x40: performRTI_IMP(  opcodeInfo: Emu6510Opcodes[0x40])
            case 0x60: performRTS_IMP(  opcodeInfo: Emu6510Opcodes[0x60])
            case 0xed: performSBC_ABS(  opcodeInfo: Emu6510Opcodes[0xed])
            case 0xfd: performSBC_ABSX( opcodeInfo: Emu6510Opcodes[0xfd])
            case 0xf9: performSBC_ABSY( opcodeInfo: Emu6510Opcodes[0xf9])
            case 0xe9: performSBC_IMM(  opcodeInfo: Emu6510Opcodes[0xe9])
            case 0xe1: performSBC_INDX( opcodeInfo: Emu6510Opcodes[0xe1])
            case 0xf1: performSBC_INDY( opcodeInfo: Emu6510Opcodes[0xf1])
            case 0xe5: performSBC_ZP(   opcodeInfo: Emu6510Opcodes[0xe5])
            case 0xf5: performSBC_ZPX(  opcodeInfo: Emu6510Opcodes[0xf5])
            case 0x38: performSEC_IMP(  opcodeInfo: Emu6510Opcodes[0x38])
            case 0xf8: performSED_IMP(  opcodeInfo: Emu6510Opcodes[0xf8])
            case 0x78: performSEI_IMP(  opcodeInfo: Emu6510Opcodes[0x78])
            case 0x8d: performSTA_ABS(  opcodeInfo: Emu6510Opcodes[0x8d])
            case 0x9d: performSTA_ABSX( opcodeInfo: Emu6510Opcodes[0x9d])
            case 0x99: performSTA_ABSY( opcodeInfo: Emu6510Opcodes[0x99])
            case 0x81: performSTA_INDX( opcodeInfo: Emu6510Opcodes[0x81])
            case 0x91: performSTA_INDY( opcodeInfo: Emu6510Opcodes[0x91])
            case 0x85: performSTA_ZP(   opcodeInfo: Emu6510Opcodes[0x85])
            case 0x95: performSTA_ZPX(  opcodeInfo: Emu6510Opcodes[0x95])
            case 0x8e: performSTX_ABS(  opcodeInfo: Emu6510Opcodes[0x8e])
            case 0x86: performSTX_ZP(   opcodeInfo: Emu6510Opcodes[0x86])
            case 0x96: performSTX_ZPY(  opcodeInfo: Emu6510Opcodes[0x96])
            case 0x8c: performSTY_ABS(  opcodeInfo: Emu6510Opcodes[0x8c])
            case 0x84: performSTY_ZP(   opcodeInfo: Emu6510Opcodes[0x84])
            case 0x94: performSTY_ZPX(  opcodeInfo: Emu6510Opcodes[0x94])
            case 0xaa: performTAX_IMP(  opcodeInfo: Emu6510Opcodes[0xaa])
            case 0xa8: performTAY_IMP(  opcodeInfo: Emu6510Opcodes[0xa8])
            case 0xba: performTSX_IMP(  opcodeInfo: Emu6510Opcodes[0xba])
            case 0x8a: performTXA_IMP(  opcodeInfo: Emu6510Opcodes[0x8a])
            case 0x9a: performTXS_IMP(  opcodeInfo: Emu6510Opcodes[0x9a])
            case 0x98: performTYA_IMP(  opcodeInfo: Emu6510Opcodes[0x98])
            default: handleInvalidOpcodes(opcode: opcode)
        }
        //@f:1
    }

    public func handleInvalidOpcodes(opcode: UInt8) {
        switch opcode {
            default: break
        }
    }

    @inlinable public func performADC_IMM(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performADC_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performADC_ZPX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performADC_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performADC_ABSX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performADC_ABSY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performADC_INDX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performADC_INDY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performAND_IMM(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performAND_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performAND_ZPX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performAND_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performAND_ABSX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performAND_ABSY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performAND_INDX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performAND_INDY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performASL_ACC(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performASL_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performASL_ZPX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performASL_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performASL_ABSX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performBCC_REL(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performBCS_REL(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performBEQ_REL(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performBMI_REL(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performBNE_REL(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performBPL_REL(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performBVC_REL(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performBVS_REL(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performBIT_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performBIT_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performBRK_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCLC_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCLD_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCLI_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCLV_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performNOP_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performPHA_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performPLA_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performPHP_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performPLP_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performRTI_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performRTS_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSEC_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSED_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSEI_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performTAX_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performTXA_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performTAY_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performTYA_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performTSX_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performTXS_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCMP_IMM(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCMP_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCMP_ZPX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCMP_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCMP_ABSX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCMP_ABSY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCMP_INDX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCMP_INDY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCPX_IMM(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCPX_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCPX_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCPY_IMM(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCPY_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performCPY_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performDEC_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performDEC_ZPX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performDEC_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performDEC_ABSX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performDEX_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performDEY_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performINX_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performINY_IMP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performEOR_IMM(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performEOR_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performEOR_ZPX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performEOR_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performEOR_ABSX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performEOR_ABSY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performEOR_INDX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performEOR_INDY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performINC_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performINC_ZPX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performINC_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performINC_ABSX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performJMP_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performJMP_IND(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performJSR_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDA_IMM(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDA_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDA_ZPX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDA_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDA_ABSX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDA_ABSY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDA_INDX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDA_INDY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDX_IMM(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDX_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDX_ZPY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDX_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDX_ABSY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDY_IMM(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDY_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDY_ZPX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDY_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLDY_ABSX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLSR_ACC(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLSR_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLSR_ZPX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLSR_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performLSR_ABSX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performORA_IMM(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performORA_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performORA_ZPX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performORA_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performORA_ABSX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performORA_ABSY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performORA_INDX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performORA_INDY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performROL_ACC(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performROL_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performROL_ZPX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performROL_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performROL_ABSX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performROR_ACC(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performROR_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performROR_ZPX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performROR_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performROR_ABSX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSBC_IMM(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSBC_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSBC_ZPX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSBC_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSBC_ABSX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSBC_ABSY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSBC_INDX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSBC_INDY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSTA_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSTA_ZPX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSTA_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSTA_ABSX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSTA_ABSY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSTA_INDX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSTA_INDY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSTX_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSTX_ZPY(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSTX_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSTY_ZP(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSTY_ZPX(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }

    @inlinable public func performSTY_ABS(opcodeInfo: OpcodeInfo?) {
        if let opcodeInfo: OpcodeInfo = opcodeInfo {
        }
        else {
            // TODO: OPCODE_NOT_FOUND_ERROR
        }
    }
}
