//
//  FileIO.swift
//  Reversi
//
//  Created by rnishimu on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

struct FileIO: FileIOAdapter {
    
    let path: String
    
    func write(_ data: String) throws {
        try data.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    func read() throws -> String {
        try String(contentsOfFile: path, encoding: .utf8)
    }
}
