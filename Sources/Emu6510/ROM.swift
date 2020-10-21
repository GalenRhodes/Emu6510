/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: ROM.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 10/20/20
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

open class ROM: RAM {

    public convenience init(start: Int, end: Int) {
        guard end > start else { fatalError("Invalid arguments. End must be > start.") }
        self.init(readOnly: true, start: start, end: end)
    }

    public convenience init(start: Int, count: Int) {
        guard count >= 0 else { fatalError("Invalid arguments. Count must be >= 0.") }
        self.init(readOnly: true, start: start, end: start + count)
    }

    public static func == (lhs: ROM, rhs: ROM) -> Bool { lhs === rhs }
}

