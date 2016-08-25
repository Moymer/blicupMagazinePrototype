//
//  MyChatsViewController.swift
//  Blicup
//
//  Created by Moymer on 29/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Kingfisher

class MyChatsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ChatRoomFetchResultPresenterDelegate, ChatListToCoverTrasitionProtocol, AlertControllerProtocol, GHContextOverlayViewDelegate, GHContextOverlayViewDataSource {
    
    enum ContextMenuItemSelected: Int {
        case MORE, SHARE, ENTER_CHAT
    }
    
    private let presenter = MyChatsPresenter()
    
    @IBOutlet weak var ivLoadingBlic: UIImageView!
    @IBOutlet weak var myChatsTableView: UITableView!
    @IBOutlet weak var btnCreateChat: BCButton!
    @IBOutlet weak var vNoMyChats: UIView!
    @IBOutlet weak var lblNoInternet: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.tabBar.translucent = true
        
        myChatsTableView.contentInset = UIEdgeInsetsMake(70, 0, kTabBarHeight, 0)
        vNoMyChats.layer.cornerRadius = 4.0
        configCreateBtn()
        
        presenter.delegate = self
        
        lblNoInternet.text = NSLocalizedString("No internet", comment: "No internet")
        
        configLoadingBlicAnimation()
        
        animateBlicLoading(true, showNoInternet: false)
        
        presenter.loadMyChats { (success, chatRoomList) in
            self.myChatsTableView.reloadData()
            
            self.animateBlicLoading(false, showNoInternet: !success)
            
            if success {
                self.animateNoChatsInfoInOut(self.presenter.chatRoomsCount() > 0)
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MyChatsViewController.moveToForeground(_:)), name: LDTPWebSocketManagerNotification.SocketOpened.rawValue, object: nil)
        
        setGHContextMenuView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().statusBarStyle = .Default
        
