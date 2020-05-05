//
//  Player.swift
//  Reversi
//
//  Created by rnishimu on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

enum Player: Int {
    case manual = 0
    case computer = 1
}

extension Player {
    var changed: Player {
        switch self {
        case .computer: return .manual
        case .manual: return .computer
        }
    }
}
