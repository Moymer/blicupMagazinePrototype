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
        let size = self.sizeThatFits(CGSizeMake(self.bounds.width, CGFloat.max))
        return size
    }
}


class CardCollectionViewCell: UICollectionViewCell {
    @IBOutlet var cardMedia: UIImageView!
    
    override func preferredLayoutAttributesFittingAttributes(layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let superAttr = super.preferredLayoutAttributesFittingAttributes(layoutAttributes)
        superAttr.size = CGSizeMake(layoutAttributes.size.width, superAttr.size.height)
        return superAttr
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.title = nil
        self.content = nil
        
    }

    var isFocusCell = false {
        didSet {
            self.userInteractionEnabled = isFocusCell
            self.alpha = isFocusCell ? 1.0 : 0.5
        }
    }
    
    
    var title: String? {
        set { print("Override this method") }
        
        get {
            print("Override this method")
            return nil
        }
    }
    
    var content: String? {
        set { print("Override this method") }
        
        get {
            print("Override this method")
            return nil
        }
    }
}

class ContentCollectionCell: CardCollectionViewCell {
    @IBOutlet weak var contentTitle: ArticleTextView!
    @IBOutlet weak var contentText: ArticleTextView!
    
    override var title: String? {
        set {
            contentTitle.text = newValue
            contentTitle.invalidateIntrinsicContentSize()
        }
        get { return contentTitle.text }
    }
    
    override var content: String? {
        set {
            contentText.text = newValue
            contentText.invalidateIntrinsicContentSize()
        }
        get { return contentText.text }
    }
}

class CoverCollectionCell: CardCollectionViewCell {
    @IBOutlet weak var articleTitle: ArticleTextView!
    @IBOutlet weak var articleLocation: LocationButton!
    
    override var title: String? {
        set {
            articleTitle.text = newValue
            articleTitle.invalidateIntrinsicContentSize()
        }
        get { return articleTitle.text }
    }
    
    override var content: String? {
        set { articleLocation.setTitle(newValue, forState: UIControlState.Normal) }
        get { return articleLocation.titleLabel?.text }
    }
}
