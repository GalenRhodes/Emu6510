/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Emu6510
 *    FILENAME: Subs.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 6/10/21
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

let templatePath = "Templates"
let sourcePath   = "Sources/Emu6510"

let opcodeList: [[String]] = getOpcodes()

func illegalOpcodeList(_ opcodeList: [[String]]) {
    var data: [String: [(String, String)]] = [:]

    for o in opcodeList.filter({ s in s[5] == "true" }) {
        if var d: [(String, String)] = data[o[1]] {
            d <+ (o[2], o[0])
            data[o[1]] = d
        }
        else {
            var d: [(String, String)] = []
            d <+ (o[2], o[0])
            data[o[1]] = d
        }
    }

    for k in data.keys.sorted() {
        if let d = data[k] {
            print("\(k): ", terminator: "")
            var b = true
            for e in d.sorted(by: { t1, t2 in (t1.0 < t2.0) }) {
                if b { b = false }
                else { print(", ", terminator: "") }
                print("%-4s (%4s)".format(e.0, e.1), terminator: "")
            }
            print()
        }
    }
}

//***********************************************************************************************************************************************************************************
func forStudy(_ opcodeList: [[String]]) {
    print("\nPLUS ONE INSTRUCTIONS\n")

    for (n, i) in opcodeList.sorted(by: { a, b in (a[1] < b[1]) || ((a[1] == b[1]) && (a[2] < b[2])) }).enumerated() {
        if i[4].count > 1 {
            print("%3d> \(i[0]): \(i[1]) - \(i[2])".format(n))
        }
    }

    print("\nADDRESSING MODE LIST\n")

    var foo1 = fooBar(opcodeList.map({ s -> (String, UInt8) in (s[2], UInt8(s[0][2 ..< 4], radix: 16) ?? 0) }))

    for (am, bilo, bihi, oc) in foo1 {
        print("%-4s \(bihi) \(bilo) - %#04x".format(am, oc))
    }

    print("\nINSTRUCTION LIST\n")

    foo1 = fooBar(opcodeList.filter { s in s[5] == "false" }.map({ s -> (String, UInt8) in (s[1], UInt8(s[0][2 ..< 4], radix: 16) ?? 0) }))

    for (am, bilo, bihi, oc) in foo1.sorted(by: { a, b in (a.am < b.am) }) {
        print("%-4s \(bihi) \(bilo) - %#04x".format(am, oc))
    }

    func fooBar(_ array: [(String, UInt8)]) -> [(am: String, bilo: String, bihi: String, oc: UInt8)] {
        var foo:  [String: UInt8]                                       = [:]
        var foo1: [(am: String, bilo: String, bihi: String, oc: UInt8)] = []

        for i in array {
            if let o = foo[i.0] {
                foo[i.0] = (o & i.1)
            }
            else {
                foo[i.0] = i.1
            }
        }

        for (am, oc) in foo { let bi = toBinary(oc, sep: "", pad: 8); foo1 <+ (am: am, bilo: String(bi[4 ..< 8]), bihi: String(bi[0 ..< 4]), oc: oc) }

        return foo1.sorted(by: { a, b in ((a.bilo < b.bilo) || ((a.bilo == b.bilo) && (a.bihi < b.bihi))) })
    }
}

//***********************************************************************************************************************************************************************************
func doAddressingModes(_ opcodeList: [[String]]) {
    var dict: [String: String] = [:]
    for e in opcodeList {
        if let b = dict[e[2]] { if b != e[3] { fatalError("duplicate entry: addressing mode: \(e[2]); existing byte count: \(b); new byte count: \(e[3])") } }
        dict[e[2]] = e[3]
    }
    parseTemplate(filename: "MOS6502AddressingMode.swift") { (o, k) -> Bool in
        switch k {
            case "INSERT:A": for am in dict.keys.sorted() { o.append(contentsOf: "%8s %s\n".format("case", am)) }
            case "INSERT:B": for am in dict.keys.sorted() { o.append(contentsOf: "%16s .%-5s return %s\n".format("case", "\(am):", am)) }
            case "INSERT:C": for am in dict.keys.sorted() { o.append(contentsOf: "%16s .%-5s return %s\n".format("case", "\(am):", (dict[am] ?? "0"))) }
            default: return false
        }
        return true
    }
}

