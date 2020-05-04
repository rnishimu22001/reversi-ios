//
//  MockReversiViewModel.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/05/04.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

@testable import Reversi

struct SetDiskArgForViewModel: SetDiskArg {
    let disk: Disk?
    let x: Int
    let y: Int
}

final class MockReversiViewModel: ReversiViewModel {

    var invokedBoardGetter = false
    var invokedBoardGetterCount = 0
    var stubbedBoard: Board = Board()

    var board: Board {
        invokedBoardGetter = true
        invokedBoardGetterCount += 1
        return stubbedBoard
    }

    var invokedSetDiskDiskAtCoordinates = false
    var invokedSetDiskDiskAtCoordinatesCount = 0
    var invokedSetDiskDiskAtCoordinatesParameters: (disk: Disk, coodinates: Coordinates)?
    var invokedSetDiskDiskAtCoordinatesParametersList = [SetDiskArgForViewModel]()

    func set(disk: Disk, at coodinates: Coordinates) {
        invokedSetDiskDiskAtCoordinates = true
        invokedSetDiskDiskAtCoordinatesCount += 1
        invokedSetDiskDiskAtCoordinatesParameters = (disk, coodinates)
        invokedSetDiskDiskAtCoordinatesParametersList.append(SetDiskArgForViewModel(disk: disk, x: coodinates.x, y: coodinates.y))
    }

    var invokedSetDiskDiskAtMultiCoordinates = false
    var invokedSetDiskDiskAtMultiCoordinatesCount = 0
    var invokedSetDiskDiskAtMultiCoordinatesParameters: (disk: Disk, coodinates: [Coordinates])?
    var invokedSetDiskDiskAtMultiCoordinatesParametersList = [(disk: Disk, coodinates: [Coordinates])]()

    func set(disk: Disk, at coodinates: [Coordinates]) {
        invokedSetDiskDiskAtMultiCoordinates = true
        invokedSetDiskDiskAtMultiCoordinatesCount += 1
        invokedSetDiskDiskAtMultiCoordinatesParameters = (disk, coodinates)
        invokedSetDiskDiskAtMultiCoordinatesParametersList.append((disk, coodinates))
    }

    var invokedReset = false
    var invokedResetCount = 0

    func reset() {
        invokedReset = true
        invokedResetCount += 1
    }

    var invokedRestore = false
    var invokedRestoreCount = 0
    var invokedRestoreParameters: (board: Board, Void)?
    var invokedRestoreParametersList = [(board: Board, Void)]()

    func restore(from board: Board) {
        invokedRestore = true
        invokedRestoreCount += 1
        invokedRestoreParameters = (board, ())
        invokedRestoreParametersList.append((board, ()))
    }
}
