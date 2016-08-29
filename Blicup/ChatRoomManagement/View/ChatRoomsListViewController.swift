//
//  ChatRoomsListViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 30/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import CoreLocation
import Kingfisher


class ChatRoomsListViewController: UIViewController, CHTCollectionViewDelegateWaterfallLayout, UICollectionViewDataSource, GHContextOverlayViewDataSource, GHContextOverlayViewDelegate, UITabBarControllerDelegate, ChatRoomFetchResultPresenterDelegate, ChatListToCoverTrasitionProtocol, AlertControllerProtocol, TipsViewProtocol,  ShareChatViewProtocol{
    
    
    enum ContextMenuItemSelected: Int {
        case MORE, SHARE, ENTER_CHAT
    }
    
    private let GRID_WIDTH : CGFloat = (screenSize.width/2)-15.0 // 15 = 10 que é o tamanho do inset lateral + 5 (metade do inset entre as fotos)
    private var viewTips: TipsView!
    private var vCreateTip: ShareChatView!
    private let chatRoomsListPresenter = ChatRoomMainListPresenter()
    
    let chatRoomListViewCellID = "chatRoomListViewCellID"
    
    var isLoadingChatList = false
    
    var shouldAnimateCell = true
    var countAnimateCell = 0.1
    
    var showBlicupGrayActivityIndicatorTimer: NSTimer?
    var ivBlic = UIImageView()
    
    @IBOutlet weak var lblNoInternet: UILabel!
    @IBOutlet weak var vEmptyListBackground: UIView!
    @IBOutlet weak var ivLoadingBlicupGray: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    var lblRecentStories: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        self.chatRoomsListPresenter.delegate = self
        
        loadBlicupGrayImages()
        setGHContextMenuView()
        getChatRoomsDatasource()
        
        lblRecentStories = UILabel(frame: CGRect(x: 10, y: 0, width: 580, height: 42))
        
        lblRecentStories.text = "Recent Stories"
        lblRecentStories.font = UIFont(name: "Avenir-Black", size: 16.0)
        lblRecentStories.textColor = UIColor.blicupGray()
        
        lblNoInternet.text = NSLocalizedString("No internet", comment: "")
        
        (self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset = UIEdgeInsetsMake(42, 10, kTabBarHeight + 2, 10)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        configureTipUserDefault()
        
        self.collectionView.alwaysBounceVertical = true
        UIApplication.sharedApplication().statusBarStyle = .Default
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBarController?.tabBar.hidden = (self.presentedViewController != nil && !(self.presentedViewController is UIAlertController)) // esconde tabbar caso esteja exibindo alguma outra tela
        createCustomBlicupLoadingView()
        BlicupAnalytics.sharedInstance.mark_EnteredScreenChatList()
        
        customizeTipView()
        initCreateChatTip()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if viewTips != nil {
            self.viewTips.hidden = true
        } else if self.vCreateTip != nil {
            self.vCreateTip.hidden = true
        }
    }
    
    func chatRoomsListChanged(insertedIdexes: [NSIndexPath], deletedIndexes: [NSIndexPath], reloadedIndexes: [NSIndexPath]) {
        collectionView.performBatchUpdates({ [weak self] in
            self?.collectionView.insertItemsAtIndexPaths(insertedIdexes)
            self?.collectionView.deleteItemsAtIndexPaths(deletedIndexes)
            self?.collectionView.reloadItemsAtIndexPaths(reloadedIndexes)
            }, completion: nil)
    }
    
    
    // MARK: - Layout
    func customizeTipView() {
        if viewTips != nil {
            self.viewTips.hidden = false
        }
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.objectForKey(kPressChatTipKey) != nil {
            let tipObject = userDefaults.objectForKey(kPressChatTipKey) as? [String : AnyObject]
            let countPCTip = tipObject!["count"] as? NSNumber
            let boolPCTip = tipObject!["hasPerformedTip"] as? Bool
            
            if countPCTip?.integerValue > 2 && !boolPCTip! {
                if viewTips == nil {
                    viewTips = TipsView(frame: CGRect(x: 0, y: (self.view.window?.frame.height)!, width: self.view.frame.width, height: 60.0))
                    viewTips.lblTips.text = NSLocalizedString("PressChat_Tip", comment: "")
                    viewTips.delegate = self
                    self.view.window?.addSubview(viewTips)
                    
                    UIView.animateWithDuration(0.5, delay: 0.2, options: [], animations: {
                        self.viewTips.transform = CGAffineTransformMakeTranslation(0, -60)
                        }, completion: { (_) in })
                }
            }
        }
    }
    
