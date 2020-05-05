//
//  MockUILabel.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/05/05.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import UIKit

final class MockUILabel: UILabel {
    private(set) var textArgs: [String?] = []
    override var text: String? {
        didSet {
            textArgs.append(text)
        }
    }
}
