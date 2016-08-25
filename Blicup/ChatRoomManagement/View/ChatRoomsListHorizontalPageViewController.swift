//
//  ChatRoomsListHorizontalPageViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 30/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Kingfisher
import ReachabilitySwift


class ChatRoomsListHorizontalPageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDataSource, UITableViewDelegate, GHContextOverlayViewDataSource, GHContextOverlayViewDelegate, CoverChatRoomsListPresenterDelegate, UserProfileViewControllerDelegate, ChatRoomFetchResultPresenterDelegate, AlertControllerProtocol {
    
    private enum CollectionType:Int {
        case CHAT_ROOM = 1, PARTICIPANTS_PHOTOS = 2
    }
    
    enum ContextMenuItemSelected: Int {
        case MORE, SHARE
    }
    
    let BOTTOM_OVERLAY_MAX_HEIGHT: CGFloat = 310
    private var presenter: CoverChatRoomsListPresenter!
    var pullOffset = CGPointZero
    var lastTableOffset:CGFloat = 0
    var bottomOverlayTotalHeight: CGFloat = 0
    var showOnlyOneChat = false
    var cgPointBtnCreate: CGPoint?
    var parentView: UIViewController!
    private let kShowUserProfile = "showUserProfile"
    
    private var prefetcher: ImagePrefetcher!
    
    private var currentIndex = NSIndexPath(forItem: 0, inSection: 0) {
        didSet {
            presenter.currentIndex = currentIndex
        }
    }
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var btnShowParticipant: UIButton!
    @IBOutlet weak var constrTopContainer: NSLayoutConstraint!
    @IBOutlet weak var vTopOverlay: UIView!
    @IBOutlet weak var ivOwnerPhoto: UIImageView!
    @IBOutlet weak var lblOwnerName: UILabel!
    @IBOutlet weak var lblChatLocale: UILabel!
    private var topGradientLayer = CAGradientLayer()
    private var bottomGradientLayer = CAGradientLayer()
    
    @IBOutlet weak var pageControll: UIPageControl!
    @IBOutlet weak var constrPageControlBottom: NSLayoutConstraint!
    
    @IBOutlet weak var constrBottomOverlayHeight: NSLayoutConstraint!
    @IBOutlet weak var constrBottomContainer: NSLayoutConstraint!
    @IBOutlet weak var vBottomOverlay: UIView!
    @IBOutlet weak var lblChatRoomName: UILabel!
    @IBOutlet weak var bcTimer: BlicupClock!
    @IBOutlet weak var lblHashtags: UILabel!
    @IBOutlet weak var vLine: UIView!
    @IBOutlet weak var ivUserNumbersPlaceholder: UIImageView!
    @IBOutlet weak var lblNumberOfUsers: UILabel!
    @IBOutlet weak var cvParticipants: UICollectionView!
    @IBOutlet weak var btnEnterChat: UIButton!
    @IBOutlet weak var btnClose: UIButton!
    
    @IBOutlet weak var previewContainer: UIView!
    private var vMessagePreview: CoverMessageView?
    private var isAnimatingMessagePreview = false
    private var previewTimer:NSTimer?
    
    private var vSlideCoverTip: SlideCoverTipView!
    private var vSlideCoverImageTip: SwipeCoverImagesTipView!

    @IBOutlet weak var ivVerifiedBadge: UIImageView!
    @IBOutlet weak var constrivVerifiedBadgeWidth: NSLayoutConstraint!
    let kVerifiedBadgeWidth: CGFloat = 15
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.delegate = self
        presenter.presenterDelegate = self
        
