//
//  ChatRoomsAndUsersSearchViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 18/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Kingfisher
import ReachabilitySwift

class ChatRoomsAndUsersSearchViewController: UIViewController, UICollectionViewDataSource, CHTCollectionViewDelegateWaterfallLayout, UITextFieldDelegate, ChatRoomFetchResultPresenterDelegate, UserProfileViewControllerDelegate, ChatListToCoverTrasitionProtocol, GHContextOverlayViewDelegate, GHContextOverlayViewDataSource, AlertControllerProtocol {

    enum ContextMenuItemSelected: Int {
        case MORE, SHARE, ENTER_CHAT
    }
    
    private let chatRoomsListPresenter = ChatRoomSearchListPresenter()
    private let userSearchPresenter = UserSearchPresenter()

    private let chatRoomListViewCellID = "chatRoomListViewCellID"
    private let userListViewCellID = "userSearchViewCellID"
    private let kShowUserProfile =  "showUserProfile"

    private var alreadyAnimated = false
    private var isUserListFlowLayoutUsed = false
    
    private var showBlicupWhiteActivityIndicatorTimer: NSTimer?
    
    private let kUserItemHeight: CGFloat = 80

    
    @IBOutlet weak var tfSearch: CustomTextField!
    @IBOutlet weak var vContainerTFSearch: UIView!
    
    @IBOutlet weak var lblNoInternet: UILabel!
    @IBOutlet weak var ivLoadingBlicupGray: UIImageView!
    
    
    @IBOutlet weak var cvcSearchChatRoomsAndUsers: UICollectionView!
    
    @IBOutlet weak var constrTFSearchWidth: NSLayoutConstraint!
    @IBOutlet weak var constrTFSearchCenterX: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lblNoInternet.text = NSLocalizedString("No internet", comment: "No internet")
        
