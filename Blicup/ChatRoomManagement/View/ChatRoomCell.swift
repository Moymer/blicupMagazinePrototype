//
//  ChatRoomCell.swift
//  Blicup
//
//  Created by Moymer on 20/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Kingfisher
import TTTAttributedLabel
@objc protocol ChatMessageCellProtocol: class {
    func chatRoomCellResentMessagePressed(cell: ChatRoomCell)
    func chatRoomCellLikePressed(cell: ChatRoomCell)
    func chatRoomCellMentionPressed(user: String)
    func chatRoomCellShowGiphy(sender:ChatRoomCell, giphyRect:CGRect)
}

class ChatRoomCell: UICollectionViewCell, TTTAttributedLabelDelegate {
    static let VERTICAL_FIXED_CELL_HEIGHT:CGFloat = 45
    private let kNotSentWidth:CGFloat = 55.0
    
    static private let kItemFixedHeight:CGFloat = 37.0 // Item height without the dynamic message height (all the rest has fixed size)
    static private let kItemFixedWidth:CGFloat = 90.0 // Item width without the dynamic message width (all the rest has fixed size)
    static private let kSizeFromEmoji: CGFloat = 40
    private var isDefaultCell = false
    private var cellState = ChatRoomMessage.MessageState.Sent
    
    @IBOutlet weak var ivVerifiedBadge: UIImageView!
    @IBOutlet weak var constrivVerifiedBadgeWidth: NSLayoutConstraint!
    
    @IBOutlet weak var messagePhoto: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var userName: UILabel!
    
    @IBOutlet weak var constrNotSentBtnWidth: NSLayoutConstraint!
    @IBOutlet weak private var likesLabel: UILabel!
    @IBOutlet weak private var btnLike: UIButton!
    @IBOutlet weak private var sendingOverlay: UIView!
    @IBOutlet weak var vContent: UIView!
    
    @IBOutlet weak private var lblMessage: TTTAttributedLabel!
    @IBOutlet weak private var vGifContainer: UIView!
    @IBOutlet weak private var ivGif: AnimatedImageView!
    private var cellType = ChatRoomMessage.MessageType.TEXT_MSG
    
    let kVerifiedBadgeWidth: CGFloat = 15
    
    weak var delegate: ChatMessageCellProtocol?
    
