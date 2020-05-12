//
//  Game.swift
//  Reversi
//
//  Created by rnishimu on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

enum GameStatus {
    case ending(winner: Disk?)
    case playing(turn: Disk)
}

struct Game {
    var turn: Disk?
    var board: Board
    var darkPlayer: Player
    var lightPlayer: Player
}
