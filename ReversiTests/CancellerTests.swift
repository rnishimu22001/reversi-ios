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
        let target = Canceller({ cancelExpectation.fulfill() })
        XCTAssertFalse(target.isCancelled, "キャンセル前はfalse")
        target.cancel()
        wait(for: [cancelExpectation], timeout: 0.1)
        XCTAssertTrue(target.isCancelled, "キャンセル後にはtrue")
    }
}
