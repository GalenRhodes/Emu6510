/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: CPU65xx.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/5/20
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

///
/// Denotes which exact CPU from the MOS 6500 family is being emulated.
///
public enum MOS65xxFamily {
    case Mos6502
    case Mos6510
    case Mos8510
}

public typealias CPUIOPort = (directionRegister: UInt8, ioPort: UInt8)

public protocol IOPortListener: AnyObject {
    func ioPortStatusChanged(oldStatus: CPUIOPort, newStatus: CPUIOPort)
}

public protocol IOPortControler: AnyObject {
    func isInput(bit: Bits8) -> Bool
    subscript(bit: Bits8) -> Bool { get set }
}

public protocol MOS65xxCPU {
    var cpuID:          MOS65xxFamily { get }
    var statusRegister: UInt8 { get }
    var accumulator:    UInt8 { get }
    var registerX:      UInt8 { get }
    var registerY:      UInt8 { get }
    var stackPointer:   UInt8 { get }
    var programCounter: UInt16 { get }
    var lastOpcode:     UInt8 { get }
    var panic:          Bool { get }

    func nextInstruction() -> Bool
    func handleError()
}

open class CPU65xx: MOS65xxCPU {

    public var cpuID:          MOS65xxFamily { .Mos6502 }
    public var statusRegister: UInt8  = 0
    public var accumulator:    UInt8  = 0
    public var registerX:      UInt8  = 0
    public var registerY:      UInt8  = 0
    public var stackPointer:   UInt8  = 255
    public var programCounter: UInt16 = 0
    public var lastOpcode:     UInt8  = 0
    public var panic:          Bool   = false
    public var addressBus:     AddressBusListener
    public let cpuClock:       CPUClock

    ///
    /// This gets set to the number of clock cycles the instruction takes minus one. The clock handler will allow this counter to go to zero before executing the next instruction.
    ///
    public var waitCycles:     UInt8  = 0

    public init(clock: CPUClock, memoryManager: MemoryManager) {
        addressBus = memoryManager
        cpuClock = clock
        cpuClock.addClosure { if !self.nextInstruction() { self.handleError() } }
    }

    public func nextInstruction() -> Bool {
        if waitCycles > 0 {
            waitCycles -= 1
            return true
        }
        else {
            let opcode: UInt8 = getNextPCByte()
            return (panic ? false : dispatchInstruction(opcode))
        }
    }

    public func handleError() {}

    @inlinable func dispatchInstruction(_ opcode: UInt8) -> Bool {
        lastOpcode = opcode
        guard let od: Mos6502OpcodeInfo = MOS6502_OPCODES[opcode] else { return false }
        let oprands: [UInt8] = getOperands(od.bytes - 1)

        if !panic {
            waitCycles = (od.cycles - 1)

            switch od.numonic {
                case .ADC: opcodeADC(od, oprands)
                case .AND: opcodeAND(od, oprands)
                case .ASL: opcodeASL(od, oprands)
                case .BCC: opcodeBCC(od, oprands)
                case .BCS: opcodeBCS(od, oprands)
                case .BEQ: opcodeBEQ(od, oprands)
                case .BIT: opcodeBIT(od, oprands)
                case .BMI: opcodeBMI(od, oprands)
                case .BNE: opcodeBNE(od, oprands)
                case .BPL: opcodeBPL(od, oprands)
                case .BRK: opcodeBRK(od, oprands)
                case .BVC: opcodeBVC(od, oprands)
                case .BVS: opcodeBVS(od, oprands)
                case .CLC: opcodeCLC(od, oprands)
                case .CLD: opcodeCLD(od, oprands)
                case .CLI: opcodeCLI(od, oprands)
                case .CLV: opcodeCLV(od, oprands)
                case .CMP: opcodeCMP(od, oprands)
                case .CPX: opcodeCPX(od, oprands)
                case .CPY: opcodeCPY(od, oprands)
                case .DEC: opcodeDEC(od, oprands)
                case .DEX: opcodeDEX(od, oprands)
                case .DEY: opcodeDEY(od, oprands)
                case .EOR: opcodeEOR(od, oprands)
                case .INC: opcodeINC(od, oprands)
                case .INX: opcodeINX(od, oprands)
                case .INY: opcodeINY(od, oprands)
                case .JMP: opcodeJMP(od, oprands)
                case .JSR: opcodeJSR(od, oprands)
                case .LDA: opcodeLDA(od, oprands)
                case .LDX: opcodeLDX(od, oprands)
                case .LDY: opcodeLDY(od, oprands)
                case .LSR: opcodeLSR(od, oprands)
                case .NOP: opcodeNOP(od, oprands)
                case .ORA: opcodeORA(od, oprands)
                case .PHA: opcodePHA(od, oprands)
                case .PHP: opcodePHP(od, oprands)
                case .PLA: opcodePLA(od, oprands)
                case .PLP: opcodePLP(od, oprands)
                case .ROL: opcodeROL(od, oprands)
                case .ROR: opcodeROR(od, oprands)
                case .RTI: opcodeRTI(od, oprands)
                case .RTS: opcodeRTS(od, oprands)
                case .SBC: opcodeSBC(od, oprands)
                case .SEC: opcodeSEC(od, oprands)
                case .SED: opcodeSED(od, oprands)
                case .SEI: opcodeSEI(od, oprands)
                case .STA: opcodeSTA(od, oprands)
                case .STX: opcodeSTX(od, oprands)
                case .STY: opcodeSTY(od, oprands)
                case .TAX: opcodeTAX(od, oprands)
                case .TAY: opcodeTAY(od, oprands)
                case .TSX: opcodeTSX(od, oprands)
                case .TXA: opcodeTXA(od, oprands)
                case .TXS: opcodeTXS(od, oprands)
                case .TYA: opcodeTYA(od, oprands)
            }
        }

        return !panic
    }