    var likesNumber:NSInteger = 0 {
        didSet {
            if likesNumber > 0 {
                likesLabel.text = "\(likesNumber)"
            }
            else {
                likesLabel.text = nil
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 4
        self.vContent.layer.cornerRadius = 4
        self.ivGif.layer.cornerRadius = 4
        
        lblMessage.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        lblMessage.linkAttributes = [NSForegroundColorAttributeName : UIColor.blicupBlue()]
        lblMessage.activeLinkAttributes = [NSForegroundColorAttributeName : UIColor.blicupBlue()]
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.delegate = nil
        isDefaultCell = false
        messagePhoto.image = nil
        userName.text = nil
        
        lblMessage.text = nil
        lblMessage.delegate = nil
        vGifContainer.hidden = true
        
        ivGif.image = nil
        ivGif.needsPrescaling = false
        ivGif.autoPlayAnimatedImage = true
        ivGif.framePreloadCount = 2
        
        timeLabel.text = nil
        likesLabel.text = nil
        likesLabel.hidden = false
        btnLike.selected = false
        btnLike.hidden = false
        sendingOverlay.hidden = true
        cellState = .Sent
        constrNotSentBtnWidth.constant = 0
    }
    
    func setAsDefaultInitialMessageOfChat(chatName chat:String?, chatImageUrl:NSURL?, chatMessage: String?) {
        isDefaultCell = true
        likesLabel.hidden = true
        btnLike.hidden = true
        timeLabel.text = nil
        userName.text = chat
        lblMessage.text = chatMessage!
        constrNotSentBtnWidth.constant = 0
        self.showVerifiedBadge(false)
        
        if let chatImageUrl = chatImageUrl {
            messagePhoto.kf_setImageWithURL(chatImageUrl)
        }
    }
    
    func setItemState(state:ChatRoomMessage.MessageState, animated:Bool) {
        if state == self.cellState {
            return
        }
        
        self.cellState = state
        self.sendingOverlay.hidden = (state == ChatRoomMessage.MessageState.Sent)
        
        var transform = CGAffineTransformIdentity
        var notSentWidth:CGFloat = 0
        
        if state == ChatRoomMessage.MessageState.Sending {
            transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.95, 0.95)
        }
        else if state == ChatRoomMessage.MessageState.NotSent {
            notSentWidth = kNotSentWidth
        }
        
        if animated {
            UIView.animateWithDuration(1) {
                self.transform = transform
                self.constrNotSentBtnWidth.constant = notSentWidth
                self.layoutIfNeeded()
            }
        }
        else {
            self.transform = transform
            self.constrNotSentBtnWidth.constant = notSentWidth
        }
    }
    
    func setMessage(message: String?) {
        
        if let message = message {
            lblMessage.font = message.isBigEmoji() ? ChatRoomCell.bigEmojiFontText() : ChatRoomCell.defaultFontText()
        }
        
        lblMessage.text = message
        lblMessage.hidden = false
        vGifContainer.hidden = true
        cellType = .TEXT_MSG
    }
    
    func setAttributtedMessage(message: NSMutableAttributedString?) {
        
        lblMessage.attributedText = nil
        lblMessage.delegate = nil
        
        message?.enumerateAttributesInRange(NSMakeRange(0, (message?.length)!),options: [] , usingBlock: { (value, range, stop) in
            if value["NSLink"] != nil && value["NSColor"] != nil && value["NSColor"] as! UIColor == UIColor.blicupBlue() //isLink
            {
                let usernameMentioned = message?.attributedSubstringFromRange(range)
                self.lblMessage.addLinkToURL(NSURL(string: (usernameMentioned?.string)!), withRange: range)
            }
        })
        
        let detector = try! NSDataDetector(types: NSTextCheckingType.Link.rawValue)
        let matches = detector.matchesInString((message?.string)!, options: [], range: NSRange(location: 0, length: (message?.length)!))
        
        for match in matches {
            
            let url = ((message?.string)! as NSString).substringWithRange(match.range)
            self.lblMessage.addLinkToURL(NSURL(string: url), withRange: match.range)
            message?.addAttribute(NSForegroundColorAttributeName, value: UIColor.blicupBlue(), range: match.range)
        }
        
        lblMessage.attributedText = message
        lblMessage.delegate = self
        lblMessage.hidden = false
        vGifContainer.hidden = true
        cellType = .TEXT_MSG
    }
    
    //MARK: TTTAttributedLabelDelegate
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        
        // MENTION
        if url.absoluteString.characters.first == "@" {
            self.delegate!.chatRoomCellMentionPressed(url.absoluteString)
            
        } else {
            
            var urlString = url
            
            // HTTP Links
            if url.scheme == "" {
                urlString = NSURL(string: "http://" + url.absoluteString)
            }
            
            if UIApplication.sharedApplication().canOpenURL(urlString) {
                UIApplication.sharedApplication().openURL(urlString)
            }
        }
    }
    
    func setGiphyUrl(url:NSURL) {
        lblMessage.hidden = true
        vGifContainer.hidden = false
        ivGif.kf_setImageWithURL(url)
        cellType = .IMAGE_MSG
    }
    
    
    func setLiked(status:Bool) {
        btnLike.selected = status
    }
    
