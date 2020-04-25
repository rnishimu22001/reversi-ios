//
//  FileIOTests.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import XCTest
@testable import Reversi

final class FileIOTests: XCTestCase {
    
    func testPath() {
        let target = ViewController()
        XCTAssertEqual(FileIO(fileName: "Game").path, target.path)
    }
}
