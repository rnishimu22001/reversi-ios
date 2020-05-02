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
    func testValidMoves() {
    
        // Given
        let target = ReversiSpecifications()
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
        XCTAssertTrue(target.validMoves(for: .light, on: board).contains(where: ({ $0.x == 4 && $0.y == 4 })))
        XCTAssertTrue(target.validMoves(for: .dark, on: board).contains(where: ({ $0.x == 0 && $0.y == 0 })))
    }
}
