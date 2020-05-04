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
    var message: CurrentValueSubject<MessageDisplayData, Never> { get }
    var darkPlayerStatus: CurrentValueSubject<PlayerStatusDisplayData, Never> { get }
    var lightPlayerStatus: CurrentValueSubject<PlayerStatusDisplayData, Never> { get }
    
    mutating func set(disk: Disk, at coodinates: Coordinates)
    mutating func set(disk: Disk, at coodinates: [Coordinates])
    
    mutating func reset()
    mutating func restore(from board: Board)
}

struct ReversiViewModelImplementation: ReversiViewModel {
  
    private(set) var specifications: ReversiSpecifications
    private(set) var board: Board {
        didSet {
            darkPlayerStatus.send(PlayerStatusDisplayData(playerType: darkPlayerStatus.value.playerType,
                                                          diskCount: board.countDisks(of: .dark)))
            lightPlayerStatus.send(PlayerStatusDisplayData(playerType: lightPlayerStatus.value.playerType,
                                                          diskCount: board.countDisks(of: .light)))
        }
    }
    private(set) var message: CurrentValueSubject<MessageDisplayData, Never> = .init(MessageDisplayData(status: .playing(turn: .dark)))
    private(set) var darkPlayerStatus: CurrentValueSubject<PlayerStatusDisplayData, Never> = .init(PlayerStatusDisplayData(playerType: .manual, diskCount: 0))
    private(set) var lightPlayerStatus: CurrentValueSubject<PlayerStatusDisplayData, Never> = .init(PlayerStatusDisplayData(playerType: .manual, diskCount: 0))
    
    init(board: Board,
         specifications: ReversiSpecifications = ReversiSpecificationsImplementation()) {
        self.board = board
        self.specifications = specifications
    }
    
    mutating func nextTurn(status: GameStatus) {
        message.send(MessageDisplayData(status: status))
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
