//
//  Canceller.swift
//  Reversi
//
//  Created by rnishimu on 2020/05/10.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

final class Canceller {
    
    enum State {
        case canceled
        case hold
        case applied
    }
    
    private(set) var isCancelled: Bool = false
    private var body: (() -> Void)?
    
    init(_ body: (() -> Void)?) {
        self.body = body
    }
    
    func prepareForReuse() {
        isCancelled = false
        body = nil
    }
    
    func cancel() {
        if isCancelled { return }
        isCancelled = true
        body?()
    }
}
