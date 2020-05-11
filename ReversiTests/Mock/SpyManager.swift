//
//  SpyManager.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/05/11.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//
@testable import Reversi

final class SpyManager: GameManager {

    var invokedPlayTurnOfComputer = false
    var invokedPlayTurnOfComputerCount = 0
    var invokedPlayTurnOfComputerParameters: (side: Disk, board: Board)?
    var invokedPlayTurnOfComputerParametersList = [(side: Disk, board: Board)]()
    var caputuredPlayTurnOfComputerCompletion: ((Coordinates?) -> Void)?

    func playTurnOfComputer(side: Disk, on board: Board, completion: @escaping ((Coordinates?) -> Void)) {
        invokedPlayTurnOfComputer = true
        invokedPlayTurnOfComputerCount += 1
        invokedPlayTurnOfComputerParameters = (side, board)
        invokedPlayTurnOfComputerParametersList.append((side, board))
        caputuredPlayTurnOfComputerCompletion = completion
    }

    var invokedCancelPlaying = false
    var invokedCancelPlayingCount = 0
    var invokedCancelPlayingParameters: (side: Disk, Void)?
    var invokedCancelPlayingParametersList = [(side: Disk, Void)]()

    func cancelPlaying(on side: Disk) {
        invokedCancelPlaying = true
        invokedCancelPlayingCount += 1
        invokedCancelPlayingParameters = (side, ())
        invokedCancelPlayingParametersList.append((side, ()))
    }

    var invokedCanceleAllPlaying = false
    var invokedCanceleAllPlayingCount = 0

    func canceleAllPlaying() {
        invokedCanceleAllPlaying = true
        invokedCanceleAllPlayingCount += 1
    }
}
