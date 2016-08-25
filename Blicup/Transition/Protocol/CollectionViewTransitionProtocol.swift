//
//  CollectionViewTransitionProtocol.swift
//  Blicup
//
//  Created by Guilherme Braga on 30/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation
import UIKit

@objc protocol CollectionViewTransitionProtocol {
    func transitionCollectionView() -> UICollectionView!
}

@objc protocol CollectionTansitionWaterfallGridViewProtocol {
    func snapShotForTransition() -> UIView!
}

@objc protocol CollectionWaterFallViewControllerProtocol: CollectionViewTransitionProtocol {
    func viewWillAppearWithPageIndex(pageIndex: NSInteger)
}

@objc protocol CollectionHorizontalPageViewControllerProtocol: CollectionViewTransitionProtocol {
    func pageViewCellScrollViewContentOffset() -> CGPoint
}