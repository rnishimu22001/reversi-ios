//
//  FileIOAdapter.swift
//  Reversi
//
//  Created by rnishimu on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

protocol FileIOAdapter {
    func write(_ data: String) throws
    func read() throws -> String
}
