//
//  GameManagerTests.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/05/11.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest
@testable import Reversi

final class GameManagerTests: XCTestCase {
    
    func testPlayTurnOfComputer() {
        XCTContext.runActivity(named: "キャンセルされない場合") { _ in
            let darkCanceller = SpyCannceller()
            let lightCanceller = SpyCannceller()
            let specifications = MockReversiSpecifications()
            let target = GameManagerImplementation(darkCanceller: darkCanceller, lightCanceller: lightCanceller, specifications: specifications)
            let validMove = Coordinates(x: 0, y: 0)
            specifications.stubbedValidMovesResult = [validMove]
            let completionExpectation = expectation(description: "completionが呼ばれること")
            target.playTurnOfComputer(side: .dark, on: Board(), completion: { coordinates in
                completionExpectation.fulfill()
                XCTAssertEqual(validMove, coordinates, "valid moveの値が渡されること")
            })
            wait(for: [completionExpectation], timeout: 3)
            XCTAssertEqual(darkCanceller.invokedCancelCount, 0, "キャンセルされない")
            XCTAssertEqual(lightCanceller.invokedCancelCount, 0, "キャンセルされない")
            XCTAssertEqual(darkCanceller.invokedInvalidateCount, 1, "実行後キャンセルされていなければivalidateされること")
            XCTAssertEqual(lightCanceller.invokedInvalidateCount, 0, "関係ないので呼ばれない")
        }
        XCTContext.runActivity(named: "キャンセルされた場合") { _ in
            let darkCanceller = SpyCannceller()
            let lightCanceller = SpyCannceller()
            let specifications = MockReversiSpecifications()
            let target = GameManagerImplementation(darkCanceller: darkCanceller, lightCanceller: lightCanceller, specifications: specifications)
            let validMove = Coordinates(x: 0, y: 0)
            specifications.stubbedValidMovesResult = [validMove]
            target.playTurnOfComputer(side: .light, on: Board(), completion: { coordinates in
                XCTFail("キャンセルされるのでcompletionが呼ばれない")
            })
            target.cancelPlaying(on: .light)
            lightCanceller.stubbedIsCancelled = true
            // completion実行まで待機
            sleep(3)
            XCTAssertEqual(darkCanceller.invokedCancelCount, 0, "関係ないので呼ばれない")
            XCTAssertEqual(lightCanceller.invokedCancelCount, 1, "キャンセルされる")
            XCTAssertEqual(darkCanceller.invokedInvalidateCount, 0, "関係ないので呼ばれない")
            XCTAssertEqual(lightCanceller.invokedInvalidateCount, 0, "関係ないので呼ばれない")
        }
    }
    
    func isCanceled() {
        
    }
}
