//
//  DiskTests.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/05/02.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest
@testable import Reversi

final class DiskTests: XCTestCase {
    
    func testSides() {
        XCTAssertEqual([.dark, .light], Disk.allCases)
    }
}
