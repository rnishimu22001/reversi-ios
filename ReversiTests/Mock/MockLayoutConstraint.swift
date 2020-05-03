//
//  MockLayoutConstraint.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/05/03.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import Foundation
import UIKit

final class MockLayoutConstraint: NSLayoutConstraint {
   
    override var constant: CGFloat {
        get {
            mockConstant
        }
        set {
            mockConstant = newValue
        }
    }
    
    var mockConstant: CGFloat = 0
    
    init(with constnat: CGFloat) {
        super.init()
        mockConstant = constant
    }
}
