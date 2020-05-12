//
//  MockUIIndicatorView.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/05/07.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import UIKit

final class MockUIIndicatorView: UIActivityIndicatorView {
    var startAnimatingCount = 0
    var startCompletion: (() -> Void)?
    override func startAnimating() {
        startAnimatingCount += 1
    }
    var stopAnimatingCount = 0
    var stopCompletion: (() -> Void)?
    override func stopAnimating() {
        stopCompletion?()
        stopAnimatingCount += 1
    }
}
