//
//  ReversiViewModel.swift
//  Reversi
//
//  Created by rnishimu on 2020/05/04.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

protocol ReversiViewModel {
    var board: Board { get }
    mutating func set(disk: Disk, x: Int, y: Int)
}

struct ReversiViewModelImplementation: ReversiViewModel {
  
    private(set) var specifications: ReversiSpecifications
    private(set) var board: Board
    
    init(board: Board,
         specifications: ReversiSpecifications = ReversiSpecificationsImplementation()) {
        self.board = board
        self.specifications = specifications
    }
    
    mutating func set(disk: Disk, x: Int, y: Int) {
        try? board.set(disk: disk, at: Coordinates(x: x, y: y))
    }
    
    mutating func reset() {
        board = specifications.initalState(from: board)
    }
   
    /// あとでboardの引数を削る
    mutating func restore(with board: Board) {
        self.board = board
    }
}
