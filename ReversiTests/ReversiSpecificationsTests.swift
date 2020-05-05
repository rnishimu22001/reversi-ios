//
//  ReversiSpecificationsTests.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/05/02.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest
@testable import Reversi

final class ReversiSpecificationsTests: XCTestCase {
    
    func testIsEndOfGame() {
        XCTContext.runActivity(named: "もうDiskをおけない場合") { _ in
            var board = Board()
            let target = ReversiSpecificationsImplementation()
            do {
                try board.set(disk: .dark, at: .init(x: 0, y: 0))
                try board.set(disk: .light, at: .init(x: 5, y: 5))
            } catch {
                fatalError()
            }
            XCTAssertTrue(target.isEndOfGame(on: board))
        }
        XCTContext.runActivity(named: "片方だけDiskが置ける場合") { _ in
            var board = Board()
            let target = ReversiSpecificationsImplementation()
            do {
                try board.set(disk: .dark, at: .init(x: 0, y: 0))
                try board.set(disk: .light, at: .init(x: 1, y: 1))
            } catch {
                fatalError()
            }
            XCTAssertFalse(target.isEndOfGame(on: board))
        }
        XCTContext.runActivity(named: "両方Diskが置ける場合") { _ in
            var board = Board()
            let target = ReversiSpecificationsImplementation()
            do {
                try board.set(disk: .dark, at: .init(x: 4, y: 4))
                try board.set(disk: .light, at: .init(x: 5, y: 5))
            } catch {
                fatalError()
            }
            XCTAssertFalse(target.isEndOfGame(on: board))
        }
    }
    
    func testInitalState() {
        let willDelete = Coordinates(x: 0, y: 0)
        var board = Board(width: 8, height: 8)
        do {
            try board.set(disk: .dark, at: willDelete)
        } catch {
            fatalError()
        }
        // When
        let newBoard = ReversiSpecificationsImplementation().initalState(from: board)
        // Then
        XCTAssertEqual(.dark, newBoard.disks[Coordinates(x: 3, y: 4)], "diskが初期位置にセットされていること")
        XCTAssertEqual(.dark, newBoard.disks[Coordinates(x: 4, y: 3)], "diskが初期位置にセットされていること")
        XCTAssertEqual(.light, newBoard.disks[Coordinates(x: 3, y: 3)], "diskが初期位置にセットされていること")
        XCTAssertEqual(.light, newBoard.disks[Coordinates(x: 4, y: 4)], "diskが初期位置にセットされていること")
        XCTAssertNil(newBoard.disks[willDelete], "diskが消えていること")
    }
    
