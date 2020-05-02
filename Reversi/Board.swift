//
//  Board.swift
//  Reversi
//
//  Created by rnishimu on 2020/04/24.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

enum BoardError: Error {
    case outOfRange(coordinates: Coordinates, range: (x: Range<Int>, y: Range<Int>))
}

struct Board {
    /// 盤の幅（ `8` ）を表します。
    public let width: Int = 8
    
    /// 盤の高さ（ `8` ）を返します。
    public let height: Int = 8
    
    /// 盤のセルの `x` の範囲（ `0 ..< 8` ）を返します。
    public let xRange: Range<Int>
    
    /// 盤のセルの `y` の範囲（ `0 ..< 8` ）を返します。
    public let yRange: Range<Int>
    
    public let coordinates: [Coordinates]
    
    init() {
        xRange = 0 ..< width
        yRange = 0 ..< height
        var boardCoordinates: [Coordinates] = []
        for x in xRange {
            for y in yRange {
                boardCoordinates.append(Coordinates(x: x, y: y))
            }
        }
        self.coordinates = boardCoordinates
    }
    
    private(set) var disks: [Coordinates: Disk] = [:]
    
    func disk(atX x: Int, y: Int) -> Disk? {
        return disks[Coordinates(x: x, y: y)]
    }
    
    func isValidInRange(coordinates: Coordinates) -> Bool {
        return yRange.contains(coordinates.x) && xRange.contains(coordinates.y)
    }
    
    mutating func set(disk: Disk?, atX x: Int, y: Int) throws {
        let coordinates = Coordinates(x: x, y: y)
        guard isValidInRange(coordinates: coordinates) else {
                throw BoardError.outOfRange(coordinates: coordinates, range: (x: xRange, y: yRange))
        }
        disks[coordinates] = disk
    }
    
    func countDisks(of side: Disk) -> Int {
        disks.filter({ $0.value == side }).count
    }
    
    func sideWithMoreDisks() -> Disk? {
        let darkCount = countDisks(of: .dark)
        let lightCount = countDisks(of: .light)
        if darkCount == lightCount {
            return nil
        } else {
            return darkCount > lightCount ? .dark : .light
        }
    }
}
