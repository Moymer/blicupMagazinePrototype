//
//  BCBlurredTabBar.swift
//  Blicup
//
//  Created by Guilherme Braga on 15/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class BCBlurredTabBar: UITabBar {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundImage = UIImage(color: UIColor.clearColor())
        let frost = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
        frost.alpha = 0.85
        frost.frame = self.bounds
        frost.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.insertSubview(frost, atIndex: 0)
    }
}

