//
//  Canceller.swift
//  Reversi
//
//  Created by rnishimu on 2020/05/10.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

enum CancellerState {
    case executed
    case hold
    case invalid
}

protocol Canceller {
    var state: CancellerState { get }
    var isCancelled: Bool { get }
    func prepareForReuse(_ body: (() -> Void)?)
    func cancel()
    func invalidate()
}

final class CancellerImplementation: Canceller {
    
    private(set) var state: CancellerState = .hold
    var isCancelled: Bool { state == .executed }
    private var body: (() -> Void)?
    
    init(_ body: (() -> Void)?) {
        self.body = body
    }
    
    func prepareForReuse(_ body: (() -> Void)?) {
        state = .hold
        self.body = body
    }
    
    func cancel() {
        guard case .hold = state else { return }
        state = .executed
        body?()
    }
    
    func invalidate() {
        state = .invalid
        body = nil
    }
}
