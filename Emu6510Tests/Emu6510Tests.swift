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
    var testData: CPUTestData? = nil

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testOpCodes() throws {
        doIt9()
    }

//    func testCPUClock() throws {
//        testData = CPUTestData()
//
//        if let d: CPUTestData = testData {
//            let clock: CPUClock = CPUClock(frequency: VideoStandard.C64_NTSC.rawValue) { if let d2: CPUTestData = self.testData { d2.ping() } }
//            clock.start()
//            while d.cc < 10000 {}
//            clock.stop()
//
//            let tots: UInt64 = (d.st2 - d.st1)
//            let avg:  UInt64 = ((d.cc > 0) ? UInt64((Double(tots) / Double(d.cc)) + 0.5) : 0)
//
//            print("    Start Time: \(d.st1)ns")
//            print("     Stop Time: \(d.st2)ns")
//            print("Total Run Time: \(tots)ns")
//            print(" Closure Count: \(d.cc)")
//            print("  Average Time: \(avg)ns")
//        }
//        else {
//            XCTFail("Test did not run.")
//        }
//    }

    //    func testPerformanceExample() throws {
    //        // This is an example of a performance test case.
    //        self.measure {
    //            // Put the code you want to measure the time of here.
    //        }
    //    }
}

class CPUTestData {
    var cc:  UInt64
    var st1: UInt64
    var st2: UInt64

    init() {
        st1 = 0
        st2 = 0
        cc = 0
    }

    func ping() {
        if st1 == 0 { st1 = getMonotonic() }
        else { st2 = getMonotonic() }
        cc += 1
    }
}
