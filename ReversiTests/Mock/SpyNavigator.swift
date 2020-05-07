//
//  SpyNavigator.swift
//  ReversiTests
//
//  Created by rnishimu on 2020/05/07.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

@testable import Reversi
import UIKit

final class SpyNavigator: Navigator {
    private(set) var presentArgs: [(UIViewController, Bool)] = []
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        presentArgs.append((viewController, animated))
    }
}
