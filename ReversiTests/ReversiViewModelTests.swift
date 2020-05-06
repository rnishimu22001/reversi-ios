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
                    XCTAssertEqual($0.displayedDisk, status.displayedDisk, "初期値なのでdarkの手番")
                    XCTAssertEqual($0.message, status.message)
                case 2:
                    let status = MessageDisplayData(status: .ending(winner: nil))
                    XCTAssertEqual($0.displayedDisk, status.displayedDisk, "ボード上のディスクは同数なのでnil")
                    XCTAssertEqual($0.message, status.message, "引き分け想定")
                default:
                    XCTFail("3回以上呼ばれない想定です")
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
        let mockSpecifications = MockReversiSpecifications()
        var target = ReversiViewModelImplementation(game: Game(turn: .dark, board: board, darkPlayer: .manual, lightPlayer: .computer),
                                                    specifications: mockSpecifications)
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
        
        target.place(disk: .dark, at: Coordinates(x: 1, y: 1))
        target.updateDiskCount()
        wait(for: [darkPlayerExpectation, lightPlayerExpectation], timeout: 0.1)
    }
    
    func testSetDisk() {
        // Given
        let mockSpecifications = MockReversiSpecifications()
        var target = ReversiViewModelImplementation(game: Game(turn: .light, board: Board(), darkPlayer: .manual, lightPlayer: .computer),
                                                    specifications: mockSpecifications)
        let willSetCoordinates = Coordinates(x: 0, y: 0)
        // Then
        let boardExpectation = expectation(description: "ボードの情報が更新されること")
        cancellables.append(target.boardStatus.sink {
            boardExpectation.fulfill()
            switch $0 {
            case .withAnimation(let disks):
                XCTAssertEqual([willSetCoordinates] + mockSpecifications.stubbedFlippedDiskCoordinatesByPlacingResult,
                               disks.map { $0.coordinates },
                               "指定された並び方で座標が並ぶこと")
            case .withoutAnimation:
                XCTFail("アニメーションを伴う更新の想定")
                
            }
        })
        // When
        mockSpecifications.stubbedFlippedDiskCoordinatesByPlacingResult = [.init(x: 1, y: 1), .init(x: 2, y: 2), .init(x: 3, y: 3), .init(x: 1, y: 5)]
        target.place(disk: .dark, at: willSetCoordinates)
        wait(for: [boardExpectation], timeout: 0.01)
    }
    
    func testNextTurn() {
        let mockSpecifications = MockReversiSpecifications()
        var target = ReversiViewModelImplementation(game: Game(turn: .light, board: Board(), darkPlayer: .manual, lightPlayer: .computer),
                                                    specifications: mockSpecifications)
        mockSpecifications.isEndOfGame = false
        let messageExpectation = expectation(description: "messageの情報が更新されること, 購読とメソッド実行で2回呼ばれる")
        messageExpectation.expectedFulfillmentCount = 2
        var messageCount = 1
        cancellables.append(target.message.sink {
            messageExpectation.fulfill()
            switch messageCount {
            case 1:
                let status = MessageDisplayData(status: .playing(turn: .light))
                XCTAssertEqual($0.displayedDisk, status.displayedDisk)
                XCTAssertEqual($0.message, status.message)
            case 2:
                let status = MessageDisplayData(status: .playing(turn: .dark))
                XCTAssertEqual($0.displayedDisk, status.displayedDisk)
                XCTAssertEqual($0.message, status.message)
            default:
                XCTFail("3回以上呼ばれない")
            }
            messageCount += 1
        })
        target.nextTurn()
        XCTAssertEqual(target.turn, .dark, "手番が交代したのでdarkに移る")
        wait(for: [messageExpectation], timeout: 0.1)
    }
    
    func testChangePlayer() {
        XCTContext.runActivity(named: "darkの切り替え") { _ in
            var target = ReversiViewModelImplementation(game: Game(turn: .dark, board: Board(), darkPlayer: .manual, lightPlayer: .computer))
            let darkPlayerExpectation = expectation(description: "darkのplayer情報が更新されること、購読時とアップデート時で2回呼ばれる")
            darkPlayerExpectation.expectedFulfillmentCount = 2
            var darkCount = 1
            cancellables.append(target.darkPlayerStatus.sink {
                darkPlayerExpectation.fulfill()
                switch darkCount {
                case 1:
                    XCTAssertEqual($0.playerType, .manual)
                case 2:
                    XCTAssertEqual($0.playerType, .computer)
                default:
                    XCTFail("3回以上は呼ばれない")
                }
                XCTAssertEqual($0.diskCount, 0)
                darkCount += 1
            })
            let lightPlayerExpectation = expectation(description: "lightのplayer情報が更新されること、購読時にのみ呼ばれる")
            cancellables.append(target.lightPlayerStatus.sink {
                lightPlayerExpectation.fulfill()
                XCTAssertEqual($0.diskCount, 0)
                XCTAssertEqual($0.playerType, .computer)
            })
            
            target.changePlayer(on: .dark)
            wait(for: [darkPlayerExpectation, lightPlayerExpectation], timeout: 0.1)
        }
        XCTContext.runActivity(named: "lightの切り替え") { _ in
            var target = ReversiViewModelImplementation(game: Game(turn: .dark, board: Board(), darkPlayer: .manual, lightPlayer: .computer))
            let darkPlayerExpectation = expectation(description: "darkのplayer情報が更新されること、購読時のみ呼ばれる")
            let lightPlayerExpectation = expectation(description: "lightのplayer情報が更新されること、購読時とアップデート時で2回呼ばれる")
            lightPlayerExpectation.expectedFulfillmentCount = 2
            cancellables.append(target.darkPlayerStatus.sink {
                darkPlayerExpectation.fulfill()
                XCTAssertEqual($0.diskCount, 0)
                XCTAssertEqual($0.playerType, .manual)
            })
            var lightCount = 1
            cancellables.append(target.lightPlayerStatus.sink {
                lightPlayerExpectation.fulfill()
                switch lightCount {
                case 1:
                    XCTAssertEqual($0.playerType, .computer)
                case 2:
                    XCTAssertEqual($0.playerType, .manual)
                default:
                    XCTFail("3回以上は呼ばれない")
                }
                XCTAssertEqual($0.diskCount, 0)
                
                lightCount += 1
            })
            target.changePlayer(on: .light)
            wait(for: [darkPlayerExpectation, lightPlayerExpectation], timeout: 0.1)
        }
    }
    
    func testRestore() {
        // Given
        let mockSpecifications = MockReversiSpecifications()
        var target = ReversiViewModelImplementation(game: Game(turn: .light, board: ReversiSpecificationsImplementation().initalState(from: Board()), darkPlayer: .manual, lightPlayer: .computer),
                                                    specifications: mockSpecifications)
        mockSpecifications.isEndOfGame = false
        let dummyCoordinatesFirst = Coordinates(x: 1, y: 4)
        let dummyCoordinatesLast = Coordinates(x: 2, y: 4)
        var board = Board()
        try! board.set(disk: .dark, at: dummyCoordinatesLast)
        try! board.set(disk: .dark, at: dummyCoordinatesFirst)
        try! board.set(disk: .light, at: .init(x: 6, y: 6))
        try! board.set(disk: .light, at: .init(x: 1, y: 5))
        try! board.set(disk: .light, at: .init(x: 1, y: 6))
        // Then
        let darkPlayerExpectation = expectation(description: "darkのplayer情報が更新されること、購読時とrestore時に呼ばれる。")
        darkPlayerExpectation.expectedFulfillmentCount = 2
        cancellables.append(target.darkPlayerStatus.sink {
            darkPlayerExpectation.fulfill()
            XCTAssertEqual($0.diskCount, 2)
            XCTAssertEqual($0.playerType, .manual)
        })
        let lightPlayerExpectation = expectation(description: "lightのplayer情報が更新されること、購読時とアップデート時で2回呼ばれる")
        lightPlayerExpectation.expectedFulfillmentCount = 2
        var lightCount = 1
        cancellables.append(target.lightPlayerStatus.sink {
            lightPlayerExpectation.fulfill()
            switch lightCount {
            case 1:
                XCTAssertEqual($0.diskCount, 2)
                XCTAssertEqual($0.playerType, .computer)
            case 2:
                XCTAssertEqual($0.diskCount, 3)
                XCTAssertEqual($0.playerType, .computer)
            default:
                XCTFail("3回以上は呼ばれない想定です")
            }
            lightCount += 1
        })
        let messageExpectation = expectation(description: "messageの情報が更新されること, 購読とメソッド実行で2回呼ばれる")
        messageExpectation.expectedFulfillmentCount = 2
        var messageCount = 1
        cancellables.append(target.message.sink {
            switch messageCount {
            case 1:
                let status = MessageDisplayData(status: .playing(turn: .light))
                XCTAssertEqual($0.displayedDisk, status.displayedDisk)
                XCTAssertEqual($0.message, status.message)
            case 2:
                let status = MessageDisplayData(status: .playing(turn: .dark))
                XCTAssertEqual($0.displayedDisk, status.displayedDisk)
                XCTAssertEqual($0.message, status.message)
            default:
                XCTFail("3回以上は呼ばれない想定です")
            }
            messageExpectation.fulfill()
            messageCount += 1
        })
        let boardExpectation = expectation(description: "ボードの情報が更新されること")
        cancellables.append(target.boardStatus.sink {
            boardExpectation.fulfill()
            switch $0 {
            case .withAnimation:
                XCTFail("アニメーションをしない想定")
            case .withoutAnimation(let disks):
                XCTAssertEqual(board.disks.map { $0.key }, disks.map { $0.coordinates })
            }
        })
        // When
        target.restore(from: Game(turn: .dark, board: board, darkPlayer: .manual, lightPlayer: .computer))
            
        // Then
        XCTAssertEqual(target.board.disks.count, 5, "ボード情報が上書きされること")
        XCTAssertEqual(target.board.disks.filter { $0.value == .dark }.count, 2, "ボード情報が上書きされること")
        XCTAssertTrue(target.board.disks.contains(where: { $0.key == dummyCoordinatesFirst || $0.key == dummyCoordinatesLast }), "ボードの情報が上書きされていること")
        wait(for: [darkPlayerExpectation, lightPlayerExpectation, messageExpectation], timeout: 0.1)
    }
    
    func testReset() {
        // Given
        let dummyCoordinatesFirst = Coordinates(x: 1, y: 4)
        let dummyCoordinatesLast = Coordinates(x: 2, y: 4)
        var board = Board()
        try! board.set(disk: .dark, at: dummyCoordinatesLast)
        try! board.set(disk: .dark, at: dummyCoordinatesFirst)
        try! board.set(disk: .light, at: .init(x: 6, y: 6))
        try! board.set(disk: .light, at: .init(x: 1, y: 5))
        let mockSpecifications = MockReversiSpecifications()
        var target = ReversiViewModelImplementation(game: Game(turn: .light, board: board, darkPlayer: .manual, lightPlayer: .computer),
                                                    specifications: mockSpecifications)
        mockSpecifications.isEndOfGame = false
        
        // Then
        let darkPlayerExpectation = expectation(description: "darkのplayer情報が更新されること、購読時とreset時に呼ばれる。")
        darkPlayerExpectation.expectedFulfillmentCount = 2
        cancellables.append(target.darkPlayerStatus.sink {
            darkPlayerExpectation.fulfill()
            XCTAssertEqual($0.diskCount, 2)
            XCTAssertEqual($0.playerType, .manual)
        })
        let lightPlayerExpectation = expectation(description: "lightのplayer情報が更新されること、購読時とアップデート時で2回呼ばれる")
        lightPlayerExpectation.expectedFulfillmentCount = 2
        var lightCount = 1
        cancellables.append(target.lightPlayerStatus.sink {
            lightPlayerExpectation.fulfill()
            switch lightCount {
            case 1:
                XCTAssertEqual($0.diskCount, 2)
                XCTAssertEqual($0.playerType, .computer)
            case 2:
                XCTAssertEqual($0.diskCount, 2)
                XCTAssertEqual($0.playerType, .manual)
            default:
                XCTFail("3回以上は呼ばれない想定です")
            }
            lightCount += 1
        })
        let messageExpectation = expectation(description: "messageの情報が更新されること, 購読とメソッド実行で2回呼ばれる")
        messageExpectation.expectedFulfillmentCount = 2
        var messageCount = 1
        cancellables.append(target.message.sink {
            switch messageCount {
            case 1:
                let status = MessageDisplayData(status: .playing(turn: .light))
                XCTAssertEqual($0.displayedDisk, status.displayedDisk)
                XCTAssertEqual($0.message, status.message)
            case 2:
                let status = MessageDisplayData(status: .playing(turn: .dark))
                XCTAssertEqual($0.displayedDisk, status.displayedDisk)
                XCTAssertEqual($0.message, status.message)
            default:
                XCTFail("3回以上は呼ばれない想定です")
            }
            messageExpectation.fulfill()
            messageCount += 1
        })
        let boardExpectation = expectation(description: "ボードの情報が更新されること")
        cancellables.append(target.boardStatus.sink {
            boardExpectation.fulfill()
            switch $0 {
            case .withAnimation:
                XCTFail("アニメーションをしない想定")
            case .withoutAnimation(let disks):
                XCTAssertEqual(MockReversiSpecifications().initalBoard.disks.map { $0.key }, disks.map { $0.coordinates })
            }
        })
        // When
        target.reset()
        // Then
        XCTAssertEqual(target.board.disks.count, 4, " 初期数に戻っていること")
        XCTAssertEqual(target.board.disks.filter { $0.value == .dark }.count, 2, " 初期数に戻っていること")
        XCTAssertFalse(target.board.disks.contains(where: { $0.key == dummyCoordinatesFirst || $0.key == dummyCoordinatesLast }), "以前のボード情報が削除されていること")
        wait(for: [boardExpectation, darkPlayerExpectation, lightPlayerExpectation, messageExpectation], timeout: 0.1)
    }
}
