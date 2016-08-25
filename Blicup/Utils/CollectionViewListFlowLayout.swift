//
//  CollectionViewListFlowLayout.swift
//  Blicup
//
//  Created by Guilherme Braga on 21/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class CollectionViewListFlowLayout: UICollectionViewFlowLayout {

    let itemHeight: CGFloat = 80
    
    override var sectionInset : UIEdgeInsets{
        didSet{
            invalidateLayout()
        }}
    
    override var minimumInteritemSpacing : CGFloat{
        didSet{
            invalidateLayout()
        }}

    
    override init() {
        super.init()
        setupLayout()
    }
    
    /**
     Init method
     
     - parameter aDecoder: aDecoder
     
     - returns: self
     */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }
    
    /**
     Sets up the layout for the collectionView. 0 distance between each cell, and vertical layout
     */
    func setupLayout() {
        minimumInteritemSpacing = 0
        minimumLineSpacing = 1
        scrollDirection = .Vertical
        
    }
    
    func itemWidth() -> CGFloat {
        return CGRectGetWidth(collectionView!.frame)
    }
    
    override var itemSize: CGSize {
        set {
            self.itemSize = CGSizeMake(itemWidth(), itemHeight)
        }
        get {
            return CGSizeMake(itemWidth(), itemHeight)
        }
    }
    
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
        return collectionView!.contentOffset
    }
    
}
