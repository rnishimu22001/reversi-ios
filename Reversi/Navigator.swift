//
//  Navigator.swift
//  Reversi
//
//  Created by rnishimu on 2020/05/07.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import UIKit

protocol Navigator {
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?)
}

final class NavigatorImplementation: Navigator {
    
    private weak var viewController: UIViewController?
   
    init(viewController: UIViewController?) {
        self.viewController = viewController
    }
    
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        self.viewController?.present(viewController, animated: animated, completion: completion)
    }
}
