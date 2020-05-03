//
//  MockBoardView.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/04/24.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

@testable import Reversi

struct SetDiskArg: Equatable {
    let disk: Disk?
    let x: Int
    let y: Int
    let aniamted: Bool
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.disk == rhs.disk && lhs.x == rhs.x && lhs.y == rhs.y && lhs.aniamted == rhs.aniamted
    }
}

final class MockBoardView: BoardView {
    
    var isSuccess: Bool = true
    var setDiskArgs: [SetDiskArg] = []
    override func setDisk(_ disk: Disk?, atX x: Int, y: Int, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        
        setDiskArgs.append(SetDiskArg(disk: disk, x: x, y: y, aniamted: animated))
        completion?(isSuccess)
    }
    
    var resetCompletion: (() -> Void)?
    override func reset() {
        resetCompletion?()
    }
    
    var dummyDisks: [Coordinates: Disk] = [:]
    var diskAtCompletion: (((x: Int, y: Int)) -> Void)?
    override func diskAt(x: Int, y: Int) -> Disk? {
        return dummyDisks[Coordinates(x: x, y: y)]
    }
}
