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
    func canceleAllPlaying()
}

protocol GameManagerDelegate: class {
    func gameManager(_ manager: GameManager, stopIndicatorOn side: Disk)
}

final class GameManagerImplementation: GameManager {
   
    let specifications: ReversiSpecifications
    private var cancellers: [Disk: Canceller] = [:]
    
    init(darkCanceller: Canceller = CancellerImplementation(nil),
         lightCanceller: Canceller = CancellerImplementation(nil),
         specifications: ReversiSpecifications = ReversiSpecificationsImplementation()) {
        self.cancellers[.dark] = darkCanceller
        self.cancellers[.light] = lightCanceller
        self.specifications = specifications
    }
   
    func playTurnOfComputer(side: Disk, on board: Board, completion: @escaping ((Coordinates?) -> Void)) {
        guard let coordinates = specifications.validMoves(for: side, on: board).randomElement() else {
            completion(nil)
            return
        }
        cancellers[side]?.prepareForReuse(nil)
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self,
                !self.isCanceled(on: side) else {
                return
            }
            self.cancellers[side]?.invalidate()
            completion(coordinates)
        }
    }
    
    func isCanceled(on side: Disk) -> Bool {
        guard let canceller = cancellers[side] else {
            return false
        }
        return canceller.isCancelled
    }
    
    func cancelPlaying(on side: Disk) {
        cancellers[side]?.cancel()
    }
    
    func canceleAllPlaying() {
        Disk.allCases.forEach { cancelPlaying(on: $0) }
    }
}
