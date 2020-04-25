//
//  Board.swift
//  Reversi
//
//  Created by rnishimu on 2020/04/24.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

struct Board {
    /// 盤の幅（ `8` ）を表します。
    public let width: Int = 8
    
    /// 盤の高さ（ `8` ）を返します。
    public let height: Int = 8
    
    /// 盤のセルの `x` の範囲（ `0 ..< 8` ）を返します。
    public let xRange: Range<Int>
    
    /// 盤のセルの `y` の範囲（ `0 ..< 8` ）を返します。
    public let yRange: Range<Int>
    
    init() {
        xRange = 0 ..< width
        yRange = 0 ..< height
    }
}
