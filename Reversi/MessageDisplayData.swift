//
//  MessageDisplayData.swift
//  Reversi
//
//  Created by rnishimu on 2020/05/04.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

struct MessageDisplayData {
    let displayedDisk: Disk?
    let message: String
    
    init(status: GameStatus) {
        switch status {
        case .ending(let winner):
            if winner == nil {
                message = "Tied"
            } else {
                message = " won"
            }
            self.displayedDisk = winner
        case .playing(let turn):
            self.displayedDisk = turn
            message = "'s turn"
        }
    }
}
