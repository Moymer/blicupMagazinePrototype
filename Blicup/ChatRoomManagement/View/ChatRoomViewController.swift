//
//  ChatRoomViewController.swift
//  Blicup
//
//  Created by Moymer on 13/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Kingfisher


class ChatRoomViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ChatRoomAccessoryViewDelegate, ChatRoomPresenterDelegate, ChatMessageCellProtocol, Dimmable, GHContextOverlayViewDataSource, GHContextOverlayViewDelegate, UserProfileViewControllerDelegate, AlertControllerProtocol, CoverChatRoomMessengersUpdated, ShareChatViewProtocol, TipsViewProtocol {
    
    
    enum ContextMenuItemSelected: Int {
        case More, Profile
    }
    
    private let COLLECTIONVIEW_TOP_INSET_OFFSET: CGFloat = 35 // 20 for StatusBar, 10 for distance of TopContainer
    private let kShowUserProfile = "showUserProfile"
    
    @IBOutlet weak var ivBackgroundImage: AnimatedImageView!
    @IBOutlet weak var vevBlur: UIVisualEffectView!
    
    @IBOutlet weak var kNewMessages: NSLayoutConstraint!
    @IBOutlet weak var vNewMessages: UIVisualEffectView!
    @IBOutlet weak var constrTopContainer: NSLayoutConstraint!
    @IBOutlet weak var vTopContainer: UIView!
    @IBOutlet weak var lblChatName: UILabel!
    @IBOutlet weak var vTimer: BlicupClock!
    @IBOutlet weak var lblParticipantsNumber: UILabel!
    private var vTipPressUser: TipsView!
    var vShareChatContent: ShareChatView?
    
    // Messages loading
    @IBOutlet weak var veLoadingMessages: UIVisualEffectView!
    @IBOutlet weak var ivLoadingMessages: UIImageView!
    @IBOutlet weak var constrLoadingMessages: NSLayoutConstraint!
    
    
    @IBOutlet weak var vInputAccessoryView: ChatRoomInputAccessoryView!
    @IBOutlet weak var cvChatMessagesCollection: UICollectionView!
    
    private var presenter = ChatRoomPresenter()
    private var showingFirstChatInAppCell = false
    private var showingDefaultCell = true
    private var shouldScrollToBottom = false
    private var isScrollingToBottom = true
    private var messageGreetings = ""
    private var openedChat = true
    private var contextMenuPresented = false
    private var hasReloadedChatroom : Bool = false
    
    private var verticalOffsetForTop: CGFloat {
        let topInset = cvChatMessagesCollection.contentInset.top
        return -topInset
    }
    
    private var verticalOffsetForBottom: CGFloat {
        let scrollViewHeight = cvChatMessagesCollection.bounds.height
        let scrollContentSizeHeight = cvChatMessagesCollection.contentSize.height
        let bottomInset = cvChatMessagesCollection.contentInset.bottom
        let scrollViewBottomOffset = scrollContentSizeHeight + bottomInset - scrollViewHeight
        return scrollViewBottomOffset
    }
    
    private func initMessageLoadingViews() {
        var animationArray: [UIImage] = []
        
        for index in 0...29 {
            animationArray.append(UIImage(named: "BlicMini_\(index)")!)
        }
        
        ivLoadingMessages.animationImages = animationArray
        ivLoadingMessages.animationDuration = 1
    }
    
    
    
    func animateLoadingMessages() {
        veLoadingMessages.hidden = false
        
        UIView.animateWithDuration(0.5, animations: {
            self.constrLoadingMessages.constant = 40
            self.veLoadingMessages.superview?.layoutIfNeeded()
        }) { (_) in
            self.ivLoadingMessages.startAnimating()
        }
    }
    
    func stopLoadingMessagesAnimation() {
        ivLoadingMessages.stopAnimating()
        
        UIView.animateWithDuration(0.5, animations: {
            self.constrLoadingMessages.constant = 0
            self.veLoadingMessages.superview?.layoutIfNeeded()
        }) { (_) in
            self.veLoadingMessages.hidden = true
        }
    }
    
