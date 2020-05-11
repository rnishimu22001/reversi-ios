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
            let target = ReversiViewModelImplementation(game: Game(turn: .light, board: Board(), darkPlayer: .manual, lightPlayer: .computer),
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
            let target = ReversiViewModelImplementation(game: Game(turn: .dark, board: Board(), darkPlayer: .manual, lightPlayer: .computer),
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
        let  target = ReversiViewModelImplementation(game: Game(turn: .dark, board: board, darkPlayer: .manual, lightPlayer: .computer),
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
        mockSpecifications.stubbedCanPlaceDiskResult = true
        mockSpecifications.placing = [.init(x: 1, y: 1)]
        try! target.place(disk: .dark, at: Coordinates(x: 1, y: 1))
        target.updateDiskCount()
        wait(for: [darkPlayerExpectation, lightPlayerExpectation], timeout: 0.1)
    }
    
    func testPlaceDisk() {
        XCTContext.runActivity(named: "座標にdiskが配置できる場合") { _ in
            // Given
            var board = Board()
            try! board.set(disk: .dark, at: .init(x: 5, y: 0))
            try! board.set(disk: .light, at: .init(x: 5, y: 1))
            let mockSpecifications = MockReversiSpecifications()
            let target = ReversiViewModelImplementation(game: Game(turn: .light, board: board, darkPlayer: .manual, lightPlayer: .computer),
                                                        specifications: mockSpecifications)
            let willSetCoordinates = Coordinates(x: 0, y: 0)
            mockSpecifications.placing = [willSetCoordinates] + [.init(x: 1, y: 1), .init(x: 2, y: 2), .init(x: 3, y: 3), .init(x: 1, y: 5)]
            mockSpecifications.stubbedCanPlaceDiskResult = true
            // Then
            let boardExpectation = expectation(description: "ボードの情報が更新されること")
            cancellables.append(target.boardStatus.sink {
                boardExpectation.fulfill()
                switch $0 {
                case .withAnimation(let disks):
                    XCTAssertEqual(mockSpecifications.placing,
                                   disks.map { $0.coordinates },
                                   "指定された並び方で座標が並ぶこと")
                case .withoutAnimation:
                    XCTFail("アニメーションを伴う更新の想定")
                    
                }
            })
            // When
            do {
                try target.place(disk: .dark, at: willSetCoordinates)
            } catch {
                XCTFail("エラーになる想定ではありません")
            }
            wait(for: [boardExpectation], timeout: 0.1)
        }
        XCTContext.runActivity(named: "diskが配置できない場合") { _ in
            // Given
            let mockSpecifications = MockReversiSpecifications()
            let target = ReversiViewModelImplementation(game: Game(turn: .light, board: Board(), darkPlayer: .manual, lightPlayer: .computer),
                                                        specifications: mockSpecifications)
            let willSetCoordinates = Coordinates(x: 0, y: 0)
            // Then
            cancellables.append(target.boardStatus.sink { _ in
                XCTFail("ボード情報更新がされないこと")
            })
            // When
            mockSpecifications.stubbedCanPlaceDiskResult = false
            do {
                try target.place(disk: .dark, at: willSetCoordinates)
                XCTFail("失敗する想定です。")
            } catch (let error as DiskPlacementError) {
                XCTAssertEqual(error.disk, .dark)
                XCTAssertEqual(error.x, willSetCoordinates.x)
                XCTAssertEqual(error.y, willSetCoordinates.y)
            } catch {
                XCTFail("指定したエラーではありません")
            }
        }

    }
    
    func testNextTurn() {
        XCTContext.runActivity(named: "ゲームが続く場合 - 次の手番がmanual") { _ in
            let mockSpecifications = MockReversiSpecifications()
            let target = ReversiViewModelImplementation(game: Game(turn: .light, board: Board(), darkPlayer: .manual, lightPlayer: .computer),
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
        XCTContext.runActivity(named: "ゲームが続く場合 - 次の手番がcomputer") { _ in
            let mockSpecifications = MockReversiSpecifications()
            let target = ReversiViewModelImplementation(game: Game(turn: .dark, board: Board(), darkPlayer: .manual, lightPlayer: .computer),
                                                        specifications: mockSpecifications)
            mockSpecifications.isEndOfGame = false
            let lightIndicatorExpectation = expectation(description: "light側のindicatorがスタートされる,購読時とスタート時で2回呼ばれる")
            lightIndicatorExpectation.expectedFulfillmentCount = 2
            var lightIndicatorCount = 1
            cancellables.append(target.lightPlayerIndicatorAnimating.sink { shouldStartAnimating in
                lightIndicatorExpectation.fulfill()
                switch lightIndicatorCount {
                case 1:
                    XCTAssertFalse(shouldStartAnimating)
                case 2:
                    XCTAssertTrue(shouldStartAnimating)
                default:
                    XCTFail("3回以上呼ばれない")
                }
                lightIndicatorCount += 1
            })
            let darkIndicatorExpectation = expectation(description: "dark側のindicatorが購読時に呼ばれる")
            cancellables.append(target.darkPlayerIndicatorAnimating.sink { shouldStartAnimating in
                darkIndicatorExpectation.fulfill()
                XCTAssertFalse(shouldStartAnimating)
            })
            target.nextTurn()
            XCTAssertEqual(target.turn, .light, "手番が交代したのでdarkに移る")
            wait(for: [darkIndicatorExpectation, lightIndicatorExpectation], timeout: 0.1)
        }
        XCTContext.runActivity(named: "ゲームが続く場合 - 次の手番がskipされる場合") { _ in
            let mockSpecifications = MockReversiSpecifications()
            let target = ReversiViewModelImplementation(game: Game(turn: .dark, board: Board(), darkPlayer: .manual, lightPlayer: .computer),
                                                        specifications: mockSpecifications)
            mockSpecifications.isEndOfGame = false
            mockSpecifications.shouldSkip = true
            let skipAlertExpectation = expectation(description: "skip alertのイベントが呼ばれる")
            cancellables.append(target.showSkipAlert.sink(receiveValue: {
                skipAlertExpectation.fulfill()
            }))
            let lightIndicatorExpecation = expectation(description: "lightのindicatorが購読時のみ呼ばれる")
            cancellables.append(target.lightPlayerIndicatorAnimating.sink { shouldStartAnimating in
                XCTAssertFalse(shouldStartAnimating, "lgithはcomputerだが手番では無いのでstartされない")
                lightIndicatorExpecation.fulfill()
            })
            let darkIndicatorExpectation = expectation(description: "dark側のindicatorが購読時に呼ばれる")
            cancellables.append(target.darkPlayerIndicatorAnimating.sink { shouldstartanimating in
                XCTAssertFalse(shouldstartanimating, "darkはcomputerではない")
                darkIndicatorExpectation.fulfill()
            })
            let messageExpectation = expectation(description: "messageの更新が購読時に呼ばれる")
            cancellables.append(target.message.sink { _ in
                messageExpectation.fulfill()
            })
            target.nextTurn()
            XCTAssertEqual(target.turn, .dark, "手番が交代しない")
            wait(for: [messageExpectation, darkIndicatorExpectation, lightIndicatorExpecation, skipAlertExpectation], timeout: 0.1)
        }
        XCTContext.runActivity(named: "ゲームが終了する場合") { _ in
            let mockSpecifications = MockReversiSpecifications()
            let target = ReversiViewModelImplementation(game: Game(turn: .light, board: Board(), darkPlayer: .manual, lightPlayer: .computer),
                                                        specifications: mockSpecifications)
            mockSpecifications.isEndOfGame = true
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
                    let status = MessageDisplayData(status: .ending(winner: nil))
                    XCTAssertEqual($0.displayedDisk, status.displayedDisk)
                    XCTAssertEqual($0.message, status.message)
                default:
                    XCTFail("3回以上呼ばれない")
                }
                messageCount += 1
            })
            target.nextTurn()
            XCTAssertNil(target.turn, "ゲーム終了のためnilになる")
            wait(for: [messageExpectation], timeout: 0.1)
        }
        
    }
    
    func testChangePlayer() {
        XCTContext.runActivity(named: "darkの切り替え") { _ in
            let specifications = MockReversiSpecifications()
            let target = ReversiViewModelImplementation(game: Game(turn: .dark, board: Board(), darkPlayer: .manual, lightPlayer: .computer), specifications: specifications)
            specifications.isEndOfGame = false
            specifications.shouldSkip = false
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
            let darkIndicatorExpectation = expectation(description: "dark側のindicatorがスタートされる,購読時とスタート時で2回呼ばれる")
            darkIndicatorExpectation.expectedFulfillmentCount = 2
            var darkIndicatorCount = 1
            cancellables.append(target.darkPlayerIndicatorAnimating.sink { shouldStartAnimating in
                darkIndicatorExpectation.fulfill()
                switch darkIndicatorCount {
                case 1:
                    XCTAssertFalse(shouldStartAnimating)
                case 2:
                    XCTAssertTrue(shouldStartAnimating)
                default:
                    XCTFail("3回以上呼ばれる想定ではない")
                }
                darkIndicatorCount += 1
            })
            target.changePlayer(on: .dark)
            wait(for: [darkPlayerExpectation, lightPlayerExpectation, darkIndicatorExpectation], timeout: 0.1)
        }
        XCTContext.runActivity(named: "lightの切り替え") { _ in
            let specifications = MockReversiSpecifications()
            specifications.isEndOfGame = false
            specifications.shouldSkip = false
            let target = ReversiViewModelImplementation(game: Game(turn: .light, board: Board(), darkPlayer: .manual, lightPlayer: .computer),
                                                        specifications: specifications)
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
            let lightIndicatorExpectation = expectation(description: "light側のindicatorがストップされる,購読時とストップ時で2回呼ばれる")
            lightIndicatorExpectation.expectedFulfillmentCount = 2
            var lightIndicatorCount = 1
            cancellables.append(target.lightPlayerIndicatorAnimating.sink { shouldStartAnimating in
                lightIndicatorExpectation.fulfill()
                switch lightIndicatorCount {
                case 1:
                    XCTAssertTrue(shouldStartAnimating)
                case 2:
                    XCTAssertFalse(shouldStartAnimating)
                default:
                    XCTFail("3回以上呼ばれない")
                }
                lightIndicatorCount += 1
            })
            target.changePlayer(on: .light)
            wait(for: [darkPlayerExpectation, lightPlayerExpectation, lightIndicatorExpectation], timeout: 0.1)
        }
    }
    
    func testRestore() {
        // Given
        let mockSpecifications = MockReversiSpecifications()
        let manager = SpyManager()
        let target = ReversiViewModelImplementation(game: Game(turn: .light, board: ReversiSpecificationsImplementation().initalState(from: Board()), darkPlayer: .manual, lightPlayer: .computer),
                                                    manager: manager,
                                                    specifications: mockSpecifications)
        mockSpecifications.isEndOfGame = false
        mockSpecifications.shouldSkip = false
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
        let lightIndicatorExpectation = expectation(description: "lightのindicatorイベントが発行されること")
        lightIndicatorExpectation.expectedFulfillmentCount = 4
        var lightIndicatorCount = 1
        cancellables.append(target.lightPlayerIndicatorAnimating.sink { animated in
            lightIndicatorExpectation.fulfill()
            switch lightIndicatorCount {
            case 1:
                XCTAssertTrue(animated, "lightのターンでcomputerとして動作")
            case 2:
                XCTAssertFalse(animated, "restoreでアニメーションが止まる")
            case 3:
                XCTAssertTrue(animated, "lightのターンで再度computerとして動作")
            case 4:
                XCTAssertFalse(animated, "computerの思考時間が終了して止まる")
            default:
                XCTFail("5回以上は呼ばれない想定です")
            }
            lightIndicatorCount += 1
        })
        // When
        target.restore(from: Game(turn: .light, board: board, darkPlayer: .manual, lightPlayer: .computer))
            
        // Then
        XCTAssertEqual(manager.invokedCanceleAllPlayingCount, 2, "playerの動作がキャンセルされること、initとrestoreで2回")
        XCTAssertEqual(manager.invokedPlayTurnOfComputerCount, 2, "computerの動作が呼びされること、initとrestoreで2回")
        XCTAssertEqual(manager.invokedPlayTurnOfComputerParametersList.first!.side, .light, "computerの動作が呼びされること")
        XCTAssertEqual(manager.invokedPlayTurnOfComputerParametersList.last!.side, .light, "computerの動作が呼びされること")
        XCTAssertEqual(target.board.disks.count, 5, "ボード情報が上書きされること")
        XCTAssertEqual(target.board.disks.filter { $0.value == .dark }.count, 2, "ボード情報が上書きされること")
        XCTAssertTrue(target.board.disks.contains(where: { $0.key == dummyCoordinatesFirst || $0.key == dummyCoordinatesLast }), "ボードの情報が上書きされていること")
        manager.caputuredPlayTurnOfComputerCompletion?(.init(x: 0, y: 0))
        wait(for: [darkPlayerExpectation, lightPlayerExpectation, messageExpectation, boardExpectation, lightIndicatorExpectation], timeout: 0.5)
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
        let manager = SpyManager()
        let mockSpecifications = MockReversiSpecifications()
        let target = ReversiViewModelImplementation(game: Game(turn: .light, board: board, darkPlayer: .manual, lightPlayer: .computer),
                                                    manager: manager,
                                                    specifications: mockSpecifications)
        mockSpecifications.isEndOfGame = false
        mockSpecifications.shouldSkip = false
        // Then
        let darkPlayerExpectation = expectation(description: "darkのplayer情報が更新されること、購読時とreset時に呼ばれる。")
        darkPlayerExpectation.expectedFulfillmentCount = 2
        cancellables.append(target.darkPlayerStatus.sink {
            darkPlayerExpectation.fulfill()
            XCTAssertEqual($0.diskCount, 2)
            XCTAssertEqual($0.playerType, .manual)
        })
        let darkIndicatorExpectation = expectation(description: "darkのindicatorのイベントが呼ばれること")
        darkIndicatorExpectation.expectedFulfillmentCount = 2
        var darkIndicatorCount = 1
        cancellables.append(target.lightPlayerIndicatorAnimating.sink { animated in
            darkIndicatorExpectation.fulfill()
            switch darkIndicatorCount {
            case 1:
                XCTAssertTrue(animated)
            case 2:
                XCTAssertFalse(animated)
            default:
                XCTFail("3回以上は呼ばれない想定です")
            }
            darkIndicatorCount += 1
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
        let lightIndicatorExpectation = expectation(description: "lightのindicatorがstopされること")
        lightIndicatorExpectation.expectedFulfillmentCount = 2
        var lightIndicatorCount = 1
        cancellables.append(target.lightPlayerIndicatorAnimating.sink { animated in
            lightIndicatorExpectation.fulfill()
            switch lightIndicatorCount {
            case 1:
                XCTAssertTrue(animated)
            case 2:
                XCTAssertFalse(animated)
            default:
                XCTFail("3回以上は呼ばれない想定です")
            }
            lightIndicatorCount += 1
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
                let inital = MockReversiSpecifications().initalBoard.disks
                XCTAssertEqual(inital.count, disks.count)
                disks.forEach {
                    XCTAssertEqual(inital[$0.coordinates], $0.side, "一気にデータをセットするため順序は関係ない")
                }
            }
        })
        // When
        target.reset()
        // Then
        XCTAssertEqual(manager.invokedCancelPlayingCount, 1, "playerの動作がキャンセルされること")
        XCTAssertEqual(manager.invokedPlayTurnOfComputerCount, 0, "呼び出されないこと")
        XCTAssertEqual(target.board.disks.count, 4, " 初期数に戻っていること")
        XCTAssertEqual(target.board.disks.filter { $0.value == .dark }.count, 2, " 初期数に戻っていること")
        XCTAssertFalse(target.board.disks.contains(where: { $0.key == dummyCoordinatesFirst || $0.key == dummyCoordinatesLast }), "以前のボード情報が削除されていること")
        wait(for: [darkIndicatorExpectation, lightIndicatorExpectation, boardExpectation, darkPlayerExpectation, lightPlayerExpectation, messageExpectation], timeout: 3.0)
    }
    
    func testGame() {
        
        let game = Game(turn: .light, board: Board(), darkPlayer: .computer, lightPlayer: .manual)
        let target = ReversiViewModelImplementation()
        target.restore(from: game)
        XCTAssertEqual(game.darkPlayer, target.game.darkPlayer)
        XCTAssertEqual(game.lightPlayer, target.game.lightPlayer)
        XCTAssertEqual(game.turn, target.game.turn)
    }
}
