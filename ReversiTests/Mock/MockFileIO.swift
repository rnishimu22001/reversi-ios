//
//  MockFileIO.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

@testable import Reversi

final class MockFileIO: FileIOAdapter {
    var written: String?
    func write(_ data: String) throws {
        written = data
    }
    
    var saved: String?
    func read() throws -> String {
        saved!
    }
}