//***********************************************************************************************************************************************************************************
func doMnemonics(_ opcodeList: [[String]]) {
    let set = Set<String>(opcodeList.map { $0[1] }).sorted()

    parseTemplate(filename: "MOS6502Mnemonic.swift") { (o: inout String, k: String) -> Bool in
        switch k {
            case "INSERT:A": for mnemonic in set { o.append(contentsOf: "    case \(mnemonic)\n") }
            case "INSERT:B": for mnemonic in set { o.append(contentsOf: "            case .\(mnemonic): return \"\(mnemonic)\"\n") }
            case "INSERT:C": for mnemonic in set {
                o.append(contentsOf: "            case .\(mnemonic): return Set<MOS6502AddressingMode>([")
                for a in opcodeList.filter({ $0[1] == mnemonic }).map({ $0[2] }) { o.append(contentsOf: " .\(a),") }
                o.append(contentsOf: " ])\n")
            }
            default: return false
        }
        return true
    }
}

//***********************************************************************************************************************************************************************************
func doOpcodes(_ opcodeList: [[String]]) {
    parseTemplate(filename: "MOS6502OpcodeList.swift") { (out: inout String, key: String) -> Bool in
        guard key == "INSERT:A" else { return false }
        for oc in opcodeList {
            out.append(contentsOf: "    MOS6502Opcode(opcode: \(oc[0]), mnemonic: .\(oc[1]), addressingMode: .%-5s cycles: ".format("\(oc[2]),"))

            let cycles = oc[4]
            if cycles.count == 1 { out.append(contentsOf: "\(cycles), plus1: false") }
            else { out.append(contentsOf: "\(cycles.first ?? "2"), plus1: true ") }

            out.append(contentsOf: ", illegal: %-6s ".format("\(oc[5]),"))

            out.append(contentsOf: "affectedFlags: [")
            var f: Bool = false
            for c in oc[6] {
                switch c {
                    case "C": out.append(contentsOf: "\(f ? ", " : " ").Carry"); f = true
                    case "Z": out.append(contentsOf: "\(f ? ", " : " ").Zero"); f = true
                    case "I": out.append(contentsOf: "\(f ? ", " : " ").IRQ"); f = true
                    case "D": out.append(contentsOf: "\(f ? ", " : " ").Decimal"); f = true
                    case "B": out.append(contentsOf: "\(f ? ", " : " ").Break"); f = true
                    case "V": out.append(contentsOf: "\(f ? ", " : " ").Overflow"); f = true
                    case "N": out.append(contentsOf: "\(f ? ", " : " ").Negative"); f = true
                    default: break
                }
            }
            out.append(contentsOf: "\(f ? " " : "")]),\n")
        }
        return true
    }
}

//***********************************************************************************************************************************************************************************
func getOpcodes() -> [[String]] {
    guard let data: String = try? String(contentsOfFile: "Other/65c02_all.csv") else { fatalError("File not found.") }
    var opcodeList: [[String]] = data.split(on: "\r?\n").map { $0.split(on: "\\s*,\\s*", limit: -1) }
    opcodeList.removeFirst()

    guard opcodeList.count == 256 else {
        for (i, oc) in opcodeList.enumerated() {
            let op = oc[0]
            let j  = (Int(op[op.index(op.startIndex, offsetBy: 2) ..< op.endIndex], radix: 16) ?? -1)
            guard i == j else {
                fatalError("There are only \(opcodeList.count) out of 256 opcodes found. Opcode 0x\(String(i, radix: 16)) is missing.")
            }
        }
        fatalError("There are only \(opcodeList.count) out of 256 opcodes found.")
    }
    return opcodeList
}