    func testValidMoves() {
        XCTContext.runActivity(named: "縦") { _ in
            // Given
            let target = ReversiSpecificationsImplementation()
            var board = Board()
            do {
                try board.set(disk: .light, at: Coordinates(x: 1, y: 1))
                try board.set(disk: .dark, at: Coordinates(x: 1, y: 2))
            } catch {
                fatalError()
            }
            // When Then
            XCTAssertTrue(target.validMoves(for: .light, on: board).contains(where: ({ $0.x == 1 && $0.y == 3 })))
            XCTAssertTrue(target.validMoves(for: .dark, on: board).contains(where: ({ $0.x == 1 && $0.y == 0 })))
            XCTAssertEqual(target.validMoves(for: .light, on: board).count, 1)
            XCTAssertEqual(target.validMoves(for: .dark, on: board).count, 1)
        }
        XCTContext.runActivity(named: "横") { _ in
            // Given
            let target = ReversiSpecificationsImplementation()
            var board = Board()
            do {
                try board.set(disk: .light, at: Coordinates(x: 1, y: 1))
                try board.set(disk: .dark, at: Coordinates(x: 2, y: 1))
            } catch {
                fatalError()
            }
            // When Then
            XCTAssertTrue(target.validMoves(for: .light, on: board).contains(where: ({ $0.x == 3 && $0.y == 1 })))
            XCTAssertTrue(target.validMoves(for: .dark, on: board).contains(where: ({ $0.x == 0 && $0.y == 1 })))
            XCTAssertEqual(target.validMoves(for: .light, on: board).count, 1)
            XCTAssertEqual(target.validMoves(for: .dark, on: board).count, 1)
        }
        XCTContext.runActivity(named: "斜め") { _ in
            // Given
            let target = ReversiSpecificationsImplementation()
            var board = Board()
            do {
                try board.set(disk: .light, at: Coordinates(x: 1, y: 1))
                try board.set(disk: .dark, at: Coordinates(x: 2, y: 2))
            } catch {
                fatalError()
            }
            // When Then
            XCTAssertTrue(target.validMoves(for: .light, on: board).contains(where: ({ $0.x == 3 && $0.y == 3 })))
            XCTAssertTrue(target.validMoves(for: .dark, on: board).contains(where: ({ $0.x == 0 && $0.y == 0 })))
            XCTAssertEqual(target.validMoves(for: .light, on: board).count, 1)
            XCTAssertEqual(target.validMoves(for: .dark, on: board).count, 1)
        }
        XCTContext.runActivity(named: "複数方向ひっくり返せる場合") { _ in
            // Given
            let target = ReversiSpecificationsImplementation()
            var board = Board()
            do {
                try board.set(disk: .light, at: Coordinates(x: 1, y: 1))
                try board.set(disk: .dark, at: Coordinates(x: 2, y: 2))
                try board.set(disk: .dark, at: Coordinates(x: 4, y: 3))
                try board.set(disk: .light, at: Coordinates(x: 5, y: 3))
            } catch {
                fatalError()
            }
            // When Then
            XCTAssertTrue(target.validMoves(for: .light, on: board).contains(where: ({ $0.x == 3 && $0.y == 3 })))
            XCTAssertEqual(target.validMoves(for: .light, on: board).count, 1)
            XCTAssertEqual(target.validMoves(for: .dark, on: board).count, 2)
        }
        XCTContext.runActivity(named: "複数のディスクを挟んでひっくり返せる場合") { _ in
            // Given
            let target = ReversiSpecificationsImplementation()
            var board = Board()
            do {
                try board.set(disk: .light, at: Coordinates(x: 1, y: 1))
                try board.set(disk: .dark, at: Coordinates(x: 2, y: 2))
                try board.set(disk: .dark, at: Coordinates(x: 3, y: 3))
            } catch {
                fatalError()
            }
            // When Then
            XCTAssertTrue(target.validMoves(for: .light, on: board).contains(where: ({ $0.x == 4 && $0.y == 4 })))
            XCTAssertEqual(target.validMoves(for: .light, on: board).count, 1)
            XCTAssertEqual(target.validMoves(for: .dark, on: board).count, 1)
        }
        XCTContext.runActivity(named: "盤外でひっくり返せない場合") { _ in
            // Given
            let target = ReversiSpecificationsImplementation()
            var board = Board()
            do {
                try board.set(disk: .light, at: Coordinates(x: 0, y: 0))
                try board.set(disk: .dark, at: Coordinates(x: 1, y: 1))
            } catch {
                fatalError()
            }
            // When Then
            print(target.validMoves(for: .dark, on: board))
            XCTAssertTrue(target.validMoves(for: .dark, on: board).isEmpty, "lightを挟んだ座標は盤外の座標になるためひっくり返せない")
            XCTAssertEqual(target.validMoves(for: .light, on: board).count, 1)
        }
    }
    func testCanPlaceDisk() {
        
        // Given
        let target = ReversiSpecificationsImplementation()
        var board = Board()
        do {
            try board.set(disk: .light, at: Coordinates(x: 1, y: 1))
            try board.set(disk: .dark, at: Coordinates(x: 2, y: 2))
            try board.set(disk: .dark, at: Coordinates(x: 3, y: 3))
            try board.set(disk: .dark, at: Coordinates(x: 5, y: 5))
            try board.set(disk: .light, at: Coordinates(x: 6, y: 6))
        } catch {
            fatalError()
        }
        // When Then
        XCTAssertTrue(target.canPlaceDisk(.light, on: board, at: Coordinates(x: 4, y: 4)))
        XCTAssertTrue(target.canPlaceDisk(.dark, on: board, at: Coordinates(x: 0, y: 0)))
        
    }
}
