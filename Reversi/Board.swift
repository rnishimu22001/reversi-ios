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
    public let width: Int
    
    /// 盤の高さ（ `8` ）を返します。
    public let height: Int
    
    /// 盤のセルの `x` の範囲（ `0 ..< 8` ）を返します。
    public let xRange: Range<Int>
    
    /// 盤のセルの `y` の範囲（ `0 ..< 8` ）を返します。
    public let yRange: Range<Int>
    
    public let coordinates: Set<Coordinates>
    
    init(width: Int = 8, height: Int = 8) {
        self.width = width
        self.height = height
        xRange = 0 ..< width
        yRange = 0 ..< height
        var boardCoordinates: Set<Coordinates> = []
        for x in xRange {
            for y in yRange {
                boardCoordinates.insert(Coordinates(x: x, y: y))
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
        try set(disk: disk, at: Coordinates(x: x, y: y))
    }
    
    mutating func set(disk: Disk?, at coordinates: Coordinates) throws {
        guard isValidInRange(coordinates: coordinates) else {
                throw BoardError.outOfRange(coordinates: coordinates, range: (x: xRange, y: yRange))
        }
        disks[coordinates] = disk
    }
   
    /// `side` で指定された色のディスクが盤上に置かれている枚数を返します。
    /// - Parameter side: 数えるディスクの色です。
    /// - Returns: `side` で指定された色のディスクの、盤上の枚数です。
    func countDisks(of side: Disk) -> Int {
        disks.filter({ $0.value == side }).count
    }
   
    /// 盤上に置かれたディスクの枚数が多い方の色を返します。
    /// 引き分けの場合は `nil` が返されます。
    /// - Returns: 盤上に置かれたディスクの枚数が多い方の色です。引き分けの場合は `nil` を返します。
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
