//
//  UserProfileViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 17/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Kingfisher

protocol UserProfileViewControllerDelegate: class {
    func presentUserProfileCardFromSelectedUser(user: User)
}

class UserProfileViewController: UIViewController, UIScrollViewDelegate, UIViewControllerTransitioningDelegate, FollowViewControllerDelegate, AlertControllerProtocol {
    
    enum CurrentSelectedIndex: Int {
        case FOLLOWERS
        case FOLLOWING
    }
    
    enum ReloadList: Int {
        case FOLLOWERS, FOLLOWING, ALL
    }
    
    
    var presenter: UserProfileCardPresenter!
    let swipeInteractionTransition = UserProfileInteractiveTransition()
    private let userProfileAnimationTransition = AlphaVerticalSlideTransition()
    
    weak var delegate: UserProfileViewControllerDelegate?
    
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        // The view controllers will be shown in this order
        return [self.newViewController("FollowerVC"),
                self.newViewController("FolloweeVC")]
    }()
    
    
    @IBOutlet weak var vUserProfileCard: UIView!
    @IBOutlet weak var constrUserProfileCardHeight: NSLayoutConstraint!
    
    @IBOutlet weak var btnClose: BCCloseButton!
    @IBOutlet weak var vUserProfileInfo: UIView!
    @IBOutlet weak var ivPhoto: UIImageView!
    @IBOutlet weak var btnUsername: UIButton!
    @IBOutlet weak var lblLikes: UILabel!
    @IBOutlet weak var lblBio: UILabel!
    @IBOutlet weak var constrUserProfileInfoHeight: NSLayoutConstraint!
    @IBOutlet weak var constrUserBioHeight: NSLayoutConstraint!
    
    // Labels top Space
    @IBOutlet weak var constrIVPhotoTop: NSLayoutConstraint!
    @IBOutlet weak var constrLblLikesTopToIvPhoto: NSLayoutConstraint!
    @IBOutlet weak var constrLblBioTopToLikes: NSLayoutConstraint!
    @IBOutlet weak var constrLblBioBottom: NSLayoutConstraint!
    
    @IBOutlet weak var constrBtnUsernameToTop: NSLayoutConstraint!
    
    @IBOutlet weak var vButtonsContainer: UIView!
    @IBOutlet weak var btnFollowers: UIButton!
    @IBOutlet weak var btnFollowing: UIButton!
    
    @IBOutlet weak var vButtonFollow: UIView!
    @IBOutlet weak var btnBlock: NonHighlightingButton!
    @IBOutlet weak var btnFollow: NonHighlightingButton!
    @IBOutlet weak var constrBtnFollowHeight: NSLayoutConstraint!
    
    @IBOutlet weak var vTopLayout: UIView!
    
    @IBOutlet weak var vScrollViewContainer: UIView!
    @IBOutlet weak var ivSelectedBtnIndicator: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var constrbtnSelectedIndicatorIVLeading: NSLayoutConstraint!
    
    @IBOutlet weak var ivVerifiedBadge: UIImageView!
    @IBOutlet weak var constrivVerifiedBadgeWidth: NSLayoutConstraint!
    
    
    private var kvUserProfileInfoDefaultHeight: CGFloat = 200
    private var kvUserProfileCardDefaultHeight: CGFloat = 315
    private let kvUserProfileCardDefaultShowingListHeight: CGFloat = screenHeight - 120
    private let kvBtnFollowDefaultHeight: CGFloat = 65
    private var kbtnUsernameTopDefaultConstr: CGFloat = 111
    
    private var hasCalculatedInitialHeight = false
    
    let kVerifiedBadgeWidth: CGFloat = 15
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        swipeInteractionTransition.wireToViewController(self)
        updateUserInfoData()
        configureView()
        adjustFollowBlockBtns()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        BlicupAnalytics.sharedInstance.mark_EnteredScreenUserProfile()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isBeingDismissed() {
            NSNotificationCenter.defaultCenter().postNotificationName("UserProfileClosed", object: nil)
        }
    }
    
    func updateUserInfoData() {
        
        presenter.updateUserInfoData { (success) in
            self.updateCardData()
            self.setUserBlocked(self.presenter.isCurrentUserBlocked())
            self.reloadAndUpdateListsUserProfileCard(ReloadList: UserProfileViewController.ReloadList.ALL, onlyReload: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !hasCalculatedInitialHeight {
            hasCalculatedInitialHeight = true
            setDefaultCardHeight()
        }
    }
    
    func configureView() {
        ivPhoto.kf_showIndicatorWhenLoading = true
        
        ivPhoto.layer.cornerRadius = ivPhoto.frame.width/2
        ivPhoto.layer.masksToBounds = true
        vUserProfileCard.layer.cornerRadius = 10
        vUserProfileCard.layer.masksToBounds = true
        vUserProfileCard.clipsToBounds = true
        
        updateCardData()
    }
    
    func updateCardData() {
        configureInitialButtons()
        btnUsername.setTitle(presenter.username(), forState: .Normal)
        btnUsername.enabled = false
        
        if lblBio.text != presenter.bio() {
            setDefaultCardHeight()
        }
        
        showVerifiedBadge()
        
        lblBio.text = presenter.bio()
        lblLikes.text = "\(presenter.numberOfLikes()) 👍"
        
        if let photoUrl = presenter.photoUrl() {
            ivPhoto.kf_setImageWithURL(photoUrl)
        }
    }
    
    func showVerifiedBadge() {
        
        let isVerified = presenter.isVerifiedUser()
        self.constrivVerifiedBadgeWidth.constant = isVerified ? kVerifiedBadgeWidth : 0
        self.ivVerifiedBadge.hidden = !isVerified
    }

    func setDefaultCardHeight() {
        
        // Calculating height from user profile card
        constrUserBioHeight.constant = presenter.heightForUserBio(constrainedToWidth: vUserProfileCard.bounds.width)
        
        if constrUserBioHeight.constant == 0 {
            constrLblBioBottom.constant = 0
            constrLblBioTopToLikes.constant = 0
        }
        
        kbtnUsernameTopDefaultConstr = constrBtnUsernameToTop.constant
        
        let viewsTopSpaces = constrIVPhotoTop.constant + constrLblLikesTopToIvPhoto.constant + constrLblBioTopToLikes.constant + constrLblBioBottom.constant
        
        let infoCardHeight = ivPhoto.frame.height + lblLikes.frame.height + constrUserBioHeight.constant + viewsTopSpaces
        kvUserProfileInfoDefaultHeight = infoCardHeight
        
        let defaultUserProfileCardHeight = kvUserProfileInfoDefaultHeight + kvBtnFollowDefaultHeight + vButtonsContainer.frame.height
        kvUserProfileCardDefaultHeight = defaultUserProfileCardHeight
        
        constrUserProfileCardHeight.constant = kvUserProfileCardDefaultHeight
        constrUserProfileInfoHeight.constant = kvUserProfileInfoDefaultHeight
        self.view.layoutIfNeeded()
        
    }
    
    func configureInitialButtons() {
        
        let titleNumberFollowers = self.presenter.followersText()
        let titleNumberFollowing = self.presenter.followeeText()
        
        let subtitleFollowers = NSLocalizedString("Followers", comment: "Followers")
        let subtitleFollowing = NSLocalizedString("Following", comment: "Following")
        
        btnFollowers.tag = CurrentSelectedIndex.FOLLOWERS.rawValue
        btnFollowing.tag = CurrentSelectedIndex.FOLLOWING.rawValue
        
        setAttributedTextAtButton(btnFollowers, title: titleNumberFollowers, subtitle: subtitleFollowers, forState: .Normal)
        setAttributedTextAtButton(btnFollowing, title: titleNumberFollowing, subtitle: subtitleFollowing, forState: .Normal)
        setAttributedTextAtButton(btnFollowers, title: titleNumberFollowers, subtitle: subtitleFollowers, color: UIColor.blicupPink(), forState: .Selected)
        setAttributedTextAtButton(btnFollowing, title: titleNumberFollowing, subtitle: subtitleFollowing, color: UIColor.blicupPink(), forState: .Selected)
    }
    
    func setAttributedTextAtButton(button: UIButton, title: String, subtitle: String, color: UIColor = UIColor.blackColor(), forState state: UIControlState) {
        
        let attrFontDefault = [NSFontAttributeName : UIFont(name: "SFUIText-Regular", size: 16)!, NSForegroundColorAttributeName : color]
        let attrFontTitle = [NSFontAttributeName : UIFont(name: "SFUIText-Bold", size: 18)!]
        
        let attrString = NSMutableAttributedString(string: "\(title)\n\(subtitle)" , attributes: attrFontDefault)
        attrString.addAttributes(attrFontTitle, range: NSRange(location: 0, length: title.length))
        
        button.setAttributedTitle(attrString, forState: state)
        button.titleLabel?.textAlignment = NSTextAlignment.Center
    }
    
    
    func adjustFollowBlockBtns() {
        btnFollow.layer.cornerRadius = 13
        btnBlock.layer.cornerRadius = 13
        
        let title = NSLocalizedString("Follow", comment: "Follow")
        btnFollow.layer.borderColor = UIColor.blicupGray2().CGColor
        btnFollow.layer.borderWidth = 3.0
        btnFollow.setTitle(title, forState: .Normal)
        
        let titleSelected = NSLocalizedString("Following", comment: "Following")
        
        btnFollow.setTitle(titleSelected, forState: .Selected)
        btnFollow.setBackgroundColor(UIColor.blicupPink(), forState: .Selected)
        
        if let userId = presenter.userId() {
            let isBlocked = presenter.isUserBlocked(userId)
            setUserBlocked(isBlocked)
        }
    }
    
    func setUserBlocked(blocked:Bool) {
        btnFollow.hidden = blocked
        btnBlock.hidden = !blocked
        
        if let userId = presenter.userId() {
            let didFollow = presenter.didFollowUser(userId)
            setFollowingUser(didFollow)
        }
    }
    
    func setFollowingUser(following:Bool) {
        btnFollow.layer.borderColor = following ? UIColor.blicupPink().CGColor : UIColor.blicupGray2().CGColor
        btnFollow.selected = following
    }
    
    // MARK: Actions
    
    @IBAction func optionsPressed(sender: AnyObject) {
        showActionSheet()
    }
    
    @IBAction func closePressed(sender: AnyObject) {
        UIView.animateWithDuration(0.1, animations: {
            self.btnClose.transform = CGAffineTransformMakeScale(1, 1)
        }) { (_) in
            self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    
    @IBAction func followPressed(sender: UIButton) {
       
        if let userId = self.presenter.userId() {
            if self.presenter.didFollowUser(userId) {
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
                let unblock = UIAlertAction(title: NSLocalizedString("Unfollow", comment: "") , style: .Default, handler: { (action) -> Void in
                    
                    self.followUnfollowUser(userId: userId, withSender: sender)
                })
                
                let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
                    
                })
                
                if #available(iOS 9.0, *) {
                    unblock.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
                    cancel.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
                }
                
                alertController.addAction(unblock)
                alertController.addAction(cancel)
                
                self.presentViewController(alertController, animated: true, completion: nil)
                
                alertController.view.tintColor = UIColor.blicupPink()
                
            } else {
                
                self.followUnfollowUser(userId: userId, withSender: sender)
            }
        }
        
    }
    
    func followUnfollowUser(userId userId: String, withSender sender: UIButton) {
        
        sender.userInteractionEnabled = false
        
        self.setFollowingUser(!self.presenter.didFollowUser(userId))
        
        self.presenter.followUnfollowUserWithId(userId, completionHandler: { (success, didFollowUser) in
            
            if !success {
                self.alertNoInternet()
                self.setFollowingUser(!didFollowUser)
            }
            
            self.updateCardData()
            self.reloadAndUpdateListsUserProfileCard(ReloadList: UserProfileViewController.ReloadList.FOLLOWERS, onlyReload: false)
            
            sender.userInteractionEnabled = true
        })
    }
    
    
    func reloadAndUpdateListsUserProfileCard(ReloadList reloadList: ReloadList, onlyReload: Bool) {
        
        var vcFollowers = FollowerViewController()
        var vcFollowee = FolloweeViewController()
        
        for vc in orderedViewControllers {
            
            if vc.isKindOfClass(FollowerViewController) {
                vcFollowers = vc as! FollowerViewController
                
            } else if vc.isKindOfClass(FolloweeViewController) {
                vcFollowee = vc as! FolloweeViewController
            }
        }
        
        switch reloadList {
            
        case .FOLLOWERS:
            
            if onlyReload {
                vcFollowers.reloadVisibleCells()
            } else {
                vcFollowers.updateDataSource()
            }
            
            break
        case .FOLLOWING:
            
            if onlyReload {
                vcFollowee.reloadVisibleCells()
            } else {
                vcFollowee.updateDataSource()
            }
                
            break
        case .ALL:
            if onlyReload {
                vcFollowers.reloadVisibleCells()
                vcFollowee.reloadVisibleCells()
            } else {
                vcFollowers.updateDataSource()
                vcFollowee.updateDataSource()
            }
            
            break
        }
    }
    
    @IBAction func blockPressed(sender: UIButton) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let unblock = UIAlertAction(title: NSLocalizedString("Unblock", comment: "") , style: .Default, handler: { (action) -> Void in
            self.presenter.blockUnblockUser { (success) in
                if !success{
                    self.setUserBlocked(true)
                    self.alertNoInternet()
                }
                self.updateCardData()
                self.reloadAndUpdateListsUserProfileCard(ReloadList: UserProfileViewController.ReloadList.ALL, onlyReload: true)
            }
            self.setUserBlocked(false)
        })
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            
        })
        
        if #available(iOS 9.0, *) {
            unblock.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
            cancel.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
        }
        
        alertController.addAction(unblock)
        alertController.addAction(cancel)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
        alertController.view.tintColor = UIColor.blicupPink()
        
    }
    
    @IBAction func showListsContainer(sender: UIButton) {
        
        let showingList = !sender.selected
        
        sender.selected = showingList
        btnUsername.enabled = showingList
        
        if !presenter.hasShownTheList {
            presenter.currentIndex = sender.tag
            instantiateViewControllers(startAtIndex: sender.tag)
        } else {
            scrollToPageIndex(sender.tag, animated: true)
        }
        
        configureCurrentButtonColor(sender.tag)
        let endAlpha: CGFloat = showingList ? 1.0 : 0.0
        let endUserProfileCardHeight = showingList ? kvUserProfileCardDefaultShowingListHeight : kvUserProfileCardDefaultHeight
        let endUserProfileInfoHeight = showingList ? vTopLayout.frame.height : kvUserProfileInfoDefaultHeight
        let endBtnFollowHeight = showingList ? 0 : kvBtnFollowDefaultHeight
        let endTransform = showingList ? CGAffineTransformScale(CGAffineTransformIdentity, 0.2, 0.2) : CGAffineTransformIdentity
        let endBtnUsernameTopSpace = showingList ? 15 : kbtnUsernameTopDefaultConstr
        
        vUserProfileInfo.hidden = false
        
        UIView.animateWithDuration(0.4, animations: {
            
            self.constrBtnFollowHeight.constant = endBtnFollowHeight
            self.constrUserProfileInfoHeight.constant = endUserProfileInfoHeight
            self.constrUserProfileCardHeight.constant = endUserProfileCardHeight
            self.constrBtnUsernameToTop.constant = endBtnUsernameTopSpace
            
            self.vUserProfileInfo.alpha = 1.0 - endAlpha
            self.ivPhoto.alpha = 1.0 - endAlpha
            self.lblLikes.alpha = 1.0 - endAlpha
            self.lblBio.alpha = 1.0 - endAlpha
            
            self.ivPhoto.transform = endTransform
            self.lblLikes.transform = endTransform
            self.lblBio.transform = endTransform
            
            self.view.layoutIfNeeded()
            
        }) { (finished) in
            self.vUserProfileInfo.hidden = showingList
        }
    }
    
    @IBAction func usernamePressed(sender: AnyObject) {
        
        var selectedButton: UIButton?
        if btnFollowers.selected {
            selectedButton = btnFollowers
        } else if btnFollowing.selected {
            selectedButton = btnFollowing
        }
        
        if let selectedButton = selectedButton {
            showListsContainer(selectedButton)
        }
    }
    
    func configureCurrentButtonColor(index: Int) {
        
        switch index {
            
        case CurrentSelectedIndex.FOLLOWERS.rawValue:
            
            if btnFollowers.selected {
                btnFollowing.selected = !btnFollowers.selected
            }
            break
            
        case CurrentSelectedIndex.FOLLOWING.rawValue:
            
            if btnFollowing.selected {
                btnFollowers.selected = !btnFollowing.selected
            }
            break
            
        default:
            btnFollowing.selected = false
            btnFollowers.selected = false
            break
        }
    }
    
    func configureCurrentButtonColorScrolling(index: Int) {
        btnFollowing.selected = index == CurrentSelectedIndex.FOLLOWING.rawValue ? true : false
        btnFollowers.selected = !btnFollowing.selected
    }
    
    func updateBtnSelectedIndicator(positionX: CGFloat) {
        
        constrbtnSelectedIndicatorIVLeading.constant = btnFollowers.center.x + positionX - ivSelectedBtnIndicator.bounds.width/2
    }
    
    // MARK: Action Sheet
    func showActionSheet() {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let reportAction = UIAlertAction(title: NSLocalizedString("Report", comment: ""), style: .Default, handler: { (action) -> Void in
            
            self.showReportDialog()
        })
        
        if #available(iOS 9.0, *) {
            reportAction.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
        }
        alertController.addAction(reportAction)
        
        if let title = presenter.blockBtnTitle() {
            let blockAction = UIAlertAction(title: title, style: .Default, handler: { (action) -> Void in
                if !self.presenter.isCurrentUserBlocked() {
                    self.showBlockDialog()
                }
                else {
                    self.presenter.blockUnblockUser({ (success) in
                        self.updateCardData()
                        self.reloadAndUpdateListsUserProfileCard(ReloadList: UserProfileViewController.ReloadList.ALL, onlyReload: false)
                    })
                    self.setUserBlocked(self.presenter.isCurrentUserBlocked())
                }
            })
            
            if #available(iOS 9.0, *) {
                blockAction.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
            }
            alertController.addAction(blockAction)
        }
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            print("Cancel Button Pressed")
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
    
    private func alertNoInternet(){
        let alert = UIAlertController(title:NSLocalizedString("NoInternetTitle", comment: "No internet") , message:NSLocalizedString("NoInternetMessage", comment: "Check your network connection and try again"), preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func showBlockDialog() {
        
        var alertActions = [UIAlertAction]()
        
        if let title = presenter.blockBtnTitle() {
            let blockAction = UIAlertAction(title: title, style: .Default, handler: { (action) -> Void in
                self.presenter.blockUnblockUser({ (success) in
                    if !success{
                        self.alertNoInternet()
                    }
                    self.updateCardData()
                    self.reloadAndUpdateListsUserProfileCard(ReloadList: UserProfileViewController.ReloadList.ALL, onlyReload: false)
                })
                self.setUserBlocked(self.presenter.isCurrentUserBlocked())
            })
            
            alertActions.append(blockAction)
        }
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            print("Cancel Button Pressed")
        })
        
        alertActions.append(cancel)
        
        showAlert(title: presenter.blockDialogTitle(), message: presenter.blockDialogMessage(), withActions: alertActions, style: UIAlertControllerStyle.Alert)
        
    }
    
    private func showReportDialog() {
        
        
        let reportAction = UIAlertAction(title: NSLocalizedString("Report", comment: "Report"), style: .Default) { (action) in
            
            self.presenter.reportUser({ (success) in
                if !success{
                    self.alertNoInternet()
                } else{
                    self.showThanksForReportingDialog()
                }
            })
        }
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            print("Cancel Button Pressed")
        })
        
        showAlert(title: presenter.reportUserDialogTitle(), message: presenter.reportUserDialogMessage(), withActions: [reportAction, cancel], style: UIAlertControllerStyle.Alert)
        
    }
    
    private func showThanksForReportingDialog() {
        
        showAlert(title: presenter.thanksForReportingDialogTitle(), message: presenter.thanksForReportingDialogMessage())
    }
    
    
    // MARK: ScrollView Controllers
    
    func instantiateViewControllers(startAtIndex index: Int) {
        
        var idx: Int = 0
        
        let width = vUserProfileCard.bounds.width
        let height =  scrollView.frame.height
        
        let numberOfPages = CGFloat(orderedViewControllers.count)
        scrollView!.contentSize = CGSizeMake(numberOfPages*width, height)
        
        for viewController in orderedViewControllers {
            
            // index is the index within the array
            // participant is the real object contained in the array
            addChildViewController(viewController)
            let originX: CGFloat = CGFloat(idx) * width
            viewController.view.frame = CGRectMake(originX, 0, width, height)
            scrollView!.addSubview(viewController.view)
            viewController.didMoveToParentViewController(self)
            idx += 1
        }
        presenter.hasShownTheList = true
        var positionX = index == CurrentSelectedIndex.FOLLOWERS.rawValue ? btnFollowers.center.x : btnFollowing.center.x
        positionX = positionX - ivSelectedBtnIndicator.bounds.width/2
        constrbtnSelectedIndicatorIVLeading.constant = positionX
        scrollToPageIndex(index, animated: false)
        
    }
    
    
    private func newViewController(name: String) -> UIViewController {
        
        let viewController = UIStoryboard(name: "Settings", bundle: nil).instantiateViewControllerWithIdentifier(name)
        
        guard let userId = presenter.user.userId else {
            return UIViewController()
        }
        
        if let followerVC = viewController as? FollowerViewController {
            
            let followerPresenter = FollowListPresenter(withUserId: userId)
            followerVC.delegate = self
            followerVC.followPresenter = followerPresenter
            followerVC.isUserProfileCard = true
            
        } else if let followeeVC = viewController as? FolloweeViewController {
            
            let followeePresenter = FollowListPresenter(withUserId: userId)
            followeeVC.delegate = self
            followeeVC.followPresenter = followeePresenter
            followeeVC.isUserProfileCard = true
        }
        
        return viewController
    }
    
    // MARK: ScrollView Delegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        // X scroll
        let numberOfPages = CGFloat(orderedViewControllers.count)
        let percentage: CGFloat = scrollView.contentOffset.x / scrollView.contentSize.width
        let positionX : CGFloat = percentage * (scrollView.contentSize.width/numberOfPages)
        
        updateBtnSelectedIndicator(positionX)
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let currentPage = scrollView.currentPage
        self.configureCurrentButtonColorScrolling(currentPage)
    }
    
    func scrollToPageIndex(index:Int, animated: Bool) {
        
        if index >= 0 && index < orderedViewControllers.count  {
            var frame = scrollView.frame;
            frame.origin.x = frame.size.width * CGFloat(index)
            frame.origin.y = 0
            scrollView.scrollRectToVisible(frame, animated: animated)
        }
    }
    
    // MARK: FollowViewControllerDelegate
    func presentUserProfileCardFromSelectedUser(user: User) {
        self.delegate?.presentUserProfileCardFromSelectedUser(user)
    }
    
    func followUnfollowOnUserTableCellPressed(viewController: UIViewController) {
        
        if viewController.isMemberOfClass(FolloweeViewController) {
            self.reloadAndUpdateListsUserProfileCard(ReloadList: UserProfileViewController.ReloadList.FOLLOWERS, onlyReload: true)
        } else if viewController.isMemberOfClass(FollowerViewController) {
            self.reloadAndUpdateListsUserProfileCard(ReloadList: UserProfileViewController.ReloadList.FOLLOWING, onlyReload: true)
        }
    }
    
    // MARK: Transition delegate
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return userProfileAnimationTransition
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return userProfileAnimationTransition
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return swipeInteractionTransition.interactionInProgress ? swipeInteractionTransition : nil
    }
}