    ///
    /// Picks up the next byte indexed by the programCounter. If there is no next byte (e.g. - At the top of RAM) then the panic flag is set and zero is returned.
    ///
    /// - Returns: the next byte or zero if there is no next byte.
    ///
    @inlinable func getNextPCByte() -> UInt8 {
        if let b: UInt8 = addressBus[++programCounter] { return b }
        panic = true
        return 0
    }

    ///
    /// Get the next count bytes from the addressBus indexed by the programCounter. If there are not enough next bytes (e.g. - At the top of RAM) then
    /// the panic flag is set and zero are substituted for the needed bytes.
    ///
    /// - Parameter count: the number of bytes to get.
    /// - Returns: an array of the bytes.
    ///
    @inlinable func getOperands(_ count: UInt8) -> [UInt8] {
        switch count {
            case 1:
                return [ getNextPCByte() ]
            case 2:
                let b1: UInt8 = getNextPCByte()
                let b2: UInt8 = getNextPCByte()
                return [ b1, b2 ]
            default:
                return []
        }
    }

    ///
    /// Process the ADC opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeADC(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the AND opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeAND(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the ASL opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeASL(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the BCC opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeBCC(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the BCS opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeBCS(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the BEQ opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeBEQ(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the BIT opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeBIT(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the BMI opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeBMI(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the BNE opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeBNE(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the BPL opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeBPL(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the BRK opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeBRK(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the BVC opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeBVC(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the BVS opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeBVS(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the CLC opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeCLC(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the CLD opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeCLD(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the CLI opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeCLI(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the CLV opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeCLV(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the CMP opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeCMP(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the CPX opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeCPX(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the CPY opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeCPY(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the DEC opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeDEC(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the DEX opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeDEX(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the DEY opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeDEY(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the EOR opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeEOR(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the INC opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeINC(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the INX opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeINX(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the INY opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeINY(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the JMP opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeJMP(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the JSR opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeJSR(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the LDA opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeLDA(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the LDX opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeLDX(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the LDY opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeLDY(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the LSR opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeLSR(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the NOP opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeNOP(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the ORA opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeORA(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the PHA opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodePHA(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the PHP opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodePHP(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the PLA opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodePLA(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the PLP opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodePLP(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the ROL opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeROL(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the ROR opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeROR(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the RTI opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeRTI(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the RTS opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeRTS(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the SBC opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeSBC(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the SEC opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeSEC(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the SED opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeSED(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the SEI opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeSEI(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the STA opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeSTA(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the STX opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeSTX(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the STY opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeSTY(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the TAX opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeTAX(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the TAY opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeTAY(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the TSX opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeTSX(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the TXA opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeTXA(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the TXS opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeTXS(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}

    ///
    /// Process the TYA opcode.
    ///
    /// - Parameter od: the opcode information.
    ///
    @inlinable func opcodeTYA(_ od: Mos6502OpcodeInfo, _ oprands: [UInt8]) {}
}
