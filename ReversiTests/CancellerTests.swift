//
//  CancellerTests.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/05/10.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest
@testable import Reversi

final class CancellerTests: XCTestCase {
    
    func testCancel() {
        let cancelExpectation = expectation(description: "キャンセルの動作が実行されること")
        let target = CancellerImplementation({ cancelExpectation.fulfill() })
        XCTAssertEqual(target.state, .hold, "キャンセル前は保留状態")
        XCTAssertFalse(target.isCancelled, "キャンセル前はfalse")
        target.cancel()
        wait(for: [cancelExpectation], timeout: 0.1)
        XCTAssertTrue(target.isCancelled, "キャンセル後にはtrue")
        XCTAssertEqual(target.state, .executed, "キャンセル後は実行済み")
    }
    
    func testInvalid() {
        let target = CancellerImplementation({ XCTFail("invalidate後はcancellerは実行されない") })
        XCTAssertEqual(target.state, .hold, "キャンセル前は保留状態")
        XCTAssertFalse(target.isCancelled, "キャンセル前はfalse")
        target.invalidate()
        target.cancel()
        XCTAssertFalse(target.isCancelled, "invalidate後はfalse")
        XCTAssertEqual(target.state, .invalid, "無効化状態")
        // 再利用のテスト
        let cancelExpectation = expectation(description: "キャンセルの動作が実行されること")
        target.prepareForReuse({ cancelExpectation.fulfill() })
        XCTAssertEqual(target.state, .hold, "再利用可能な状態になったら保留状態")
        XCTAssertFalse(target.isCancelled, "キャンセル前はfalse")
        target.cancel()
        wait(for: [cancelExpectation], timeout: 0.1)
    }
}
