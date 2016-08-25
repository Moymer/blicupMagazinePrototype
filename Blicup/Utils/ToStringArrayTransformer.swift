//
//  ToStringArrayTransformer.swift
//  Blicup
//
//  Created by Moymer on 5/26/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class ToStringArrayTransformer: NSValueTransformer {

    
    override class func transformedValueClass() -> AnyClass {
 
       return  NSArray.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(value: AnyObject?) -> AnyObject? {
     
        return value as? [String]
    }
    
    
 
    
}
