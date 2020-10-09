//
//  main.swift
//  DocFixer
//
//  Created by Galen Rhodes on 3/26/20.
//  Copyright © 2020 Project Galen. All rights reserved.
//

import Foundation
import PGDocFixer
// import Rubicon
//
//let filename: String           = "/Users/grhodes/Projects/2020/SwiftProjects/Emu6510/Sources/Emu6510/CPU.swift"
//let src:      String           = try! String(contentsOfFile: filename, encoding: String.Encoding.utf8)
//let rx1:      RegEx            = try! RegEx(pattern: "^[ \\t]+/\\*={123}\\*/\\R(?:[ \\t]+///.*\\R){4}[ \\t]+@inlinable open func process(\\w+)[^}]+\\}\\R", options: [ RegEx.Options.anchorsMatchLines ])
//var map:      [String: String] = [:]
//var first:    NSRange?         = nil
//var last:     NSRange?         = nil
//
//rx1.withMatches(in: src) {
//    (match: RegExResult, _) in
//    if first == nil { first = match.range }
//    last = match.range
//    let key: String = src.substr(nsRange: match.range(at: 1))
//    let val: String = src.substr(nsRange: match.range)
//    map[key] = val
//    return false
//}
//
//if let f: NSRange = first, let l: NSRange = last {
//    var srcout: String = String(src[src.startIndex ..< src.index(idx: f.location)])
//    let keys: [(key: String, value: String)] = map.sorted(by: <)
//
//    for item: (key: String, value: String) in keys {
//        srcout += "\n\(item.value)"
//    }
//
//    srcout += String(src[src.index(idx: l.upperBound) ..< src.endIndex])
//
//    print(srcout)
//    try! srcout.write(toFile: filename, atomically: false, encoding: String.Encoding.utf8)
//}

exit(Int32(doDocFixer(args: CommandLine.arguments, replacements: [])))
