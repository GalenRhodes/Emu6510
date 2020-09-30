/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: CPU.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 9/26/20
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
import Rubicon

public class Emu6510 {

    public var statusRegister: UInt8 { didSet { self.statusRegister = (self.statusRegister | 32) } }
    public var clock:          ClockFrequencies { cpuClock.clock }

    public internal(set) var programCounter: UInt16
    public internal(set) var isKilled:       Bool = false

    var cpuWatcher: ClockWatcher
    var cpuClock:   CPUClock
    var tickWait:   Int = 0

    public init(clock: ClockFrequencies = .C64_NTSC) {
        self.programCounter = 0x0000
        self.statusRegister = 32
        self.cpuWatcher = ClockWatcher()
        self.cpuClock = CPUClock(clock: clock)
        try? self.cpuClock.addWatcher(self.cpuWatcher)
        self.cpuWatcher.closure = { self.clockTick() }
    }

    public func startCPU() throws {
        try cpuClock.start()
    }

    public func stopCPU() throws {
        try cpuClock.stop()
    }

    deinit {
        try? cpuClock.stop()
    }

    public final func clockTick() {
        // TODO: Grab next instruction and execute.
    }

    public func handleOpcode(opcode: UInt8) {
        //@f:0
        switch opcode {
            case 0x00: processBRK(opcode: Emu6510Opcodes[0x00])
            case 0x01: processORA(opcode: Emu6510Opcodes[0x01])
            case 0x02: processKIL(opcode: Emu6510Opcodes[0x02])
            case 0x03: processSLO(opcode: Emu6510Opcodes[0x03])
            case 0x04: processNOP(opcode: Emu6510Opcodes[0x04])
            case 0x05: processORA(opcode: Emu6510Opcodes[0x05])
            case 0x06: processASL(opcode: Emu6510Opcodes[0x06])
            case 0x07: processSLO(opcode: Emu6510Opcodes[0x07])
            case 0x08: processPHP(opcode: Emu6510Opcodes[0x08])
            case 0x09: processORA(opcode: Emu6510Opcodes[0x09])
            case 0x0a: processASL(opcode: Emu6510Opcodes[0x0a])
            case 0x0b: processANC(opcode: Emu6510Opcodes[0x0b])
            case 0x0c: processNOP(opcode: Emu6510Opcodes[0x0c])
            case 0x0d: processORA(opcode: Emu6510Opcodes[0x0d])
            case 0x0e: processASL(opcode: Emu6510Opcodes[0x0e])
            case 0x0f: processSLO(opcode: Emu6510Opcodes[0x0f])
            case 0x10: processBPL(opcode: Emu6510Opcodes[0x10])
            case 0x11: processORA(opcode: Emu6510Opcodes[0x11])
            case 0x12: processKIL(opcode: Emu6510Opcodes[0x12])
            case 0x13: processSLO(opcode: Emu6510Opcodes[0x13])
            case 0x14: processNOP(opcode: Emu6510Opcodes[0x14])
            case 0x15: processORA(opcode: Emu6510Opcodes[0x15])
            case 0x16: processASL(opcode: Emu6510Opcodes[0x16])
            case 0x17: processSLO(opcode: Emu6510Opcodes[0x17])
            case 0x18: processCLC(opcode: Emu6510Opcodes[0x18])
            case 0x19: processORA(opcode: Emu6510Opcodes[0x19])
            case 0x1a: processNOP(opcode: Emu6510Opcodes[0x1a])
            case 0x1b: processSLO(opcode: Emu6510Opcodes[0x1b])
            case 0x1c: processNOP(opcode: Emu6510Opcodes[0x1c])
            case 0x1d: processORA(opcode: Emu6510Opcodes[0x1d])
            case 0x1e: processASL(opcode: Emu6510Opcodes[0x1e])
            case 0x1f: processSLO(opcode: Emu6510Opcodes[0x1f])
            case 0x20: processJSR(opcode: Emu6510Opcodes[0x20])
            case 0x21: processAND(opcode: Emu6510Opcodes[0x21])
            case 0x22: processKIL(opcode: Emu6510Opcodes[0x22])
            case 0x23: processRLA(opcode: Emu6510Opcodes[0x23])
            case 0x24: processBIT(opcode: Emu6510Opcodes[0x24])
            case 0x25: processAND(opcode: Emu6510Opcodes[0x25])
            case 0x26: processROL(opcode: Emu6510Opcodes[0x26])
            case 0x27: processRLA(opcode: Emu6510Opcodes[0x27])
            case 0x28: processPLP(opcode: Emu6510Opcodes[0x28])
            case 0x29: processAND(opcode: Emu6510Opcodes[0x29])
            case 0x2a: processROL(opcode: Emu6510Opcodes[0x2a])
            case 0x2b: processANC(opcode: Emu6510Opcodes[0x2b])
            case 0x2c: processBIT(opcode: Emu6510Opcodes[0x2c])
            case 0x2d: processAND(opcode: Emu6510Opcodes[0x2d])
            case 0x2e: processROL(opcode: Emu6510Opcodes[0x2e])
            case 0x2f: processRLA(opcode: Emu6510Opcodes[0x2f])
            case 0x30: processBMI(opcode: Emu6510Opcodes[0x30])
            case 0x31: processAND(opcode: Emu6510Opcodes[0x31])
            case 0x32: processKIL(opcode: Emu6510Opcodes[0x32])
            case 0x33: processRLA(opcode: Emu6510Opcodes[0x33])
            case 0x34: processNOP(opcode: Emu6510Opcodes[0x34])
            case 0x35: processAND(opcode: Emu6510Opcodes[0x35])
            case 0x36: processROL(opcode: Emu6510Opcodes[0x36])
            case 0x37: processRLA(opcode: Emu6510Opcodes[0x37])
            case 0x38: processSEC(opcode: Emu6510Opcodes[0x38])
            case 0x39: processAND(opcode: Emu6510Opcodes[0x39])
            case 0x3a: processNOP(opcode: Emu6510Opcodes[0x3a])
            case 0x3b: processRLA(opcode: Emu6510Opcodes[0x3b])
            case 0x3c: processNOP(opcode: Emu6510Opcodes[0x3c])
            case 0x3d: processAND(opcode: Emu6510Opcodes[0x3d])
            case 0x3e: processROL(opcode: Emu6510Opcodes[0x3e])
            case 0x3f: processRLA(opcode: Emu6510Opcodes[0x3f])
            case 0x40: processRTI(opcode: Emu6510Opcodes[0x40])
            case 0x41: processEOR(opcode: Emu6510Opcodes[0x41])
            case 0x42: processKIL(opcode: Emu6510Opcodes[0x42])
            case 0x43: processSRE(opcode: Emu6510Opcodes[0x43])
            case 0x44: processNOP(opcode: Emu6510Opcodes[0x44])
            case 0x45: processEOR(opcode: Emu6510Opcodes[0x45])
            case 0x46: processLSR(opcode: Emu6510Opcodes[0x46])
            case 0x47: processSRE(opcode: Emu6510Opcodes[0x47])
            case 0x48: processPHA(opcode: Emu6510Opcodes[0x48])
            case 0x49: processEOR(opcode: Emu6510Opcodes[0x49])
            case 0x4a: processLSR(opcode: Emu6510Opcodes[0x4a])
            case 0x4b: processALR(opcode: Emu6510Opcodes[0x4b])
            case 0x4c: processJMP(opcode: Emu6510Opcodes[0x4c])
            case 0x4d: processEOR(opcode: Emu6510Opcodes[0x4d])
            case 0x4e: processLSR(opcode: Emu6510Opcodes[0x4e])
            case 0x4f: processSRE(opcode: Emu6510Opcodes[0x4f])
            case 0x50: processBVC(opcode: Emu6510Opcodes[0x50])
            case 0x51: processEOR(opcode: Emu6510Opcodes[0x51])
            case 0x52: processKIL(opcode: Emu6510Opcodes[0x52])
            case 0x53: processSRE(opcode: Emu6510Opcodes[0x53])
            case 0x54: processNOP(opcode: Emu6510Opcodes[0x54])
            case 0x55: processEOR(opcode: Emu6510Opcodes[0x55])
            case 0x56: processLSR(opcode: Emu6510Opcodes[0x56])
            case 0x57: processSRE(opcode: Emu6510Opcodes[0x57])
            case 0x58: processCLI(opcode: Emu6510Opcodes[0x58])
            case 0x59: processEOR(opcode: Emu6510Opcodes[0x59])
            case 0x5a: processNOP(opcode: Emu6510Opcodes[0x5a])
            case 0x5b: processSRE(opcode: Emu6510Opcodes[0x5b])
            case 0x5c: processNOP(opcode: Emu6510Opcodes[0x5c])
            case 0x5d: processEOR(opcode: Emu6510Opcodes[0x5d])
            case 0x5e: processLSR(opcode: Emu6510Opcodes[0x5e])
            case 0x5f: processSRE(opcode: Emu6510Opcodes[0x5f])
            case 0x60: processRTS(opcode: Emu6510Opcodes[0x60])
            case 0x61: processADC(opcode: Emu6510Opcodes[0x61])
            case 0x62: processKIL(opcode: Emu6510Opcodes[0x62])
            case 0x63: processRRA(opcode: Emu6510Opcodes[0x63])
            case 0x64: processNOP(opcode: Emu6510Opcodes[0x64])
            case 0x65: processADC(opcode: Emu6510Opcodes[0x65])
            case 0x66: processROR(opcode: Emu6510Opcodes[0x66])
            case 0x67: processRRA(opcode: Emu6510Opcodes[0x67])
            case 0x68: processPLA(opcode: Emu6510Opcodes[0x68])
            case 0x69: processADC(opcode: Emu6510Opcodes[0x69])
            case 0x6a: processROR(opcode: Emu6510Opcodes[0x6a])
            case 0x6b: processARR(opcode: Emu6510Opcodes[0x6b])
            case 0x6c: processJMP(opcode: Emu6510Opcodes[0x6c])
            case 0x6d: processADC(opcode: Emu6510Opcodes[0x6d])
            case 0x6e: processROR(opcode: Emu6510Opcodes[0x6e])
            case 0x6f: processRRA(opcode: Emu6510Opcodes[0x6f])
            case 0x70: processBVS(opcode: Emu6510Opcodes[0x70])
            case 0x71: processADC(opcode: Emu6510Opcodes[0x71])
            case 0x72: processKIL(opcode: Emu6510Opcodes[0x72])
            case 0x73: processRRA(opcode: Emu6510Opcodes[0x73])
            case 0x74: processNOP(opcode: Emu6510Opcodes[0x74])
            case 0x75: processADC(opcode: Emu6510Opcodes[0x75])
            case 0x76: processROR(opcode: Emu6510Opcodes[0x76])
            case 0x77: processRRA(opcode: Emu6510Opcodes[0x77])
            case 0x78: processSEI(opcode: Emu6510Opcodes[0x78])
            case 0x79: processADC(opcode: Emu6510Opcodes[0x79])
            case 0x7a: processNOP(opcode: Emu6510Opcodes[0x7a])
            case 0x7b: processRRA(opcode: Emu6510Opcodes[0x7b])
            case 0x7c: processNOP(opcode: Emu6510Opcodes[0x7c])
            case 0x7d: processADC(opcode: Emu6510Opcodes[0x7d])
            case 0x7e: processROR(opcode: Emu6510Opcodes[0x7e])
            case 0x7f: processRRA(opcode: Emu6510Opcodes[0x7f])
            case 0x80: processNOP(opcode: Emu6510Opcodes[0x80])
            case 0x81: processSTA(opcode: Emu6510Opcodes[0x81])
            case 0x82: processNOP(opcode: Emu6510Opcodes[0x82])
            case 0x83: processSAX(opcode: Emu6510Opcodes[0x83])
            case 0x84: processSTY(opcode: Emu6510Opcodes[0x84])
            case 0x85: processSTA(opcode: Emu6510Opcodes[0x85])
            case 0x86: processSTX(opcode: Emu6510Opcodes[0x86])
            case 0x87: processSAX(opcode: Emu6510Opcodes[0x87])
            case 0x88: processDEY(opcode: Emu6510Opcodes[0x88])
            case 0x89: processNOP(opcode: Emu6510Opcodes[0x89])
            case 0x8a: processTXA(opcode: Emu6510Opcodes[0x8a])
            case 0x8b: processXAA(opcode: Emu6510Opcodes[0x8b])
            case 0x8c: processSTY(opcode: Emu6510Opcodes[0x8c])
            case 0x8d: processSTA(opcode: Emu6510Opcodes[0x8d])
            case 0x8e: processSTX(opcode: Emu6510Opcodes[0x8e])
            case 0x8f: processSAX(opcode: Emu6510Opcodes[0x8f])
            case 0x90: processBCC(opcode: Emu6510Opcodes[0x90])
            case 0x91: processSTA(opcode: Emu6510Opcodes[0x91])
            case 0x92: processKIL(opcode: Emu6510Opcodes[0x92])
            case 0x93: processAHX(opcode: Emu6510Opcodes[0x93])
            case 0x94: processSTY(opcode: Emu6510Opcodes[0x94])
            case 0x95: processSTA(opcode: Emu6510Opcodes[0x95])
            case 0x96: processSTX(opcode: Emu6510Opcodes[0x96])
            case 0x97: processSAX(opcode: Emu6510Opcodes[0x97])
            case 0x98: processTYA(opcode: Emu6510Opcodes[0x98])
            case 0x99: processSTA(opcode: Emu6510Opcodes[0x99])
            case 0x9a: processTXS(opcode: Emu6510Opcodes[0x9a])
            case 0x9b: processTAS(opcode: Emu6510Opcodes[0x9b])
            case 0x9c: processSHY(opcode: Emu6510Opcodes[0x9c])
            case 0x9d: processSTA(opcode: Emu6510Opcodes[0x9d])
            case 0x9e: processSHX(opcode: Emu6510Opcodes[0x9e])
            case 0x9f: processAHX(opcode: Emu6510Opcodes[0x9f])
            case 0xa0: processLDY(opcode: Emu6510Opcodes[0xa0])
            case 0xa1: processLDA(opcode: Emu6510Opcodes[0xa1])
            case 0xa2: processLDX(opcode: Emu6510Opcodes[0xa2])
            case 0xa3: processLAX(opcode: Emu6510Opcodes[0xa3])
            case 0xa4: processLDY(opcode: Emu6510Opcodes[0xa4])
            case 0xa5: processLDA(opcode: Emu6510Opcodes[0xa5])
            case 0xa6: processLDX(opcode: Emu6510Opcodes[0xa6])
            case 0xa7: processLAX(opcode: Emu6510Opcodes[0xa7])
            case 0xa8: processTAY(opcode: Emu6510Opcodes[0xa8])
            case 0xa9: processLDA(opcode: Emu6510Opcodes[0xa9])
            case 0xaa: processTAX(opcode: Emu6510Opcodes[0xaa])
            case 0xab: processLAX(opcode: Emu6510Opcodes[0xab])
            case 0xac: processLDY(opcode: Emu6510Opcodes[0xac])
            case 0xad: processLDA(opcode: Emu6510Opcodes[0xad])
            case 0xae: processLDX(opcode: Emu6510Opcodes[0xae])
            case 0xaf: processLAX(opcode: Emu6510Opcodes[0xaf])
            case 0xb0: processBCS(opcode: Emu6510Opcodes[0xb0])
            case 0xb1: processLDA(opcode: Emu6510Opcodes[0xb1])
            case 0xb2: processKIL(opcode: Emu6510Opcodes[0xb2])
            case 0xb3: processLAX(opcode: Emu6510Opcodes[0xb3])
            case 0xb4: processLDY(opcode: Emu6510Opcodes[0xb4])
            case 0xb5: processLDA(opcode: Emu6510Opcodes[0xb5])
            case 0xb6: processLDX(opcode: Emu6510Opcodes[0xb6])
            case 0xb7: processLAX(opcode: Emu6510Opcodes[0xb7])
            case 0xb8: processCLV(opcode: Emu6510Opcodes[0xb8])
            case 0xb9: processLDA(opcode: Emu6510Opcodes[0xb9])
            case 0xba: processTSX(opcode: Emu6510Opcodes[0xba])
            case 0xbb: processLAS(opcode: Emu6510Opcodes[0xbb])
            case 0xbc: processLDY(opcode: Emu6510Opcodes[0xbc])
            case 0xbd: processLDA(opcode: Emu6510Opcodes[0xbd])
            case 0xbe: processLDX(opcode: Emu6510Opcodes[0xbe])
            case 0xbf: processLAX(opcode: Emu6510Opcodes[0xbf])
            case 0xc0: processCPY(opcode: Emu6510Opcodes[0xc0])
            case 0xc1: processCMP(opcode: Emu6510Opcodes[0xc1])
            case 0xc2: processNOP(opcode: Emu6510Opcodes[0xc2])
            case 0xc3: processDCP(opcode: Emu6510Opcodes[0xc3])
            case 0xc4: processCPY(opcode: Emu6510Opcodes[0xc4])
            case 0xc5: processCMP(opcode: Emu6510Opcodes[0xc5])
            case 0xc6: processDEC(opcode: Emu6510Opcodes[0xc6])
            case 0xc7: processDCP(opcode: Emu6510Opcodes[0xc7])
            case 0xc8: processINY(opcode: Emu6510Opcodes[0xc8])
            case 0xc9: processCMP(opcode: Emu6510Opcodes[0xc9])
            case 0xca: processDEX(opcode: Emu6510Opcodes[0xca])
            case 0xcb: processAXS(opcode: Emu6510Opcodes[0xcb])
            case 0xcc: processCPY(opcode: Emu6510Opcodes[0xcc])
            case 0xcd: processCMP(opcode: Emu6510Opcodes[0xcd])
            case 0xce: processDEC(opcode: Emu6510Opcodes[0xce])
            case 0xcf: processDCP(opcode: Emu6510Opcodes[0xcf])
            case 0xd0: processBNE(opcode: Emu6510Opcodes[0xd0])
            case 0xd1: processCMP(opcode: Emu6510Opcodes[0xd1])
            case 0xd2: processKIL(opcode: Emu6510Opcodes[0xd2])
            case 0xd3: processDCP(opcode: Emu6510Opcodes[0xd3])
            case 0xd4: processNOP(opcode: Emu6510Opcodes[0xd4])
            case 0xd5: processCMP(opcode: Emu6510Opcodes[0xd5])
            case 0xd6: processDEC(opcode: Emu6510Opcodes[0xd6])
            case 0xd7: processDCP(opcode: Emu6510Opcodes[0xd7])
            case 0xd8: processCLD(opcode: Emu6510Opcodes[0xd8])
            case 0xd9: processCMP(opcode: Emu6510Opcodes[0xd9])
            case 0xda: processNOP(opcode: Emu6510Opcodes[0xda])
            case 0xdb: processDCP(opcode: Emu6510Opcodes[0xdb])
            case 0xdc: processNOP(opcode: Emu6510Opcodes[0xdc])
            case 0xdd: processCMP(opcode: Emu6510Opcodes[0xdd])
            case 0xde: processDEC(opcode: Emu6510Opcodes[0xde])
            case 0xdf: processDCP(opcode: Emu6510Opcodes[0xdf])
            case 0xe0: processCPX(opcode: Emu6510Opcodes[0xe0])
            case 0xe1: processSBC(opcode: Emu6510Opcodes[0xe1])
            case 0xe2: processNOP(opcode: Emu6510Opcodes[0xe2])
            case 0xe3: processISC(opcode: Emu6510Opcodes[0xe3])
            case 0xe4: processCPX(opcode: Emu6510Opcodes[0xe4])
            case 0xe5: processSBC(opcode: Emu6510Opcodes[0xe5])
            case 0xe6: processINC(opcode: Emu6510Opcodes[0xe6])
            case 0xe7: processISC(opcode: Emu6510Opcodes[0xe7])
            case 0xe8: processINX(opcode: Emu6510Opcodes[0xe8])
            case 0xe9: processSBC(opcode: Emu6510Opcodes[0xe9])
            case 0xea: processNOP(opcode: Emu6510Opcodes[0xea])
            case 0xeb: processSBC(opcode: Emu6510Opcodes[0xeb])
            case 0xec: processCPX(opcode: Emu6510Opcodes[0xec])
            case 0xed: processSBC(opcode: Emu6510Opcodes[0xed])
            case 0xee: processINC(opcode: Emu6510Opcodes[0xee])
            case 0xef: processISC(opcode: Emu6510Opcodes[0xef])
            case 0xf0: processBEQ(opcode: Emu6510Opcodes[0xf0])
            case 0xf1: processSBC(opcode: Emu6510Opcodes[0xf1])
            case 0xf2: processKIL(opcode: Emu6510Opcodes[0xf2])
            case 0xf3: processISC(opcode: Emu6510Opcodes[0xf3])
            case 0xf4: processNOP(opcode: Emu6510Opcodes[0xf4])
            case 0xf5: processSBC(opcode: Emu6510Opcodes[0xf5])
            case 0xf6: processINC(opcode: Emu6510Opcodes[0xf6])
            case 0xf7: processISC(opcode: Emu6510Opcodes[0xf7])
            case 0xf8: processSED(opcode: Emu6510Opcodes[0xf8])
            case 0xf9: processSBC(opcode: Emu6510Opcodes[0xf9])
            case 0xfa: processNOP(opcode: Emu6510Opcodes[0xfa])
            case 0xfb: processISC(opcode: Emu6510Opcodes[0xfb])
            case 0xfc: processNOP(opcode: Emu6510Opcodes[0xfc])
            case 0xfd: processSBC(opcode: Emu6510Opcodes[0xfd])
            case 0xfe: processINC(opcode: Emu6510Opcodes[0xfe])
            case 0xff: processISC(opcode: Emu6510Opcodes[0xff])
            default:   processKIL(opcode: Emu6510Opcodes[0x02])
        }
        //@f:1
    }

