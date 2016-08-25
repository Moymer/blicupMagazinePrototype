//
//  FlowLayout.swift
//  Blicup
//
//  Created by Guilherme Braga on 17/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class FlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        let attributesForElementsInRect = super.layoutAttributesForElementsInRect(rect)
        var newAttributesForElementsInRect = [UICollectionViewLayoutAttributes]()
        
        // use a value to keep track of left margin
        var leftMargin: CGFloat = 0.0;
        
        for attributes in attributesForElementsInRect! {
            let refAttributes = attributes 
            // assign value if next row
            if (refAttributes.frame.origin.x == self.sectionInset.left) {
                leftMargin = self.sectionInset.left
            } else {
                // set x position of attributes to current margin
                var newLeftAlignedFrame = refAttributes.frame
                if leftMargin + refAttributes.frame.width >= (rect.width - self.sectionInset.right) {
                    newLeftAlignedFrame.origin.x = self.sectionInset.left
                } else {
                    newLeftAlignedFrame.origin.x = leftMargin == 0 ? self.sectionInset.left : leftMargin
                }
                refAttributes.frame = newLeftAlignedFrame
            }
            // calculate new value for current margin
            leftMargin += refAttributes.frame.size.width + 8
            newAttributesForElementsInRect.append(refAttributes)
        }
        
        return newAttributesForElementsInRect
    }
}
