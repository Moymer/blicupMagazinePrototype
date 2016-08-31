//
//  CardsCollectionViewCell.swift
//  Blicup
//
//  Created by Moymer on 30/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class LocationButton: UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.titleLabel?.textAlignment = NSTextAlignment.Center
    }
    
    override func intrinsicContentSize() -> CGSize {
        let labelSize = titleLabel?.sizeThatFits(CGSizeMake(self.frame.size.width, CGFloat.max)) ?? CGSizeZero
        let desiredButtonSize = CGSizeMake(labelSize.width + titleEdgeInsets.left + titleEdgeInsets.right, labelSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom)
        
        return desiredButtonSize
    }
    
    override func setTitle(title: String?, forState state: UIControlState) {
        if state == UIControlState.Normal && title?.characterCount() == 0 {
            super.setTitle("Location", forState: state)
        }
        else {
            super.setTitle(title, forState: state)
        }
    }
}


class ArticleTextView: UITextView {

    override func intrinsicContentSize() -> CGSize {
        return self.contentSize
    }
}


class CoverCollectionViewCell: UICollectionViewCell {
    @IBOutlet var cardMedia: UIImageView!
    
    override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let superAttr = super.preferredLayoutAttributesFittingAttributes(layoutAttributes)
        superAttr.size = CGSizeMake(layoutAttributes.size.width, superAttr.size.height)
        return superAttr
    }
}
