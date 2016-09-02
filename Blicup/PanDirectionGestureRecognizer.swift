//
//  PanDirectionGestureRecognizer.swift
//  Blicup
//
//  Created by Gustavo Tiago on 02/09/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation
import UIKit
import UIKit.UIGestureRecognizerSubclass

enum PanDirection {
    case Vertical
    case Horizontal
}

class PanDirectionGestureRecognizer: UIPanGestureRecognizer {
    
    let direction : PanDirection
    
    init(direction: PanDirection, target: AnyObject, action: Selector) {
        self.direction = direction
        super.init(target: target, action: action)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        if state == .Began {
            let velocity = velocityInView(self.view!)
            switch direction {
            case .Horizontal where fabs(velocity.y) > fabs(velocity.x):
                state = .Cancelled
            case .Vertical where fabs(velocity.x) > fabs(velocity.y):
                state = .Cancelled
            default:
                break
            }
        }
    }
}