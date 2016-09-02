//
//  MapChatListViewController.swift
//  Blicup
//
//  Created by Moymer on 09/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class MapChatListViewController: UIViewController, UICollectionViewDataSource, CHTCollectionViewDelegateWaterfallLayout, ChatListToCoverTrasitionProtocol, ChatRoomFetchResultPresenterDelegate, GHContextOverlayViewDataSource, GHContextOverlayViewDelegate, AlertControllerProtocol {
    
    enum ContextMenuItemSelected: Int {
        case MORE, SHARE, ENTER_CHAT
    }
    
    
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var vevBlurBackground: UIVisualEffectView!
    @IBOutlet weak var lblNumberOfChats: UILabel!
    @IBOutlet weak var cvChatListCollection: UICollectionView!
    @IBOutlet weak var vTopContainer: UIView!
    
    var presenter:MapChatRoomListPresenter! {
        didSet {
            presenter.delegate = self
        }
    }
    
    private var alreadyAnimated = false
    
    private var shouldAnimateCell = true
    private var countAnimateCell = 0.1
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnClose.layer.cornerRadius = btnClose.bounds.height/2
        
        var t = CGAffineTransformIdentity
        t = CGAffineTransformRotate(t, CGFloat((M_PI * 45) / 180))
        
        self.btnClose.transform = t
        
        setCollectionDefaultViewLayout()
        setGHContextMenuView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().statusBarStyle = .Default
        self.presentingViewController!.tabBarController?.tabBar.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        BlicupAnalytics.sharedInstance.mark_EnteredScreenChatListFromMap()
        
        if alreadyAnimated == false {
            UIView.animateWithDuration(0.5, animations: {
                self.vevBlurBackground.alpha = 1
                
                var t = CGAffineTransformIdentity
                t = CGAffineTransformRotate(t, CGFloat((M_PI * 90) / 180))
                self.btnClose.transform = t
                self.btnClose.backgroundColor = UIColor.blackColor()
                
            }) { (finished) in
                self.alreadyAnimated = true
                self.loadChats()
            }
        }
    }
    
    private func loadChats() {
        self.cvChatListCollection.reloadData()
        
        let chatsNumber = self.presenter.chatRoomsCount()
        self.lblNumberOfChats.text = "\(chatsNumber) Chats"
        
        UIView.animateWithDuration(0.5, animations: {
            self.lblNumberOfChats.alpha = 1
        })
    }
    
    func setGHContextMenuView() {
        let contextMenu = GHContextMenuView()
        contextMenu.dataSource = self
        contextMenu.delegate = self
        
        let longPress = UILongPressGestureRecognizer(target: contextMenu, action: #selector(GHContextMenuView.longPressDetected(_:)))
        self.cvChatListCollection.addGestureRecognizer(longPress)
        
    }

    
    @IBAction func closePressed(sender: UIButton) {
        
        UIView.animateWithDuration(0.05, animations: {
            var t = CGAffineTransformIdentity
            t = CGAffineTransformScale(t, 1, 1)
            t = CGAffineTransformRotate(t, CGFloat((M_PI * 90) / 180))
            self.btnClose.transform = t
        }) { (_) in
            UIView.animateWithDuration(0.5, animations: {
                self.vevBlurBackground.alpha = 0
                self.lblNumberOfChats.alpha = 0
                self.cvChatListCollection.alpha = 0
                self.vTopContainer.backgroundColor = UIColor.clearColor()
                
                var t = CGAffineTransformIdentity
                t = CGAffineTransformRotate(t, CGFloat((M_PI * 45) / 180))
                self.btnClose.transform = t
                self.btnClose.backgroundColor = UIColor.blicupGreen()
                
            }) { (finished) in
                self.presentingViewController!.tabBarController?.tabBar.hidden = false
                self.dismissViewControllerAnimated(false, completion: nil)
            }
        }
    }
    
    @IBAction func btnDragExit(sender: AnyObject) {
        UIView.animateWithDuration(0.1) {
            var t = CGAffineTransformIdentity
            t = CGAffineTransformScale(t, 1, 1)
            t = CGAffineTransformRotate(t, CGFloat((M_PI * 90) / 180))
            self.btnClose.transform = t
        }
    }
    
    @IBAction func btnDragEnter(sender: AnyObject) {
        UIView.animateWithDuration(0.1) {
            var t = CGAffineTransformIdentity
            t = CGAffineTransformScale(t, 0.8, 0.8)
            t = CGAffineTransformRotate(t, CGFloat((M_PI * 90) / 180))
            self.btnClose.transform = t
        }
    }
    
    @IBAction func btnPressedDown(sender: AnyObject) {
        UIView.animateWithDuration(0.17) {
            var t = CGAffineTransformIdentity
            t = CGAffineTransformScale(t, 0.8, 0.8)
            t = CGAffineTransformRotate(t, CGFloat((M_PI * 90) / 180))
            self.btnClose.transform = t
        }
    }
    
    @IBAction func btnTouchCancel(sender: AnyObject) {
        UIView.animateWithDuration(0.1) {
            var t = CGAffineTransformIdentity
            t = CGAffineTransformScale(t, 1, 1)
            t = CGAffineTransformRotate(t, CGFloat((M_PI * 90) / 180))
            self.btnClose.transform = t
        }
    }
    
    // MARK: Presenter Delegate
    func chatRoomsListChanged(insertedIdexes: [NSIndexPath], deletedIndexes: [NSIndexPath], reloadedIndexes: [NSIndexPath]) {
        guard cvChatListCollection != nil else {
            return
        }
        
        cvChatListCollection.performBatchUpdates({[weak self] in
            self?.cvChatListCollection.insertItemsAtIndexPaths(insertedIdexes)
            self?.cvChatListCollection.deleteItemsAtIndexPaths(deletedIndexes)
            self?.cvChatListCollection.reloadItemsAtIndexPaths(reloadedIndexes)
            }, completion: nil)
    }
    
    
    // MARK: Collection Datasource e Delegate
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let totalLines = getNameAndTagListTotalAndTaglLines(indexPath).0
        let size = self.presenter.getChatItemSizeForLines(totalLines)
        
        let imageHeight = size.height*(GRID_WIDTH/size.width)
        return CGSizeMake(GRID_WIDTH, imageHeight)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        shouldAnimateCell = false
        self.performSegueWithIdentifier("ShowCoverSegue", sender: indexPath)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let collectionCell: ChatRoomListCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("MapChatCell", forIndexPath: indexPath) as! ChatRoomListCollectionViewCell
        
        collectionCell.lblParticipantsCount.text = "\(self.presenter.chatRoomNumberOfParticipants(indexPath))"
        collectionCell.bcTimer.updateBasedOnTime(self.presenter.chatRoomLastUpdate(indexPath))
        collectionCell.lblName.text = self.presenter.chatRoomName(forIndex: indexPath)
        collectionCell.vContainer.backgroundColor = self.presenter.chatRoomMainColor(indexPath)
        collectionCell.showVerifiedBadge(presenter.chatRoomOwnerIsVerified(forIndex: indexPath))
        
        if let photoUrl = presenter.chatRoomMainImageUrl(indexPath)  {
            collectionCell.ivBackground.kf_setImageWithURL(photoUrl)
        }
        
        collectionCell.lblTagList.text = self.presenter.chatRoomHashtags(forIndex: indexPath)
        
        if let ownerPhoto = presenter.chatRoomOwnerPhotoUrl(forIndex: indexPath) {
            collectionCell.ivWhoCreatedPhoto.kf_setImageWithURL(ownerPhoto)
        }
        else {
            collectionCell.ivWhoCreatedPhoto.image = nil
        }
        
        collectionCell.lblWhoCreatedUsername.text = presenter.chatRoomOwnerName(forIndex: indexPath)
        
        collectionCell.layer.shouldRasterize = true
        collectionCell.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        let totalAndTagLines = getNameAndTagListTotalAndTaglLines(indexPath)
        collectionCell.lblTagList.numberOfLines = totalAndTagLines.1
        
        if shouldAnimateCell {
            animateCell(collectionCell)
        }

        //analytics
        let chatRoom = presenter.chatRoomAtIndex(indexPath)
        BlicupAnalytics.sharedInstance.seenChatFromMap(chatRoom.chatRoomId!)
        
        return collectionCell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if alreadyAnimated {
            return self.presenter.chatRoomsCount()
        }
        else {
            return 0
        }
    }
    
    
    // MARK: - CollectionView Size\Layout Helper
    private func setCollectionDefaultViewLayout() {
        let collectionViewLayout = CHTCollectionViewWaterfallLayout()
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(kChatRoomsListTopSectionInsetDefault, 2, 2, 2)
        
        cvChatListCollection.scrollIndicatorInsets = UIEdgeInsetsMake(kChatRoomsListTopSectionInsetDefault, 2, 2, 2)
        cvChatListCollection.setCollectionViewLayout(collectionViewLayout, animated: true)
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
    
    // Returns total lines and taglist max lines
    private func getNameAndTagListTotalAndTaglLines(indexPath: NSIndexPath) -> (Int, Int){
        let lblNameWidth = GRID_WIDTH - 16
        let lblTagListWidth = GRID_WIDTH - 16
        
        let lblTagListFont = UIFont(name: "SFUIText-Regular", size: 13)
        let lblNameFont = UIFont(name: "SFUIText-Bold", size: 15)
        
        var chatRoomHashTags = ""
        if let hashTags = self.presenter.chatRoomHashtags(forIndex: indexPath) {
            chatRoomHashTags = hashTags
        }
        
        var numberOfLinesName = 0
        if let chatRoomName = self.presenter.chatRoomName(forIndex: indexPath) {
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
    
    
    // MARK: Action sheet
    
    func showReportActionShet(indexPath index: NSIndexPath) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let reportChatAction = UIAlertAction(title: NSLocalizedString("Report", comment: ""), style: .Default, handler: { (action) -> Void in
            self.showReportChatDialog(indexPath: index)
        })
        
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            print("Cancel Button Pressed")
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
            
            self.presenter.reportChatRoom(index, completionHandler: { (success) in
                
                if success {
                    self.showThanksForReportingDialog()
                } else {
                    // TODO: tratar caso de falha no report
                }
            })
        }
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            print("Cancel Button Pressed")
        })
        
        showAlert(title: presenter.reportChatDialogTitle(), message: presenter.reportChatDialogMessage(index), withActions: [reportAction, cancel], style: UIAlertControllerStyle.Alert)
    }
    
    private func showThanksForReportingDialog() {
        
        showAlert(title: presenter.thanksForReportingDialogTitle(), message: presenter.thanksForReportingDialogMessage())
    }
    
    
    // MARK Share ChatRoom
    func shareChatRoom(indexPath index: NSIndexPath) {
        
        guard let shareChatRoomCard = self.presenter.chatRoomShareCard(index) else {
            return
        }
        
        let shareItems: Array = [shareChatRoomCard]
        let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypePostToWeibo, UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList, UIActivityTypePostToVimeo]
        self.presentViewController(activityViewController, animated: true, completion: nil)
        
    }
    
    // MARK: - GHContextMenu  Methods
    
    func shouldShowMenuAtPoint(point: CGPoint) -> Bool {
        
        let indexPath = self.cvChatListCollection.indexPathForItemAtPoint(point)
        
        return indexPath != nil
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
        
        guard let indexPath = self.cvChatListCollection.indexPathForItemAtPoint(point) else {
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
            
            guard let chatRoomId = self.presenter.chatRoomId(indexPath: indexPath) else {
                return
            }
            
            BlicupRouter.routeBlicupToChatRoom(chatRoomId, checkSavedStatus: false)
            
            break
        default:
            break
        }
        
    }
    
    func getSnapViewInCollection(point: CGPoint) -> UIView {
        
        guard let indexPath = self.cvChatListCollection.indexPathForItemAtPoint(point), collectionCell = self.cvChatListCollection.cellForItemAtIndexPath(indexPath) as? ChatRoomListCollectionViewCell else {
            return UIView()
        }
        
        collectionCell.animateHighlightCell()
        let viewForSnap = collectionCell.snapshotViewAfterScreenUpdates(true)
        viewForSnap.frame = self.view.convertRect(collectionCell.frame, fromView: self.cvChatListCollection)
        
        return viewForSnap
    }
    
    func contextMenuWillHideforMenuAtPoint(point: CGPoint) {
        
        guard let indexPath = self.cvChatListCollection.indexPathForItemAtPoint(point), collectionCell = self.cvChatListCollection.cellForItemAtIndexPath(indexPath) as? ChatRoomListCollectionViewCell else {
            return
        }
        
        collectionCell.animateUnhighlightCell()
    }
    
    
    // MARK: Transition Delegate
    func snapshotViewToAnimateOnTrasition(chatIndex:NSIndexPath)->UIView {
        guard let cell = cvChatListCollection.cellForItemAtIndexPath(chatIndex) as? ChatRoomListCollectionViewCell else {
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
        
        let photoSize = presenter.getChatCellSize(chatIndex)
        let imageHeight = photoSize.height*GRID_WIDTH/photoSize.width
        if imageHeight > 400 {//whatever you like, it's the max value for height of image
            position = .Top
        }
        
        cvChatListCollection.setToIndexPath(chatIndex)
        if chatIndex.item < 2 {
            cvChatListCollection.setContentOffset(CGPointZero, animated: false)
        } else {
            cvChatListCollection.scrollToItemAtIndexPath(chatIndex, atScrollPosition: position, animated: false)
        }
        
        let chatFrame = cvChatListCollection.layoutAttributesForItemAtIndexPath(chatIndex)!.frame
        return self.view.convertRect(chatFrame, fromView: cvChatListCollection)
    }
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowCoverSegue" {
            guard let pageViewController = segue.destinationViewController as? ChatRoomsListHorizontalPageViewController,
                let indexPath = sender as? NSIndexPath else {
                    return
            }
            
            let presenter = CoverChatRoomsListPresenter(withLocalChats: self.presenter.currentChatIds())
            presenter.currentIndex = indexPath
            pageViewController.initCover(coverPresenter: presenter)
            pageViewController.hidesBottomBarWhenPushed = true
            self.cvChatListCollection.setToIndexPath(indexPath)
        }
    }
    
    
    // MARK: Scroll View
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        shouldAnimateCell = false
    }
}
