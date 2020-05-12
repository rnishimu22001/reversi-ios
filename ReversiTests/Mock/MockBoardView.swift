//
//  MockBoardView.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/04/24.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

@testable import Reversi

protocol SetDiskArg: Equatable {
    var disk: Disk? { get }
    var x: Int { get }
    var y: Int { get }
}

extension SetDiskArg {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.disk == rhs.disk && lhs.x == rhs.x && lhs.y == rhs.y
    }
}

struct SetDiskArgForMockView: SetDiskArg {
    let disk: Disk?
    let x: Int
    let y: Int
    let aniamted: Bool
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.disk == rhs.disk && lhs.x == rhs.x && lhs.y == rhs.y && lhs.aniamted == rhs.aniamted
    }
}

final class MockBoardView: BoardView {
    
    var setDiskArgs: [SetDiskArgForMockView] = []
    var capturedCompletion: ((Bool) -> Void)?
    var shouldCaputreCompletion = false
    override func setDisk(_ disk: Disk?, atX x: Int, y: Int, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        setDiskArgs.append(SetDiskArgForMockView(disk: disk, x: x, y: y, aniamted: animated))
        if shouldCaputreCompletion {
            capturedCompletion = completion
        } else {
            completion?(true)
        }
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
