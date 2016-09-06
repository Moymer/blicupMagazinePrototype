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
    var editing = false
    
    override func prepareLayout() {
        if let collectionView = self.collectionView {
            let verticalInsets = (collectionView.bounds.height - 330)/2
            self.sectionInset = UIEdgeInsetsMake(verticalInsets, 20, verticalInsets, 20)
            let cellWidth = collectionView.bounds.width - (self.sectionInset.left + self.sectionInset.right)
            self.minimumLineSpacing = 50
            if editing {
                self.estimatedItemSize = CGSizeMake(cellWidth/1.5, 330)
            } else {
                self.estimatedItemSize = CGSizeMake(cellWidth, 330)
            }
        }
        super.prepareLayout()
    }
    
    override func shouldInvalidateLayoutForPreferredLayoutAttributes(preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        return true
    }
    
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