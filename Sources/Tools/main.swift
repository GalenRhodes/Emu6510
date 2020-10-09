//
//  main.swift
//  Tools
//
//  Created by Galen Rhodes on 9/24/20.
//

import Foundation
import Rubicon
import RingBuffer

let input:  String = (try? String(contentsOfFile: "Other/65c02.csv", encoding: String.Encoding.utf8)) ?? ""
let input2: String = (try? String(contentsOfFile: "Other/65c02_invalid.csv", encoding: String.Encoding.utf8)) ?? ""

let rxLines:  RegEx = try! RegEx(pattern: "(.+?)\\s*,(.+?)\\s*,(.+?)\\s*,(.+?)\\s*,(.+?)\\s*,(.+?)\\s*\\R")
let rxCycles: RegEx = try! RegEx(pattern: "/")

var shouldBe: UInt8 = 0

extension OpcodeInfo {
    @inlinable var handlerName: String { "process\(mnemonic)" }
    @inlinable var opcodeAsHex: String { ((opcode < 16) ? "0x0\(String(opcode, radix: 16, uppercase: false))" : "0x\(String(opcode, radix: 16, uppercase: false))") }

    func printInit() {
        print("OpcodeInfo(opcode: \(opcodeAsHex), mnemonic: \"\(mnemonic)\", addrMode: .\(addressingMode), isInvalid: \(isInvalid), cycleCount: \(cycleCount)", terminator: "")
        if affectedFlags == 0 { print("),") }
        else { print(", affectedFlags: \(ProcessorFlags.flagsList(flags: affectedFlags))),") }
    }

    func printCaseStatement() {
        print("case \(opcodeAsHex): \(handlerName)(opcode: Emu6510Opcodes[\(opcodeAsHex)])")
    }

    func printHandler(insSet: inout Set<String>) {
        if insSet.insert(handlerName).inserted {
            let c: String = "///"
            print("""
                  \(c) Handles the \(handlerName) opcode.
                  \(c) 
                  \(c) - Parameter opcode: The opcode information.
                  \(c) 
                  @inlinable func \(handlerName)(opcode: OpcodeInfo) {
                      // TODO: \(handlerName) opcode
                  }

                  """)
        }
    }
}

var strSet: Set<String> = []

for oi in Emu6510Opcodes {
    oi.printCaseStatement()
}

for oi in Emu6510Opcodes {
    oi.printHandler(insSet: &strSet)
}
