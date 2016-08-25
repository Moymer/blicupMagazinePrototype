 //
 //  ChatRoomInputAccessoryView.swift
 //  Blicup
 //
 //  Created by Moymer on 20/05/16.
 //  Copyright © 2016 Moymer. All rights reserved.
 //
 
 import UIKit
 import ReachabilitySwift
 
 protocol ChatRoomAccessoryViewDelegate: class {
    func sendMessage(message:String)
    func sendGiphy(gifUrl:NSURL, gifSize:CGSize)
    func showMoreOptionsActionShet()
 }
 
 class ChatRoomInputAccessoryView: UIView, UITextViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, TipsViewProtocol {
    weak var delegate:ChatRoomAccessoryViewDelegate?
    
    private let ORIGINAL_PHOTO_WIDTH:CGFloat = 57
    private let MAX_NUM_CHARS = 140
    
    @IBOutlet weak var ivUserPhoto: UIImageView!
    @IBOutlet weak var tvMessage: UITextView!
    @IBOutlet weak private var constrPhotoWidth: NSLayoutConstraint!
    @IBOutlet weak private var vInputContainer: UIView!
    @IBOutlet weak private var lblPlaceholder: UILabel!
    @IBOutlet weak var btnCloseOptions: UIButton!
    @IBOutlet weak var btnMoreOptions: UIButton!
    @IBOutlet weak var vGifAndUserContainer: UIView!
    @IBOutlet weak var vLine: UIView!
    
    
    // MARK: Variáveis Search GIF
    private var showingContainerSearch = false
    private let chatRoomGiphySearchPresenter = ChatRoomGiphySearchPresenter()
    private var showBlicupWhiteActivityIndicatorTimer: NSTimer?
    private let kWebImageSearchCollectionCell = "webImageSearchCollectionCell"
    private let kCvcContainerGIFHeight: CGFloat = 110
    
    @IBOutlet weak var ivLoadingBlicup: UIImageView!
    @IBOutlet weak var lblCollectionInfo: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var constrCvcContainerHeight: NSLayoutConstraint!
    
    // MARK: Powered By Giphy
    @IBOutlet weak var ivPoweredByGiphy: UIImageView!
    @IBOutlet weak var constrivPoweredByGiphyHeight: NSLayoutConstraint!
    private let kIVPoweredByGiphyDefaultHeight: CGFloat = 11
    
    // MARK: Variáveis Menção
    private let userSearchPresenter = UserSearchPresenter()
    private let kChatRoomUserMentionCollectionCell = "chatRoomUserMentionCollectionCell"
    private let kUserItemHeight: CGFloat = 45
    private var isUserMentionListFlowLayoutUsed = false
    private let kCvcContainerUserMentionHeight: CGFloat = 145
    
    private var lastCursorTVMessageRange: NSRange?
    
    @IBOutlet weak var vContainerTips: TipsView!
    @IBOutlet weak var constrHeightViewTips: NSLayoutConstraint!
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if self.tvMessage.text.isEmpty {
            vContainerTips.delegate = self
            vInputContainer.layer.cornerRadius = 6
            self.constrHeightViewTips.constant = 0
            self.tvMessage.backgroundColor = UIColor.blicupDisabledTextFieldBackgroundColor()
            self.lblPlaceholder.text = NSLocalizedString("Message_Placeholder", comment: "Say something...")
            self.constrPhotoWidth.constant = 0
            self.constrCvcContainerHeight.constant = 0
            self.lblCollectionInfo.hidden = true
            self.loadBlicupWhiteImages()
            self.setupInitialCollectionViewLayout()
        }
    }
    
    func endMessageEditing() {
        self.tvMessage.resignFirstResponder()
    }
    
    // MARK: Actions
    
    @IBAction func closePressed(sender: UIButton) {
        endMessageEditing()
    }
    
    @IBAction func optionsPressed(sender: UIButton) {
        delegate?.showMoreOptionsActionShet()
    }
    
    
    //MARK: Tips
    
    func shouldShowTip() {
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        let tipGIFObject = userDefaults.objectForKey(kGIFTipKey) as? [String : AnyObject]
        let countGIFTip = tipGIFObject!["count"] as? NSNumber
        let boolGIFTip = tipGIFObject!["hasPerformedTip"] as? Bool
        
        let tipMentionObject = userDefaults.objectForKey(kMentionTipKey) as? [String : AnyObject]
        let countMentionTip = tipMentionObject!["count"] as? NSNumber
        let boolMentionTip = tipMentionObject!["hasPerformedTip"] as? Bool
        
        if countGIFTip?.integerValue > 1 && !boolGIFTip! {
            self.vContainerTips.lblTips.text =  NSLocalizedString("GIF_Tip", comment: "")
            self.vContainerTips.typeOfTip = TipType.GIFMessage
            self.constrHeightViewTips.constant = 60
        } else if countGIFTip?.integerValue > 1 && boolGIFTip! {
            if (countMentionTip?.integerValue)! > 2 && !boolMentionTip! {
                self.vContainerTips.lblTips.text = NSLocalizedString("Mention_Tip", comment: "")
                self.vContainerTips.typeOfTip = TipType.MentionMessage
                self.constrHeightViewTips.constant = 60
            }
        }
    }
    
    // MARK: TextViewDelegate
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            if textView.text.length > 0 {
                if showingContainerSearch { showOrUpdateContainerSearch(false) }
                delegate?.sendMessage(textView.text)
            }
            
            textView.text = nil
            lblPlaceholder.hidden = false
            return false
        }
        
        
        let finalString = (textView.text as NSString).stringByReplacingCharactersInRange(range, withString: text)
        
        // Menção de usuário em qualquer lugar do texto
        let result = finalString.findMentionNearPosition(range.location)
        let mention = result.mention
        if mention != "" && result.location >= 0 && text != " " {
            
            searchUsersWithSearchTerm(mention)
            
        } else if finalString.findArrobaNearPosition(range.location).find {
            
            showUserFolloweeList()
            
        } else if finalString == "/" {
            if self.vContainerTips.typeOfTip == TipType.GIFMessage {
                self.vContainerTips.performedTaskTip()
            }
            setupGIFHorizontalListCollectionFlowLayout()
            showOrUpdateContainerSearch(true)
            searchGiphyImagesWithQuery("", trending: true)
            
        } else if (finalString == "" && textView.text.hasPrefix("/")) || (!finalString.containsString("@") && isUserMentionListFlowLayoutUsed) || (isUserMentionListFlowLayoutUsed && text == " ") {
            
            showOrUpdateContainerSearch(false)
            self.userSearchPresenter.clearSearchTerm()
            
        }
        
        if finalString.length <= MAX_NUM_CHARS {
            lastCursorTVMessageRange = range
            return true
        }
        else {
            textView.text = finalString.substringToIndex(finalString.startIndex.advancedBy(MAX_NUM_CHARS))
            return false
        }
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(self.bounds.width, 200)
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        
        self.btnCloseOptions.hidden = false
        
        if textView.text.isEmpty {
            shouldShowTip()
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            UIView.animateWithDuration(0.2 , animations: {
                self.tvMessage.backgroundColor = UIColor.whiteColor()
                self.constrPhotoWidth.constant = self.ORIGINAL_PHOTO_WIDTH
                self.btnCloseOptions.alpha = 1
                self.btnMoreOptions.alpha = 0
                self.vLine.alpha = 0
                self.layoutIfNeeded()
            }) { (finished) in
                if finished {
                    self.btnMoreOptions.hidden = true
                }
            }
        })
        
        if self.tvMessage.text.hasPrefix("/") && !isUserMentionListFlowLayoutUsed && self.tvMessage.isFirstResponder() {
            showOrUpdateContainerSearch(true)
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        
        self.btnMoreOptions.hidden = false
        textView.text = textView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        UIView.animateWithDuration(0.2, animations: {
            if textView.text.length == 0 {
                self.tvMessage.backgroundColor = UIColor.blicupDisabledTextFieldBackgroundColor()
                self.constrPhotoWidth.constant = 0
                self.vLine.alpha = 1
            }
            self.btnCloseOptions.alpha = 0
            self.btnMoreOptions.alpha = 1
            self.layoutIfNeeded()
            
        }) { (finished) in
            if finished {
                self.btnCloseOptions.hidden = true
            }
        }
        
        if showingContainerSearch {
            showOrUpdateContainerSearch(false)
        }
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        
        // Quando usuário está com uma menção aberta e mexe o cursor até sair do range de menção, o container é escondido
        if showingContainerSearch && isUserMentionListFlowLayoutUsed {
            if let selectedRange = textView.selectedTextRange {
                
                let index = textView.offsetFromPosition(textView.beginningOfDocument, toPosition: selectedRange.start)
                
                let result = textView.text.findMentionNearPosition(index)
                let mention = result.mention
                if mention == "" {
                    showOrUpdateContainerSearch(false)
                    userSearchPresenter.clearSearchTerm()
                }
            }
        }
        
    }
    
    func textViewDidChange(textView: UITextView) {
        lblPlaceholder.hidden = textView.text.length > 0
        
        if showingContainerSearch {
            
            if !self.isUserMentionListFlowLayoutUsed && textView.text != "/" && textView.text != "" {
                searchGiphyImagesWithQuery(textView.text, trending: false)
            }
        }
    }
    
    
    func setUserImage(imageUrl:NSURL) {
        ivUserPhoto.kf_setImageWithURL(imageUrl)
    }
    
    func showOrUpdateContainerSearch(show: Bool) {
        
        let poweredByGiphyHeight: CGFloat = isUserMentionListFlowLayoutUsed ? 0 : kIVPoweredByGiphyDefaultHeight
        let height = isUserMentionListFlowLayoutUsed ? heightForUserMentionContainerSearch() : kCvcContainerGIFHeight
        let containerHeight =  show ? height + poweredByGiphyHeight : 0
        
        if constrCvcContainerHeight.constant != containerHeight {
            
            self.collectionView.collectionViewLayout.invalidateLayout()
            constrCvcContainerHeight.constant = containerHeight
            constrivPoweredByGiphyHeight.constant = poweredByGiphyHeight
            showingContainerSearch = show
            self.vGifAndUserContainer.alpha = show ? 1 : 0
            ivPoweredByGiphy.alpha = isUserMentionListFlowLayoutUsed ? 0 : 1
            UIView.animateWithDuration(0.2, animations: {
                self.vGifAndUserContainer.layoutIfNeeded()
            })
        }
    }
    
    func heightForUserMentionContainerSearch() -> CGFloat {
        
        let padding: CGFloat = 10
        switch userSearchPresenter.userCount() {
        case 1:
            return kUserItemHeight + padding
        case 2:
            return 2*kUserItemHeight + padding
        default:
            return kCvcContainerUserMentionHeight
        }
    }
    
    func searchGiphyImagesWithQuery(query: String, trending: Bool) {
        
        showlblNoGifs(false)
        self.chatRoomGiphySearchPresenter.removeAllItems()
        self.collectionView.reloadData()
        
        if let reachability = try? Reachability.reachabilityForInternetConnection() {
            if reachability.isReachable() {
                
                invalidateShowBlicupWhiteTimer()
                showBlicupWhiteActivityIndicatorTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(ChatRoomInputAccessoryView.startBlicupActivityIndicator), userInfo: nil, repeats: false)
                
                chatRoomGiphySearchPresenter.searchImagesWithQuery(query, trending: trending, completionHandler: { (success) in
                    
                    self.stopBlicupActivityIndicator()
                    
                    if success {
                        
                        self.collectionView.reloadData()
                        
                        if self.chatRoomGiphySearchPresenter.numberOfItems() == 0 {
                            self.showlblNoGifs(true)
                        }
                    } else {
                        // TODO: Mostrar sem internet
                        self.showlblNoInternet(true)
                    }
                })
            }
        } else {
            showlblNoInternet(true)
        }
    }
    
    
    func showlblNoGifs(show: Bool) {
        
        lblCollectionInfo.text = NSLocalizedString("No GIFs to show", comment: "No GIFs to show")
        lblCollectionInfo.hidden = !show
    }
    
    func showlblNoInternet(show: Bool) {
        
        invalidateShowBlicupWhiteTimer()
        
        lblCollectionInfo.text = NSLocalizedString("No Internet", comment: "No Internet")
        lblCollectionInfo.hidden = !show
    }
    
    // MARK: SearchUsers
    
    func searchUsersWithSearchTerm(searchTerm: String) {
        
        showlblNoGifs(false)
        if searchTerm != userSearchPresenter.searchTerm {
            
            removeAllBeforeSearchUser()
            
            let searchTermTimestamp = NSDate().timeIntervalSince1970
            
            userSearchPresenter.searchUsersWithSearchTerm(searchTerm, timestamp: searchTermTimestamp, completionHandler: { (success) in
                
                if success {
                    
                    if self.userSearchPresenter.userCount() > 0 && !self.tvMessage.text.isEmpty {
                        
                        self.showOrUpdateContainerSearch(true)
                        self.collectionView.reloadData()
                        
                    } else {
                        self.showOrUpdateContainerSearch(false)
                        self.userSearchPresenter.clearSearchTerm()
                    }
                }
            })
        }
    }
    
    func showUserFolloweeList() {
        
        showlblNoGifs(false)
        removeAllBeforeSearchUser()
        
        let getFolloweeTimestamp = NSDate().timeIntervalSince1970
        
        userSearchPresenter.getUserFolloweeList(getFolloweeTimestamp) { (success) in
            
            if success {
                
                if self.userSearchPresenter.userCount() > 0 && !self.tvMessage.text.isEmpty {
                    
                    self.showOrUpdateContainerSearch(true)
                    self.collectionView.reloadData()
                    
                } else {
                    self.showOrUpdateContainerSearch(false)
                    self.userSearchPresenter.clearSearchTerm()
                }
            }
        }
    }
    
    func removeAllBeforeSearchUser() {
        
        if !self.isUserMentionListFlowLayoutUsed {
            self.setupUserVerticalListCollectionFlowLayout()
        } else {
            self.userSearchPresenter.removeAllItems()
            self.collectionView.reloadData()
        }
    }
    
    // Blicup Loading
    
    func loadBlicupWhiteImages() {
        
        var animationArray: [UIImage] = []
        
        for index in 0...29 {
            animationArray.append(UIImage(named: "BlicMini_\(index)")!)
        }
        
        ivLoadingBlicup.animationImages = animationArray
        ivLoadingBlicup.animationDuration = 1.0
        ivLoadingBlicup.alpha = 0
    }
    
    func invalidateShowBlicupWhiteTimer() {
        
        if showBlicupWhiteActivityIndicatorTimer != nil {
            showBlicupWhiteActivityIndicatorTimer?.invalidate()
            showBlicupWhiteActivityIndicatorTimer = nil
        }
    }
    
    
    func startBlicupActivityIndicator() {
        
        UIView.animateWithDuration(0.3) { () -> Void in
            self.ivLoadingBlicup.alpha = 1
        }
        
        ivLoadingBlicup.startAnimating()
    }
    
    func stopBlicupActivityIndicator() {
        
        invalidateShowBlicupWhiteTimer()
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            
            self.ivLoadingBlicup.alpha = 0
            
            }, completion: { (finished) -> Void in
                
                self.ivLoadingBlicup.stopAnimating()
                
        })
    }
    
    // MARK: CollectionViewDelegate
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if isUserMentionListFlowLayoutUsed {
            return self.userSearchPresenter.userCount()
        } else {
            return self.chatRoomGiphySearchPresenter.numberOfItems()
        }
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if isUserMentionListFlowLayoutUsed {
            
            let userCell = collectionView.dequeueReusableCellWithReuseIdentifier(kChatRoomUserMentionCollectionCell, forIndexPath: indexPath) as! ChatRoomUserMentionCollectionViewCell
            
            if let username = userSearchPresenter.usernameAtIndex(indexPath) {
                userCell.lblUsername.text = username
            }
            
            if let userPhotoUrl = userSearchPresenter.photoUrlAtIndex(indexPath) {
                userCell.ivUserPhoto.kf_setImageWithURL(userPhotoUrl)
            } else {
                userCell.ivUserPhoto.image = nil
            }
            
            return userCell
            
        } else {
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(kWebImageSearchCollectionCell, forIndexPath: indexPath) as! WebImageSearchCollectionViewCell
            
            if let imagetmbUrl = chatRoomGiphySearchPresenter.imageTmbUrlAtIndex(indexPath.row) {
                cell.imageView.kf_setImageWithURL(imagetmbUrl, placeholderImage: nil, optionsInfo: [.Transition(.Fade(1))])
            } else {
                cell.imageView.image = nil
            }
            
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if isUserMentionListFlowLayoutUsed {
            
            if let index = self.lastCursorTVMessageRange?.location {
                let result = self.tvMessage.text.findMentionNearPosition(index)
                let mention = result.mention
                var location = result.location
                
                let resultArroba = self.tvMessage.text.findArrobaNearPosition(index)
                let findArroba = resultArroba.find
                if location < 0 && findArroba {
                    location = resultArroba.location + 1
                }
                
                // Usa username sem @ para evitar repeticao.
                var username = userSearchPresenter.usernameAtIndex(indexPath)
                username = username?.substringFromIndex(username!.startIndex.successor())
                
                //print("location = \(location) menção = \(mention) username = \(username)")
                if location >= 0 {
                    
                    let text = self.tvMessage.text
                    
                    let mentionText = text as NSString
                    let finalText =  mentionText.stringByReplacingCharactersInRange(NSMakeRange(location,  mention.length), withString: username!)
                    
                    // text.replaceRange(text.startIndex.advancedBy(location)..<text.startIndex.advancedBy(location + mention.length), with: username!)
                    if text.length <= MAX_NUM_CHARS {
                        tvMessage.text = finalText
                    }
                }
                
                showOrUpdateContainerSearch(false)
                self.userSearchPresenter.clearSearchTerm()
            }
            
        } else {
            
            let url = chatRoomGiphySearchPresenter.imageUrlAtIndex(indexPath.row)
            let size = chatRoomGiphySearchPresenter.imageSizeAtIndex(indexPath.row)
            delegate?.sendGiphy(url, gifSize: size)
            
            tvMessage.text = nil
            lblPlaceholder.hidden = false
            showOrUpdateContainerSearch(false)
            self.userSearchPresenter.clearSearchTerm()
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        if isUserMentionListFlowLayoutUsed {
            return CGSize(width: collectionView.frame.width, height: kUserItemHeight)
        } else {
            return chatRoomGiphySearchPresenter.imageTmbSizeAtIndex(indexPath.row)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        if !isUserMentionListFlowLayoutUsed {
            if let collectionCell =  cell as? ChatRoomListCollectionViewCell {
                collectionCell.ivBackground.stopAnimating()
                collectionCell.ivBackground.kf_cancelDownloadTask()
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        if !isUserMentionListFlowLayoutUsed {
            if let collectionCell =  cell as? ChatRoomListCollectionViewCell {
                collectionCell.ivBackground.startAnimating()
            }
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if !isUserMentionListFlowLayoutUsed {
            
            let currentOffset = scrollView.contentOffset.x
            let maximumOffset = scrollView.contentSize.width - scrollView.frame.size.width
            
            if (maximumOffset - currentOffset) <= 10 && !chatRoomGiphySearchPresenter.giphyLoading && chatRoomGiphySearchPresenter.numberOfItems() > 0 {
                let numberOfItems = chatRoomGiphySearchPresenter.numberOfItems()
                chatRoomGiphySearchPresenter.loadMoreGiphyImages({ (success) in
                    if success && numberOfItems < self.chatRoomGiphySearchPresenter.numberOfItems() {
                        self.collectionView.reloadData()
                    }
                })
            }
        }
    }
    
    
    // MARK: - CollectionView Layout
    
    private func setupInitialCollectionViewLayout() {
        
        let collectionViewLayout = CollectionViewListFlowLayout()
        collectionViewLayout.minimumInteritemSpacing = 5
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(5, 5, 0, 0)
        collectionViewLayout.invalidateLayout()
        self.collectionView.setCollectionViewLayout(collectionViewLayout, animated: false)
        
    }
    
    private func setupGIFHorizontalListCollectionFlowLayout() {
        
        isUserMentionListFlowLayoutUsed = false
        removeAllItems()
        self.collectionView.reloadData()
        
        if let collectionViewLayout = self.collectionView.collectionViewLayout as? CollectionViewListFlowLayout {
            collectionViewLayout.scrollDirection = .Horizontal
            collectionViewLayout.minimumInteritemSpacing = 5
            collectionViewLayout.sectionInset = UIEdgeInsetsMake(5, 5, 0, 0)
            
            UIView.animateWithDuration(0.2) { () -> Void in
                collectionViewLayout.invalidateLayout()
                self.collectionView.setCollectionViewLayout(collectionViewLayout, animated: false)
            }
        }
    }
    
    private func setupUserVerticalListCollectionFlowLayout() {
        if self.vContainerTips.typeOfTip == TipType.MentionMessage {
            self.vContainerTips.performedTaskTip()
        }
        
        isUserMentionListFlowLayoutUsed = true
        removeAllItems()
        self.collectionView.reloadData()
        
        if let collectionViewLayout = self.collectionView.collectionViewLayout as? CollectionViewListFlowLayout {
            collectionViewLayout.scrollDirection = .Vertical
            collectionViewLayout.minimumInteritemSpacing = 1
            collectionViewLayout.sectionInset = UIEdgeInsetsMake(5, 0, 5, 0)
            
            UIView.animateWithDuration(0.2) { () -> Void in
                collectionViewLayout.invalidateLayout()
                self.collectionView.setCollectionViewLayout(collectionViewLayout, animated: false)
            }
        }
    }
    
    func removeAllItems() {
        self.chatRoomGiphySearchPresenter.removeAllItems()
        self.userSearchPresenter.removeAllItems()
    }
    
    func showGHContextMenuAboveAccessoryView(blackView: UIView) {
        
        let blackView = blackView
        blackView.frame = self.frame
        self.addSubview(blackView)
        self.bringSubviewToFront(blackView)
        
    }
    
    //MARK: Tip Protocol
    func tipViewClosePressed(sender: UIButton) {
        var key = ""
        if self.vContainerTips.typeOfTip == TipType.GIFMessage {
            key = kGIFTipKey
        } else if self.vContainerTips.typeOfTip == TipType.MentionMessage {
            key = kMentionTipKey
        }
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let tipObject = userDefaults.objectForKey(key) as? [String : AnyObject]
        let countPCTip = tipObject!["count"] as? NSNumber
        let updatedObject : [String : AnyObject] = ["count" : (countPCTip?.integerValue)!, "hasPerformedTip" : true]
        
        userDefaults.setObject(updatedObject, forKey: key)
        self.constrHeightViewTips.constant = 0
    }
 }
