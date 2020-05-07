//
//  Navigator.swift
//  Reversi
//
//  Created by rnishimu on 2020/05/07.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import UIKit

protocol Navigator {
    func present(viewContorller: UIViewController, animated: Bool, completion: (() -> Void)?)
}

final class NavigatorImplementation: Navigator {
    
    private weak var navigationController: UINavigationController?
   
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    func present(viewContorller: UIViewController, animated: Bool, completion: (() -> Void)?) {
        navigationController?.present(viewContorller, animated: animated, completion: completion)
    }
}
