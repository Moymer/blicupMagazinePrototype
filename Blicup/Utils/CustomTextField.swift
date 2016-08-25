//
//  CustomTextField.swift
//  Blicup
//
//  Created by Guilherme Braga on 24/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class CustomTextField: UITextField {

    var paddingPosX: CGFloat = 20
    var paddingPosY: CGFloat = 10

    
    // placeholder position
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, paddingPosX, paddingPosY)
    }
    
    override func placeholderRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, paddingPosX, paddingPosY)
    }
    
    // text position
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, paddingPosX, paddingPosY)
    }
}