        chatRoomsListPresenter.delegate = self
        setGHContextMenuView()
        customizeTextFieldSearch()
        loadBlicupWhiteImages()
        setupInitialCollectionViewLayout()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UserListFollowBlockViewController.reloadVisibleCells), name: "UserProfileClosed", object: nil)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        BlicupAnalytics.sharedInstance.mark_EnteredScreenSearch()
        
        if alreadyAnimated == false {
            UIView.animateWithDuration(0.5, animations: {
                self.cvcSearchChatRoomsAndUsers.alpha = 1
                self.view.backgroundColor = UIColor.whiteColor()
                
            }) { (finished) in
                self.alreadyAnimated = true
            }

            self.constrTFSearchWidth.constant = self.vContainerTFSearch.frame.width
            self.constrTFSearchCenterX.constant = 0

            UIView.animateWithDuration(0.1, delay: 0.0, options: [.CurveEaseIn], animations: {

                self.view.layoutIfNeeded()

            }, completion: { (finished) in
                let string = screenWidth > 320 ? NSLocalizedString("CRM_ChatRoomsAndUsersTextFieldSearchPlaceholder", comment: "Search for chats or @users") : NSLocalizedString("CRM_ChatRoomsAndUsersTextFieldSearchPlaceholder_smaller_screen", comment: "Chats or @users")
                let str = NSAttributedString(string: string, attributes: [NSForegroundColorAttributeName : UIColor.blicupGray()])
                self.tfSearch.attributedPlaceholder = str

                
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: true)
        self.presentingViewController!.tabBarController?.tabBar.hidden = true
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func reloadVisibleCells() {
        let visibleIndexes = cvcSearchChatRoomsAndUsers.indexPathsForVisibleItems()
        cvcSearchChatRoomsAndUsers.reloadItemsAtIndexPaths(visibleIndexes)
    }

    private func setGHContextMenuView() {
        let contextMenu = GHContextMenuView()
        contextMenu.dataSource = self
        contextMenu.delegate = self
        
        let longPress = UILongPressGestureRecognizer(target: contextMenu, action: #selector(GHContextMenuView.longPressDetected(_:)))
        self.cvcSearchChatRoomsAndUsers.addGestureRecognizer(longPress)
        
    }
    
    func customizeTextFieldSearch() {
        
        let paddingX: CGFloat = 30
        let vPadding = UIView(frame: CGRect(x: 0, y: 0, width: paddingX, height: self.tfSearch.frame.height))
        let ivIconSearchPadding = UIImageView(frame: CGRectMake(10, 0, 16, self.tfSearch.frame.height))
        ivIconSearchPadding.contentMode = .ScaleAspectFit
        ivIconSearchPadding.image = UIImage(named: "ic_search")?.imageWithRenderingMode(.AlwaysOriginal)
        vPadding.addSubview(ivIconSearchPadding)
        tfSearch.paddingPosX = paddingX
        tfSearch.leftView = vPadding
        tfSearch.leftViewMode = UITextFieldViewMode.Always
        vContainerTFSearch.layer.cornerRadius = vContainerTFSearch.frame.height/2
        vContainerTFSearch.clipsToBounds = true
        
        tfSearch.performSelector(#selector(UIResponder.becomeFirstResponder), withObject: nil, afterDelay: 0.5)
        
    }

    func loadBlicupWhiteImages() {
        
        var animationArray: [UIImage] = []
        
        for index in 0...29 {
            animationArray.append(UIImage(named: "BlicMini_\(index)")!)
        }
        
        ivLoadingBlicupGray.animationImages = animationArray
        ivLoadingBlicupGray.animationDuration = 1.0
        ivLoadingBlicupGray.alpha = 0
    }
    
    
    func chatRoomsListChanged(insertedIdexes: [NSIndexPath], deletedIndexes: [NSIndexPath], reloadedIndexes: [NSIndexPath]) {
        if !isUserListFlowLayoutUsed {
            cvcSearchChatRoomsAndUsers.performBatchUpdates({ [weak self] in
                self?.cvcSearchChatRoomsAndUsers.insertItemsAtIndexPaths(insertedIdexes)
                self?.cvcSearchChatRoomsAndUsers.deleteItemsAtIndexPaths(deletedIndexes)
                self?.cvcSearchChatRoomsAndUsers.reloadItemsAtIndexPaths(reloadedIndexes)
                }, completion: nil)
        }
    }
    
    // MARK: - CollectionView
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        if isUserListFlowLayoutUsed {
            return CGSize(width: collectionView.frame.width, height: kUserItemHeight)
        } else {
            let totalLines = getNameAndTagListTotalAndTaglLines(indexPath).0
            let size = self.chatRoomsListPresenter.getChatItemSizeForLines(totalLines)
            
            let imageHeight = size.height*(GRID_WIDTH/size.width)
            return CGSize(width: GRID_WIDTH, height: imageHeight)
        }
        
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isUserListFlowLayoutUsed {
            return self.userSearchPresenter.userCount()
        } else {
            return self.chatRoomsListPresenter.chatRoomsCount()
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
       
        if isUserListFlowLayoutUsed {
            
            let userCell: UserSearchCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(userListViewCellID, forIndexPath: indexPath) as! UserSearchCollectionViewCell
            
            if let userPhotoUrl = userSearchPresenter.photoUrlAtIndex(indexPath) {
                userCell.ivUserPhoto.kf_setImageWithURL(userPhotoUrl)
            }
            
            userCell.lblUsername.text = userSearchPresenter.usernameAtIndex(indexPath)
//            userCell.lblBio.text = "\(userSearchPresenter.(indexPath)) 👍"
            userCell.showVerifiedBadge(userSearchPresenter.isVerifiedUser(indexPath))
            
            return userCell
        
        } else {
            
            let collectionCell: ChatRoomListCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRoomListViewCellID, forIndexPath: indexPath) as! ChatRoomListCollectionViewCell
            
            collectionCell.layer.shouldRasterize = true
            collectionCell.layer.rasterizationScale = UIScreen.mainScreen().scale
            
            collectionCell.lblParticipantsCount.text = "\(self.chatRoomsListPresenter.chatRoomNumberOfParticipants(indexPath))"
            collectionCell.bcTimer.updateBasedOnTime(self.chatRoomsListPresenter.chatRoomLastUpdate(indexPath))
            collectionCell.lblName.text = self.chatRoomsListPresenter.chatRoomName(forIndex: indexPath)
            collectionCell.vContainer.backgroundColor = self.chatRoomsListPresenter.chatRoomMainColor(indexPath)
            collectionCell.showVerifiedBadge(chatRoomsListPresenter.chatRoomOwnerIsVerified(forIndex: indexPath))
            
            if let photoUrl = chatRoomsListPresenter.chatRoomMainImageUrl(indexPath) {
                let optionInfo: KingfisherOptionsInfo = [
                    .BackgroundDecode,
                    .ScaleFactor(0.25)]
                
                collectionCell.ivBackground.kf_setImageWithURL(photoUrl, placeholderImage: nil, optionsInfo: optionInfo, progressBlock: nil, completionHandler: nil)
            }
            
            collectionCell.lblTagList.text = self.chatRoomsListPresenter.chatRoomHashtags(forIndex: indexPath)
            
            if let ownerPhoto = chatRoomsListPresenter.chatRoomOwnerPhotoUrl(forIndex: indexPath) {
                collectionCell.ivWhoCreatedPhoto.kf_setImageWithURL(ownerPhoto)
            }
            else {
                collectionCell.ivWhoCreatedPhoto.image = nil
            }
            
            collectionCell.lblWhoCreatedUsername.text = chatRoomsListPresenter.chatRoomOwnerName(forIndex: indexPath)
            
            
            let totalAndTagLines = getNameAndTagListTotalAndTaglLines(indexPath)
            collectionCell.lblTagList.numberOfLines = totalAndTagLines.1
            
            //analytics
            let chatRoom = chatRoomsListPresenter.chatRoomAtIndex(indexPath)
            BlicupAnalytics.sharedInstance.seenChatFromSearch(chatRoom.chatRoomId!)
            
            return collectionCell
        }
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if isUserListFlowLayoutUsed {
            // TODO: Card de usuário
            
            let user = userSearchPresenter.userAtIndex(indexPath)
            if let loggedUser = UserBS.getLoggedUser() where loggedUser != user {
                self.performSegueWithIdentifier("showUserProfile", sender: user)
            }
            
        } else {
            if let pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("CoverController") as? ChatRoomsListHorizontalPageViewController {
                let presenter = CoverChatRoomsListPresenter(withLocalChats: self.chatRoomsListPresenter.currentChatIds())
                presenter.currentIndex = indexPath
                pageViewController.initCover(coverPresenter: presenter)
                pageViewController.hidesBottomBarWhenPushed = true
                collectionView.setToIndexPath(indexPath)
                self.navigationController?.pushViewController(pageViewController, animated: true)
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        if !isUserListFlowLayoutUsed {
            if let collectionCell =  cell as? ChatRoomListCollectionViewCell {
                collectionCell.ivBackground.stopAnimating()
                collectionCell.ivBackground.kf_cancelDownloadTask()
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        if !isUserListFlowLayoutUsed {
            let collectionCell =  cell as! ChatRoomListCollectionViewCell
            collectionCell.ivBackground.startAnimating()
        }
    }
    
    
    // MARK: - CollectionView Chat Size Helper
    
    // Returns total lines and taglist max lines
    private func getNameAndTagListTotalAndTaglLines(indexPath: NSIndexPath) -> (Int, Int){
        let lblNameWidth = GRID_WIDTH - 16
        let lblTagListWidth = GRID_WIDTH - 16
        
        let lblTagListFont = UIFont(name: "SFUIText-Regular", size: 13)
        let lblNameFont = UIFont(name: "SFUIText-Bold", size: 15)
        
        var chatRoomHashTags = ""
        if let hashTags = self.chatRoomsListPresenter.chatRoomHashtags(forIndex: indexPath) {
            chatRoomHashTags = hashTags
        }
        
        var numberOfLinesName = 0
        if let chatRoomName = self.chatRoomsListPresenter.chatRoomName(forIndex: indexPath) {
            numberOfLinesName = self.numberOfLinesInLabel(chatRoomName, labelWidth: lblNameWidth, labelHeight: CGFloat.max, font: lblTagListFont!)
        }
        
        let numberOfLinesTagList = self.numberOfLinesInLabel(chatRoomHashTags, labelWidth: lblTagListWidth, labelHeight: CGFloat.max, font: lblNameFont!)
        
        let total = (numberOfLinesName + numberOfLinesTagList)
        if total > 10 {
            return (10, 10 - numberOfLinesName)
        }
        else {
            return (total, numberOfLinesTagList)
        }
    }
    
    private func numberOfLinesInLabel(yourString: String, labelWidth: CGFloat, labelHeight: CGFloat, font: UIFont) -> Int {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = labelHeight
        paragraphStyle.maximumLineHeight = labelHeight
        paragraphStyle.lineBreakMode = .ByTruncatingTail
        
        let attributes: [String: AnyObject] = [NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraphStyle]
        
        let constrain = CGSizeMake(labelWidth, CGFloat(Float.infinity))
        
        let size = yourString.sizeWithAttributes(attributes)
        let stringWidth = size.width
        
        let numberOfLines = ceil(Double(stringWidth/constrain.width))
        
        return Int(numberOfLines)
    }

    // MARK: - CollectionView Layout
    
    private func setupInitialCollectionViewLayout() {
        
        setupGridCollectionFlowLayout()
    }
    
    private func setupGridCollectionFlowLayout() {
        
        reloadData()

        let collectionViewLayout = CHTCollectionViewWaterfallLayout()
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(kChatRoomsListTopSectionInsetDefault, 2, 2, 2)
        
        UIView.animateWithDuration(0.2) { () -> Void in
            self.cvcSearchChatRoomsAndUsers.scrollIndicatorInsets = UIEdgeInsetsMake(kChatRoomsListTopSectionInsetDefault, 2, 2, 2)
            self.cvcSearchChatRoomsAndUsers.collectionViewLayout.invalidateLayout()
            self.cvcSearchChatRoomsAndUsers.setCollectionViewLayout(collectionViewLayout, animated: false)
        }
    }
    
    private func setupListCollectionFlowLayout() {
        
        removeAllItems()
        reloadData()
        let collectionViewLayout = CollectionViewListFlowLayout()
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(75, 0, 0, 0)
        
        UIView.animateWithDuration(0.2) { () -> Void in
            self.cvcSearchChatRoomsAndUsers.scrollIndicatorInsets = UIEdgeInsetsMake(75, 0, 10, 0)
            self.cvcSearchChatRoomsAndUsers.collectionViewLayout.invalidateLayout()
            self.cvcSearchChatRoomsAndUsers.setCollectionViewLayout(collectionViewLayout, animated: false)
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {

        dismissKeyboard(nil)
        return false
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        
        if text == "" && string == "@" {
            isUserListFlowLayoutUsed = true
            return true
        }
        
        isUserListFlowLayoutUsed = text.hasPrefix("@") ? true : false

        if isUserListFlowLayoutUsed {
            
            if !cvcSearchChatRoomsAndUsers.collectionViewLayout.isKindOfClass(CollectionViewListFlowLayout) {
                setupListCollectionFlowLayout()
            }
            
            if let validatedText = SignupPresenter.validateIncomingUsernameEdit(string) {
        
                var searchTerm = (text as NSString).stringByReplacingCharactersInRange(range, withString: validatedText)
                
                if searchTerm.length > USERNAME_LIMIT_LENGTH {
                    searchTerm = (searchTerm as NSString).substringToIndex(USERNAME_LIMIT_LENGTH)
                }
                
                textField.text = searchTerm as String
                
                searchTerm = String(searchTerm.characters.dropFirst()) 
                
                if searchTerm != "" {
                    searchUsersWithSearchTerm(searchTerm)
                } else {
                    removeAllItems()
                    reloadData()
                }
            }
 
            return false
            
        } else {
        
            if !cvcSearchChatRoomsAndUsers.collectionViewLayout.isKindOfClass(CHTCollectionViewWaterfallLayout) {
                setupGridCollectionFlowLayout()
            }
            
            let newLength = text.utf16.count + string.utf16.count - range.length
            let searchTerm = (text as NSString).stringByReplacingCharactersInRange(range, withString: string)
            
            
            if searchTerm != "" {
                searchChatRoomWithSearchTerm(searchTerm)
            } else {
                removeAllItems()
                reloadData()
            }
            
            return newLength <= TAG_LIMIT_LENGTH
        }
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        
        removeAllItems()
//        hideNoChatsOrUsersWithSearchTerm()
        
        reloadData()
        return true
    }
    
    
    // MARK: SearchChats
    
    func searchChatRoomWithSearchTerm(searchTerm: String) {
        
        if let reachability = try? Reachability.reachabilityForInternetConnection() {
            
            prepareToPerfomSearch()
            
            if reachability.isReachable() {
                
                let searchTermTimestamp = NSDate().timeIntervalSince1970
                userSearchPresenter.searchTermTimestamp = searchTermTimestamp
                
                chatRoomsListPresenter.searchChatRoomsWithSearchTerm(searchTerm, timestamp: searchTermTimestamp, completionHandler: { (success) in
                    self.stopBlicupActivityIndicator()
                    
                    if success {
                        
                        if self.chatRoomsListPresenter.chatRoomsCount() > 0 {
                            self.reloadData()
                        } else {
//                            self.showNoChatsWithSearchTerm(searchTerm)
                        }
                    } else {
                        // TODO: tratar timout servidor
                        self.showlblNoInternet()
                    }
                    
                })
                
            } else {
                showlblNoInternet()
            }
            
        } else {
            showlblNoInternet()
        }
    }
    
    func prepareToPerfomSearch() {
        hidelblNoInternet()
//        hideNoChatsOrUsersWithSearchTerm()
        removeAllItems()
        reloadData()
        
        invalidateShowBlicupWhiteTimer()
        showBlicupWhiteActivityIndicatorTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: #selector(ChatRoomsAndUsersSearchViewController.startBlicupActivityIndicator), userInfo: nil, repeats: false)
        
        
    }
    
    // MARK: SearchUsers
    
    func searchUsersWithSearchTerm(searchTerm: String) {
        
        if let reachability = try? Reachability.reachabilityForInternetConnection() {
            
            prepareToPerfomSearch()
            
            if reachability.isReachable() {
                
                let searchTermTimestamp = NSDate().timeIntervalSince1970
                chatRoomsListPresenter.searchTermTimestamp = searchTermTimestamp
                
                userSearchPresenter.searchUsersWithSearchTerm(searchTerm, timestamp: searchTermTimestamp, completionHandler: { (success) in
                    self.stopBlicupActivityIndicator()
                
                    if success {
                            
                        if self.userSearchPresenter.userCount() > 0 {
                            self.reloadData()
                        } else {
//                            self.showNoUsersWithSearchTerm(searchTerm)
                        }
                    } else {
                        self.showlblNoInternet()
                            
                    }
                })
                
            } else {
                showlblNoInternet()
            }
        } else {
            showlblNoInternet()
        }
    }
    
    func reloadData() {
        self.cvcSearchChatRoomsAndUsers.reloadData()
    }
    
    func invalidateShowBlicupWhiteTimer() {
        if showBlicupWhiteActivityIndicatorTimer != nil {
            showBlicupWhiteActivityIndicatorTimer?.invalidate()
            showBlicupWhiteActivityIndicatorTimer = nil
        }
    }

    func removeAllItems() {
        self.userSearchPresenter.removeAllItems()
        self.chatRoomsListPresenter.clearChats()
    }
    
    // MARK: No internet
    
    func showlblNoInternet() {
        
        invalidateShowBlicupWhiteTimer()
        
        if self.lblNoInternet.hidden {
            
            lblNoInternet.alpha = 0
            lblNoInternet.hidden = false
            
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.ivLoadingBlicupGray.alpha = 0
                self.lblNoInternet.alpha = 1
                
            }, completion: { (finished) -> Void in
                
                self.ivLoadingBlicupGray.stopAnimating()
            })
        }
    }
    
    func hidelblNoInternet() {
        
        if !self.lblNoInternet.hidden {
            self.lblNoInternet.alpha = 0
            self.lblNoInternet.hidden = true
        }
    }
    
    
    func dismissKeyboard(sender: AnyObject?) {
        if tfSearch.isFirstResponder() {
            tfSearch.resignFirstResponder()
        }
    }
    
    
    // MARK: - Show Loading
    
    func startBlicupActivityIndicator() {
        
        UIView.animateWithDuration(0.6) { () -> Void in
            self.ivLoadingBlicupGray.alpha = 1
        }
        
        ivLoadingBlicupGray.startAnimating()
    }
    
    func stopBlicupActivityIndicator() {
        
        invalidateShowBlicupWhiteTimer()

        UIView.animateWithDuration(0.6, animations: { () -> Void in
            
            self.ivLoadingBlicupGray.alpha = 0
            
        }, completion: { (finished) -> Void in
                
            self.ivLoadingBlicupGray.stopAnimating()
        })
    }

    
    // MARK: Action sheet
    
    func showReportActionShet(indexPath index: NSIndexPath) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let reportChatAction = UIAlertAction(title: NSLocalizedString("Report", comment: ""), style: .Default, handler: { (action) -> Void in
            self.showReportChatDialog(indexPath: index)
        })
        
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            //print("Cancel Button Pressed")
        })
        
        alertController.addAction(reportChatAction)
        alertController.addAction(cancel)
        
        if #available(iOS 9.0, *) { reportChatAction.setValue(UIColor.blicupPink(), forKey: "titleTextColor") }
        
        self.presentViewController(alertController, animated: true, completion: nil)
        alertController.view.tintColor = UIColor.blicupPink()
        
        if let subView = alertController.view.subviews.first {
            if let contentView = subView.subviews.first {
                contentView.backgroundColor = UIColor.whiteColor()
            }
        }
    }
    
    private func showReportChatDialog(indexPath index: NSIndexPath) {
        
        let reportAction = UIAlertAction(title: NSLocalizedString("Report", comment: "Report"), style: .Default) { (action) in
            
            self.chatRoomsListPresenter.reportChatRoom(index, completionHandler: { (success) in
                
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
        
        showAlert(title: chatRoomsListPresenter.reportChatDialogTitle(), message: chatRoomsListPresenter.reportChatDialogMessage(index), withActions: [reportAction, cancel], style: UIAlertControllerStyle.Alert)
    }
    
    private func showThanksForReportingDialog() {
        
        showAlert(title: chatRoomsListPresenter.thanksForReportingDialogTitle(), message: chatRoomsListPresenter.thanksForReportingDialogMessage())
    }
    
    // MARK Share ChatRoom
    func shareChatRoom(indexPath index: NSIndexPath) {
        
        guard let shareChatRoomCard = self.chatRoomsListPresenter.chatRoomShareCard(index) else {
            return
        }
        
        let shareItems: Array = [shareChatRoomCard]
        let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypePostToWeibo, UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList, UIActivityTypePostToVimeo]
        self.presentViewController(activityViewController, animated: true, completion: nil)
        
    }
    
    // MARK: - GHContextMenu  Methods
    
    func shouldShowMenuAtPoint(point: CGPoint) -> Bool {
        
        let indexPath = self.cvcSearchChatRoomsAndUsers.indexPathForItemAtPoint(point)
        
        return indexPath != nil && !isUserListFlowLayoutUsed
    }
    
    func numberOfMenuItems() -> Int {
        return self.chatRoomsListPresenter.contextMenuNumberOfItems()
    }
    
    func imageForItemAtIndex(index: Int) -> UIImage! {
        return self.chatRoomsListPresenter.contextMenuImageForItem(index)
    }
    
    func highLightedImageForItemAtIndex(index: Int) -> UIImage! {
        return self.chatRoomsListPresenter.contextMenuHighlightedImage(index)
    }
    
    func highLightedTitleForItemAtIndex(index: Int) -> String! {
        return self.chatRoomsListPresenter.contextMenuHighlightedImageTitleForItem(index)
    }
    
    func didSelectItemAtIndex(selectedIndex: Int, forMenuAtPoint point: CGPoint) {
        
        guard let indexPath = self.cvcSearchChatRoomsAndUsers.indexPathForItemAtPoint(point) else {
            return
        }
        
        switch selectedIndex {
            
        case ContextMenuItemSelected.MORE.rawValue:
            showReportActionShet(indexPath: indexPath)
            break
            
        case ContextMenuItemSelected.SHARE.rawValue:
            shareChatRoom(indexPath: indexPath)
            break
            
        case ContextMenuItemSelected.ENTER_CHAT.rawValue:
            guard let chatRoomId = self.chatRoomsListPresenter.chatRoomId(indexPath: indexPath) else {
                return
            }
            BlicupRouter.routeBlicupToChatRoom(chatRoomId, checkSavedStatus: false)
            break
            
        default:
            break
        }
        
        
    }
    
    func getSnapViewInCollection(point: CGPoint) -> UIView {
        
        guard let indexPath = self.cvcSearchChatRoomsAndUsers.indexPathForItemAtPoint(point), collectionCell = self.cvcSearchChatRoomsAndUsers.cellForItemAtIndexPath(indexPath) as? ChatRoomListCollectionViewCell else {
            return UIView()
        }
        
        collectionCell.animateHighlightCell()
        let viewForSnap = collectionCell.snapshotViewAfterScreenUpdates(true)
        viewForSnap.frame = self.view.convertRect(collectionCell.frame, fromView: self.cvcSearchChatRoomsAndUsers)
        
        return viewForSnap
    }
    
    func contextMenuWillHideforMenuAtPoint(point: CGPoint) {
        
        guard let indexPath = self.cvcSearchChatRoomsAndUsers.indexPathForItemAtPoint(point), collectionCell = self.cvcSearchChatRoomsAndUsers.cellForItemAtIndexPath(indexPath) as? ChatRoomListCollectionViewCell else {
            return
        }
        
        collectionCell.animateUnhighlightCell()
    }
    
    
    // MARK: - Actions
    
    @IBAction func cancelPressed(sender: AnyObject) {
        
        self.view.endEditing(true)
        
        UIView.animateWithDuration(0.5, animations: {
            self.view.backgroundColor = UIColor.clearColor()
            self.cvcSearchChatRoomsAndUsers.alpha = 0
            
            self.constrTFSearchWidth.constant = 30
            self.constrTFSearchCenterX.constant = 0
            self.tfSearch.text = ""
            self.tfSearch.placeholder = ""
            self.view.layoutIfNeeded()
            
        }) { (finished) in
            self.presentingViewController!.tabBarController?.tabBar.hidden = false
            self.performSegueWithIdentifier("unwindFromSecondary", sender: self)
        }
    }

   
    // MARK: Transition Delegate
    func snapshotViewToAnimateOnTrasition(chatIndex:NSIndexPath)->UIView {
        guard let cell = cvcSearchChatRoomsAndUsers.cellForItemAtIndexPath(chatIndex) as? ChatRoomListCollectionViewCell else {
            return UIView()
        }
        
        let snapShotView = UIImageView(image: cell.ivBackground.image)
        snapShotView.clipsToBounds = true
        snapShotView.frame = self.view.convertRect(cell.ivBackground.bounds, fromView: cell.ivBackground)
        snapShotView.contentMode = UIViewContentMode.ScaleAspectFill
        
        return snapShotView
    }
    
    func showSelectedChat(chatIndex:NSIndexPath)->CGRect {
        guard chatIndex.item < chatRoomsListPresenter.chatRoomsCount() else {
            return CGRectZero
        }
        
        var position : UICollectionViewScrollPosition =
            UICollectionViewScrollPosition.CenteredHorizontally.intersect(.CenteredVertically)
        
        let photoSize = chatRoomsListPresenter.getChatCellSize(chatIndex)
        let imageHeight = photoSize.height*GRID_WIDTH/photoSize.width
        if imageHeight > 400 {//whatever you like, it's the max value for height of image
            position = .Top
        }
        
        cvcSearchChatRoomsAndUsers.setToIndexPath(chatIndex)
        if chatIndex.item < 2 {
            cvcSearchChatRoomsAndUsers.setContentOffset(CGPointZero, animated: false)
        } else {
            cvcSearchChatRoomsAndUsers.scrollToItemAtIndexPath(chatIndex, atScrollPosition: position, animated: false)
        }
        
        let chatFrame = cvcSearchChatRoomsAndUsers.layoutAttributesForItemAtIndexPath(chatIndex)!.frame
        return self.view.convertRect(chatFrame, fromView: cvcSearchChatRoomsAndUsers)
    }

    
    // MARK : UserProfileViewControllerDelegate
    func presentUserProfileCardFromSelectedUser(user: User) {
        self.performSegueWithIdentifier(kShowUserProfile, sender: user)
    }
    
    //MARK: Alert
    func alertNoInternet(){
        let alert = UIAlertController(title:NSLocalizedString("NoInternetTitle", comment: "No internet") , message:NSLocalizedString("NoInternetMessage", comment: "Check your network connection and try again"), preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        if segue.identifier == kShowUserProfile, let vcUserProfile = segue.destinationViewController as? UserProfileViewController{
            
            if let user = sender as? User {
                let presenter = UserProfileCardPresenter(user: user)
                vcUserProfile.presenter = presenter
                vcUserProfile.transitioningDelegate = vcUserProfile
                vcUserProfile.modalPresentationStyle = .Custom
                vcUserProfile.delegate = self
            }
        }
    }
}