        self.view.layoutIfNeeded()
        if let flowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.itemSize = self.collectionView.bounds.size
            self.collectionView.collectionViewLayout = flowLayout
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(socketConnected(_:)), name: LDTPWebSocketManagerNotification.SocketOpened.rawValue, object: nil)
        
        presenter.startUpdatingChat(currentIndex)
        setGHContextMenuView()
        
        configureTipUserDefault()
    }
    
    
    func socketConnected(notification: NSNotification) {
        presenter.startUpdatingChat(currentIndex)
    }
    
    
    func initCover(coverPresenter presenter:CoverChatRoomsListPresenter) {
        self.presenter = presenter
        currentIndex = presenter.currentIndex
    }
    
    func coverShowingIndex()->NSIndexPath {
        return presenter.currentIndex
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.hidden = true
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: true)
        
        if presenter.stillHasChats() {
            collectionView.scrollToItemAtIndexPath(currentIndex, atScrollPosition: UICollectionViewScrollPosition.None, animated: false)
        }
        
        setupSwipeNextChatTip(self.currentIndex)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        BlicupAnalytics.sharedInstance.mark_EnteredScreenChatCover()
        
        if presenter.stillHasChats() && (self.presentingViewController != nil || self.cgPointBtnCreate == nil) {
            setInitialOverlaysDataAndLayout()
        }
        else {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    
    deinit {
        presenter.stopUpdatingChat(currentIndex)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: LDTPWebSocketManagerNotification.SocketOpened.rawValue, object: nil)
    }
    
    //MARK: Tip Setup
    
    private func configureTipUserDefault() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.objectForKey(kSwipeCoverTipKey) == nil {
            let tipObject: [String : AnyObject] = ["hasPerformedTip" : false]
            userDefaults.setObject(tipObject, forKey: kSwipeCoverTipKey)
        }
        
        if userDefaults.objectForKey(kSwipeCoverImagesTipKey) == nil {
            let tipObject: [String : AnyObject] = ["hasPerformedTip" : false]
            userDefaults.setObject(tipObject, forKey: kSwipeCoverImagesTipKey)
        }
    }
    
    private func setupSwipeNextChatTip(index: NSIndexPath) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if let tipObject = userDefaults.objectForKey(kSwipeCoverTipKey) as? [String : AnyObject] {
            let hasPerformedTip = tipObject["hasPerformedTip"] as? Bool
            let chatRoom = self.presenter.chatRoomAtIndex(index)
            if !hasPerformedTip! && !(chatRoom.saved?.boolValue)! {
                if vSlideCoverTip == nil {
                    vSlideCoverTip = SlideCoverTipView(frame: self.view.frame)
                    vSlideCoverTip.center = self.view.center
                    view.addSubview(vSlideCoverTip)
                    vSlideCoverTip.startAnimation()
                }
            } else {
                setupSwipeNextImageTip(index)
            }
        }
    }
    
    private func setupSwipeNextImageTip(index: NSIndexPath) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let chatRoom = self.presenter.chatRoomAtIndex(index)
        if let tipImagesObject = userDefaults.objectForKey(kSwipeCoverImagesTipKey) as? [String : AnyObject] {
            let hasPerformedImagesCoverTip = tipImagesObject["hasPerformedTip"] as? Bool
            if !hasPerformedImagesCoverTip! && self.presenter.chatRoomPhotoCount(index) > 1{
                if vSlideCoverImageTip == nil && !(chatRoom.saved?.boolValue)! {
                    vSlideCoverImageTip = SwipeCoverImagesTipView(frame: self.view.frame)
                    vSlideCoverImageTip.center = self.view.center
                    view.addSubview(vSlideCoverImageTip)
                    vSlideCoverImageTip.startAnimation()
                }
            }
        }
    }
    
    func chatRoomsListChanged(insertedIdexes: [NSIndexPath], deletedIndexes: [NSIndexPath], reloadedIndexes: [NSIndexPath]) {
        collectionView.performBatchUpdates({  [weak self] in
            self?.collectionView.insertItemsAtIndexPaths(insertedIdexes)
            self?.collectionView.deleteItemsAtIndexPaths(deletedIndexes)
            
            //Retirado o reload, pois não seria necessário para atualizar nenhum conteúdo do chat (updateOverlaysWithChatRoom() faz isto). E ele estava relacionado ao bug "Ao entrar no cover, se eu arrastar rápido para exibir a próxima imagem (vertical), às vezes da uma travada na tela, continua na primeira imagem mas a bolinha do lado direito pula para segunda (como se fosse a segunda foto)".
            if let weakSelf = self {
                if weakSelf.presenter.stillHasChats() && weakSelf.currentIndex != weakSelf.presenter.currentIndex {
                    weakSelf.currentIndex = weakSelf.presenter.currentIndex
                    weakSelf.collectionView.scrollToItemAtIndexPath(weakSelf.currentIndex, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: false)
                }
            }
            
        }) {  [weak self] (finished) in
            if let weakSelf = self {
                if reloadedIndexes.contains(weakSelf.currentIndex) {
                    weakSelf.updateOverlaysWithChatRoom()
                }
            }
        }
    }
    
    
    // MARK: CollectionView Datasource
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if collectionView.tag == CollectionType.CHAT_ROOM.rawValue {
            let collectionCell = collectionView.dequeueReusableCellWithReuseIdentifier("CoverCell", forIndexPath: indexPath) as! ChatRoomCoverCell
            collectionCell.cellIndex = indexPath.item
            collectionCell.backgroundColor = presenter.chatRoomMainColor(indexPath)
            self.startPrefetchImagesChat()
            presenter.checkIfChatRoomRemovalOrDead(chatRoomIndex: currentIndex)
            
            if currentIndex.item != indexPath.item {
                if vSlideCoverTip != nil {
                    vSlideCoverTip.stopAnimation()
                    vSlideCoverTip = nil
                } else if vSlideCoverImageTip != nil {
                    vSlideCoverImageTip.removeFromSuperview()
                    vSlideCoverImageTip = nil
                }
            }
            return collectionCell
        }
        else {
            let collectionCell = collectionView.dequeueReusableCellWithReuseIdentifier("ParticipantPhotoCell", forIndexPath: indexPath)
            let ivPhoto = collectionCell.viewWithTag(1) as! UIImageView
            ivPhoto.layer.cornerRadius = ivPhoto.bounds.height/2
            
            // TODO: Tratar caso de nao conseguir pegar foto
            if let url = self.presenter.chatRoomParticipantPhotoURL(chatRoomIndex: currentIndex, participantIndex: indexPath.row) {
                ivPhoto.kf_setImageWithURL(url)
            }
            else {
                ivPhoto.image = nil
            }
            
            return collectionCell
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == CollectionType.CHAT_ROOM.rawValue {
            return self.presenter.chatRoomsCount()
        }
        else if presenter.stillHasChats() {
            return self.presenter.chatRoomParticipantsCount(collectionView.bounds.size, forIndex: currentIndex)
        }
        else {
            return 0
        }
    }
    
    
    
    // MARK: TableView Datasource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let chatRoomIndex = NSIndexPath(forItem: tableView.tag, inSection: 0)
        return presenter.chatRoomPhotoCount(chatRoomIndex)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return tableView.bounds.height
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("ChatPhotosCell") as? ChatRoomCoverPhotoCell
        
        if cell == nil {
            cell = ChatRoomCoverPhotoCell(reuseIdentifier: "ChatPhotosCell")
        }
        
        if indexPath.item > 0 {
            if self.vSlideCoverImageTip != nil {
                self.vSlideCoverImageTip.stopAnimation()
            }
        }
        
        let chatRoomIndex = NSIndexPath(forItem: tableView.tag, inSection: 0)
        
        let photoUrl = presenter.chatRoomPhotoUrl(chatIndex: chatRoomIndex, photoNumber: indexPath.row)
        
        if let thumbUrl = presenter.chatRoomThumbUrl(chatIndex: chatRoomIndex, photoNumber: indexPath.row) {
            //has thumb so get from cache
            KingfisherManager.sharedManager.retrieveImageWithURL( thumbUrl, optionsInfo: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
                // Previne que carregamentos demorados setem valores errados
                if chatRoomIndex.row == tableView.tag {
                    self.setupImage(cell!, photoUrl: photoUrl, image: image)
                }
            })
        }
        else {
            self.setupImage(cell!, photoUrl: photoUrl, image: nil)
        }
        
        return cell!
    }
    
    private func setupImage(cell:ChatRoomCoverPhotoCell, photoUrl : NSURL?, image: UIImage?) {
        guard let photoUrl = photoUrl else {
            return
        }
        
        if image == nil {
            cell.aivBackgroundPhoto.kf_setImageWithURL(photoUrl)
        }
        else {
            cell.aivBackgroundPhoto.kf_setImageWithURL(photoUrl, placeholderImage: image, optionsInfo: [], progressBlock: nil, completionHandler: nil)
        }
    }
    
    
    func startPrefetchImagesChat(){
        
        let urlsList = self.presenter.chatRoomPhotoUrlList(currentIndex)
        
        prefetcher = ImagePrefetcher(urls: urlsList)
        prefetcher.maxConcurrentDownloads = 15 // 3 chatrooms photo
        prefetcher.start()
        
    }
    
    // MARK: ChatRoomRemovalOrDead
    
    func chatRoomRemovalOrDead(chatRoom: ChatRoom) {
        
        showAlertChatsOverOrUserRemoved(chatRoom)
    }
    
    // MARK: - New messages preview
    func showMessagePreview(photo photoUrl:NSURL?, userID: String, user:String?, message:String?, isUpdating: Bool) {
        if !presenter.isBlockedUser(userID) && !isUpdating && !isAnimatingMessagePreview && !presenter.userIsBlockingMe(userID){
            isAnimatingMessagePreview = true
            
            let coverMessage = CoverMessageView.newCoverMessage()
            previewContainer.addSubview(coverMessage)
            
            if photoUrl != nil {
                coverMessage.ivPhoto.kf_setImageWithURL(photoUrl!)
            }
            coverMessage.lblUserName.text = user
            coverMessage.lblMessage.text = message
            coverMessage.layer.cornerRadius = 6
            
            coverMessage.frame = CGRectMake(0, previewContainer.bounds.height, previewContainer.bounds.width, 0)
            
            UIView.animateWithDuration(0.3, animations: {
                coverMessage.frame = self.btnEnterChat.bounds
                self.vMessagePreview?.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.95, 0.95)
                self.vMessagePreview?.alpha = 0.5
            }) { (finished) in
                self.vMessagePreview?.removeFromSuperview()
                self.vMessagePreview = coverMessage
                self.isAnimatingMessagePreview = false
                self.previewTimer?.invalidate()
                self.previewTimer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(self.removeMessagePreview), userInfo: nil, repeats: false)
            }
        }
    }
    
    func removeMessagePreview() {
        guard let preview = vMessagePreview where isAnimatingMessagePreview == false else {
            return
        }
        
        isAnimatingMessagePreview = true
        
        var frame = preview.frame
        frame.origin.y = previewContainer.bounds.height
        
        UIView.animateWithDuration(0.5, animations: {
            preview.frame = frame
        }) { (finished) in
            self.vMessagePreview = nil
            self.isAnimatingMessagePreview = false
        }
    }
    
    // MARK: - Overlays
    private func animateOverlaysIn() {
        UIView.animateWithDuration(0.2) {
            self.constrTopContainer.constant = 0
            self.constrBottomContainer.constant = 0
            self.view.layoutIfNeeded()
            
            self.bottomOverlayTotalHeight = self.vBottomOverlay.bounds.height
        }
    }
    
    private func animateOverlaysOut(completion:(()->Void)?) {
        isAnimatingMessagePreview = true
        previewTimer?.invalidate()
        
        UIView.animateWithDuration(0.2, animations: {
            self.constrTopContainer.constant = -(self.vTopOverlay.bounds.height + 20)
            self.constrBottomContainer.constant = -(self.vBottomOverlay.bounds.height)
            self.view.layoutIfNeeded()
            
        }) { (finished) in
            self.vMessagePreview?.removeFromSuperview()
            self.vMessagePreview = nil
            self.isAnimatingMessagePreview = false
            completion?()
        }
    }
    
    private func expandOverlays() {
        self.btnShowParticipant.enabled = true
        self.constrBottomOverlayHeight.constant = BOTTOM_OVERLAY_MAX_HEIGHT
        self.lblHashtags.alpha = 1
        self.vLine.alpha = 1
        self.ivUserNumbersPlaceholder.alpha = 1
        self.lblNumberOfUsers.alpha = 1
        self.cvParticipants.alpha = 1
        self.vBottomOverlay.layoutIfNeeded()
    }
    
    private func compressOverlays() {
        self.btnShowParticipant.enabled = false
        self.constrBottomOverlayHeight.constant = lblChatRoomName.bounds.height + btnEnterChat.bounds.height + 15
        self.lblHashtags.alpha = 0
        self.vLine.alpha = 0
        self.ivUserNumbersPlaceholder.alpha = 0
        self.lblNumberOfUsers.alpha = 0
        self.cvParticipants.alpha = 0
        self.vBottomOverlay.layoutIfNeeded()
    }
    
    private func updateOverlaysWithChatRoom() {
        // Top Overlay
        lblOwnerName.text = self.presenter.chatRoomOwnerName(forIndex: currentIndex)
        
        showVerifiedBadge(self.presenter.chatRoomOwnerIsVerified(forIndex: currentIndex))
        
        pageControll.numberOfPages = self.presenter.chatRoomPhotoCount(currentIndex)
        constrPageControlBottom.constant = CGFloat(5*pageControll.numberOfPages) + 72
        
        if let photoUrl = self.presenter.chatRoomOwnerPhotoUrl(forIndex: currentIndex) {
            ivOwnerPhoto.kf_setImageWithURL(photoUrl)
        }
        else {
            ivOwnerPhoto.image = nil
        }
        
        lblChatLocale.attributedText = self.presenter.chatRoomAddress(currentIndex)
        
        
        // Bottom Overlay
        lblChatRoomName.text = presenter.chatRoomName(forIndex: currentIndex)
        lblHashtags.text = presenter.chatRoomHashtags(forIndex: currentIndex)
        lblNumberOfUsers.text = "\(presenter.chatRoomNumberOfParticipants(currentIndex))"
        bcTimer.updateBasedOnTime(presenter.chatRoomLastUpdate(currentIndex))
        
        cvParticipants.reloadData()
    }
    
    @IBAction func btnClosePressed(sender: UIButton) {
        UIView.animateWithDuration(0.2, animations: {
            self.btnClose.transform = CGAffineTransformMakeScale(1, 1)
        }) { (_) in
            self.btnClose.enabled = false
            if self.showOnlyOneChat{
                if self.presenter.chatRoomsCount() == 1{
                    let segue = OHCircleSegue(identifier: "unwindOneShowChat", source: self, destination: self.parentView)
                    segue.circleOrigin = self.cgPointBtnCreate!
                    self.showOnlyOneChat = false
                    segue.perform()
                }
            }
            else {
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
    }
    
    @IBAction func btnDragExit(sender: AnyObject) {
        UIView.animateWithDuration(0.1) {
            self.btnClose.transform = CGAffineTransformMakeScale(1, 1)
        }
    }
    
    @IBAction func btnDragEnter(sender: AnyObject) {
        UIView.animateWithDuration(0.1) {
            self.btnClose.transform = CGAffineTransformMakeScale(0.8, 0.8)
        }
    }
    
    @IBAction func btnPressedDown(sender: AnyObject) {
        UIView.animateWithDuration(0.1) {
            self.btnClose.transform = CGAffineTransformMakeScale(0.8, 0.8)
        }
    }
    
    @IBAction func btnTouchCancel(sender: AnyObject) {
        UIView.animateWithDuration(0.1) {
            self.btnClose.transform = CGAffineTransformMakeScale(1, 1)
        }
    }
    
    
    func showVerifiedBadge(isVerified: Bool) {
        
        self.constrivVerifiedBadgeWidth.constant = isVerified ? kVerifiedBadgeWidth : 0
        self.ivVerifiedBadge.hidden = !isVerified
    }
    
    
    private func setInitialOverlaysDataAndLayout() {
        ivOwnerPhoto.layer.cornerRadius = ivOwnerPhoto.bounds.height/2
        previewContainer.viewWithTag(1)?.layer.cornerRadius = 6 // Seta a borda da view com a mensagem de entrada (view com tag 1)
        pageControll.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        
        let darkerColor = UIColor.blackColor().colorWithAlphaComponent(0.6).CGColor
        let clearColor = UIColor.clearColor().CGColor
        
        topGradientLayer.frame = vTopOverlay.bounds
        bottomGradientLayer.frame = CGRectMake(0, 0, vBottomOverlay.bounds.width, BOTTOM_OVERLAY_MAX_HEIGHT+80)
        
        topGradientLayer.colors = [darkerColor, clearColor]
        topGradientLayer.locations = [0.0, 1.0]
        vTopOverlay.layer.insertSublayer(topGradientLayer, atIndex: 0)
        
        bottomGradientLayer.colors = [clearColor, darkerColor, darkerColor]
        bottomGradientLayer.locations = [0.0, 0.35, 1.0]
        vBottomOverlay.layer.insertSublayer(bottomGradientLayer, atIndex: 0)
        
        vTopOverlay.hidden = false
        vBottomOverlay.hidden = false
        
        updateOverlaysWithChatRoom()
        
        self.constrTopContainer.constant = -(self.vTopOverlay.bounds.height + 20)
        self.constrBottomContainer.constant = -(self.vBottomOverlay.bounds.height)
        self.view.layoutIfNeeded()
        
        animateOverlaysIn()
    }
    
    @IBAction func didTapChatOwner(sender: UIButton) {
        
        if !presenter.isLoggedUserChatOwner(chatRoomIndex: self.currentIndex) && !presenter.isBlockingMe(chatRoomIndex: self.currentIndex) {
            let user = presenter.chatRoomOwner(self.currentIndex)
            self.performSegueWithIdentifier(kShowUserProfile, sender: user)
        }
    }
    
    
    // MARK: Scroll View
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView is UITableView {
            guard scrollView.contentOffset.y >= 0 else {
                return
            }
            
            guard scrollView.contentOffset.y <= (scrollView.contentSize.height - scrollView.bounds.height) else {
                UIView.animateWithDuration(0.2, animations: {
                    self.expandOverlays()
                })
                return
            }
            
            let initialPage = scrollView.contentOffset.y/scrollView.bounds.height
            pageControll.currentPage = Int(floor(initialPage+0.5))
            
            let compressedHeight = lblChatRoomName.bounds.height + btnEnterChat.bounds.height + 15
            let diff = BOTTOM_OVERLAY_MAX_HEIGHT - compressedHeight
            
            let deltaOffset = lastTableOffset - scrollView.contentOffset.y
            var finalHeight = self.constrBottomOverlayHeight.constant + deltaOffset
            
            if finalHeight < compressedHeight {
                finalHeight = compressedHeight
            }
            else if finalHeight > BOTTOM_OVERLAY_MAX_HEIGHT {
                finalHeight = BOTTOM_OVERLAY_MAX_HEIGHT
            }
            
            let finalAlpha = (finalHeight - compressedHeight)/diff
            
            self.constrBottomOverlayHeight.constant = finalHeight
            self.lblHashtags.alpha = finalAlpha
            self.vLine.alpha = finalAlpha
            self.ivUserNumbersPlaceholder.alpha = finalAlpha
            self.lblNumberOfUsers.alpha = finalAlpha
            self.cvParticipants.alpha = finalAlpha
            
            lastTableOffset = scrollView.contentOffset.y
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if let collectionView = scrollView as? UICollectionView {
            let newIndex = Int(collectionView.contentOffset.x/collectionView.bounds.width)
            
            if newIndex != currentIndex.item {
                
                presenter.stopUpdatingChat(currentIndex)
                
                let newIndexPath = NSIndexPath(forItem: newIndex, inSection: 0)
                setupSwipeNextChatTip(newIndexPath)
                currentIndex = newIndexPath
                presenter.startUpdatingChat(newIndexPath)
                
                updateOverlaysWithChatRoom()
                expandOverlays()
            } else {
                setupSwipeNextChatTip(currentIndex)
            }
            
            animateOverlaysIn()
        }
        else {
            let compressedHeight = lblChatRoomName.bounds.height + btnEnterChat.bounds.height + 15
            let overlayHeightDiff = vBottomOverlay.bounds.height - compressedHeight
            
            if overlayHeightDiff < (bottomOverlayTotalHeight - compressedHeight)/2 {
                UIView.animateWithDuration(0.2, animations: {
                    self.compressOverlays()
                })
            }
            else {
                UIView.animateWithDuration(0.2, animations: {
                    self.expandOverlays()
                })
            }
        }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if scrollView is UICollectionView {
            animateOverlaysOut(nil)
        }
    }
    
    func scrollViewWillBeginDecelerating(scrollView : UIScrollView) {
        if scrollView.contentOffset.x < -50 || scrollView.contentOffset.y < -50 {
            if self.showOnlyOneChat{
                if self.presenter.chatRoomsCount() == 1{
                    let segue = OHCircleSegue(identifier: "unwindOneShowChat", source: self, destination: self.parentView)
                    segue.circleOrigin = self.cgPointBtnCreate!
                    self.showOnlyOneChat = false
                    segue.perform()
                    
                }
            }
            else {
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
    }
    
    // MARK: Go to ChatRoom
    @IBAction func enterChatPressed(sender: UIButton) {
        if let chatController = self.storyboard?.instantiateViewControllerWithIdentifier("ChatRoomViewController") as? ChatRoomViewController {
            self.animateOverlaysOut({
                chatController.setChatRoom(self.presenter.chatRoomAtIndex(self.currentIndex))
                
                CATransaction.begin()
                CATransaction.setCompletionBlock({
                    if self.presenter.isLoadingMessageChats {
                        self.presenter.messagesDelegate = chatController
                        chatController.animateLoadingMessages()
                    }
                })
                self.navigationController?.pushViewController(chatController, animated: false)
                CATransaction.commit()
            })
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
        
        showAlert(title: presenter.reportChatDialogTitle(), message: presenter.reportChatDialogMessage(index), withActions: [reportAction, cancel], style: UIAlertControllerStyle.Alert)
    }
    
    private func showThanksForReportingDialog() {
        
        showAlert(title: presenter.thanksForReportingDialogTitle(), message: presenter.thanksForReportingDialogMessage())
    }
    
    
    // MARK: - GHContextMenu  Methods
    func setGHContextMenuView() {
        let contextMenu = GHContextMenuView()
        contextMenu.dataSource = self
        contextMenu.delegate = self
        
        let longPress = UILongPressGestureRecognizer(target: contextMenu, action: #selector(GHContextMenuView.longPressDetected(_:)))
        self.collectionView.addGestureRecognizer(longPress)
    }
    
    func shouldShowMenuAtPoint(point: CGPoint) -> Bool {
        let indexPath = self.collectionView.indexPathForItemAtPoint(point)
        var cell:UICollectionViewCell?
        
        if let indexPath = indexPath {
            cell = self.collectionView.cellForItemAtIndexPath(indexPath)
        }
        
        return cell != nil
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
            
        default:
            break
        }
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
    
    // MARK : UserProfileViewControllerDelegate
    func presentUserProfileCardFromSelectedUser(user: User) {
        self.performSegueWithIdentifier(kShowUserProfile, sender: user)
    }
    
    // MARK: - Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showPreviewParticipants"{
            if let vDestination = segue.destinationViewController as? ChatRoomTalkInfoViewController {
                let chat = self.presenter.chatRoomAtIndex(self.currentIndex)
                vDestination.chatRoomID = chat.chatRoomId!
                vDestination.transitioningDelegate = vDestination
                vDestination.modalPresentationStyle = .Custom
            }
        } else if segue.identifier == kShowUserProfile, let vcUserProfile = segue.destinationViewController as? UserProfileViewController{
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
            //            dim(.Out, speed: 0.3)
        }
    }
}