//
//  ReversiSpecifications.swift
//  Reversi
//
//  Created by rnishimu on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

protocol ReversiSpecifications {
    func initalState(from board: Board) -> Board
    func flippedDiskCoordinatesByPlacing(disk: Disk, on board: Board, at coordinates: Coordinates) -> [Coordinates]
    func canPlaceDisk(_ disk: Disk, on board: Board, at coordinates: Coordinates) -> Bool
    func validMoves(for side: Disk, on board: Board) -> [Coordinates]
}

struct ReversiSpecificationsImplementation: ReversiSpecifications {
    
    func initalState(from board: Board) -> Board {
        var newBoard = Board(width: board.width, height: board.height)
        do {
            try newBoard.set(disk: .light, atX: board.width / 2 - 1, y: board.height / 2 - 1)
            try newBoard.set(disk: .dark, atX: board.width / 2, y: board.height / 2 - 1)
            try newBoard.set(disk: .dark, atX: board.width / 2 - 1, y: board.height / 2)
            try newBoard.set(disk: .light, atX: board.width / 2, y: board.height / 2)
        } catch {
            fatalError("初期化に失敗しました")
        }
        return newBoard
    }
    
    func isEndOfGame(on board: Board) -> Bool {
        Disk.allCases.reduce(true) { (previous, disk) in
            previous && self.validMoves(for: disk, on: board).isEmpty
        }
    }
    
    func flippedDiskCoordinatesByPlacing(disk: Disk, on board: Board, at coordinates: Coordinates) -> [Coordinates] {
        
        let directions = [
            Coordinates(x: -1, y: -1),
            Coordinates(x:  0, y: -1),
            Coordinates(x:  1, y: -1),
            Coordinates(x:  1, y:  0),
            Coordinates(x:  1, y:  1),
            Coordinates(x:  0, y:  1),
            Coordinates(x: -1, y:  0),
            Coordinates(x: -1, y:  1),
        ]
        
        guard board.disks[coordinates] == nil,
            board.isValidInRange(coordinates: coordinates) else {
            return []
        }
       
        let flipped = directions.compactMap { direction -> [Coordinates] in
            var scanning = coordinates
            var canFlip: [Coordinates] = []
            var candidates: [Coordinates] = []
            flipping: while true {
                scanning = Coordinates(x: scanning.x + direction.x, y: scanning.y + direction.y)
                switch (disk, board.disks[scanning]) { // Uses tuples to make patterns exhaustive
                case (.dark, .some(.dark)), (.light, .some(.light)):
                    canFlip = candidates
                    break flipping
                case (.dark, .some(.light)), (.light, .some(.dark)):
                    candidates.append(scanning)
                case (_, .none):
                    break flipping
                }
            }
            return canFlip
        }.joined()
        
        return Array(flipped)
    }
    
    func canPlaceDisk(_ disk: Disk, on board: Board, at coordinates: Coordinates) -> Bool {
        !flippedDiskCoordinatesByPlacing(disk: disk, on: board, at: coordinates).isEmpty
    }
    
    func validMoves(for side: Disk, on board: Board) -> [Coordinates] {
        return board.coordinates.compactMap {
            guard canPlaceDisk(side, on: board, at: $0) else {
                return nil
            }
            return $0
        }
    }
}
