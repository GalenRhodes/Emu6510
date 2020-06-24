/************************************************************************//**
 *     PROJECT: Emu6510
 *    FILENAME: MemoryManager.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/14/20
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

public protocol MemoryManager: AddressBusListener, IOPortListener {
}

public class C64MemoryManager: MemoryManager {
    public private(set) var offset: UInt16    = 0
    public private(set) var size:   UInt32    = AddressRange
    public private(set) var ioPort: CPUIOPort = (directionRegister: 0, ioPort: 0)

    public init() {}

    public subscript(address: UInt16) -> UInt8? {
        get { nil }
        set {}
    }

    public func ioPortStatusChanged(oldStatus: CPUIOPort, newStatus: CPUIOPort) {
        ioPort = newStatus
    }
}
