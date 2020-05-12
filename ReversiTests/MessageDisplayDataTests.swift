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
            XCTAssertEqual(target.displayedDisk, .dark)
            XCTAssertEqual(target.message, "'s turn")
        }
        XCTContext.runActivity(named: "決着がついた場合") { _ in
            let target = MessageDisplayData(status: .ending(winner: .light))
            XCTAssertEqual(target.displayedDisk, .light)
            XCTAssertEqual(target.message, " won")
        }
        XCTContext.runActivity(named: "引き分けの場合") { _ in
            let target = MessageDisplayData(status: .ending(winner: nil))
            XCTAssertEqual(target.displayedDisk, nil)
            XCTAssertEqual(target.message, "Tied")
        }
    }
}
