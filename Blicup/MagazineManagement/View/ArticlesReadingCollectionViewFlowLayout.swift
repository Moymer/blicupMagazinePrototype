//
//  ArticlesReadingCollectionViewFlowLayout.swift
//  Blicup
//
//  Created by Moymer on 9/8/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class ArticlesReadingCollectionViewFlowLayout: UICollectionViewFlowLayout {


    
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return super.targetContentOffsetForProposedContentOffset(proposedContentOffset) }
        
        let halfHeight = collectionView.bounds.height / 2
        
        let dir : CGFloat = velocity.y > 0 ? 1 : -1
        let proposedContentOffsetCenterY = proposedContentOffset.y + (dir * 1.5 * halfHeight)
        
        let layoutAttributes = layoutAttributesForElementsInRect(collectionView.bounds)
        let closest = layoutAttributes?.sort { abs($0.center.y - proposedContentOffsetCenterY) < abs($1.center.y - proposedContentOffsetCenterY) }.first ?? UICollectionViewLayoutAttributes()
        
        return CGPoint(x: proposedContentOffset.x, y: closest.center.y - halfHeight)
    }
}
