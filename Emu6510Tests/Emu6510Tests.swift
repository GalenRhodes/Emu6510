//
//  Emu6510Tests.swift
//  Emu6510Tests
//
//  Created by Galen Rhodes on 5/18/20.
//  Copyright © 2020 Project Galen. All rights reserved.
//

import XCTest
@testable import Emu6510



class Emu6510Tests: XCTestCase {

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testOpCodes() throws {
        var z: Int = 0
        for x in (0..<128) {
            z += 1
            print("\(x), ", terminator: (((z % 16) == 0) ? "\n" : ""))
        }
        for y: Int in (-128..<0) {
            z += 1
            print("\(y), ", terminator: (((z % 16) == 0) ? "\n" : ""))
        }
        print("")
    }
}
