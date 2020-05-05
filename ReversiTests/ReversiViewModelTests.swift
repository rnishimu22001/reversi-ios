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
    
    func testUpdateMessage() {
        XCTContext.runActivity(named: "ゲーム中") { _ in
            let mockSpecifications = MockReversiSpecifications()
            var target = ReversiViewModelImplementation(game: Game(turn: .light, board: Board(), darkPlayer: .manual, lightPlayer: .computer),
                                                        specifications: mockSpecifications)
            mockSpecifications.isEndOfGame = false
            let messageExpectation = expectation(description: "messageの情報が更新されること, 購読とメソッド実行で2回呼ばれる")
            messageExpectation.expectedFulfillmentCount = 2
            cancellables.append(target.message.sink {
                messageExpectation.fulfill()
                let status = MessageDisplayData(status: .playing(turn: .light))
                XCTAssertEqual($0.displayedDisk, status.displayedDisk)
                XCTAssertEqual($0.message, status.message)
            })
            target.updateMessage()
            wait(for: [messageExpectation], timeout: 0.1)
        }
        XCTContext.runActivity(named: "ゲーム終了") { _ in
            let mockSpecifications = MockReversiSpecifications()
            var target = ReversiViewModelImplementation(game: Game(turn: .dark, board: Board(), darkPlayer: .manual, lightPlayer: .computer),
                                                        specifications: mockSpecifications)
            mockSpecifications.isEndOfGame = true
            let messageExpectation = expectation(description: "messageの情報が更新されること, 購読とメソッド実行で2回呼ばれる")
            messageExpectation.expectedFulfillmentCount = 2
            var count = 1
            cancellables.append(target.message.sink {
                messageExpectation.fulfill()
                switch count {
                case 1:
                    let status = MessageDisplayData(status: .playing(turn: .dark))
                    XCTAssertEqual($0.displayedDisk, status.displayedDisk)
                    XCTAssertEqual($0.message, status.message)
                case 2:
                    let status = MessageDisplayData(status: .ending(winner: nil))
                    XCTAssertEqual($0.displayedDisk, status.displayedDisk)
                    XCTAssertEqual($0.message, status.message)
                default:
                    XCTFail("2回以上呼ばれない想定です")
                }
                count += 1
            })
            target.updateMessage()
            wait(for: [messageExpectation], timeout: 0.1)
        }
    }
    
    func testUpdateCount() {
        var board = Board()
        
        try! board.set(disk: .dark, at: Coordinates(x: 2, y: 2))
        try! board.set(disk: .dark, at: Coordinates(x: 2, y: 3))
        try! board.set(disk: .dark, at: Coordinates(x: 2, y: 4))
        try! board.set(disk: .light, at: Coordinates(x: 1, y: 4))
        
        var target = ReversiViewModelImplementation(game: Game(turn: .dark, board: board, darkPlayer: .manual, lightPlayer: .computer))
        let darkPlayerExpectation = expectation(description: "darkのplayer情報が更新されること、購読時とアップデート時で2回呼ばれる")
        darkPlayerExpectation.expectedFulfillmentCount = 2
        let lightPlayerExpectation = expectation(description: "lightのplayer情報が更新されること、購読時にのみ呼ばれる")
        var darkCount = 3
        cancellables.append(target.darkPlayerStatus.sink {
            darkPlayerExpectation.fulfill()
            XCTAssertEqual($0.diskCount, darkCount)
            XCTAssertEqual($0.playerType, .manual)
            darkCount += 1
        })
        cancellables.append(target.lightPlayerStatus.sink {
            lightPlayerExpectation.fulfill()
            XCTAssertEqual($0.diskCount, 1)
            XCTAssertEqual($0.playerType, .computer)
        })
        
        target.set(disk: .dark, at: Coordinates(x: 1, y: 1))
        target.updateDiskCount()
        wait(for: [darkPlayerExpectation, lightPlayerExpectation], timeout: 0.1)
    }
    
    func testSetSingleDisk() {
        
    }
    
    func testSetMultiDisk() {
        
    }
    
    func testRestore() {
        
    }
}
