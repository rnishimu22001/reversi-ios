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
    override func startAnimating() {
        startAnimatingCount += 1
    }
}