    func loadBlicupGrayImages() {
        
        var animationArray: [UIImage] = []
        
        for index in 0...29 {
            animationArray.append(UIImage(named: "BlicMini_gray_\(index)")!)
        }
        
        ivLoadingBlicupGray.animationImages = animationArray
        ivLoadingBlicupGray.animationDuration = 1.0
        ivLoadingBlicupGray.alpha = 0
    }
    
    
    func createCustomBlicupLoadingView() {
        ivBlic.contentMode = UIViewContentMode.ScaleAspectFit
        ivBlic.image = UIImage(named: "BlicUpdate_grey_0")
        
        var animationArray = [UIImage]()
        
        for index in 0...30 {
            animationArray.append(UIImage(named: "BlicUpdate_grey_\(index)")!)
        }
        
        ivBlic.animationImages = animationArray
        ivBlic.animationDuration = 1.0
        
        ivBlic.frame = CGRectMake(0, -42, 35, 35)
        ivBlic.center = CGPointMake(collectionView.bounds.width/2, ivBlic.center.y)
        
        collectionView.addSubview(ivBlic)
        collectionView.addSubview(lblRecentStories)
    }
    
    func setGHContextMenuView() {
        let contextMenu = GHContextMenuView()
        contextMenu.dataSource = self
        contextMenu.delegate = self
        
        let longPress = UILongPressGestureRecognizer(target: contextMenu, action: #selector(GHContextMenuView.longPressDetected(_:)))
        self.collectionView.addGestureRecognizer(longPress)
        
    }
    
    // MARK: - Datasource
    
    func getChatRoomsDatasource() {
        isLoadingChatList = true
        
        showBlicupGrayActivityIndicatorTimer = NSTimer.scheduledTimerWithTimeInterval(1.5, target: self, selector: #selector(ChatRoomsListViewController.startBlicupGrayActivityIndicator), userInfo: nil, repeats: false)
        
        chatRoomsListPresenter.updateChatRoomList { (success) in
            self.collectionView.reloadData()
            
            if success {
                self.stopBlicupGrayActivityIndicator()
            }
            else if self.chatRoomsListPresenter.chatRoomsCount() == 0 {
                self.showNoInternet()
            } else {
                self.stopBlicupGrayActivityIndicator()
            }
            
            self.isLoadingChatList = false
        }
    }
    
    
    // MARK: - Tabbar
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        guard let navController = viewController as? UINavigationController else {
            return false
        }
        
        if navController.topViewController! == self && self.view.window != nil && self.collectionView.contentOffset.y > 0 {
            self.collectionView.setContentOffset(CGPointZero, animated: true)
        }
        return true
    }
    
    // MARK: - CollectionView
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let totalLines = getNameAndTagListTotalAndTaglLines(indexPath).0
        let size = self.chatRoomsListPresenter.getChatItemSizeForLines(totalLines)
        
        let imageHeight = size.height*(GRID_WIDTH/size.width)*1.5
        return CGSizeMake(GRID_WIDTH, imageHeight)
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = self.collectionView.cellForItemAtIndexPath(indexPath) {
            self.view.userInteractionEnabled = false
            UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                cell.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.95, 0.95)
                }, completion: { (_) in
                    UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                        cell.transform = CGAffineTransformIdentity
                        }, completion: { (_) in
                            self.shouldAnimateCell = false
                            if let pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("CoverController") as? ChatRoomsListHorizontalPageViewController {
                                pageViewController.hidesBottomBarWhenPushed = true
                                let presenter = CoverChatRoomsListPresenter(withMyChats: false)
                                presenter.currentIndex = indexPath
                                pageViewController.initCover(coverPresenter: presenter)
                                collectionView.setToIndexPath(indexPath)
                                self.navigationController?.pushViewController(pageViewController, animated: true)
                            }
                            self.view.userInteractionEnabled = true
                    })
            })
        }
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let collectionCell: ChatRoomListCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRoomListViewCellID, forIndexPath: indexPath) as! ChatRoomListCollectionViewCell
        
        collectionCell.layer.shouldRasterize = true
        collectionCell.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        collectionCell.lblName.text = self.chatRoomsListPresenter.chatRoomName(forIndex: indexPath)
        
        collectionCell.vContainer.backgroundColor = self.chatRoomsListPresenter.chatRoomMainColor(indexPath)
        collectionCell.ivBackground.setMainColor(self.chatRoomsListPresenter.chatRoomMainColor(indexPath))
        
        
        let photoUrlList = self.chatRoomsListPresenter.photoUrlList(indexPath)
        
        startPrefetchImagesThumb(photoUrlList)
        
        if let thumbUrl = chatRoomsListPresenter.chatRoomMainThumbUrl(indexPath) {
            let optionInfo: KingfisherOptionsInfo = [
                .DownloadPriority(1.0),
                .BackgroundDecode,
                .ScaleFactor(0.5)
            ]
            collectionCell.ivBackground.kf_setImageWithURL(thumbUrl, placeholderImage: nil, optionsInfo: optionInfo, progressBlock: nil, completionHandler: nil)
        }
        
        collectionCell.lblWhoCreatedUsername.text = chatRoomsListPresenter.chatRoomOwnerName(forIndex: indexPath)
        collectionCell.showVerifiedBadge(chatRoomsListPresenter.chatRoomOwnerIsVerified(forIndex: indexPath))
        
        if shouldAnimateCell{
            animateCell(collectionCell)
        }
        
        //analytics
        let chatRoom = chatRoomsListPresenter.chatRoomAtIndex(indexPath)
        BlicupAnalytics.sharedInstance.seenChatFromMain(chatRoom.chatRoomId!)
        
        return collectionCell
    }
    
    
    func startPrefetchImagesThumb(photoUrlList: [String]){
        
        let urlsList = photoUrlList.flatMap { (stringURL) -> NSURL? in
            return NSURL(string: AmazonManager.getThumbUrlFromMainUrl(stringURL))
        }
        
        let prefetcher = ImagePrefetcher(urls: urlsList)
        prefetcher.maxConcurrentDownloads = 20
        prefetcher.start()
        
    }
    
    /**
     func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
     let collectionCell =  cell as! ChatRoomListCollectionViewCell
     collectionCell.ivBackground.stopAnimating()
     collectionCell.ivBackground.kf_cancelDownloadTask()
     }
     
     func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
     let collectionCell =  cell as! ChatRoomListCollectionViewCell
     collectionCell.ivBackground.startAnimating()
     
     }*/
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.chatRoomsListPresenter.chatRoomsCount()
    }
    
    
    // MARK: - CollectionView Size\Layout Helper
    
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
    
    private func animateCell(collectionCell: ChatRoomListCollectionViewCell){
        collectionCell.transform = CGAffineTransformMakeTranslation(0.0, self.view.bounds.height)
        let delay = countAnimateCell * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        countAnimateCell = countAnimateCell + 0.1
        dispatch_after(time, dispatch_get_main_queue()) {
            UIView.animateWithDuration(0.2, animations: {
                collectionCell.transform = CGAffineTransformIdentity
            })
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
    
    
    // MARK: - CollectionViewTransitionProtocol
    func snapshotViewToAnimateOnTrasition(chatIndex:NSIndexPath)->UIView {
        guard let cell = collectionView.cellForItemAtIndexPath(chatIndex) as? ChatRoomListCollectionViewCell else {
            return UIView()
        }
        
        let snapShotView = UIImageView(image: cell.ivBackground.image)
        snapShotView.clipsToBounds = true
        snapShotView.frame = self.view.convertRect(cell.ivBackground.bounds, fromView: cell.ivBackground)
        snapShotView.contentMode = UIViewContentMode.ScaleAspectFill
        
        return snapShotView
    }
    
    func showSelectedChat(chatIndex:NSIndexPath)->CGRect {
        var position : UICollectionViewScrollPosition =
            UICollectionViewScrollPosition.CenteredHorizontally.intersect(.CenteredVertically)
        
        let photoSize = self.chatRoomsListPresenter.getChatCellSize(chatIndex)
        let imageHeight = photoSize.height*GRID_WIDTH/photoSize.width
        if imageHeight > 400 {//whatever you like, it's the max value for height of image
            position = .Top
        }
        
        collectionView.setToIndexPath(chatIndex)
        if chatIndex.item < 2 {
            collectionView.setContentOffset(CGPointZero, animated: false)
        } else {
            collectionView.scrollToItemAtIndexPath(chatIndex, atScrollPosition: position, animated: false)
        }
        
        let chatFrame = collectionView.layoutAttributesForItemAtIndexPath(chatIndex)!.frame
        return self.view.convertRect(chatFrame, fromView: collectionView)
    }
    
    //MARK: Tip Protocol
    func tipViewClosePressed(sender: UIButton) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let tipObject = userDefaults.objectForKey(kPressChatTipKey) as? [String : AnyObject]
        let countPCTip = tipObject!["count"] as? NSNumber
        let updatedObject : [String : AnyObject] = ["count" : (countPCTip?.integerValue)!, "hasPerformedTip" : true]
        userDefaults.setObject(updatedObject, forKey: kPressChatTipKey)
        
        UIView.animateWithDuration(0.5, delay: 0.2, options: [], animations: {
            self.viewTips.transform = CGAffineTransformMakeTranslation(0, 60)
        }) { (_) in
            self.viewTips.removeFromSuperview()
            self.viewTips = nil
        }
    }
    
    private func configureTipUserDefault() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.objectForKey(kPressChatTipKey) == nil {
            let tipObject: [String : AnyObject] = ["count" : 1, "hasPerformedTip" : false]
            userDefaults.setObject(tipObject, forKey: kPressChatTipKey)
        } else {
            let tipObject = userDefaults.objectForKey(kPressChatTipKey) as? [String : AnyObject]
            let countPCTip = tipObject!["count"] as? NSNumber
            let boolPCTip = tipObject!["hasPerformedTip"] as? Bool
            
            if !boolPCTip! {
                let updatedObject : [String : AnyObject] = ["count" : ((countPCTip?.integerValue)! + 1), "hasPerformedTip" : boolPCTip!]
                userDefaults.setObject(updatedObject, forKey: kPressChatTipKey)
            }
            
            //Tip Create Chat Only Start Count After User Finished Tip Press Chat
            
            if userDefaults.objectForKey(kCreateChatTipKey) == nil {
                let tipObject: [String : AnyObject] = ["count" : 1, "hasPerformedTip" : false]
                userDefaults.setObject(tipObject, forKey: kCreateChatTipKey)
            } else {
                if boolPCTip! {
                    let tipObject = userDefaults.objectForKey(kCreateChatTipKey) as? [String : AnyObject]
                    let countCCTip = tipObject!["count"] as? NSNumber
                    let boolCCTip = tipObject!["hasPerformedTip"] as? Bool
                    
                    if !boolCCTip! {
                        let updatedObject : [String : AnyObject] = ["count" : ((countCCTip?.integerValue)! + 1), "hasPerformedTip" : boolCCTip!]
                        userDefaults.setObject(updatedObject, forKey: kCreateChatTipKey)
                    }
                    
                }
            }
        }
    }
    
    //MARK: Setup Create Chat Tip
    
    func initCreateChatTip() {
        
        if self.vCreateTip != nil {
            self.vCreateTip.hidden = false
        }
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.objectForKey(kCreateChatTipKey) != nil {
            let tipObject = userDefaults.objectForKey(kCreateChatTipKey) as? [String : AnyObject]
            let countPCTip = tipObject!["count"] as? NSNumber
            let boolPCTip = tipObject!["hasPerformedTip"] as? Bool
            
            if ((countPCTip?.integerValue)!%6 == 0) && !boolPCTip!{
                if vCreateTip == nil {
                    self.vCreateTip = ShareChatView(frame: CGRect(x: 0, y: (self.view.window?.frame.height)!, width: self.view.frame.width, height: 89.0))
                    
                    self.vCreateTip?.lblShare.text = NSLocalizedString("Create_Chat_Tip", comment: "")
                    self.vCreateTip?.btnShare.setTitle(NSLocalizedString("Create_Tip", comment: "Create"), forState: .Normal)
                    self.vCreateTip?.btnLater.setTitle(NSLocalizedString("ShareLater", comment: "Later"), forState: .Normal)
                    
                    vCreateTip.delegate = self
                    self.view.window?.addSubview(vCreateTip)
                    
                    UIView.animateWithDuration(0.5, delay: 0.2, options: [], animations: {
                        self.vCreateTip.transform = CGAffineTransformMakeTranslation(0, -89)
                        }, completion: { (_) in })
                }
            }
        }
        
        
    }
    
    // MARK: - ScrollView Delegate
    var lastContentOffset :  CGFloat = 0
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        var scrollDirection :ScrollDirection = ScrollDirection.ScrollDirectionUp
        
        if self.lastContentOffset > scrollView.contentOffset.y
        {
            scrollDirection = ScrollDirection.ScrollDirectionUp
        }
        else if self.lastContentOffset < scrollView.contentOffset.y
        {
            scrollDirection = ScrollDirection.ScrollDirectionDown
        }
        
        self.lastContentOffset = scrollView.contentOffset.y
        
        if   scrollDirection == ScrollDirection.ScrollDirectionDown && self.collectionView.contentOffset.y > 0 && self.collectionView.contentOffset.y > (self.collectionView.contentSize.height - 2*self.collectionView.bounds.size.height) && !isLoadingChatList
        {
            isLoadingChatList = true
            self.chatRoomsListPresenter.getMoreChatRooms({ (success) in
                self.isLoadingChatList = false
            })
        }
        
        if self.collectionView.contentOffset.y <= -40{
            if !ivBlic.isAnimating() {
                ivBlic.startAnimating()
            }
        }
        
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if self.collectionView.contentOffset.y <= -40{
            var loadingInset = scrollView.contentInset
            loadingInset.top = 40.0
            
            let contentOffSet = scrollView.contentOffset
            
            UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                scrollView.contentInset = loadingInset
                scrollView.contentOffset = contentOffSet
                }, completion: { (_) in
                    self.updateChatRoomns()
            })
        }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        shouldAnimateCell = false
    }
    
    // MARK: - Refresh Methods
    func updateChatRoomns(){
        if !isLoadingChatList {
            isLoadingChatList = true
            
            chatRoomsListPresenter.updateChatRoomList { (success) in
                if success {
                    self.collectionView.performSelector(#selector(self.collectionView.reloadData), withObject: nil, afterDelay: 0.3)
                }
                
                UIView.animateWithDuration(0.3, animations: {
                    self.ivBlic.stopAnimating()
                    self.collectionView.contentInset = UIEdgeInsetsZero
                    self.lblNoInternet.alpha = success ? 0.0 : 1.0
                    
                    }, completion: { (_) in
                        self.isLoadingChatList = false
                        self.lblNoInternet.hidden = !success && !(self.chatRoomsListPresenter.chatRoomsCount() == 0)
                })
            }
        }
    }
    
    
    // MARK: - Show Loading
    
    func startBlicupGrayActivityIndicator() {
        UIView.animateWithDuration(1.0) { () -> Void in
            self.ivLoadingBlicupGray.alpha = 1
            self.ivBlic.alpha = 0
        }
        
        ivLoadingBlicupGray.startAnimating()
    }
    
    func stopBlicupGrayActivityIndicator() {
        
        self.collectionView.alpha = 0
        UIView.animateWithDuration(1.0, animations: { () -> Void in
            self.ivLoadingBlicupGray.alpha = 0
            self.ivBlic.alpha = 1
            self.collectionView.alpha = 1
            
            }, completion: { (finished) -> Void in
                self.ivLoadingBlicupGray.stopAnimating()
                self.lblNoInternet.alpha = 0
        })
        invalidateShowBlicupGrayTimer()
    }
    
    func showNoInternet() {
        
        lblNoInternet.alpha = 0
        lblNoInternet.hidden = false
        
        
        UIView.animateWithDuration(1.0, animations: { () -> Void in
            self.ivLoadingBlicupGray.alpha = 0
            self.ivBlic.alpha = 1
            self.lblNoInternet.alpha = 1
            
            }, completion: { (finished) -> Void in
                
                if finished {
                    
                    self.ivLoadingBlicupGray.stopAnimating()
                }
        })
        
        invalidateShowBlicupGrayTimer()
    }
    
    
    func invalidateShowBlicupGrayTimer() {
        if showBlicupGrayActivityIndicatorTimer != nil {
            showBlicupGrayActivityIndicatorTimer?.invalidate()
            showBlicupGrayActivityIndicatorTimer = nil
        }
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
    
    // MARK: - GHContextMenu  Methods
    
    func shouldShowMenuAtPoint(point: CGPoint) -> Bool {
        
        let indexPath = self.collectionView.indexPathForItemAtPoint(point)
        
        return indexPath != nil
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
        
        guard let indexPath = self.collectionView.indexPathForItemAtPoint(point) else {
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
        
        guard let indexPath = self.collectionView.indexPathForItemAtPoint(point), collectionCell = self.collectionView.cellForItemAtIndexPath(indexPath) as? ChatRoomListCollectionViewCell else {
            return UIView()
        }
        
        collectionCell.animateHighlightCell()
        let viewForSnap = collectionCell.snapshotViewAfterScreenUpdates(true)
        viewForSnap.frame = self.view.convertRect(collectionCell.frame, fromView: self.collectionView)
        
        return viewForSnap
    }
    
    func contextMenuWillHideforMenuAtPoint(point: CGPoint) {
        
        guard let indexPath = self.collectionView.indexPathForItemAtPoint(point), collectionCell = self.collectionView.cellForItemAtIndexPath(indexPath) as? ChatRoomListCollectionViewCell else {
            return
        }
        
        collectionCell.animateUnhighlightCell()
    }
    
    func shouldAnimateTipPerformed() {
        if viewTips != nil  && !viewTips.hidden{
            let button = UIButton(frame: CGRect(x: 0, y: (self.view.window?.frame.height)! - 60, width: self.view.frame.width, height: 60.0))
            UIApplication.sharedApplication().keyWindow?.addSubview(button)
            
            self.viewTips.performedTaskTip()
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
    
    // MARK: Share ChatRoom
    func shareChatRoom(indexPath index: NSIndexPath) {
        
        guard let shareChatRoomCard = self.chatRoomsListPresenter.chatRoomShareCard(index) else {
            return
        }
        
        let shareItems: Array = [shareChatRoomCard]
        let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypePostToWeibo, UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList, UIActivityTypePostToVimeo]
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    
    //MARK:
    
    func sharePressed(sender: UIButton) {
        UIView.animateWithDuration(0.5, delay: 0.2, options: [], animations: {
            self.vCreateTip.transform = CGAffineTransformMakeTranslation(0, 60)
        }) { (_) in
            self.vCreateTip.removeFromSuperview()
            self.vCreateTip = nil
        }
    }
    
    func laterSharePressed(sender: UIButton) {
        UIView.animateWithDuration(0.5, delay: 0.2, options: [], animations: {
            self.vCreateTip.transform = CGAffineTransformMakeTranslation(0, 60)
        }) { (_) in
            self.vCreateTip.removeFromSuperview()
            self.vCreateTip = nil
        }
    }
    
    // MARK: - Navigation
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "createChatSegue" {
            let touch = sender as! UIButton
            
            (segue as! OHCircleSegue).circleOrigin = CGPoint(x: touch.frame.midX, y: touch.frame.midY)
            let cgPointBtnCreate = CGPoint(x: touch.frame.midX, y: touch.frame.midY)
            
            if let destination = segue.destinationViewController as? CreateChatRoomViewController{
                destination.parentView = self
                destination.cgPointBtnCreate = cgPointBtnCreate
            }
        }
    }
    
    @IBAction func unwindFromSecondary(segue: UIStoryboardSegue) {
        if (segue.identifier == "unwindFromSecondary")
        {
            if self.viewTips != nil {
                self.viewTips.hidden = false
            } else if self.vCreateTip != nil {
                self.vCreateTip.hidden = false
                
            }
        }
    }
    
}
