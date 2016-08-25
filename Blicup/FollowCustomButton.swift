//
//  FollowCustomButton.swift
//  Blicup
//
//  Created by Gustavo Tiago on 20/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class FollowCustomButton: UIButton {
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */
    
    // MARK: Overrides
    
    override internal func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override var highlighted: Bool{
        didSet{
            if !highlighted{
                self.layer.borderColor = UIColor(colorLiteralRed: 208.0/255, green: 208.0/255, blue: 208.0/255, alpha: 1.0).CGColor
            } else{
                self.backgroundColor = UIColor(colorLiteralRed: 252.0/255, green: 0.0/255, blue: 83.0/255, alpha: 1.0)
            }
        }
    }
    
    override var selected: Bool{
        didSet{
            self.layer.cornerRadius = 15
            self.layer.borderColor = UIColor(colorLiteralRed: 252.0/255, green: 0.0/255, blue: 83.0/255, alpha: 1.0).CGColor
            self.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            self.layer.borderWidth = 1.0
        }
    }
    
   
    
}



