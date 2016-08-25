//
//  CreateChatRoomInputAccessoryView.swift
//  Blicup
//
//  Created by Guilherme Braga on 14/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class CreateChatRoomInputAccessoryView: UIView {

    @IBOutlet weak var constrBtnCreateChatHeight: NSLayoutConstraint!
    
    override func didMoveToSuperview() {
        
        super.didMoveToSuperview()
        self.constrBtnCreateChatHeight.constant = 50
        self.alpha = 0
        self.layoutIfNeeded()
    }
    
    func showBtnCreateChat(show: Bool) {
    
//        self.constrBtnCreateChatHeight.constant = show ? 50 : 0
//        self.layoutIfNeeded()
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: [], animations: {
            self.alpha = show ? 1.0 : 0.0
//            self.layoutIfNeeded()
            }, completion: nil)
    }

    override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(self.bounds.width, 50)
    }
    
}