        presenter.reloadMyChatsList { (success, chatRoomsList) in
            if success {
                self.animateNoChatsInfoInOut(self.presenter.chatRoomsCount() > 0)
            }
            self.showNoInternet(!success, afterDelay: 0.0)
            
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBarController?.tabBar.hidden = false
        BlicupAnalytics.sharedInstance.mark_EnteredScreenMyChats()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: LDTPWebSocketManagerNotification.SocketOpened.rawValue, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func configCreateBtn() {
        btnCreateChat.layer.shadowOpacity = 0.2
        btnCreateChat.layer.shadowOffset = CGSize(width: 0, height: 0)
        btnCreateChat.layer.shadowRadius = 1.0
        btnCreateChat.layer.shadowColor = UIColor.blackColor().CGColor
        btnCreateChat.layer.masksToBounds = false
    }
    
    @IBAction func createChatPressed(sender: BCButton) {
        self.view.userInteractionEnabled = false
        UIView.animateWithDuration(0.05, animations: {
            self.btnCreateChat.transform = CGAffineTransformMakeScale(1, 1)
        }) { (_) in
            self.performSegueWithIdentifier("createChatSegue", sender: sender)
            self.view.userInteractionEnabled = true
        }
    }
    
    private func animateNoChatsInfoInOut(hideInfo:Bool) {
        if vNoMyChats.hidden != hideInfo {
            self.vNoMyChats.hidden = false
            
            UIView.animateWithDuration(0.5, animations: {
                self.vNoMyChats.alpha = hideInfo ? 0.0 : 1.0
                }, completion: { (_) in
                    self.vNoMyChats.hidden = hideInfo
            })
        }
    }
    
    // MARK: - Loading Blic
    private func configLoadingBlicAnimation() {
        var animationArray: [UIImage] = []
        
        for index in 0...29 {
            animationArray.append(UIImage(named: "BlicMini_gray_\(index)")!)
        }
        
        ivLoadingBlic.animationImages = animationArray
        ivLoadingBlic.animationDuration = 1.0
        ivLoadingBlic.alpha = 0
    }
    
    private func animateBlicLoading(animate:Bool, showNoInternet: Bool) {
        if ivLoadingBlic.isAnimating() == animate {
            return
        }
        
        let finalAlpha: CGFloat = animate ? 1.0 : 0.0
        
        self.lblNoInternet.alpha = 0.0
        
        ivLoadingBlic.hidden = false
        
        if animate {
            ivLoadingBlic.startAnimating()
        }
        
        UIView.animateWithDuration(1.0, animations: {
            self.ivLoadingBlic.alpha = finalAlpha
            self.myChatsTableView.alpha = 1.0 - finalAlpha
            
        }) { (_) in
            
            self.ivLoadingBlic.hidden = !animate
            if !animate { self.ivLoadingBlic.stopAnimating() }
            
            self.showNoInternet(showNoInternet, afterDelay: 2.0)
        }
    }
    
    func showNoInternet(showNoInternet: Bool, afterDelay: NSTimeInterval) {
        
        let noInternetFinalAlpha: CGFloat = (showNoInternet && self.presenter.chatRoomsCount() == 0 && self.vNoMyChats.hidden) ? 1.0 : 0.0
        UIView.animateWithDuration(0.5, delay: afterDelay, options: [], animations: {
            self.lblNoInternet.alpha = noInternetFinalAlpha
            }, completion: { (_) in })
        
    }
    
    func setGHContextMenuView() {
        let contextMenu = GHContextMenuView()
        contextMenu.dataSource = self
        contextMenu.delegate = self
        
        let longPress = UILongPressGestureRecognizer(target: contextMenu, action: #selector(GHContextMenuView.longPressDetected(_:)))
        self.myChatsTableView.addGestureRecognizer(longPress)
    }
    
    // MARK: - Chat List changed
    func chatRoomsListChanged(insertedIdexes: [NSIndexPath], deletedIndexes: [NSIndexPath], reloadedIndexes: [NSIndexPath]) {
        myChatsTableView.beginUpdates()
        myChatsTableView.insertRowsAtIndexPaths(insertedIdexes, withRowAnimation: UITableViewRowAnimation.Automatic)
        myChatsTableView.deleteRowsAtIndexPaths(deletedIndexes, withRowAnimation: UITableViewRowAnimation.Automatic)
        myChatsTableView.reloadRowsAtIndexPaths(reloadedIndexes, withRowAnimation: UITableViewRowAnimation.None)
        myChatsTableView.endUpdates()
        
        self.animateNoChatsInfoInOut(self.presenter.chatRoomsCount() > 0) // Mostra ou esconde mensagem de my chats vazio
    }
    
    func moveToForeground(notification: NSNotification){
        presenter.reloadMyChatsList { (success, chatRoomsList) in
            if success {
                self.animateNoChatsInfoInOut(self.presenter.chatRoomsCount() > 0)
            }
            self.showNoInternet(!success, afterDelay: 0.0)
            
        }
    }
    
    
    // MARK: - TableView DataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = presenter.chatRoomsCount()
        return count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100.0
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MyChatsTableCell.kCellIdentifier) as! MyChatsTableCell
        
        cell.vCellContent.backgroundColor = presenter.chatRoomMainColor(indexPath)
        
        let urlsList = presenter.chatRoomThumbUrlList(indexPath)
        startPrefetchImagesThumb(urlsList)
        
        if let thumbUrl = urlsList.first {
            let optionInfo: KingfisherOptionsInfo = [
                .DownloadPriority(1.0),
                .BackgroundDecode,
                .ScaleFactor(0.5)
            ]
            cell.ivBackground.kf_setImageWithURL(thumbUrl, placeholderImage: nil, optionsInfo: optionInfo, progressBlock: nil, completionHandler: nil)
        }
        
        cell.lblChatName.text = presenter.chatRoomName(forIndex: indexPath)
        cell.lblChatParticipants.text = "\(presenter.chatRoomNumberOfParticipants(indexPath))"
        if let ownerPhotoUrl = presenter.chatRoomOwnerPhotoUrl(forIndex: indexPath) {
            cell.ivOwnerPhoto.kf_setImageWithURL(ownerPhotoUrl)
        }
        cell.lblOwnerName.text = presenter.chatRoomOwnerName(forIndex: indexPath)
        cell.showVerifiedBadge(presenter.chatRoomOwnerIsVerified(forIndex: indexPath))
        cell.blicupClock.updateBasedOnTime(presenter.chatRoomLastUpdate(indexPath))
        
        cell.showBadge(presenter.chatRoomHasNewMessages(indexPath))
        cell.setChatAsOver(presenter.isChatRoomOver(indexPath))
        cell.setOverText(presenter.chatOverText(indexPath))
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard self.presenter.isChatRoomOver(indexPath) == false else {
            let chatRoom = self.presenter.chatRoomAtIndex(indexPath)
            showAlertChatsOverOrUserRemoved(chatRoom)
            return
        }
        
        guard let pageViewController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("CoverController") as? ChatRoomsListHorizontalPageViewController else {
            return
        }
        
        guard let myChatsTableCell = tableView.cellForRowAtIndexPath(indexPath) as? MyChatsTableCell else {
            openCoverAtIndex(indexPath: indexPath, pageViewController: pageViewController)
            return
        }
        
        
        self.view.userInteractionEnabled = false
        myChatsTableCell.animateHighlightCell { (finished) in
            myChatsTableCell.animateUnhighlightCell({ (finished) in
                self.view.userInteractionEnabled = true
                self.openCoverAtIndex(indexPath: indexPath, pageViewController: pageViewController)
            })
        }
    }
    
