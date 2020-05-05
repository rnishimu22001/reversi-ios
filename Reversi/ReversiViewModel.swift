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
    
    mutating func updateDiskCount()
    mutating func updateMessage()
    
    mutating func set(disk: Disk, at coodinates: Coordinates)
    mutating func set(disk: Disk, at coodinates: [Coordinates])
    
    mutating func restore(from board: Board)
}

struct ReversiViewModelImplementation: ReversiViewModel {
  
    private(set) var specifications: ReversiSpecifications
    private(set) var board: Board
    private(set) var turn: Disk? = .dark
    private(set) var message: CurrentValueSubject<MessageDisplayData, Never> = .init(MessageDisplayData(status: .playing(turn: .dark)))
    private(set) var darkPlayerStatus: CurrentValueSubject<PlayerStatusDisplayData, Never> = .init(PlayerStatusDisplayData(playerType: .manual, diskCount: 0))
    private(set) var lightPlayerStatus: CurrentValueSubject<PlayerStatusDisplayData, Never> = .init(PlayerStatusDisplayData(playerType: .manual, diskCount: 0))
    
    init(board: Board,
         specifications: ReversiSpecifications = ReversiSpecificationsImplementation()) {
        self.board = board
        self.specifications = specifications
        updateDiskCount()
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
    
    mutating func restore(from board: Board) {
        self.board = board
    }
    
    mutating func updateDiskCount() {
        let dark = PlayerStatusDisplayData(playerType: darkPlayerStatus.value.playerType,
                                           diskCount: board.countDisks(of: .dark))
        if dark != darkPlayerStatus.value {
            darkPlayerStatus.value = dark
        }
        let light = PlayerStatusDisplayData(playerType: lightPlayerStatus.value.playerType,
                                            diskCount: board.countDisks(of: .light))
        if light != lightPlayerStatus.value {
            lightPlayerStatus.value = light
        }
    }
    
    mutating func updateMessage() {
        
    }
}
