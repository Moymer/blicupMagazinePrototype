//
//  BCCloseButton.swift
//  Blicup
//
//  Created by Gustavo Tiago on 13/07/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation
import UIKit

class BCCloseButton: UIButton {
    
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.addActions()
    }
    
    func addActions() {
        addTarget(self, action: #selector(BCButton.btnDragEnter(_:)), forControlEvents: .TouchDragEnter)
        addTarget(self, action: #selector(BCButton.btnDragExit(_:)), forControlEvents: .TouchDragExit)
        addTarget(self, action: #selector(BCButton.btnPressedDown(_:)), forControlEvents: .TouchDown)
        addTarget(self, action: #selector(BCButton.btnTouchCancel(_:)), forControlEvents: .TouchCancel)
    }
    
    
    func btnDragEnter(sender: AnyObject) {
        UIView.animateWithDuration(0.2) {
            self.transform = CGAffineTransformMakeScale(0.7, 0.7)
        }
    }
    
    func btnDragExit(sender: AnyObject) {
        UIView.animateWithDuration(0.1) {
            self.transform = CGAffineTransformMakeScale(1, 1)
        }
    }
    
    func btnPressedDown(sender: AnyObject) {
        UIView.animateWithDuration(0.2) {
            self.transform = CGAffineTransformMakeScale(0.7, 0.7)
        }
    }
    
    func btnTouchCancel(sender: AnyObject) {
        UIView.animateWithDuration(0.1) {
            self.transform = CGAffineTransformMakeScale(1, 1)
        }
    }
    
}