//
//  BoardTests.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest
@testable import Reversi

final class BoardTests: XCTestCase {
    
    func testRange() {
        XCTAssertEqual(Board().xRange, BoardView().xRange)
        XCTAssertEqual(Board().yRange, BoardView().yRange)
    }
}
