/*******************************************************************************************************************************************************************************//*
 *     PROJECT: Emu6510
 *    FILENAME: MOS6502SystemMemoryMap.swift
 *         IDE: AppCode
 *      AUTHOR: Galen Rhodes
 *        DATE: 5/17/21
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

open class MOS6502SystemMemoryMap: MOS6502Addressable {
    var addressableItems: [AddressableItem] = []

    public var ramBankCount: Int = 0

    open var list: [String] { addressableItems.map { item -> String in item.name } }

    public init(baseRAM count: Int = SixtyFourK) {
        ramBankCount = ((count + (SixtyFourK - 1)) / SixtyFourK)
        if ramBankCount > 0 {
            let c = (ramBankCount - 1)
            let r = (count % SixtyFourK)
            for i in (0 ..< c) {
                addressableItems <+ AddressableItem(name: "RAM Bank \(i)", addressableItem: MOS6502Ram(start: 0, count: SixtyFourK), layer: 0, visible: (i == 0))
            }
            if r > 0 {
                addressableItems <+ AddressableItem(name: "RAM Bank \(c)", addressableItem: MOS6502Ram(start: 0, count: r), layer: 0, visible: (c == 0))
            }
        }

        super.init(start: 0, count: SixtyFourK)
    }

    public init(baseRAMBanks: [(Index, Int)]) {
        ramBankCount = baseRAMBanks.count
        for (i, r): (Int, (Index, Int)) in baseRAMBanks.enumerated() {
            addressableItems <+ AddressableItem(name: "RAM Bank \(i)", addressableItem: MOS6502Ram(start: r.0, count: r.1), layer: 0, visible: (i == 0))
        }
        super.init(start: 0, count: SixtyFourK)
    }

    open func remove(name: String) -> MOS6502Addressable? {
        let idx = addressableItems.firstIndex { item in item.name == name }
        guard let idx = idx else { return nil }
        return addressableItems.remove(at: idx).addressableItem
    }

    open func add(name: String, item: MOS6502Addressable, layer: Int, visible: Bool) throws {
        guard !addressableItems.contains(where: { item in item.name == name }) else {
            throw MOS6502Error.AlreadyExists(description: "System Addressable Item Already Exists: \(name)")
        }
        addressableItems <+ AddressableItem(name: name, addressableItem: item, layer: layer, visible: visible)
        sortLayers()
    }

    open func set(visible: Bool, name: String) -> Bool {
        guard let item = itemFor(name: name) else { return false }
        item.visible = visible
        return true
    }

    open override subscript(position: Index) -> UInt8 {
        get {
            guard let item = itemAt(position: position) else { return 0 }
            return item.addressableItem[position]
        }
        set { if let item = itemAt(position: position) { item.addressableItem[position] = newValue } }
    }

    func itemFor(name: String) -> AddressableItem? {
        addressableItems.first { item in item.name == name }
    }

    func itemAt(position: Index) -> AddressableItem? {
        testIndex(position: position)
        for item in addressableItems {
            if item.visible && item.addressableItem.memoryRange.contains(position) {
                return item
            }
        }
        return nil
    }

    func sortLayers() {
        addressableItems.sort { item1, item2 in item1.layer > item2.layer }
    }

    class AddressableItem {
        let name:            String
        let addressableItem: MOS6502Addressable
        let layer:           Int
        var visible:         Bool

        init(name: String, addressableItem: MOS6502Addressable, layer: Int, visible: Bool) {
            self.name = name
            self.addressableItem = addressableItem
            self.layer = layer
            self.visible = visible
        }
    }
}
