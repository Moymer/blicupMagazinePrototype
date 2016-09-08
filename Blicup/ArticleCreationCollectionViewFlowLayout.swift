//
//  ArticleCreationCollectionViewFlowLayout.swift
//  Blicup
//
//  Created by Gustavo Tiago on 30/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation
import UIKit

class ArticleCreationCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    var disablePaging = false
    
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return !CGSizeEqualToSize(newBounds.size, self.collectionView!.frame.size)
    }
    
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        guard disablePaging == false else {
            return proposedContentOffset
        }
        
        if let cv = self.collectionView {
            
            let cvBounds = cv.bounds
            let halfHeight = cvBounds.size.height * 0.5;
            let proposedContentOffsetCenterY = proposedContentOffset.y + halfHeight;
            
            if let attributesForVisibleCells = self.layoutAttributesForElementsInRect(cvBounds) {
                
                var candidateAttributes : UICollectionViewLayoutAttributes?
                for attributes in attributesForVisibleCells {
                    
                    if attributes.representedElementCategory != UICollectionElementCategory.Cell {
                        continue
                    }
                    
                    
                    if (attributes.center.y == 0) || (attributes.center.y > (cv.contentOffset.y + halfHeight) && velocity.y < 0) {
                        continue
                    }
                    
                    // == First time in the loop == //
                    guard let candAttrs = candidateAttributes else {
                        candidateAttributes = attributes
                        continue
                    }
                    
                    let a = attributes.center.y - proposedContentOffsetCenterY
                    let b = candAttrs.center.y - proposedContentOffsetCenterY
                    
                    if fabsf(Float(a)) < fabsf(Float(b)) {
                        candidateAttributes = attributes;
                    }
                }
                
                if(proposedContentOffset.y == -(cv.contentInset.top) || proposedContentOffset.y == -(cv.contentInset.bottom)) {
                    return proposedContentOffset
                }
                
                guard let attr = candidateAttributes else {
                    return proposedContentOffset
                }
                
                return CGPoint(x: attr.center.x, y: floor(attr.center.y - halfHeight))
            }
        }
        
        return super.targetContentOffsetForProposedContentOffset(proposedContentOffset)
    }
    
}