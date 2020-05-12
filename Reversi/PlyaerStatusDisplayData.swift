//
//  PlyaerStatusDisplayData.swift
//  Reversi
//
//  Created by rnishimu on 2020/05/04.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

struct PlayerStatusDisplayData: Equatable {
    let playerType: Player
    let diskCount: Int
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.playerType == rhs.playerType && lhs.diskCount == rhs.diskCount
    }
}
