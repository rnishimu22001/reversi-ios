//
//  MockBoardView.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/04/24.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

@testable import Reversi

final class MockBoardView: BoardView {
    
    var setDiskCompletion: (((disk: Disk?, x: Int, y: Int, animated: Bool)) -> Void)?
    var isSuccess: Bool = true
    override func setDisk(_ disk: Disk?, atX x: Int, y: Int, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        setDiskCompletion?((disk: disk, x: x, y: y, animated))
        completion?(isSuccess)
    }
    
    var resetCompletion: (() -> Void)?
    override func reset() {
        resetCompletion?()
    }
    
    var dummyDisks: [Path: Disk] = [:]
    override func diskAt(x: Int, y: Int) -> Disk? {
        return dummyDisks[Path(x: x, y: y)]
    }
}
