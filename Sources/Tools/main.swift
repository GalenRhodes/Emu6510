//
//  main.swift
//  Tools
//
//  Created by Galen Rhodes on 9/24/20.
//

import Foundation
import Rubicon
import RingBuffer

let input:    String = (try? String(contentsOfFile: "65c02.csv", encoding: String.Encoding.utf8)) ?? ""
let rxLines:  RegEx  = try! RegEx(pattern: "([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),(.+)\\R")
let rxCycles: RegEx  = try! RegEx(pattern: "/")

func scanFile(body: @escaping (String, String, String, String, String, String) -> ()) {
    var first: Bool = true;
    rxLines.withMatches(in: input) {
        (match: RegExResult, _) in

        if first {
            first = false
        }
        else {
            let opcode:        String = input.substr(nsRange: match.range(at: 1))
            let mnemonic:      String = input.substr(nsRange: match.range(at: 2))
            let addrMode:      String = input.substr(nsRange: match.range(at: 3))
            let byteCount:     String = input.substr(nsRange: match.range(at: 4))
            let cycleCounts:   String = input.substr(nsRange: match.range(at: 5))
            let affectedFlags: String = input.substr(nsRange: match.range(at: 6))
            body(opcode, mnemonic, addrMode, byteCount, cycleCounts, affectedFlags)
        }

        return false
    }
}

print("public let Emu6510Opcodes: [UInt8: OpcodeInfo] = [")
scanFile() { (opcode: String, mnemonic: String, addrMode: String, byteCount: String, cycleCounts: String, affectedFlags: String) in
    print("    \(opcode): OpcodeInfo(opcode: \(opcode), mnemonic: \"\(mnemonic)\", addrMode: .\(addrMode), byteCount: \(byteCount), cycleCount: [", terminator: "")
    var last: Int = 0
    rxCycles.withMatches(in: cycleCounts) {
        (cMatch: RegExResult, _) in
        let r: NSRange = cMatch.range
        let s: NSRange = NSRange(location: last, length: (r.location - last))
        last = r.upperBound
        print("\(cycleCounts.substr(nsRange: s)),", terminator: "")
        return false
    }
    let s: String = cycleCounts.substring(from: cycleCounts.index(idx: last))
    print("\(s)", terminator: "")

    print("], affectedFlags: [ ", terminator: "")
    for ch: Character in affectedFlags {
        switch ch {
            case "C": print(".Carry, ", terminator: "")
            case "Z": print(".Zero, ", terminator: "")
            case "I": print(".Interrupt, ", terminator: "")
            case "D": print(".Decimal, ", terminator: "")
            case "B": print(".Break, ", terminator: "")
            case "V": print(".Overflow, ", terminator: "")
            case "N": print(".Negative, ", terminator: "")
            default: break
        }
    }
    print("]),")
}
print("]")
print("")

scanFile() { (opcode: String, mnemonic: String, addrMode: String, byteCount: String, cycleCounts: String, affectedFlags: String) in
    print("    @inlinable public func perform\(mnemonic)_\(addrMode)(opcodeInfo: OpcodeInfo?) {")
    print("        if let opcodeInfo: OpcodeInfo = opcodeInfo {")
    print("        }")
    print("        else {")
    print("            // TODO: OPCODE_NOT_FOUND_ERROR")
    print("        }")
    print("    }")
}

print("")
print("    switch opcode {")
scanFile() { (opcode: String, mnemonic: String, addrMode: String, byteCount: String, cycleCounts: String, affectedFlags: String) in
    print("        case \(opcode): perform\(mnemonic)_\(addrMode)(opcodeInfo: Emu6510Opcodes[\(opcode)])")
}
print("        default: break")
print("    }")
print("")
