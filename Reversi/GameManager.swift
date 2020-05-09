//
//  GameManager.swift
//  Reversi
//
//  Created by rnishimu on 2020/05/09.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

protocol GameManager {
    func playTurnOfComputer(side: Disk, canceller: Canceller, completion: (() -> Void)?)
}

final class GameManagerImplementation: GameManager {
    func playTurnOfComputer(side: Disk, canceller: Canceller, completion: (() -> Void)?) {
        
    }
}
