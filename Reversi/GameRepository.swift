//
//  GameRepository.swift
//  Reversi
//
//  Created by rnishimu on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

protocol GameRepository {
    func save(game: Game) throws
    func restore() throws -> Game
}

struct GameRepositoryImplementation: GameRepository {
    
    private let fileIO: FileIOAdapter
    
    init(fileIO: FileIOAdapter = FileIO(fileName: "Game")) {
        self.fileIO = fileIO
    }
    
    func save(game: Game) throws {
        var output: String = ""
        output += game.turn.symbol
        for side in Disk.allCases {
            switch side {
            case .dark:
                output += game.darkPlayer.rawValue.description
            case .light:
                output += game.lightPlayer.rawValue.description
            }
        }
        output += "\n"
        
        for y in game.board.yRange {
            for x in game.board.xRange {
                output += game.board.disk(atX: x, y: y).symbol
            }
            output += "\n"
        }
        
        do {
            try fileIO.write(output)
        } catch let error {
            throw FileIOError.read(path: fileIO.path, cause: error)
        }
    }
    
    func restore() throws -> Game {
        var game = Game(board: Board(), darkPlayer: .manual, lightPlayer: .manual)
        let input = try fileIO.read()
        var lines: ArraySlice<Substring> = input.split(separator: "\n")[...]
        
        guard var line = lines.popFirst() else {
            throw FileIOError.read(path: fileIO.path, cause: nil)
        }
        
        do { // turn
            guard
                let diskSymbol = line.popFirst(),
                let disk = Optional<Disk>(symbol: diskSymbol.description)
            else {
                throw FileIOError.read(path: fileIO.path, cause: nil)
            }
            game.turn = disk
        }

        // players
        for side in Disk.allCases {
            guard
                let playerSymbol = line.popFirst(),
                let playerNumber = Int(playerSymbol.description),
                let player = Player(rawValue: playerNumber)
            else {
                throw FileIOError.read(path: fileIO.path, cause: nil)
            }
            switch side {
            case .dark:
                game.darkPlayer = player
            case .light:
                game.lightPlayer = player
            }
        }

        do { // board
            guard lines.count == game.board.height else {
                throw FileIOError.read(path: fileIO.path, cause: nil)
            }
            
            var y = 0
            while let line = lines.popFirst() {
                guard line.count == game.board.width else {
                    throw FileIOError.read(path: fileIO.path, cause: nil)
                }
                var x = 0
                for character in line {
                    let disk = Disk?(symbol: "\(character)").flatMap { $0 }
                    try game.board.set(disk: disk, atX: x, y: y)
                    x += 1
                }
                y += 1
            }
            guard y == game.board.height else {
                throw FileIOError.read(path: fileIO.path, cause: nil)
            }
        }
        return game
    }
}

// MARK: File-private extensions

extension Disk {
    init(index: Int) {
        for side in Disk.allCases {
            if index == side.index {
                self = side
                return
            }
        }
        preconditionFailure("Illegal index: \(index)")
    }
    
    var index: Int {
        switch self {
        case .dark: return 0
        case .light: return 1
        }
    }
}

extension Optional where Wrapped == Disk {
    fileprivate init?<S: StringProtocol>(symbol: S) {
        switch symbol {
        case "x":
            self = .some(.dark)
        case "o":
            self = .some(.light)
        case "-":
            self = .none
        default:
            return nil
        }
    }
    
    fileprivate var symbol: String {
        switch self {
        case .some(.dark):
            return "x"
        case .some(.light):
            return "o"
        case .none:
            return "-"
        }
    }
}