    /// Handles the processBRK opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processBRK(opcode: OpcodeInfo) {
        // TODO: processBRK opcode
    }

    /// Handles the processORA opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processORA(opcode: OpcodeInfo) {
        // TODO: processORA opcode
    }

    /// Handles the processKIL opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processKIL(opcode: OpcodeInfo) {
    }

    /// Handles the processSLO opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processSLO(opcode: OpcodeInfo) {
        // TODO: processSLO opcode
    }

    /// Handles the processNOP opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processNOP(opcode: OpcodeInfo) {
        // TODO: processNOP opcode
    }

    /// Handles the processASL opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processASL(opcode: OpcodeInfo) {
        // TODO: processASL opcode
    }

    /// Handles the processPHP opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processPHP(opcode: OpcodeInfo) {
        // TODO: processPHP opcode
    }

    /// Handles the processANC opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processANC(opcode: OpcodeInfo) {
        // TODO: processANC opcode
    }

    /// Handles the processBPL opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processBPL(opcode: OpcodeInfo) {
        // TODO: processBPL opcode
    }

    /// Handles the processCLC opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processCLC(opcode: OpcodeInfo) {
        // TODO: processCLC opcode
    }

    /// Handles the processJSR opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processJSR(opcode: OpcodeInfo) {
        // TODO: processJSR opcode
    }

    /// Handles the processAND opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processAND(opcode: OpcodeInfo) {
        // TODO: processAND opcode
    }

    /// Handles the processRLA opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processRLA(opcode: OpcodeInfo) {
        // TODO: processRLA opcode
    }

    /// Handles the processBIT opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processBIT(opcode: OpcodeInfo) {
        // TODO: processBIT opcode
    }

    /// Handles the processROL opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processROL(opcode: OpcodeInfo) {
        // TODO: processROL opcode
    }

    /// Handles the processPLP opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processPLP(opcode: OpcodeInfo) {
        // TODO: processPLP opcode
    }

    /// Handles the processBMI opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processBMI(opcode: OpcodeInfo) {
        // TODO: processBMI opcode
    }

    /// Handles the processSEC opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processSEC(opcode: OpcodeInfo) {
        // TODO: processSEC opcode
    }

    /// Handles the processRTI opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processRTI(opcode: OpcodeInfo) {
        // TODO: processRTI opcode
    }

    /// Handles the processEOR opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processEOR(opcode: OpcodeInfo) {
        // TODO: processEOR opcode
    }

    /// Handles the processSRE opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processSRE(opcode: OpcodeInfo) {
        // TODO: processSRE opcode
    }

    /// Handles the processLSR opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processLSR(opcode: OpcodeInfo) {
        // TODO: processLSR opcode
    }

    /// Handles the processPHA opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processPHA(opcode: OpcodeInfo) {
        // TODO: processPHA opcode
    }

    /// Handles the processALR opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processALR(opcode: OpcodeInfo) {
        // TODO: processALR opcode
    }

    /// Handles the processJMP opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processJMP(opcode: OpcodeInfo) {
        // TODO: processJMP opcode
    }

    /// Handles the processBVC opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processBVC(opcode: OpcodeInfo) {
        // TODO: processBVC opcode
    }

    /// Handles the processCLI opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processCLI(opcode: OpcodeInfo) {
        // TODO: processCLI opcode
    }

    /// Handles the processRTS opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processRTS(opcode: OpcodeInfo) {
        // TODO: processRTS opcode
    }

    /// Handles the processADC opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processADC(opcode: OpcodeInfo) {
        // TODO: processADC opcode
    }

    /// Handles the processRRA opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processRRA(opcode: OpcodeInfo) {
        // TODO: processRRA opcode
    }

    /// Handles the processROR opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processROR(opcode: OpcodeInfo) {
        // TODO: processROR opcode
    }

    /// Handles the processPLA opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processPLA(opcode: OpcodeInfo) {
        // TODO: processPLA opcode
    }

    /// Handles the processARR opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processARR(opcode: OpcodeInfo) {
        // TODO: processARR opcode
    }

    /// Handles the processBVS opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processBVS(opcode: OpcodeInfo) {
        // TODO: processBVS opcode
    }

    /// Handles the processSEI opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processSEI(opcode: OpcodeInfo) {
        // TODO: processSEI opcode
    }

    /// Handles the processSTA opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processSTA(opcode: OpcodeInfo) {
        // TODO: processSTA opcode
    }

    /// Handles the processSAX opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processSAX(opcode: OpcodeInfo) {
        // TODO: processSAX opcode
    }

    /// Handles the processSTY opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processSTY(opcode: OpcodeInfo) {
        // TODO: processSTY opcode
    }

    /// Handles the processSTX opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processSTX(opcode: OpcodeInfo) {
        // TODO: processSTX opcode
    }

    /// Handles the processDEY opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processDEY(opcode: OpcodeInfo) {
        // TODO: processDEY opcode
    }

    /// Handles the processTXA opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processTXA(opcode: OpcodeInfo) {
        // TODO: processTXA opcode
    }

    /// Handles the processXAA opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processXAA(opcode: OpcodeInfo) {
        // TODO: processXAA opcode
    }

    /// Handles the processBCC opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processBCC(opcode: OpcodeInfo) {
        // TODO: processBCC opcode
    }

    /// Handles the processAHX opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processAHX(opcode: OpcodeInfo) {
        // TODO: processAHX opcode
    }

    /// Handles the processTYA opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processTYA(opcode: OpcodeInfo) {
        // TODO: processTYA opcode
    }

    /// Handles the processTXS opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processTXS(opcode: OpcodeInfo) {
        // TODO: processTXS opcode
    }

    /// Handles the processTAS opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processTAS(opcode: OpcodeInfo) {
        // TODO: processTAS opcode
    }

    /// Handles the processSHY opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processSHY(opcode: OpcodeInfo) {
        // TODO: processSHY opcode
    }

    /// Handles the processSHX opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processSHX(opcode: OpcodeInfo) {
        // TODO: processSHX opcode
    }

    /// Handles the processLDY opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processLDY(opcode: OpcodeInfo) {
        // TODO: processLDY opcode
    }

    /// Handles the processLDA opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processLDA(opcode: OpcodeInfo) {
        // TODO: processLDA opcode
    }

    /// Handles the processLDX opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processLDX(opcode: OpcodeInfo) {
        // TODO: processLDX opcode
    }

    /// Handles the processLAX opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processLAX(opcode: OpcodeInfo) {
        // TODO: processLAX opcode
    }

    /// Handles the processTAY opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processTAY(opcode: OpcodeInfo) {
        // TODO: processTAY opcode
    }

    /// Handles the processTAX opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processTAX(opcode: OpcodeInfo) {
        // TODO: processTAX opcode
    }

    /// Handles the processBCS opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processBCS(opcode: OpcodeInfo) {
        // TODO: processBCS opcode
    }

    /// Handles the processCLV opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processCLV(opcode: OpcodeInfo) {
        // TODO: processCLV opcode
    }

    /// Handles the processTSX opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processTSX(opcode: OpcodeInfo) {
        // TODO: processTSX opcode
    }

    /// Handles the processLAS opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processLAS(opcode: OpcodeInfo) {
        // TODO: processLAS opcode
    }

    /// Handles the processCPY opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processCPY(opcode: OpcodeInfo) {
        // TODO: processCPY opcode
    }

    /// Handles the processCMP opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processCMP(opcode: OpcodeInfo) {
        // TODO: processCMP opcode
    }

    /// Handles the processDCP opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processDCP(opcode: OpcodeInfo) {
        // TODO: processDCP opcode
    }

    /// Handles the processDEC opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processDEC(opcode: OpcodeInfo) {
        // TODO: processDEC opcode
    }

    /// Handles the processINY opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processINY(opcode: OpcodeInfo) {
        // TODO: processINY opcode
    }

    /// Handles the processDEX opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processDEX(opcode: OpcodeInfo) {
        // TODO: processDEX opcode
    }

    /// Handles the processAXS opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processAXS(opcode: OpcodeInfo) {
        // TODO: processAXS opcode
    }

    /// Handles the processBNE opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processBNE(opcode: OpcodeInfo) {
        // TODO: processBNE opcode
    }

    /// Handles the processCLD opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processCLD(opcode: OpcodeInfo) {
        // TODO: processCLD opcode
    }

    /// Handles the processCPX opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processCPX(opcode: OpcodeInfo) {
        // TODO: processCPX opcode
    }

    /// Handles the processSBC opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processSBC(opcode: OpcodeInfo) {
        // TODO: processSBC opcode
    }

    /// Handles the processISC opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processISC(opcode: OpcodeInfo) {
        // TODO: processISC opcode
    }

    /// Handles the processINC opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processINC(opcode: OpcodeInfo) {
        // TODO: processINC opcode
    }

    /// Handles the processINX opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processINX(opcode: OpcodeInfo) {
        // TODO: processINX opcode
    }

    /// Handles the processBEQ opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processBEQ(opcode: OpcodeInfo) {
        // TODO: processBEQ opcode
    }

    /// Handles the processSED opcode.
    ///
    /// - Parameter opcode: The opcode information.
    ///
    @inlinable func processSED(opcode: OpcodeInfo) {
        // TODO: processSED opcode
    }
}

