//
//  MessageDisplayDataTests.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/05/04.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest
@testable import Reversi

final class MessageDisplayDataTests: XCTestCase {
    
    func testInitWithStatus() {
        XCTContext.runActivity(named: "プレイ中の場合") { _ in
            let target = MessageDisplayData(status: .playing(turn: .dark))
            XCTAssertEqual(target.turn, .dark)
            XCTAssertEqual(target.message, "'s turn")
        }
        XCTContext.runActivity(named: "決着がついた場合") { _ in
            let target = MessageDisplayData(status: .ending(winner: .light))
            XCTAssertEqual(target.turn, .light)
            XCTAssertEqual(target.message, " won")
        }
        XCTContext.runActivity(named: "引き分けの場合") { _ in
            let target = MessageDisplayData(status: .ending(winner: nil))
            XCTAssertEqual(target.turn, nil)
            XCTAssertEqual(target.message, "Tied")
        }
    }
}