class UserProfileInteractiveTransition: UIPercentDrivenInteractiveTransition {
    var interactionInProgress = false
    private var shouldCompleteTransition = false
    private weak var viewController: UIViewController!
    private var initialOffset: CGFloat = 0.0
    
    func wireToViewController(viewController: UserProfileViewController!) {
        self.viewController = viewController
        initialOffset = viewController.vUserProfileCard.frame.origin.y
        prepareGestureRecognizerInView(viewController.vUserProfileCard)
    }
    
    private func prepareGestureRecognizerInView(view: UIView) {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        view.addGestureRecognizer(gesture)
    }
    
    func handleGesture(gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translationInView(viewController.view)
        var progress:CGFloat = 0.0
        if translation.y > 0 {
            progress = (translation.y/(viewController.view.bounds.height - initialOffset))
            progress = fmax(progress, 0)
            progress = fmin(progress, 1)
        }
        
        switch gestureRecognizer.state {
            
        case .Began:
            interactionInProgress = true
            viewController.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            break
            
        case .Changed:
            shouldCompleteTransition = (progress > 0.5 || gestureRecognizer.velocityInView(viewController.view).y > 200)
            updateInteractiveTransition(progress)
            break
            
        case .Cancelled:
            interactionInProgress = false
            cancelInteractiveTransition()
            break
            
        case .Ended:
            interactionInProgress = false
            
            if !shouldCompleteTransition {
                cancelInteractiveTransition()
            } else {
                finishInteractiveTransition()
            }
            break
            
        default:
            print("Unsupported")
        }
    }
}

class NonHighlightingButton: UIButton {
    override var highlighted: Bool {
        set { }
        get { return super.highlighted }
    }
}