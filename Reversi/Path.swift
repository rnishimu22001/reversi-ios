//
//  Path.swift
//  Reversi
//
//  Created by rnishimu on 2020/04/24.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

struct Path: Equatable, Hashable {
    let x: Int
    let y: Int
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
}