    func openCoverAtIndex(indexPath indexPath: NSIndexPath, pageViewController: ChatRoomsListHorizontalPageViewController) {
        self.tabBarController?.tabBar.hidden = true
        let presenter = CoverChatRoomsListPresenter(withMyChats: true)
        presenter.currentIndex = indexPath
        pageViewController.initCover(coverPresenter: presenter)
        self.navigationController?.pushViewController(pageViewController, animated: true)
        
    }
    
    
    // MARK: - Image Prefetch
    func startPrefetchImagesThumb(urlsList:[NSURL]){
        let prefetcher = ImagePrefetcher(urls: urlsList)
        prefetcher.maxConcurrentDownloads = 20
        prefetcher.start()
    }
    
    // MARK: - GHContextMenu  Methods
    
    func shouldShowMenuAtPoint(point: CGPoint) -> Bool {
        
        guard let indexPath = self.myChatsTableView.indexPathForRowAtPoint(point) else {
            return false
        }
        
        return !self.presenter.isChatRoomOver(indexPath)
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
        
        guard let indexPath = self.myChatsTableView.indexPathForRowAtPoint(point) else {
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
        
        guard let indexPath = self.myChatsTableView.indexPathForRowAtPoint(point), myChatsCell = self.myChatsTableView.cellForRowAtIndexPath(indexPath) as? MyChatsTableCell else {
            return UIView()
        }
        
        myChatsCell.animateHighlightCell(nil)
        
        let viewForSnap = myChatsCell.snapshotViewAfterScreenUpdates(true)
        viewForSnap.frame = self.view.convertRect(myChatsCell.frame, fromView: self.myChatsTableView)
        
        return viewForSnap
    }
    
    func contextMenuWillHideforMenuAtPoint(point: CGPoint) {
        
        guard let indexPath = self.myChatsTableView.indexPathForRowAtPoint(point),
            let myChatsCell = self.myChatsTableView.cellForRowAtIndexPath(indexPath) as? MyChatsTableCell else {
                return
        }
        
        myChatsCell.animateUnhighlightCell(nil)
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
    
    // MARK: Action sheet
    
    func showReportActionShet(indexPath index: NSIndexPath) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let reportChatAction = UIAlertAction(title: NSLocalizedString("Report", comment: ""), style: .Default, handler: { (action) -> Void in
            self.showReportChatDialog(indexPath: index)
        })
        
        let leaveChatAction = UIAlertAction(title: NSLocalizedString("Leave Chat", comment: ""), style: .Default, handler: { (action) -> Void in
            self.showRemoveChatRoomOfInterestDialog(indexPath: index)
        })
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            //print("Cancel Button Pressed")
        })
        
        alertController.addAction(reportChatAction)
        alertController.addAction(leaveChatAction)
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
            //print("Cancel Button Pressed")
        })
        
        showAlert(title: self.presenter.reportChatDialogTitle(), message: presenter.reportChatDialogMessage(index), withActions: [reportAction, cancel], style: UIAlertControllerStyle.Alert)
    }
    
    private func showThanksForReportingDialog() {
        
        showAlert(title: self.presenter.thanksForReportingDialogTitle(), message: presenter.thanksForReportingDialogMessage())
    }
    
    private func showRemoveChatRoomOfInterestDialog(indexPath index : NSIndexPath) {
        
        let leaveAction = UIAlertAction(title: NSLocalizedString("Leave", comment: "Leave"), style: .Default) { (action) in
            
            self.presenter.removeChatRoomOfInterest(index, completionHandler: { (success) in
                if success {
                    
                } else {
                    // TODO: tratar caso de falha no leave chat
                }
            })
        }
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            //print("Cancel Button Pressed")
        })
        
        showAlert(title: presenter.removeChatRoomOfInterestDialogTitle(), message: presenter.removeChatRoomOfInterestDialogMessage(index), withActions: [leaveAction, cancel], style: UIAlertControllerStyle.Alert)
        
    }
    
    // MARK: - Trasition Protocol
    func snapshotViewToAnimateOnTrasition(chatIndex:NSIndexPath)->UIView {
        guard let selectedCell = myChatsTableView.cellForRowAtIndexPath(chatIndex) as? MyChatsTableCell else {
            return UIView()
        }
        
        let imageView = UIImageView(image: selectedCell.ivBackground.image)
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.backgroundColor = selectedCell.ivBackground.backgroundColor
        imageView.frame = self.view.convertRect(selectedCell.ivBackground.bounds, fromView: selectedCell.ivBackground)
        
        return imageView
    }
    
    func showSelectedChat(chatIndex:NSIndexPath)->CGRect {
        myChatsTableView.scrollToRowAtIndexPath(chatIndex, atScrollPosition: UITableViewScrollPosition.Middle, animated: false)
        
        var rect = myChatsTableView.rectForRowAtIndexPath(chatIndex)
        rect.size.height = rect.height - MyChatsTableCell.kVerticalOffset
        rect.origin.y = rect.origin.y + MyChatsTableCell.kVerticalOffset/2
        
        return self.view.convertRect(rect, fromView: myChatsTableView)
    }
    
    
    // MARK: - Prepare for segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "createChatSegue"{
            let touch = sender as! UIButton
            (segue as! OHCircleSegue).circleOrigin = CGPoint(x: touch.frame.midX, y: touch.frame.midY)
            
            let seguePoint = CGPoint(x: touch.frame.midX, y: touch.frame.midY + 20)
            
            if let destVC = segue.destinationViewController as? CreateChatRoomViewController{
                destVC.parentView = self
                destVC.cgPointBtnCreate = seguePoint
            }
        }
    }
}


