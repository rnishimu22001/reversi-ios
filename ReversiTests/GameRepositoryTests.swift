//
//  GameRepositoryTests.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest
@testable import Reversi

final class GameRepositoryTests: XCTestCase {
    
    func testSaveGame() {
        // Given
        var board = Board()
        /*
         x00
         --------
         --------
         --------
         --xxx---
         ---xo---
         --------
         --------
         --------
         */
        do {
            try board.set(disk: .dark, atX: 2, y: 3)
            try board.set(disk: .dark, atX: 3, y: 3)
            try board.set(disk: .dark, atX: 4, y: 3)
            try board.set(disk: .dark, atX: 3, y: 4)
            try board.set(disk: .light, atX: 4, y: 4)
        } catch {
            XCTFail()
            return
        }
        let mockIO = MockFileIO()
        let target = GameRepositoryImplementation(fileIO: mockIO)
        // When
        do {
            try target.save(game: Game(turn: .dark, board: board, darkPlayer: .manual, lightPlayer: .computer))
        } catch {
            fatalError()
        }
        // 最後の行に開業が含まれるので空白行が必要
        XCTAssertEqual(mockIO.written!, """
                                        x01
                                        --------
                                        --------
                                        --------
                                        --xxx---
                                        ---xo---
                                        --------
                                        --------
                                        --------

                                        """)
        
    }
    
    func testLoadGame() {
        XCTContext.runActivity(named: "正常データ") { _ in
            
            // Given
            let mockIO = MockFileIO()
            let target = GameRepositoryImplementation(fileIO: mockIO)
            // 最後の行に開業が含まれるので空白行が必要
            mockIO.saved = """
                        x01
                        --------
                        --------
                        --------
                        --xxx---
                        ---xo---
                        --------
                        --------
                        --------

                        """
            // When
            let game: Game
            do {
                game = try target.restore()
            } catch {
                fatalError()
            }
            // Then
            (1...(game.board.height * game.board.width)).forEach {
                let x = $0 / game.board.width
                let y = $0 % game.board.height
                switch (x, y) {
                case (2, 3), (3, 3), (4, 3), (3, 4):
                    XCTAssertEqual(game.board.disk(atX: x, y: y), .dark, "x: \(x),y: \(y)")
                case (4, 4):
                    XCTAssertEqual(game.board.disk(atX: x, y: y), .light, "x: \(x),y: \(y)")
                default:
                    XCTAssertNil(game.board.disk(atX: x, y: y))
                }
            }
            XCTAssertEqual(game.turn, .dark, "x01なのでdarkの手番")
            XCTAssertEqual(game.darkPlayer, .manual, "x01なので初手のプレイヤーは0")
            XCTAssertEqual(game.lightPlayer, .computer, "x01なので後手のプレイヤーは1")
        }
        XCTContext.runActivity(named: "y軸の盤面が異常データ") { _ in
            // Given
            let mockIO = MockFileIO()
            let target = GameRepositoryImplementation(fileIO: mockIO)
            // 最後の行に開業が含まれるので空白行が必要
            // y軸の段が9個あり、定義より一行だけ多い
            mockIO.saved = """
                        x01
                        --------
                        --------
                        --------
                        --xxx---
                        ---xo---
                        --------
                        --------
                        --------
                        --------

                        """
            // When
            do {
                _ = try target.restore()
                XCTFail("不正データのためrestoreにエラーが発生しなければ失敗")
            } catch(let error) {
                // Then
                guard case FileIOError.read = error else {
                    XCTFail("読み込みエラーが発生する想定")
                    return
                }
            }
        }
        XCTContext.runActivity(named: "x軸の盤面が異常データ") { _ in
            // Given
            let mockIO = MockFileIO()
            let target = GameRepositoryImplementation(fileIO: mockIO)
            // 最後の行に開業が含まれるので空白行が必要
            // x軸の幅が9あり、定義より一つだけ多い
            mockIO.saved = """
                        x01
                        ---------
                        ---------
                        ---------
                        --xxx----
                        ---xo----
                        ---------
                        ---------
                        ---------

                        """
            // When
            do {
                _ = try target.restore()
                XCTFail("不正データのためrestoreにエラーが発生しなければ失敗")
            } catch(let error) {
                // Then
                guard case FileIOError.read = error else {
                    XCTFail("読み込みエラーが発生する想定")
                    return
                }
            }
        }
        XCTContext.runActivity(named: "盤面が空") { _ in
            // Given
            let mockIO = MockFileIO()
            let target = GameRepositoryImplementation(fileIO: mockIO)
            // 最後の行に開業が含まれるので空白行が必要
            // x軸の幅が9あり、定義より一つだけ多い
            mockIO.saved = ""
            // When
            do {
                _ = try target.restore()
                XCTFail("不正データのためrestoreにエラーが発生しなければ失敗")
            } catch(let error) {
                // Then
                guard case FileIOError.read = error else {
                    XCTFail("読み込みエラーが発生する想定")
                    return
                }
            }
        }
        XCTContext.runActivity(named: "disk simbolが不正") { _ in
            // Given
            let mockIO = MockFileIO()
            let target = GameRepositoryImplementation(fileIO: mockIO)
            mockIO.saved = """
                        y01
                        --------
                        --------
                        --------
                        --xxx---
                        ---xo---
                        --------
                        --------
                        --------

                        """
            // When
            do {
                _ = try target.restore()
                XCTFail("不正データのためrestoreにエラーが発生しなければ失敗")
            } catch(let error) {
                // Then
                guard case FileIOError.read = error else {
                    XCTFail("読み込みエラーが発生する想定")
                    return
                }
            }
        }
        XCTContext.runActivity(named: "player simbolが不正") { _ in
            // Given
            let mockIO = MockFileIO()
            let target = GameRepositoryImplementation(fileIO: mockIO)
            mockIO.saved = """
                        x09
                        --------
                        --------
                        --------
                        --xxx---
                        ---xo---
                        --------
                        --------
                        --------

                        """
            // When
            do {
                _ = try target.restore()
                XCTFail("不正データのためrestoreにエラーが発生しなければ失敗")
            } catch(let error) {
                // Then
                guard case FileIOError.read = error else {
                    XCTFail("読み込みエラーが発生する想定")
                    return
                }
            }
        }
    }
}
