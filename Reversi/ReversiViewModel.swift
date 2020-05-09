//
//  ReversiViewModel.swift
//  Reversi
//
//  Created by rnishimu on 2020/05/04.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Combine

enum BoardUpdate {
    case withAnimation(disks: [SetDiskDisplayData])
    case withoutAnimation(disks: [SetDiskDisplayData])
}

protocol ReversiViewModel {
   
    // MARK: 通知用
    var message: CurrentValueSubject<MessageDisplayData, Never> { get }
    var darkPlayerStatus: CurrentValueSubject<PlayerStatusDisplayData, Never> { get }
    var lightPlayerStatus: CurrentValueSubject<PlayerStatusDisplayData, Never> { get }
    var boardStatus: PassthroughSubject<BoardUpdate, Never> { get }
   
    /// 次のターンに移る
    mutating func nextTurn()
    /// manualとcomputerを切り返る
    mutating func changePlayer(on side: Disk)
    /// `x`, `y` で指定された座標のdiskデータをもとに盤面を更新します。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Throws: もし `disk` を `x`, `y` で指定されるセルに置けない場合、 `DiskPlacementError` を `throw` します。
    mutating func place(disk: Disk, at coordinates: Coordinates) throws
   
    /// ゲームの状態を復元
    mutating func restore(from game: Game)
    /// ゲームの状態を初期状態に戻す
    mutating func reset()
    
    // MARK: のちに削除
    var turn: Disk? { get }
    var board: Board { get }
    
    mutating func updateDiskCount()
    mutating func updateMessage()
}

struct ReversiViewModelImplementation: ReversiViewModel {
    
    private(set) var specifications: ReversiSpecifications
   
    private(set) var message: CurrentValueSubject<MessageDisplayData, Never> = .init(MessageDisplayData(status: .playing(turn: .dark)))
    private(set) var darkPlayerStatus: CurrentValueSubject<PlayerStatusDisplayData, Never> = .init(PlayerStatusDisplayData(playerType: .manual, diskCount: 0))
    private(set) var lightPlayerStatus: CurrentValueSubject<PlayerStatusDisplayData, Never> = .init(PlayerStatusDisplayData(playerType: .manual, diskCount: 0))
    private(set) var boardStatus: PassthroughSubject<BoardUpdate, Never> = .init()
    
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
        updateMessage()
    }
    
    mutating func nextTurn() {
        defer {
            updateMessage()
        }
        // ゲームが終わったか確認
        guard !specifications.isEndOfGame(on: board) else {
            turn = nil
            return
        }
        turn?.flip()
    }
    
    mutating func changePlayer(on side: Disk) {
        switch side {
        case .dark:
            darkPlayerStatus.value = PlayerStatusDisplayData(playerType: darkPlayerStatus.value.playerType.changed,
                                                             diskCount: darkPlayerStatus.value.diskCount)
        case .light:
            lightPlayerStatus.value = PlayerStatusDisplayData(playerType: lightPlayerStatus.value.playerType.changed,
                                                              diskCount: lightPlayerStatus.value.diskCount)
        }
    }
    
    mutating func place(disk: Disk, at coordinates: Coordinates) throws {
       
        guard specifications.canPlaceDisk(disk, on: board, at: coordinates) else {
            throw DiskPlacementError(disk: disk, x: coordinates.x, y: coordinates.y)
        }
        
        let willFlip = specifications.placingDiskCoordinates(byPlacing: disk, on: board, at: coordinates)
        
        willFlip.forEach {
            try? board.set(disk: disk, at: $0)
        }
        boardStatus
            .send(.withAnimation(disks:
                willFlip
                    .map { SetDiskDisplayData(side: disk, coordinates: $0) }
                )
        )
    }
    
    mutating func restore(from game: Game) {
        board = game.board
        turn = game.turn
        darkPlayerStatus.value = PlayerStatusDisplayData(playerType: game.darkPlayer, diskCount: board.countDisks(of: .dark))
        lightPlayerStatus.value = PlayerStatusDisplayData(playerType: game.lightPlayer, diskCount: board.countDisks(of: .light))
        restoreBoardWithoutAnimation()
        updateMessage()
    }
    
    mutating func reset() {
        restore(from: Game(turn: .dark, board: specifications.initalState(from: Board()), darkPlayer: .manual, lightPlayer: .manual))
    }
    
    mutating func restoreBoardWithoutAnimation() {
        boardStatus
            .send(
                .withoutAnimation(disks:
                    board.disks
                        .map { SetDiskDisplayData(side: $0.value, coordinates: $0.key) }
                )
        )
    }
   
    /// 各プレイヤーの獲得したディスクの枚数を更新します。
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
   
    /// 現在のターン、勝敗の決着などに関する情報を更新します。
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
