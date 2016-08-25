//
//  TextFieldNoTextOptions.swift
//  Blicup
//
//  Created by Guilherme Braga on 10/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class TextFieldNoTextOptions: UITextField {

    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        return false
    }
    
    // placeholder position
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, 20, 10)
    }
    // text position
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, 20, 10)
    }


}