class MyChatsTableCell: UITableViewCell {
    
    static let kCellIdentifier = "MyChatCell"
    static let kVerticalOffset:CGFloat = 10.0
    
    @IBOutlet weak var constrBadgeWidth: NSLayoutConstraint!
    @IBOutlet weak var vCellContent: UIView!
    @IBOutlet weak var ivBackground: BCGradientImageView!
    @IBOutlet weak var lblChatName: UILabel!
    @IBOutlet weak var lblChatParticipants: UILabel!
    @IBOutlet weak var ivOwnerPhoto: UIImageView!
    @IBOutlet weak var lblOwnerName: UILabel!
    @IBOutlet weak var blicupClock: BlicupClock!
    
    @IBOutlet weak var ivVerifiedBadge: UIImageView!
    @IBOutlet weak var constrivVerifiedBadgeWidth: NSLayoutConstraint!
    let kVerifiedBadgeWidth: CGFloat = 15
    
    @IBOutlet private weak var vOverChatOverlay: UIView!
    @IBOutlet private weak var lblOverRemovedText: CustomLabelChatOver!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        vCellContent.layer.cornerRadius = 4
        ivOwnerPhoto.layer.cornerRadius = ivOwnerPhoto.bounds.width/2
        
        lblOverRemovedText.layer.cornerRadius = lblOverRemovedText.bounds.height/2
        lblOverRemovedText.clipsToBounds = true
        
        ivBackground.runLoopMode = NSDefaultRunLoopMode
        ivBackground.needsPrescaling = false
        ivBackground.autoPlayAnimatedImage = true
        ivBackground.framePreloadCount = 2
        
        cleanCellData()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        ivBackground.kf_cancelDownloadTask()
        ivOwnerPhoto.kf_cancelDownloadTask()
        cleanCellData()
    }
    
    private func cleanCellData() {
        lblChatName.text = nil
        lblChatParticipants.text = nil
        lblOwnerName.text = nil
        ivBackground.image = nil
        ivOwnerPhoto.image = nil
        lblOverRemovedText.text = nil
        setChatAsOver(false)
    }
    
    func showBadge(show:Bool) {
        constrBadgeWidth.constant = show ? 10 : 0
    }
    
    func showVerifiedBadge(isVerified: Bool) {
        
        self.constrivVerifiedBadgeWidth.constant = isVerified ? kVerifiedBadgeWidth : 0
        self.ivVerifiedBadge.hidden = !isVerified
        self.layoutIfNeeded()
    }
    
    func setChatAsOver(isOver:Bool) {
        vOverChatOverlay.hidden = !isOver
        blicupClock.hidden = isOver
    }
    
    func setOverText(text:String?) {
        lblOverRemovedText.text = text
    }
    
    func animateHighlightCell(completionHandler:((finished:Bool)->Void)?) {
        UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.95, 0.95)
            }, completion: { (finished) in
                completionHandler?(finished: finished)
        })
    }
    
    func animateUnhighlightCell(completionHandler:((finished:Bool)->Void)?) {
        UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.transform = CGAffineTransformIdentity
            }, completion: { (finished) in
                completionHandler?(finished: finished)
        })
    }
}
