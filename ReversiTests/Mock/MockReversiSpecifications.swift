//
//  MockReversiSpecifications.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/05/03.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

@testable import Reversi

final class MockReversiSpecifications: ReversiSpecifications {
    var initalBoard: Board = ReversiSpecificationsImplementation().initalState(from: Board())
    func initalState(from board: Board) -> Board {
        initalBoard
    }
   
    var isEndOfGame = false
    func isEndOfGame(on board: Board) -> Bool {
        isEndOfGame
    }
    
    
    var stubbedInitalState: Board?
    func boardOfInitalState(from board: Board) -> Board {
        stubbedInitalState!
    }

    var stubbedFlippedDiskCoordinatesByPlacingResult: [Coordinates]! = []

    func flippedDiskCoordinatesByPlacing(disk: Disk, on board: Board, at coordinates: Coordinates) -> [Coordinates] {
        return stubbedFlippedDiskCoordinatesByPlacingResult
    }

    var stubbedCanPlaceDiskResult: Bool! = false

    func canPlaceDisk(_ disk: Disk, on board: Board, at coordinates: Coordinates) -> Bool {
        return stubbedCanPlaceDiskResult
    }

    var stubbedValidMovesResult: [Coordinates]! = []

    func validMoves(for side: Disk, on board: Board) -> [Coordinates] {
        return stubbedValidMovesResult
    }
}
