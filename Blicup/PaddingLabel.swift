//
//  PaddingLabel.swift
//  Blicup
//
//  Created by Gustavo Tiago on 08/07/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation
import UIKit

class PaddingLabel: UILabel {
    
    let padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    
    
    override func drawTextInRect(rect: CGRect) {
        self.numberOfLines = 0
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, padding))
    }
    
    // Override -intrinsicContentSize: for Auto layout code
    override func intrinsicContentSize() -> CGSize {
        let superContentSize = super.intrinsicContentSize()
        let textWidth = frame.size.width - (self.padding.left + self.padding.right)
        let text = self.text! as NSString
        let newSize = text.boundingRectWithSize(CGSizeMake(textWidth, CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName : self.font], context: nil)
        
        let width = superContentSize.width + padding.left + padding.right
        let heigth = newSize.size.height + padding.top + padding.bottom + 5
        return CGSize(width: width, height: heigth)
    }
    
    // Override -sizeThatFits: for Springs & Struts code
    override func sizeThatFits(size: CGSize) -> CGSize {
        let superSizeThatFits = super.sizeThatFits(size)
        
        let textWidth = frame.size.width - (self.padding.left + self.padding.right)
        let text = self.text! as NSString
        let newSize = text.boundingRectWithSize(CGSizeMake(textWidth, CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName : self.font], context: nil)
        
        let width = superSizeThatFits.width + padding.left + padding.right
        let heigth = newSize.height + padding.top + padding.bottom
        return CGSize(width: width, height: heigth)
    }
    
}