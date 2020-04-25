//
//  BoardRepository.swift
//  Reversi
//
//  Created by rnishimu on 2020/04/25.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

struct BoardRepository {
    
    let fileIO: FileIOAdapter
    
    init(fileIO: FileIOAdapter = FileIO(fileName: "Game")) {
        self.fileIO = fileIO
    }
    
    func saveGame() {
        
    }
    
    func loadGame() throws {
        
    }
}
