/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Emu6510
 *    FILENAME: ParseTemplate.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/14/21
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

func parseTemplate(filename: String, with block: (inout String, String) -> Bool) {
    guard let template: String = try? String(contentsOfFile: "\(templatePath)/\(filename)") else { fatalError("File not found: \(templatePath)/\(filename)") }
    do { try parseTemplate(template, with: block).write(toFile: "\(sourcePath)/\(filename)", atomically: false, encoding: .utf8) }
    catch let e { fatalError("Unable to safe file \"\(sourcePath)/\(filename)\": \(e)") }
}

fileprivate func parseTemplate(_ template: String, with block: (inout String, String) -> Bool) -> String {
    guard let rx: RegularExpression = RegularExpression(pattern: "/\\*@\\{([^}]+)\\}@\\*/") else { fatalError("Invalid REGEX") }
    var out:  String       = ""
    var lIdx: String.Index = template.startIndex

    rx.forEachMatch(in: template) { m, _, _ in
        if let m = m {
            out.append(contentsOf: template[lIdx ..< m.range.lowerBound])
            lIdx = m.range.upperBound

            if let key = m[1].subString {
                if key == "DATE" {
                    out.append("%tm/%<td/%<tY".format(Date()))
                }
                else {
                    var _t: String = ""
                    if block(&_t, key) { out.append(_t) }
                    else { out.append(m.subString) }
                }
            }
            else {
                out.append(m.subString)
            }
        }
    }

    out.append(contentsOf: template[lIdx ..< template.endIndex])
    return out
}
