//
//  ReversiViewModel.swift
//  Reversi
//
//  Created by rnishimu on 2020/05/04.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Combine

protocol ReversiViewModel {
   
    var turn: Disk? { get }
    
    var board: Board { get }
    var message: CurrentValueSubject<MessageDisplayData, Never> { get }
    var darkPlayerStatus: CurrentValueSubject<PlayerStatusDisplayData, Never> { get }
    var lightPlayerStatus: CurrentValueSubject<PlayerStatusDisplayData, Never> { get }
    
    mutating func updateDiskCount()
    mutating func updateMessage()
    
    mutating func nextTurn()
    
    mutating func set(disk: Disk, at coodinates: Coordinates)
    mutating func set(disk: Disk, at coodinates: [Coordinates])
    
    mutating func restore(from game: Game)
}

struct ReversiViewModelImplementation: ReversiViewModel {
    
    private(set) var specifications: ReversiSpecifications
   
    // MARK: 通知用
    private(set) var message: CurrentValueSubject<MessageDisplayData, Never> = .init(MessageDisplayData(status: .playing(turn: .dark)))
    private(set) var darkPlayerStatus: CurrentValueSubject<PlayerStatusDisplayData, Never> = .init(PlayerStatusDisplayData(playerType: .manual, diskCount: 0))
    private(set) var lightPlayerStatus: CurrentValueSubject<PlayerStatusDisplayData, Never> = .init(PlayerStatusDisplayData(playerType: .manual, diskCount: 0))
  
    // MARK: ゲームの状態
    private(set) var board: Board
    private(set) var turn: Disk?
    
    init(game: Game? = nil,
         specifications: ReversiSpecifications = ReversiSpecificationsImplementation()) {
        self.board = Board()
        self.specifications = specifications
        if let game = game {
            restore(from: game)
        } else {
            reset()
        }
        updateDiskCount()
    }
    
    mutating func nextTurn() {
        turn?.flip()
    }
    
    mutating func set(disk: Disk, at coodinates: Coordinates) {
        try? board.set(disk: disk, at: coodinates)
    }
    
    mutating func set(disk: Disk, at coodinates: [Coordinates]) {
        coodinates.forEach {
            try? board.set(disk: disk, at: $0)
        }
    }
    
    mutating func restore(from game: Game) {
        board = game.board
        turn = game.turn
        darkPlayerStatus.value = PlayerStatusDisplayData(playerType: game.darkPlayer, diskCount: board.countDisks(of: .dark))
        lightPlayerStatus.value = PlayerStatusDisplayData(playerType: game.lightPlayer, diskCount: board.countDisks(of: .light))
    }
    
    mutating func reset() {
        board = specifications.initalState(from: Board())
        turn = .dark
        darkPlayerStatus.value = PlayerStatusDisplayData(playerType: .manual, diskCount: board.countDisks(of: .dark))
        lightPlayerStatus.value = PlayerStatusDisplayData(playerType: .manual, diskCount: board.countDisks(of: .light))
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
        if specifications.isEndOfGame(on: board) {
            message.value = MessageDisplayData(status: .ending(winner: board.sideWithMoreDisks()))
        } else {
            guard let turn = turn else {
                fatalError("ゲーム中の手番が設定されていません")
            }
            message.value = MessageDisplayData(status: .playing(turn: turn))
        }
    }
}
