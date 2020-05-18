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

public typealias CPUIOPort = (directionRegister: UInt8, ioPort: UInt8)

public protocol IOPortListener: AnyObject {
    func ioPortStatusChanged(oldStatus: CPUIOPort, newStatus: CPUIOPort)
}

fileprivate protocol IOPortControler: AnyObject {
    var ioDirection:     UInt8 { get set }
    var ioPort:          UInt8 { get set }
    var ioPortListeners: [IOPortListener] { get set }
}

open class CPU65xx: IOPortControler, ClockListener {

    internal var statusRegister: UInt8 = 0
    internal var accumulator:    UInt8 = 0
    internal var registerX:      UInt8 = 0
    internal var registerY:      UInt8 = 0
    internal var stackPointer:   UInt8 = 255

    fileprivate var ioDirection:     UInt8 = 0
    fileprivate var ioPort:          UInt8 = 0
    fileprivate var ioPortListeners: [IOPortListener] = []

    internal var addressPointer: UInt16 = 0
    internal var addressBus:     AddressBusListener

    public init(memoryManager: MemoryManager) {
        self.addressBus = memoryManager
        self.ioPortListeners.append(memoryManager)
    }

    public func clockSignal(tick: UInt64) {}
}
