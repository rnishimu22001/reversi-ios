//
//  ReversiViewModelTests.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/05/04.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Combine
import XCTest
@testable import Reversi

final class ReversiViewModelTests: XCTestCase {
    
    var cancellables: [AnyCancellable] = []
    
    override func tearDown() {
        cancellables = []
    }
    
    func testReset() {
        var board = Board()
        
        try! board.set(disk: .dark, at: Coordinates(x: 2, y: 2))
        try! board.set(disk: .dark, at: Coordinates(x: 2, y: 3))
        try! board.set(disk: .dark, at: Coordinates(x: 2, y: 4))
        try! board.set(disk: .light, at: Coordinates(x: 1, y: 4))
        
        var target = ReversiViewModelImplementation(board: board)
        let darkPlayerExpectation = expectation(description: "darkのplayer情報が更新されること、購読時とアップデート時で2回呼ばれる")
        darkPlayerExpectation.expectedFulfillmentCount = 2
        let lightPlayerExpectation = expectation(description: "lightのplayer情報が更新されること、購読時にのみ呼ばれる")
        var darkCount = 3
        cancellables.append(target.darkPlayerStatus.sink {
            darkPlayerExpectation.fulfill()
            XCTAssertEqual($0.diskCount, darkCount)
            darkCount += 1
        })
        cancellables.append(target.lightPlayerStatus.sink {
            lightPlayerExpectation.fulfill()
            XCTAssertEqual($0.diskCount, 1)
        })
        
        target.set(disk: .dark, at: Coordinates(x: 1, y: 1))
        wait(for: [darkPlayerExpectation, lightPlayerExpectation], timeout: 0.1)
    }
    
    func testSetSingleDisk() {
        
    }
    
    func testSetMultiDisk() {
        
    }
    
    func testRestore() {
        
    }
}
