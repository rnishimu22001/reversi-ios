//
//  MockGameRepository.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/05/02.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

@testable import Reversi

final class MockGameRepository: GameRepository {
    var saved: Game?
    func save(game: Game) throws {
        saved = game
    }
    
    var restored: Game!
    func restore() throws -> Game {
        restored
    }
}
