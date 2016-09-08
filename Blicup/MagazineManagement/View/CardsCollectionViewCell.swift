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
        if state == UIControlState.Normal && (title==nil || title!.characterCount()==0) {
            super.setTitle("Location", forState: state)
        }
        else {
            super.setTitle(title, forState: state)
        }
    }
}


@IBDesignable class ArticleTextView: UITextView {
    private let lblPlaceholder = UILabel()
    
    @IBInspectable var placeholder:String? = "placeholder" {
        didSet {
            lblPlaceholder.text = placeholder
        }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        initPlaceholder()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initPlaceholder()
    }

    
    private func initPlaceholder() {        
        lblPlaceholder.frame = self.bounds
        lblPlaceholder.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        
        self.addSubview(lblPlaceholder)
        
        lblPlaceholder.font = self.font
        lblPlaceholder.textAlignment = self.textAlignment
        lblPlaceholder.textColor = UIColor.lightGrayColor()
        lblPlaceholder.text = placeholder        
    }
    
    func adjustPlaceholder(forceHidde shouldHide:Bool) {
        lblPlaceholder.hidden = (shouldHide || self.text.characterCount() > 0)
    }
}


class CardCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var cardImage: UIImageView!
    @IBOutlet weak var cardVideo: FullscreenVideoView!
    @IBOutlet weak var vContainer: UIView!
    @IBOutlet weak var btnTrash: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialConfig()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialConfig()
    }
    
    private func initialConfig() {
        if let container = self.viewWithTag(1) {
            container.layer.cornerRadius = 20
        }
        
        self.layer.shadowColor = UIColor.lightGrayColor().CGColor
        self.layer.shadowOffset = CGSizeMake(2, 2)
        self.layer.shadowOpacity = 0.5
        self.layer.shadowRadius = 3.0
        self.clipsToBounds = false
        self.layer.masksToBounds = false
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
    
    class func cellSize(width:CGFloat, title:String?, content: String?)->CGSize {
        return CGSizeMake(300, 330)
    }
}

class ContentCollectionCell: CardCollectionViewCell {
    @IBOutlet weak var contentTitle: ArticleTextView!
    @IBOutlet weak var contentText: ArticleTextView!
    
    override var title: String? {
        set {
            contentTitle.text = newValue
            contentTitle.adjustPlaceholder(forceHidde: false)
        }
        get { return contentTitle.text }
    }
    
    override var content: String? {
        set {
            contentText.text = newValue
            contentText.adjustPlaceholder(forceHidde: false)
        }
        get { return contentText.text }
    }
    
    override class func cellSize(width:CGFloat, title:String?, content: String?)->CGSize {
        let FIXED_HEIGHT: CGFloat = 250.0
        let width = width - 20
        
        let tv = ArticleTextView()
        
        tv.font = UIFont(name: "Avenir-Black", size: 23.0)
        tv.text = title
        let titleSize = tv.sizeThatFits(CGSizeMake(width, CGFloat.max))
        
        tv.font = UIFont(name: "Avenir-Roman", size: 16.0)
        tv.text = content
        let contentSize = tv.sizeThatFits(CGSizeMake(width, CGFloat.max))
        
        let totalHeight = FIXED_HEIGHT + titleSize.height + contentSize.height
        return CGSizeMake(width, totalHeight)
    }
}

class CoverCollectionCell: CardCollectionViewCell {
    @IBOutlet weak var articleTitle: ArticleTextView!
    @IBOutlet weak var articleLocation: LocationButton!
    
    override var title: String? {
        set {
            articleTitle.text = newValue
            articleTitle.adjustPlaceholder(forceHidde: false)
        }
        get { return articleTitle.text }
    }
    
    override var content: String? {
        set { articleLocation.setTitle(newValue, forState: UIControlState.Normal) }
        get { return articleLocation.titleLabel?.text }
    }
}
