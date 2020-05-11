//
//  SpyCanceller.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/05/11.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

@testable import Reversi

final class SpyCannceller: Canceller {

    var invokedStateGetter = false
    var invokedStateGetterCount = 0
    var stubbedState: CancellerState = .hold

    var state: CancellerState {
        invokedStateGetter = true
        invokedStateGetterCount += 1
        return stubbedState
    }

    var invokedIsCancelledGetter = false
    var invokedIsCancelledGetterCount = 0
    var stubbedIsCancelled: Bool! = false

    var isCancelled: Bool {
        invokedIsCancelledGetter = true
        invokedIsCancelledGetterCount += 1
        return stubbedIsCancelled
    }

    var invokedPrepareForReuse = false
    var invokedPrepareForReuseCount = 0
    var shouldInvokePrepareForReuseBody = false

    func prepareForReuse(_ body: (() -> Void)?) {
        invokedPrepareForReuse = true
        invokedPrepareForReuseCount += 1
        if shouldInvokePrepareForReuseBody {
            body?()
        }
    }

    var invokedCancel = false
    var invokedCancelCount = 0

    func cancel() {
        invokedCancel = true
        invokedCancelCount += 1
    }

    var invokedInvalidate = false
    var invokedInvalidateCount = 0

    func invalidate() {
        invokedInvalidate = true
        invokedInvalidateCount += 1
    }
}
