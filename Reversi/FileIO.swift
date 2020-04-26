//
//  FileIO.swift
//  Reversi
//
//  Created by rnishimu on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

enum FileIOError: Error {
    case write(path: String, cause: Error?)
    case read(path: String, cause: Error?)
}

struct FileIO: FileIOAdapter {
    
    let path: String
    
    init(path: String) {
        self.path = path
    }
    
    init(fileName: String) {
        path = (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent(fileName)
    }
    
    func write(_ data: String) throws {
        try data.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    func read() throws -> String {
        try String(contentsOfFile: path, encoding: .utf8)
    }
}
