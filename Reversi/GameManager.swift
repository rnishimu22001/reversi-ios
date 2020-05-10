//
//  GameManager.swift
//  Reversi
//
//  Created by rnishimu on 2020/05/09.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation

protocol GameManager {
    func playTurnOfComputer(side: Disk, on board: Board, completion: @escaping ((Coordinates?) -> Void))
    func cancelPlaying(on side: Disk)
    func reset()
}

protocol GameManagerDelegate: class {
    func gameManager(_ manager: GameManager, stopIndicatorOn side: Disk)
}

final class GameManagerImplementation: GameManager {
   
    let specifications: ReversiSpecifications
    private var darkPlayerCanceller: Canceller?
    var isPlayingDark: Bool { darkPlayerCanceller != nil }
    private var lightPlayerCanceller: Canceller?
    var isPlayingLight: Bool { lightPlayerCanceller != nil }
    
    init(specifications: ReversiSpecifications = ReversiSpecificationsImplementation()) {
        self.specifications = specifications
    }
   
    func playTurnOfComputer(side: Disk, on board: Board, completion: @escaping ((Coordinates?) -> Void)) {
        guard let coordinates = specifications.validMoves(for: side, on: board).randomElement() else {
            completion(nil)
            return
        }
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self,
                !self.isCanceled(on: side) else {
                return
            }
            completion(coordinates)
        }
    }
    
    func isCanceled(on side: Disk) -> Bool {
        switch side {
        case .dark:
            guard let canceller = darkPlayerCanceller else {
                return false
            }
            return canceller.isCancelled
        case .light:
            guard let canceller = lightPlayerCanceller else {
                return false
            }
            return canceller.isCancelled
        }
    }
    
    func cancelPlaying(on side: Disk) {
        switch side {
        case .dark:
            darkPlayerCanceller?.cancel()
            darkPlayerCanceller = nil
        case .light:
            lightPlayerCanceller?.cancel()
            lightPlayerCanceller = nil
        }
    }
    
    func reset() {
        Disk.allCases.forEach { cancelPlaying(on: $0) }
    }
}