    func setMessageColor(color:UIColor) {
        sendingOverlay.backgroundColor = color.colorWithAlphaComponent(0.5)
        messagePhoto.backgroundColor = color.colorWithAlphaComponent(0.5)
        ivGif.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)
    }
    
    func showVerifiedBadge(isVerified: Bool) {
        
        self.constrivVerifiedBadgeWidth.constant = isVerified ? kVerifiedBadgeWidth : 0
        self.ivVerifiedBadge.hidden = !isVerified
        self.layoutIfNeeded()
        
    }
    
    func animateHighlightCell() {
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.95, 0.95)
            }, completion: nil)
    }
    
    func animateUnhighlightCell() {
        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.transform = CGAffineTransformIdentity
            }, completion: nil)
    }
    
    // MARK: Actions
    func tapDetected(gestureRecognizer: UIGestureRecognizer) {
        
        let tapLocation = gestureRecognizer.locationInView(self.lblMessage)
        
        if self.lblMessage.containslinkAtPoint(tapLocation) {
            
            let link = lblMessage.linkAtPoint(tapLocation)
            let result = link.result
            
            if result != nil && result.resultType == NSTextCheckingType.Link {
                self.attributedLabel(self.lblMessage, didSelectLinkWithURL: result.URL)
            }
            
        } else if cellState == ChatRoomMessage.MessageState.Sent {
            
            self.animateHighlightCell()
            
            self.btnLike.selected = !self.btnLike.selected
            likePressed(btnLike)
        }
    }
    
    @IBAction func likePressed(sender: UIButton) {
        
        UIView.animateKeyframesWithDuration(0.4, delay: 0, options: UIViewKeyframeAnimationOptions.CalculationModeLinear, animations: {
            // CELL CONTENT
            UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.6, animations: {
                self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.05, 1.05)
            })
            
            UIView.addKeyframeWithRelativeStartTime(0.6, relativeDuration: 0.4, animations: {
                self.transform = CGAffineTransformIdentity
            })
            
            if !self.isDefaultCell {
                // LIKE BTN
                UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.75, animations: {
                    sender.transform = CGAffineTransformScale(sender.transform, 1.5, 1.5)
                })
                
                UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.25, animations: {
                    sender.transform = CGAffineTransformRotate(sender.transform, CGFloat(-M_PI_4))
                })
                
                UIView.addKeyframeWithRelativeStartTime(0.25, relativeDuration: 0.5, animations: {
                    sender.transform = CGAffineTransformRotate(sender.transform, CGFloat(M_PI_2))
                })
                
                UIView.addKeyframeWithRelativeStartTime(0.75, relativeDuration: 0.25, animations: {
                    sender.transform = CGAffineTransformIdentity
                })
            }
        }) { (finished) in
            if !self.isDefaultCell {
                self.delegate?.chatRoomCellLikePressed(self)
            }
        }
    }
    
    @IBAction func messageErrorBtnPressed(sender: UIButton) {
        self.delegate?.chatRoomCellResentMessagePressed(self)
    }
    
    @IBAction func gifPressed(sender: UIButton) {
        let giphyFrame = self.convertRect(ivGif.bounds, fromView: ivGif)
        self.delegate?.chatRoomCellShowGiphy(self, giphyRect: giphyFrame)
    }
    
    
    // MARK: Class method
    class func itemHeightForMessage(message: String?, time:String?, mentionMessage: NSMutableAttributedString?, constrainedToWidth width:CGFloat)->CGFloat {
        let mockLabel = UILabel()
        mockLabel.numberOfLines = 0
        mockLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        
        mockLabel.font = UIFont(name: "SFUIText-Italic", size: 14.0)
        mockLabel.text = time
        mockLabel.sizeToFit()
        
        let timeSize = mockLabel.bounds.width
        let maxSize = CGSizeMake(width-kItemFixedWidth-timeSize, CGFloat.max)
        
        let attributedLabel = TTTAttributedLabel(frame: CGRect(x: 0.0, y: 0.0, width: maxSize.width, height: 0))
        
        attributedLabel.numberOfLines = 0
        
        attributedLabel.lineHeightMultiple = 1.0
        attributedLabel.linkAttributes = [NSFontAttributeName: UIFont(name: "SFUIText-Regular", size: 16.0)!]
        attributedLabel.activeLinkAttributes = nil
        
        if mentionMessage != nil {
            attributedLabel.attributedText = mentionMessage
        }
        else {
            if message != nil && message!.isBigEmoji() {
                attributedLabel.font = ChatRoomCell.bigEmojiFontText()
                attributedLabel.minimumLineHeight = ChatRoomCell.bigEmojiFontText().lineHeight
                attributedLabel.maximumLineHeight =  ChatRoomCell.bigEmojiFontText().lineHeight
            }
            else {
                attributedLabel.font = ChatRoomCell.defaultFontText()
                attributedLabel.minimumLineHeight = ChatRoomCell.defaultFontText().lineHeight
                attributedLabel.maximumLineHeight =  ChatRoomCell.defaultFontText().lineHeight
            }
            
            attributedLabel.text = message
        }
        
        let frame = attributedLabel.sizeThatFits(maxSize).height
        
        return CGFloat(ceil(Double(frame + kItemFixedHeight)))
        
    }
    
    
    class func itemHeightForImageSize(size:CGSize, time:String?, constrainedToWidth width:CGFloat)->CGFloat {
        let font = UIFont(name: "SFUIText-Italic", size: 14.0)
        
        let mockLabel = UILabel()
        mockLabel.numberOfLines = 0
        mockLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        mockLabel.font = font
        mockLabel.text = time
        mockLabel.sizeToFit()
        let timeSize = mockLabel.bounds.width
        let maxGiphyWidth = width - kItemFixedWidth - timeSize
        var giphyHeight:CGFloat!
        
        if size.width > maxGiphyWidth {
            let ratio = maxGiphyWidth/size.width
            giphyHeight = (size.height * ratio)
        }
        else {
            giphyHeight = size.height
        }
        
        return (giphyHeight + kItemFixedHeight)
    }
    
    class func defaultFontText() -> UIFont {
        return UIFont(name: "SFUIText-Regular", size: 16.0)!
    }
    
    class func bigEmojiFontText() -> UIFont {
        return UIFont(name: "AppleColorEmoji", size: kSizeFromEmoji)!
    }
    
    class func defaultAttributtedText() -> [String : NSObject] {
        return [NSFontAttributeName : ChatRoomCell.defaultFontText(), NSForegroundColorAttributeName : UIColor.blackColor()]
    }
}