    func didUpdateChatMessages() {
        self.stopLoadingMessagesAnimation()
        openedChat = true
    }
    
    
    //MARK: Context Menu view for Snap
    var vBackgroundGHMenuContextAboveAccessoryView = UIView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adjustInitialViews()
        setGHContextMenuView()
        initMessageLoadingViews()
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UserListFollowBlockViewController.reloadVisibleCells), name: "UserProfileClosed", object: nil)
        
        if presenter.isLoggedUserChatOwner() {
            if (NSUserDefaults.standardUserDefaults().objectForKey(kIsFirstCreatedChatKey) as? Bool) == true {
                if (NSUserDefaults.standardUserDefaults().objectForKey("firstTimeInApp") as? Bool) == true {
                    self.showingFirstChatInAppCell = (NSUserDefaults.standardUserDefaults().objectForKey("firstTimeInApp") as? Bool)!
                    NSUserDefaults.standardUserDefaults().setObject(false, forKey: "firstTimeInApp")
                }
            }
        }
        
        BlicupAnalytics.sharedInstance.seenChatRoom(presenter.chatRoomID()!)
        
        self.messageGreetings = generateMessageGreetings()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChatRoomViewController.tapDetected(_:)))
        self.cvChatMessagesCollection.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureTipUserDefault()
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        BlicupAnalytics.sharedInstance.mark_EnteredScreenChatRoom()
        
        presenter.delegate = self
        startObservingKeyboardEvents()
        
        UIView.animateWithDuration(0.2) {
            self.constrTopContainer.constant = 0
            self.vevBlur.alpha = 1
            self.view.layoutIfNeeded()
            
            self.adjustCollectionViewInsets()
        }
        
        if presenter.isLoggedUserChatOwner() {
            if let _ = NSUserDefaults.standardUserDefaults().objectForKey(self.presenter.chatRoomID()!) as? Bool {
                setShareChatView()
                NSUserDefaults.standardUserDefaults().removeObjectForKey(self.presenter.chatRoomID()!)
            }
        }
        
        customizeTipView()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopObservingKeyboardEvents()
    }
    
    override func viewDidLayoutSubviews() {
        if openedChat {
            if self.presenter.messagesNumber() > 1 {
                self.cvChatMessagesCollection.scrollToItemAtIndexPath(NSIndexPath(forItem: self.presenter.messagesNumber() - 1, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.None, animated: false)
            }
            openedChat = false
        }
    }
    
    override var inputAccessoryView: UIView? {
        vInputAccessoryView.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        
        if let url = presenter.userPhotoUrl() {
            vInputAccessoryView.setUserImage(url)
        }
        vInputAccessoryView.delegate = self
        
        return vInputAccessoryView
    }
    
    override func canBecomeFirstResponder() -> Bool {
        guard (self.presentedViewController == nil || self.presentedViewController?.isBeingDismissed() == true) && self.parentViewController != nil && (self.vShareChatContent == nil) && (self.vTipPressUser == nil) else {
            return false
        }
        
        return true
    }
    
    
    private func adjustInitialViews() {
        constrTopContainer.constant = -vTopContainer.bounds.height
        vevBlur.alpha = 0
        
        ivBackgroundImage.needsPrescaling = false
        ivBackgroundImage.autoPlayAnimatedImage = false
        ivBackgroundImage.framePreloadCount = 2
        ivBackgroundImage.backgroundColor = presenter.chatBackgroundColor()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(ChatRoomViewController.newMessagesTapped))
        self.vNewMessages.addGestureRecognizer(gesture)
        self.vNewMessages.layer.cornerRadius = 25
        self.vNewMessages.clipsToBounds = true
        
        if let imageUrl = presenter.chatBackgroundImageUrl() {
            ivBackgroundImage.kf_setImageWithURL(imageUrl)
        }
        
        adjustCollectionViewInsets()
        
        lblChatName.text = presenter.chatName()
        lblParticipantsNumber.text = "\(presenter.chatParticipantsNumber())"
        
        updateChatroomClock()
        
    }
    
    private func setGHContextMenuView() {
        let contextMenu = GHContextMenuView()
        contextMenu.dataSource = self
        contextMenu.delegate = self
        
        self.vBackgroundGHMenuContextAboveAccessoryView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.8)
        
        self.vBackgroundGHMenuContextAboveAccessoryView.userInteractionEnabled = false
        
        let longPress = UILongPressGestureRecognizer(target: contextMenu, action: #selector(GHContextMenuView.longPressDetected(_:)))
        self.cvChatMessagesCollection.addGestureRecognizer(longPress)
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func reloadVisibleCells() {
        let visibleIndexes = cvChatMessagesCollection.indexPathsForVisibleItems()
        self.cvChatMessagesCollection.reloadItemsAtIndexPaths(visibleIndexes)
        
    }
    
    func newMessagesTapped(){
        scrollToBottom()
        UIView.animateWithDuration(0.1) {
            self.vNewMessages.hidden = true
            self.vNewMessages.layer.borderWidth = 0
            self.vNewMessages.layer.borderColor = UIColor.clearColor().CGColor
        }
    }
    
    func animateViewScrollToBottom(){
        if !self.vNewMessages.hidden{
            UIView.animateWithDuration(0.1, delay: 0.0, usingSpringWithDamping: 0.1, initialSpringVelocity: 10, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                self.vNewMessages.layer.borderWidth = 3
                self.vNewMessages.layer.borderColor = UIColor(colorLiteralRed: 255.0/255, green: 0.0/255, blue: 103.0/255, alpha: 1.0).CGColor
                self.vNewMessages.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1)
            }) { (finished) in
                UIView.animateWithDuration(0.1, delay: 0.0, usingSpringWithDamping: 0.1, initialSpringVelocity: 10, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                    
                    self.vNewMessages.transform = CGAffineTransformIdentity
                    
                }) { (finished) in
                }
            }
            
        }
    }
    
    private func updateChatroomClock()
    {
        vTimer.updateBasedOnTime(presenter.getLastChatroomUpdate())
    }
    
    
    func updatedChatroom() {
        
        updateChatroomClock()
        
        lblParticipantsNumber.text = "\(presenter.chatParticipantsNumber())"
    }
    
    private func adjustCollectionViewInsets() {
        var cvInsets = cvChatMessagesCollection.contentInset
        cvInsets.top = vTopContainer.bounds.height + COLLECTIONVIEW_TOP_INSET_OFFSET + constrTopContainer.constant
        cvInsets.bottom = self.inputAccessoryView!.bounds.height + 10
        cvChatMessagesCollection.contentInset = cvInsets
        
        self.kNewMessages.constant = cvInsets.bottom
        
        //        scrollToBottom()
    }
    
    func setChatRoom(chatRoom:ChatRoom) {
        presenter.loadChatRoom(chatRoom)
    }
    
    @IBAction func backPressed(sender: UIButton) {
        self.resignFirstResponder()
        
        if self.vShareChatContent != nil {
            self.laterSharePressed(UIButton())
        }
        
        if self.vTipPressUser != nil {
            UIView.animateWithDuration(0.5, delay: 0.0, options: [], animations: {
                self.vTipPressUser.transform = CGAffineTransformMakeTranslation(0, 60)
                }, completion: { (_) in })
        }
        
        UIView.animateWithDuration(0.2, animations: {
            self.constrTopContainer.constant = -self.vTopContainer.bounds.height
            self.cvChatMessagesCollection.alpha = 0
            self.vevBlur.alpha = 0
            self.view.layoutIfNeeded()
            
        }) { (finished) in
            BlicupRouter.routeChatRoomBack(self, chatRoomId: self.presenter.chatRoomID()!)
        }
    }
    
    func customizeTipView() {
        if vTipPressUser != nil {
            self.vTipPressUser.hidden = false
        }
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.objectForKey(kPressUserTipKey) != nil {
            let tipObject = userDefaults.objectForKey(kPressUserTipKey) as? [String : AnyObject]
            let countPCTip = tipObject!["count"] as? NSNumber
            let boolPCTip = tipObject!["hasPerformedTip"] as? Bool
            
            if countPCTip?.integerValue > 3 && !boolPCTip! && !self.presenter.isLoggedUserChatOwner() && (self.vShareChatContent == nil) && (self.presenter.messagesNumber() > 0) {
                if vTipPressUser == nil {
                    self.resignFirstResponder()
                    vTipPressUser = TipsView(frame: CGRect(x: 0, y: (self.view.frame.height), width: self.view.frame.width, height: 60.0))
                    vTipPressUser.lblTips.text = NSLocalizedString("PressUser_Tip", comment: "")
                    vTipPressUser.delegate = self
                    self.view.addSubview(vTipPressUser)
                    
                    UIView.animateWithDuration(0.5, delay: 0.2, options: [], animations: {
                        self.vTipPressUser.transform = CGAffineTransformMakeTranslation(0, -60)
                        }, completion: { (_) in })
                }
            }
        }
    }
    
    func shouldAnimateTipPerformed() {
        if vTipPressUser != nil {
            let button = UIButton(frame: CGRect(x: 0, y: (self.view.window?.frame.height)! - 60, width: self.view.frame.width, height: 60.0))
            UIApplication.sharedApplication().keyWindow?.addSubview(button)
            
            self.vTipPressUser.animatedTip = true
            
            self.vTipPressUser.performedTaskTip()
            button.setImage(UIImage(named: "ic_check_gray")?.imageWithRenderingMode(.AlwaysOriginal), forState: .Normal)
            
            button.transform = CGAffineTransformMakeScale(0.9, 0.9)
            UIView.animateWithDuration(0.6, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 3, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                button.transform = CGAffineTransformIdentity
                button.backgroundColor = UIColor.blicupGreenLemon()
                
                }, completion: { (finished) in
                    
                    button.imageView?.transform = CGAffineTransformMakeScale(0.8, 0.8)
                    
                    UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 4, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                        button.imageView?.transform = CGAffineTransformIdentity
                        }, completion: { (finished) in
                            UIView.animateWithDuration(0.5, animations: {
                                button.transform = CGAffineTransformMakeTranslation(0, 60)
                                }, completion: { (_) in
                                    button.setImage(nil, forState: .Normal)
                                    button.removeFromSuperview()
                            })
                    })
            })
        }
    }
    
    //MARK: Tip Protocol
    func tipViewClosePressed(sender: UIButton) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let tipObject = userDefaults.objectForKey(kPressUserTipKey) as? [String : AnyObject]
        let countPCTip = tipObject!["count"] as? NSNumber
        let updatedObject : [String : AnyObject] = ["count" : (countPCTip?.integerValue)!, "hasPerformedTip" : true]
        userDefaults.setObject(updatedObject, forKey: kPressUserTipKey)
        
        UIView.animateWithDuration(0.5, delay: 0.2, options: [], animations: {
            self.vTipPressUser.transform = CGAffineTransformMakeTranslation(0, 60)
        }) { (_) in
            if self.vTipPressUser != nil {
                if !self.vTipPressUser.animatedTip {
                    self.vTipPressUser.removeFromSuperview()
                    self.vTipPressUser = nil
                    self.becomeFirstResponder()
                } else {
                    self.vTipPressUser.removeFromSuperview()
                    self.vTipPressUser = nil
                }
            }
        }
    }
    
    
    // MARK: CollectionView Datasource Delegate
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numberOfMessages = presenter.messagesNumber()
        
        if numberOfMessages > 0 {
            showingFirstChatInAppCell = false
            showingDefaultCell = false
            return numberOfMessages
        } else {
            if showingFirstChatInAppCell {
                showingDefaultCell = false
                return 4
            } else {
                showingDefaultCell = true
                return 1
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        var itemHeight:CGFloat = 70.0
        let collectionWidth = collectionView.bounds.width
        
        if showingFirstChatInAppCell {
            let message = presenter.defaultMessageAtIndex(indexPath)
            itemHeight = ChatRoomCell.itemHeightForMessage(message, time: "", mentionMessage: nil, constrainedToWidth: collectionWidth)
        }
        else if !showingDefaultCell {
            if presenter.isMessageBlock(indexPath) || presenter.isBlockingMe(indexPath) {
                itemHeight = 30.0
            }
            else if let size = presenter.messageImageSizeAtIndex(indexPath) {
                itemHeight = ChatRoomCell.itemHeightForImageSize(size, time: presenter.messageSentTimeAtIndex(indexPath), constrainedToWidth: collectionWidth)
            }
            else {
                let message = presenter.messageAtIndex(indexPath)
                var attrMessage: NSMutableAttributedString!
                if presenter.isMessageWithMention(indexPath) {
                    attrMessage = presenter.messageWithMentionAtIndex(indexPath)
                }
                itemHeight = ChatRoomCell.itemHeightForMessage(message, time: presenter.messageSentTimeAtIndex(indexPath), mentionMessage: attrMessage, constrainedToWidth: collectionWidth)
            }
        } else {
            itemHeight = ChatRoomCell.itemHeightForMessage(self.messageGreetings, time: "", mentionMessage: nil, constrainedToWidth: collectionWidth)
        }
        
        return CGSizeMake(collectionWidth, itemHeight)
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if showingFirstChatInAppCell{
            let item = collectionView.dequeueReusableCellWithReuseIdentifier("ChatRoomCell", forIndexPath: indexPath) as! ChatRoomCell
            item.setAsDefaultInitialMessageOfChat(chatName: presenter.chatName(), chatImageUrl: presenter.chatBackgroundImageUrl(), chatMessage: presenter.defaultMessageAtIndex(indexPath))
            return item
        }
        else if showingDefaultCell {
            let item = collectionView.dequeueReusableCellWithReuseIdentifier("ChatRoomCell", forIndexPath: indexPath) as! ChatRoomCell
            item.setAsDefaultInitialMessageOfChat(chatName: presenter.chatName(), chatImageUrl: presenter.chatBackgroundImageUrl(), chatMessage: self.messageGreetings)
            return item
        }
        else if presenter.isMessageBlock(indexPath) {
            let item = collectionView.dequeueReusableCellWithReuseIdentifier("BlockedUserCell", forIndexPath: indexPath)
            item.layer.cornerRadius = 4
            let lbltext = item.viewWithTag(1) as! UILabel
            lbltext.text = presenter.messageUserNameAtIndex(indexPath)
            return item
        }
        else if presenter.isBlockingMe(indexPath) {
            let item = collectionView.dequeueReusableCellWithReuseIdentifier("BlockerUserCell", forIndexPath: indexPath)
            item.layer.cornerRadius = 4
            return item
        }
        else {
            let item = collectionView.dequeueReusableCellWithReuseIdentifier("ChatRoomCell", forIndexPath: indexPath) as! ChatRoomCell
            
            if let photo = presenter.messageUserPhotoAtIndex(indexPath) {
                item.messagePhoto.kf_setImageWithURL(photo)
            }
            
            item.userName.text = presenter.messageUserNameAtIndex(indexPath)
            item.likesNumber = presenter.messageLikesCountAtIndex(indexPath)
            
            
            if let imageUrl = presenter.messageImageUrlAtIndex(indexPath) {
                item.setGiphyUrl(imageUrl)
            }
            else if presenter.isMessageWithMention(indexPath) {
                let attrMessage = presenter.messageWithMentionAtIndex(indexPath)
                item.setAttributtedMessage(attrMessage)
            }
            else {
                let message = presenter.messageAtIndex(indexPath)
                item.setMessage(message)
            }
            
            item.showVerifiedBadge(presenter.messageUserIsVerified(indexPath))
            item.timeLabel.text = presenter.messageSentTimeAtIndex(indexPath)
            item.setMessageColor(presenter.chatBackgroundColor())
            item.setLiked(presenter.didLikedMessageAtIndex(indexPath))
            
            let animate = collectionView.indexPathsForVisibleItems().contains(indexPath)
            item.setItemState(presenter.messageStateAtIndex(indexPath), animated: animate)
            
            item.delegate = self
            return item
        }
    }
    
    func tapDetected(recognizer: UIGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Ended {
            let tapLocation = recognizer.locationInView(self.cvChatMessagesCollection)
            if let tapIndexPath = cvChatMessagesCollection.indexPathForItemAtPoint(tapLocation) {
                if let chatRoomCell = self.cvChatMessagesCollection.cellForItemAtIndexPath(tapIndexPath) as? ChatRoomCell {
                    chatRoomCell.tapDetected(recognizer)
                }
            }
        }
    }
    
    
    // MARK: Input Accessoryview Delegate
    func chatRoomCellLikePressed(cell: ChatRoomCell) {
        if let index = cvChatMessagesCollection.indexPathForCell(cell) {
            presenter.setLikeAtMessageIndex(index)
        }
    }
    
    func chatRoomCellShowGiphy(sender:ChatRoomCell, giphyRect:CGRect) {
        
        let cellIndex = cvChatMessagesCollection.indexPathForCell(sender)
        let giphy = presenter.messageImageUrlAtIndex(cellIndex!)
        let giphyFrame = sender.convertRect(giphyRect, toView: self.view)
        
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("giphyViewerController") as! GiphyViewerController
        controller.loadGiphy(giphy!, withInitialFrame: giphyFrame)
        controller.transitioningDelegate = controller
        
        self.vInputAccessoryView.endMessageEditing()
        self.resignFirstResponder()
        
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    // MARK: ChatRoomCell Delegate
    
    func chatRoomCellResentMessagePressed(cell: ChatRoomCell) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let resentAction = UIAlertAction(title: NSLocalizedString("Resend", comment: ""), style: .Default, handler: { (action) -> Void in
            if let index = self.cvChatMessagesCollection.indexPathForCell(cell) {
                self.presenter.resentMessageAtIndex(index)
            }
        })
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            //print("Cancel Button Pressed")
        })
        
        if #available(iOS 9.0, *) {
            resentAction.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
        }
        
        alertController.addAction(resentAction)
        alertController.addAction(cancel)
        
        (self.inputAccessoryView as! ChatRoomInputAccessoryView).endMessageEditing()
        
        // Wait for keyboard to dismiss to avoid the strange behavior of keyboard with black buttons
        let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            self.presentViewController(alertController, animated: true, completion: nil)
            
            alertController.view.tintColor = UIColor.blicupPink()
            
            if let subView = alertController.view.subviews.first {
                if let contentView = subView.subviews.first {
                    contentView.backgroundColor = UIColor.whiteColor()
                }
            }
        })
    }
    
    func chatRoomCellMentionPressed(user: String){
        presenter.userForMention(user) { (user) in
            if let userMentioned = user{
                if !self.presenter.isLoggedUserMentioned(userMentioned.userId!){
                    self.performSegueWithIdentifier(self.kShowUserProfile, sender: userMentioned)
                }
            }
        }
    }
    
    
    // MARK: AccessoryViewDelegate
    func sendMessage(message: String) {
        shouldScrollToBottom = true
        presenter.sendMessage(message)
    }
    
    func sendGiphy(gifUrl: NSURL, gifSize: CGSize) {
        shouldScrollToBottom = true
        presenter.sendGiphy(gifUrl, gifSize: gifSize)
    }
    
    
    // MARK: Presenter Delegate
    func updateMessagesData(insertedIdexes: [NSIndexPath], deletedIndexes: [NSIndexPath], reloadedIndexes: [NSIndexPath]) {
        guard showingDefaultCell == false && showingFirstChatInAppCell == false  && hasReloadedChatroom == false else {
            cvChatMessagesCollection.reloadData()
            self.view.setNeedsLayout()
            return
        }
        
        
        self.cvChatMessagesCollection.performBatchUpdates({ [weak self] in
            if insertedIdexes.count > 0 {
                self?.cvChatMessagesCollection.insertItemsAtIndexPaths(insertedIdexes)
                
                if !(self?.shouldScrollToBottom)! {
                    self?.animateViewScrollToBottom()
                }
            }
            
            if deletedIndexes.count > 0 {
                self?.cvChatMessagesCollection.deleteItemsAtIndexPaths(deletedIndexes)
            }
            
            if( reloadedIndexes.count > 0) {
                self?.cvChatMessagesCollection.reloadItemsAtIndexPaths(reloadedIndexes)
            }
            
        }) {[weak self] (_) in
            if let weakSelf = self {
                if weakSelf.shouldScrollToBottom {
                    weakSelf.newMessagesTapped()
                }
                else if (weakSelf.cvChatMessagesCollection.contentOffset.y  + weakSelf.cvChatMessagesCollection.frame.height + 70 ) > weakSelf.cvChatMessagesCollection.contentSize.height
                {
                    weakSelf.scrollToBottom()
                }
            }
            
        }
    }
    
    //MARK: Tips Configuration
    
    private func configureTipUserDefault() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.objectForKey(kGIFTipKey) == nil {
            let tipObject: [String : AnyObject] = ["count" : 1, "hasPerformedTip" : false]
            userDefaults.setObject(tipObject, forKey: kGIFTipKey)
        } else {
            let tipObject = userDefaults.objectForKey(kGIFTipKey) as? [String : AnyObject]
            let countPCTip = tipObject!["count"] as? NSNumber
            let boolPCTip = tipObject!["hasPerformedTip"] as? Bool
            
            if !boolPCTip! {
                let updatedObject : [String : AnyObject] = ["count" : ((countPCTip?.integerValue)! + 1), "hasPerformedTip" : boolPCTip!]
                userDefaults.setObject(updatedObject, forKey: kGIFTipKey)
            }
        }
        
        if userDefaults.objectForKey(kMentionTipKey) == nil {
            let tipObject: [String : AnyObject] = ["count" : 1, "hasPerformedTip" : false]
            userDefaults.setObject(tipObject, forKey: kMentionTipKey)
        } else {
            let tipObject = userDefaults.objectForKey(kMentionTipKey) as? [String : AnyObject]
            let countPCTip = tipObject!["count"] as? NSNumber
            let boolPCTip = tipObject!["hasPerformedTip"] as? Bool
            
            if !boolPCTip! {
                let updatedObject : [String : AnyObject] = ["count" : ((countPCTip?.integerValue)! + 1), "hasPerformedTip" : boolPCTip!]
                userDefaults.setObject(updatedObject, forKey: kMentionTipKey)
            }
        }
        
        if userDefaults.objectForKey(kPressUserTipKey) == nil {
            let tipObject: [String : AnyObject] = ["count" : 1, "hasPerformedTip" : false]
            userDefaults.setObject(tipObject, forKey: kPressUserTipKey)
        } else {
            let tipObject = userDefaults.objectForKey(kPressUserTipKey) as? [String : AnyObject]
            let countPCTip = tipObject!["count"] as? NSNumber
            let boolPCTip = tipObject!["hasPerformedTip"] as? Bool
            
            if !boolPCTip! {
                let updatedObject : [String : AnyObject] = ["count" : ((countPCTip?.integerValue)! + 1), "hasPerformedTip" : boolPCTip!]
                userDefaults.setObject(updatedObject, forKey: kPressUserTipKey)
            }
        }
    }
    
    
    
    // MARK: Keyboard
    private func startObservingKeyboardEvents() {
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:#selector(self.keyboardWillShow(_:)),
                                                         name:UIKeyboardWillShowNotification,
                                                         object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:#selector(self.keyboardWillHide(_:)),
                                                         name:UIKeyboardWillHideNotification,
                                                         object:nil)
        
    }
    
    
    private func stopObservingKeyboardEvents() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    @IBAction func dismissKeyboard(sender: UITapGestureRecognizer) {
        if let inputView = self.inputAccessoryView as? ChatRoomInputAccessoryView {
            inputView.endMessageEditing()
        }
    }
    
    
    private func scrollToBottom() {
        let offsetY = max(verticalOffsetForTop, verticalOffsetForBottom)
        let contentOffset = CGPointMake(0, offsetY)
        cvChatMessagesCollection.setContentOffset(contentOffset, animated: true)
        self.shouldScrollToBottom = false
        self.isScrollingToBottom = true
    }
    
    private func adjustCollectionInsetsAndOffset(keyboardUserInfo:NSDictionary) {
        if let kbEndHeight = keyboardUserInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size.height {
            var contentInsets = cvChatMessagesCollection.contentInset
            contentInsets.bottom = kbEndHeight + 10
            
            self.cvChatMessagesCollection.contentInset = contentInsets
            self.cvChatMessagesCollection.scrollIndicatorInsets = contentInsets
            
            var newYOffset = cvChatMessagesCollection.contentOffset.y + kbEndHeight
            if newYOffset < verticalOffsetForTop || newYOffset > verticalOffsetForBottom {
                newYOffset = max(verticalOffsetForTop, verticalOffsetForBottom)
            }
            
            self.cvChatMessagesCollection.contentOffset = CGPointMake(0, newYOffset)
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let state = UIApplication.sharedApplication().applicationState
        guard state == UIApplicationState.Active else {
            return
        }
        
        if let userInfo = notification.userInfo {
            if !contextMenuPresented {
                adjustCollectionInsetsAndOffset(userInfo)
            }
            configureConstantViewNewMessages(notification)
            
        }
    }
    
    
    // MARK: - GHContextMenu  Methods
    
    func shouldShowMenuAtPoint(point: CGPoint) -> Bool {
        
        guard let indexPath = self.cvChatMessagesCollection.indexPathForItemAtPoint(point) else {
            return false
        }
        let shouldShow = !showingDefaultCell && !showingFirstChatInAppCell && !presenter.isLoggedUser(indexPath) && !showingFirstChatInAppCell && !presenter.isBlockingMe(indexPath)
        
        if shouldShow {
            self.contextMenuPresented = true
            self.dismissKeyboard(UITapGestureRecognizer())
            self.resignFirstResponder()
        }
        
        return shouldShow
    }
    
    func numberOfMenuItems() -> Int {
        return self.presenter.contextMenuNumberOfItems()
    }
    
    func imageForItemAtIndex(index: Int) -> UIImage! {
        return self.presenter.contextMenuImageForItem(index)
    }
    
    func highLightedImageForItemAtIndex(index: Int) -> UIImage! {
        return self.presenter.contextMenuHighlightedImage(index)
    }
    
    func highLightedTitleForItemAtIndex(index: Int) -> String! {
        return self.presenter.contextMenuHighlightedImageTitleForItem(index)
    }
    
    func didSelectItemAtIndex(selectedIndex: Int, forMenuAtPoint point: CGPoint) {
        
        self.becomeFirstResponder()
        
        guard let indexPath = self.cvChatMessagesCollection.indexPathForItemAtPoint(point),  user = presenter.whoSentMessageAtIndex(indexPath) else {
            return
        }
        
        switch selectedIndex {
            
        case ContextMenuItemSelected.More.rawValue:
            
            showReportOrBlockActionShet(user)
            
            break
            
        case ContextMenuItemSelected.Profile.rawValue:
            
            self.performSegueWithIdentifier(kShowUserProfile, sender: user)
            
            break
            
        default:
            
            self.performSegueWithIdentifier(kShowUserProfile, sender: user)
            
            break
        }
    }
    
    func getSnapViewInCollection(point: CGPoint) -> UIView! {
        
        guard let indexPath = self.cvChatMessagesCollection.indexPathForItemAtPoint(point), collectionCell = self.cvChatMessagesCollection.cellForItemAtIndexPath(indexPath) as? ChatRoomCell else {
            return UIView()
        }
        
        collectionCell.animateHighlightCell()
        let viewForSnap = collectionCell.snapshotViewAfterScreenUpdates(true)
        viewForSnap.frame = self.view.convertRect(collectionCell.frame, fromView: cvChatMessagesCollection)
        
        
        (self.inputAccessoryView as! ChatRoomInputAccessoryView).showGHContextMenuAboveAccessoryView(self.vBackgroundGHMenuContextAboveAccessoryView)
        self.vBackgroundGHMenuContextAboveAccessoryView.alpha = 0
        
        UIView.animateWithDuration(0.2) {
            self.vBackgroundGHMenuContextAboveAccessoryView.alpha = 1
        }
        
        return viewForSnap
        
    }
    
    func contextMenuWillHideforMenuAtPoint(point: CGPoint) {
        
        guard let indexPath = self.cvChatMessagesCollection.indexPathForItemAtPoint(point), collectionCell = self.cvChatMessagesCollection.cellForItemAtIndexPath(indexPath) as? ChatRoomCell else {
            return
        }
        
        self.contextMenuPresented = false
        collectionCell.animateUnhighlightCell()
        UIView.animateWithDuration(0.2, animations: {
            self.vBackgroundGHMenuContextAboveAccessoryView.alpha = 0
        }) { (_) in
            self.vBackgroundGHMenuContextAboveAccessoryView.removeFromSuperview()
            
            let shouldShow = !self.showingDefaultCell && !self.showingFirstChatInAppCell && !self.presenter.isLoggedUser(indexPath) && !self.showingFirstChatInAppCell && !self.presenter.isBlockingMe(indexPath)
            
            if shouldShow {
                self.becomeFirstResponder()
            }
        }
    }
    
    // MARK Share ChatRoom
    func shareChatRoom() {
        
        guard let shareChatRoomCard = self.presenter.chatRoomShareCard() else {
            return
        }
        
        let shareItems: Array = [shareChatRoomCard]
        let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypePostToWeibo, UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList, UIActivityTypePostToVimeo]
        self.presentViewController(activityViewController, animated: true, completion: nil)
        
    }
    
    // MARK: Action Sheet
    
    func showMoreOptionsActionShet() {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let leaveChatAction = UIAlertAction(title: NSLocalizedString("Leave Chat", comment: ""), style: .Default, handler: { (action) -> Void in
            self.showRemoveChatRoomOfInterestDialog()
        })
        
        let enterChatAction = UIAlertAction(title: NSLocalizedString("Save Chat", comment: ""), style: .Default, handler: { (action) -> Void in
            self.presenter.saveChatRoom()
        })
        
        let shareChatAction = UIAlertAction(title: NSLocalizedString("LongPressMenuShare", comment: ""), style: .Default, handler: { (action) -> Void in
            self.shareChatRoom()
        })
        
        let reportChatAction = UIAlertAction(title: NSLocalizedString("Report", comment: ""), style: .Default, handler: { (action) -> Void in
            self.showReportChatDialog()
        })
        
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            //print("Cancel Button Pressed")
        })
        
        
        if presenter.isSavedChatRoom() {
            alertController.addAction(leaveChatAction)
        } else {
            alertController.addAction(enterChatAction)
        }
        
        alertController.addAction(shareChatAction)
        alertController.addAction(reportChatAction)
        alertController.addAction(cancel)
        
        if #available(iOS 9.0, *) {
            leaveChatAction.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
            reportChatAction.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
        }
        
        self.presentViewController(alertController, animated: true, completion: nil)
        alertController.view.tintColor = UIColor.blicupPink()
        
        if let subView = alertController.view.subviews.first {
            if let contentView = subView.subviews.first {
                contentView.backgroundColor = UIColor.whiteColor()
            }
        }
    }
    
    
    func showReportOrBlockActionShet(user: User) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let reportAction = UIAlertAction(title: NSLocalizedString("Report", comment: ""), style: .Default, handler: { (action) -> Void in
            
            self.showReportUserDialog(user)
        })
        
        if #available(iOS 9.0, *) {
            reportAction.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
        }
        alertController.addAction(reportAction)
        
        if presenter.isLoggedUserChatOwner() {
            
            let removeAndBlockAction = UIAlertAction(title: NSLocalizedString("RemoveAndBlockDialogTitle", comment: "Remove and Block"), style: .Default, handler: { (action) -> Void in
                self.showRemoveAndBlockUserDialog(user)
            })
            if #available(iOS 9.0, *) {
                removeAndBlockAction.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
            }
            alertController.addAction(removeAndBlockAction)
            
        } else if let title = presenter.blockBtnTitle(user) {
            
            let blockAction = UIAlertAction(title: title, style: .Default, handler: { (action) -> Void in
                if !self.presenter.isCurrentUserBlocked(user) {
                    self.showBlockDialog(user)
                }
                else {
                    self.presenter.blockUnblockUser(user, completionHandler: { (success) in
                        self.cvChatMessagesCollection.reloadData()
                    })
                }
            })
            if #available(iOS 9.0, *) {
                blockAction.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
            }
            alertController.addAction(blockAction)
        }
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            //print("Cancel Button Pressed")
        })
        
        alertController.addAction(cancel)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        alertController.view.tintColor = UIColor.blicupPink()
        
        if let subView = alertController.view.subviews.first {
            if let contentView = subView.subviews.first {
                contentView.backgroundColor = UIColor.whiteColor()
            }
        }
    }
    
    private func showRemoveAndBlockUserDialog(user: User) {
        
        let removeAndBlockAction = UIAlertAction(title: NSLocalizedString("Block", comment: "Block"), style: .Default) { (action) in
            
            self.presenter.removeAndBlockUser(user, completionHandler: { (success) in
                
                if success {
                    self.reloadVisibleCells()
                } else {
                    // TODO: tratar caso de falha no report
                }
            })
        }
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            //print("Cancel Button Pressed")
        })
        
        showAlert(title: presenter.removeAndBlockUserDialogTitle(), message: presenter.removeAndBlockUserDialogMessage(user), withActions: [removeAndBlockAction, cancel], style: UIAlertControllerStyle.Alert)
        
    }
    
    private func showReportUserDialog(user: User) {
        
        let reportAction = UIAlertAction(title: NSLocalizedString("Report", comment: "Report"), style: .Default) { (action) in
            
            self.presenter.reportUser(user, completionHandler: { (success) in
                
                if success {
                    self.showThanksForReportingDialog()
                } else {
                    // TODO: tratar caso de falha no report
                }
            })
        }
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            //print("Cancel Button Pressed")
        })
        
        showAlert(title: presenter.reportUserDialogTitle(), message: presenter.reportUserDialogMessage(user), withActions: [reportAction, cancel], style: UIAlertControllerStyle.Alert)
        
    }
    
    private func showRemoveChatRoomOfInterestDialog() {
        
        let leaveAction = UIAlertAction(title: NSLocalizedString("Leave", comment: "Leave"), style: .Default) { (action) in
            
            self.presenter.removeChatRoomOfInterest({ (success) in
                if success {
                    
                } else {
                    // TODO: tratar caso de falha no leave chat
                }
            })
        }
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            //print("Cancel Button Pressed")
        })
        
        showAlert(title: presenter.removeChatRoomOfInterestDialogTitle(), message: presenter.removeChatRoomOfInterestDialogMessage(), withActions: [leaveAction, cancel], style: UIAlertControllerStyle.Alert)
        
    }
    
    private func showReportChatDialog() {
        
        let reportAction = UIAlertAction(title: NSLocalizedString("Report", comment: "Report"), style: .Default) { (action) in
            
            self.presenter.reportChatRoom({ (success) in
                if success {
                    self.showThanksForReportingDialog()
                } else {
                    // TODO: tratar caso de falha no report
                }
            })
        }
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            //print("Cancel Button Pressed")
        })
        
        showAlert(title: presenter.reportChatDialogTitle(), message: presenter.reportChatDialogMessage(), withActions: [reportAction, cancel], style: UIAlertControllerStyle.Alert)
    }
    
    
    private func showThanksForReportingDialog() {
        
        showAlert(title: presenter.thanksForReportingDialogTitle(), message: presenter.thanksForReportingDialogMessage())
    }
    
    private func showBlockDialog(user: User) {
        
        var alertActions = [UIAlertAction]()
        
        if let title = presenter.blockBtnTitle(user) {
            let blockAction = UIAlertAction(title: title, style: .Default, handler: { (action) -> Void in
                
                self.presenter.blockUnblockUser(user, completionHandler: { (success) in
                    self.cvChatMessagesCollection.reloadData()
                })
            })
            
            alertActions.append(blockAction)
        }
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            //print("Cancel Button Pressed")
        })
        
        alertActions.append(cancel)
        
        showAlert(title: presenter.blockDialogTitle(user), message: presenter.blockDialogMessage(user), withActions: alertActions, style: UIAlertControllerStyle.Alert)
    }
    
    
    func keyboardWillHide(notification: NSNotification) {
        let state = UIApplication.sharedApplication().applicationState
        guard state == UIApplicationState.Active else {
            return
        }
        
        if !contextMenuPresented {
            adjustCollectionInsetsAndOffsetKeyboardHide(notification.userInfo)
        }
        
        configureConstantViewNewMessages(notification)
        
    }
    
    
    //Mark: Configure Keyboard Transition
    private func configureConstantViewNewMessages(notification: NSNotification){
        
        if let userInfo = notification.userInfo {
            let animationDuration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let keyboardEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            let convertedKeyboardEndFrame = view.convertRect(keyboardEndFrame, fromView: view.window)
            let rawAnimationCurve = (notification.userInfo![UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedIntValue << 16
            let animationCurve = UIViewAnimationOptions(rawValue: UInt(rawAnimationCurve))
            
            self.kNewMessages.constant = CGRectGetMaxY(view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame) + 10
            
            UIView.animateWithDuration(animationDuration, delay: 0.0, options: [.BeginFromCurrentState, animationCurve], animations: {
                self.view.layoutIfNeeded()
                }, completion: nil)
        }
    }
    
    private func adjustCollectionInsetsAndOffsetKeyboardHide(kbUserInfo: [NSObject : AnyObject]?){
        if let keyboardUserInfo = kbUserInfo {
            let animationDuration = (keyboardUserInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let keyboardEndFrame = (keyboardUserInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            let convertedKeyboardEndFrame = view.convertRect(keyboardEndFrame, fromView: view.window)
            let rawAnimationCurve = (keyboardUserInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).unsignedIntValue << 16
            let animationCurve = UIViewAnimationOptions(rawValue: UInt(rawAnimationCurve))
            var contentInsets = cvChatMessagesCollection.contentInset
            contentInsets.bottom = CGRectGetMaxY(view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame) + 10
            
            self.cvChatMessagesCollection.contentInset = contentInsets
            self.cvChatMessagesCollection.scrollIndicatorInsets = contentInsets
            
            var newYOffset = cvChatMessagesCollection.contentOffset.y + (keyboardUserInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size.height)!
            if newYOffset < verticalOffsetForTop || newYOffset > verticalOffsetForBottom {
                newYOffset = max(verticalOffsetForTop, verticalOffsetForBottom)
            }
            
            UIView.animateWithDuration(animationDuration, delay: 0.0, options: [.BeginFromCurrentState, animationCurve], animations: {
                self.cvChatMessagesCollection.contentOffset = CGPointMake(0, newYOffset)
                }, completion: nil)
        }
    }
    
    // MARK : UserProfileViewControllerDelegate
    func presentUserProfileCardFromSelectedUser(user: User) {
        self.performSegueWithIdentifier(kShowUserProfile, sender: user)
    }
    
    //MARK: Generate Random Message Greetings
    private func generateMessageGreetings() -> String{
        switch (0 ... 7).randomInt {
        case 0:
            return NSLocalizedString("Message_Greetings", comment: "")
        case 1:
            return NSLocalizedString("Message_Greetings_1", comment: "")
        case 2:
            return NSLocalizedString("Message_Greetings_2", comment: "")
        case 3:
            return NSLocalizedString("Message_Greetings_3", comment: "")
        case 4:
            return NSLocalizedString("Message_Greetings_4", comment: "")
        case 5:
            return NSLocalizedString("Message_Greetings_5", comment: "")
        case 6:
            return NSLocalizedString("Message_Greetings_6", comment: "")
        default:
            return NSLocalizedString("Message_Greetings_7", comment: "")
        }
    }
    
    //MARK: ShareView Protocol
    
    func setShareChatView() {
        self.resignFirstResponder()
        
        self.vShareChatContent = ShareChatView(frame: CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: 89.0))
        self.vShareChatContent?.delegate = self
        
        self.vShareChatContent?.lblShare.text = NSLocalizedString("ShareChat_ChatRoom", comment: "Share Later")
        self.vShareChatContent?.btnShare.setTitle(NSLocalizedString("LongPressMenuShare", comment: "Share"), forState: .Normal)
        self.vShareChatContent?.btnLater.setTitle(NSLocalizedString("ShareLater", comment: "Share Later"), forState: .Normal)
        
        self.view.addSubview(vShareChatContent!)
        
        UIView.animateWithDuration(0.5, delay: 0.0, options: [], animations: {
            self.vShareChatContent!.transform = CGAffineTransformMakeTranslation(0, -89)
            }, completion: { (_) in })
    }
    
    func sharePressed(sender: UIButton) {
        UIView.animateWithDuration(0.3, delay: 0.0, options: [], animations: {
            self.vShareChatContent!.transform = CGAffineTransformMakeTranslation(0, 89)
        }) { (_) in
            self.vShareChatContent!.removeFromSuperview()
            self.vShareChatContent = nil
            self.shareChatRoom()
            self.becomeFirstResponder()
        }
    }
    
    func laterSharePressed(sender: UIButton) {
        UIView.animateWithDuration(0.3, delay: 0.0, options: [], animations: {
            self.vShareChatContent!.transform = CGAffineTransformMakeTranslation(0, 89)
        }) { (_) in
            self.vShareChatContent!.removeFromSuperview()
            self.vShareChatContent = nil
            self.becomeFirstResponder()
        }
    }
    
    // MARK: - Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let inputView = self.inputAccessoryView as? ChatRoomInputAccessoryView {
            inputView.endMessageEditing()
        }
        self.resignFirstResponder()
        
        if let vDestination = segue.destinationViewController as? ChatRoomTalkInfoViewController{
            vDestination.chatRoomID = presenter.chatRoomID()!
            vDestination.transitioningDelegate = vDestination
            vDestination.modalPresentationStyle = .Custom
            
        } else  if segue.identifier == kShowUserProfile, let vcUserProfile = segue.destinationViewController as? UserProfileViewController {
            
            if let user = sender as? User {
                let presenter = UserProfileCardPresenter(user: user)
                vcUserProfile.presenter = presenter
                vcUserProfile.transitioningDelegate = vcUserProfile
                vcUserProfile.modalPresentationStyle = .Custom
                vcUserProfile.delegate = self
            }
        }
    }
    
    @IBAction func unwindFromSecondary(segue: UIStoryboardSegue) {
        if (segue.identifier == "unwindFromSecondary")
        {
            
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard inputAccessoryView != nil else {
            return
        }
        
        let offsetY = max(verticalOffsetForTop, verticalOffsetForBottom)
        
        if !isScrollingToBottom{
            if scrollView.contentOffset.y + 1000 < (offsetY) && self.cvChatMessagesCollection.contentSize.height > (self.cvChatMessagesCollection.frame.height - (self.inputAccessoryView?.frame.height)!){
                self.vNewMessages.hidden = false
            }
        }
        
        
        if scrollView.contentOffset.y + 5 >= offsetY{
            UIView.animateWithDuration(0.1, animations: {
                self.vNewMessages.hidden = true
                self.vNewMessages.layer.borderWidth = 0
                self.vNewMessages.layer.borderColor = UIColor.clearColor().CGColor
            })
            self.isScrollingToBottom = false
        }
        
        
    }
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        //reduce msg amount seen
        checkMessageLimit(scrollView)
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        checkLoadMore(scrollView)
        
        checkMessageLimit(scrollView)
        
    }
    
    
    func checkLoadMore(scrollView: UIScrollView)
    {
        if scrollView.contentOffset.y < 0 {
            
            var indexPath: NSIndexPath?
            if let firstVisibleCell  = self.cvChatMessagesCollection.visibleCells().first {
                indexPath = self.cvChatMessagesCollection.indexPathForCell(firstVisibleCell)!
            }
            let howManyLoaded = presenter.loadMoreMessages()
            
            self.cvChatMessagesCollection.reloadData()
            if indexPath != nil  && howManyLoaded > 0 {
                
                let newIndex = NSIndexPath(forItem:  indexPath!.row + howManyLoaded, inSection: indexPath!.section)
                self.cvChatMessagesCollection.scrollToItemAtIndexPath(newIndex, atScrollPosition: UICollectionViewScrollPosition.Top, animated: false)
                
            }
        }
        
    }
    
    
    func checkMessageLimit(scrollView: UIScrollView) -> Void {
        if (scrollView.contentOffset.y  + self.cvChatMessagesCollection.frame.height ) > self.cvChatMessagesCollection.contentSize.height
        {
            if presenter.loadLessMessages() {
                hasReloadedChatroom = true
                self.cvChatMessagesCollection.reloadData()
                
                //guarantee that after reload complete the variable will be false
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    self.hasReloadedChatroom = false
                }
                
            }
        }
    }
}
