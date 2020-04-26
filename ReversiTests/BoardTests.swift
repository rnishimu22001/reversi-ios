//
//  BoardTests.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest
@testable import Reversi

final class BoardTests: XCTestCase {
    
    func testRange() {
        XCTAssertEqual(Board().xRange, BoardView().xRange)
        XCTAssertEqual(Board().yRange, BoardView().yRange)
    }
    
    func testSet() {
        XCTContext.runActivity(named: "セット成功") { _ in
            // Given
            var target = Board()
            let coordinates = Coordinates(x: 0, y: 0)
            // When
            do {
                try target.set(disk: .dark, atX: coordinates.x, y: coordinates.y)
            } catch {
                XCTFail("座標がボードの範囲内のため成功する")
            }
            // Then
            XCTAssertEqual(target.disks[coordinates], .dark)
        }
        XCTContext.runActivity(named: "セット失敗 - y軸が範囲外") { _ in
            // Given
            var target = Board()
            let coordinates = Coordinates(x: 0, y: 8)
            // When
            do {
                try target.set(disk: .dark, atX: coordinates.x, y: coordinates.y)
                XCTFail("座標がボードの範囲外のため失敗する")
            } catch (let error) {
                guard case BoardError.outOfRange = error else {
                    XCTFail("範囲外のエラーではない")
                    return
                }
            }
        }
        XCTContext.runActivity(named: "セット失敗 - x軸が範囲外") { _ in
            // Given
            var target = Board()
            let coordinates = Coordinates(x: 8, y: 0)
            // When
            do {
                try target.set(disk: .dark, atX: coordinates.x, y: coordinates.y)
                XCTFail("座標がボードの範囲外のため失敗する")
            } catch (let error) {
                guard case BoardError.outOfRange = error else {
                    XCTFail("範囲外のエラーではない")
                    return
                }
            }
        }
    }
}
