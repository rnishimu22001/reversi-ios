//
//  ReversiSpecifications.swift
//  Reversi
//
//  Created by rnishimu on 2020/04/26.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

struct ReversiSpecifications {
    
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
