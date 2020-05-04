//
//  ReversiViewModel.swift
//  Reversi
//
//  Created by rnishimu on 2020/05/04.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Combine

protocol ReversiViewModel {
    var board: Board { get }
    mutating func set(disk: Disk, at coodinates: Coordinates)
    mutating func set(disk: Disk, at coodinates: [Coordinates])
    
    mutating func reset()
    mutating func restore(from board: Board)
}

struct ReversiViewModelImplementation: ReversiViewModel {
  
    private(set) var specifications: ReversiSpecifications
    private(set) var board: Board
    private(set) var message: CurrentValueSubject<MessageDisplayData?, Never> = .init(nil)
    
    init(board: Board,
         specifications: ReversiSpecifications = ReversiSpecificationsImplementation()) {
        self.board = board
        self.specifications = specifications
    }
    
    mutating func set(disk: Disk, at coodinates: Coordinates) {
        try? board.set(disk: disk, at: coodinates)
    }
    
    mutating func set(disk: Disk, at coodinates: [Coordinates]) {
        coodinates.forEach {
            try? board.set(disk: disk, at: $0)
        }
    }
    
    mutating func reset() {
        board = specifications.initalState(from: board)
    }
    
    mutating func restore(from board: Board) {
        self.board = board
    }
}
