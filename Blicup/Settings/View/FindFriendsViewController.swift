//
//  FindFriendsViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 09/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import FBSDKShareKit
import ReachabilitySwift

class FindFriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UserWithLikeTableViewCellProtocol, FBSDKAppInviteDialogDelegate, UserProfileViewControllerDelegate {

    @IBOutlet weak var btnFacebook: UIButton!
    @IBOutlet weak var btnTwitter: UIButton!
    @IBOutlet weak var vSocialMediaSelected: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var btnConnectFacebook: UIButton!
    @IBOutlet weak var btnConnectTwitter: UIButton!
    @IBOutlet weak var btnFBInviteFriends: UIButton!
    
    private let kShowUserProfile = "showUserProfile"
    private let kUserCell = "userWithLikeCell"
    private var lblBackground: UILabel = UILabel()
    var showBlicupGrayActivityIndicatorTimer: NSTimer?
    @IBOutlet weak var ivLoadingBlicupGray: UIImageView!
    
    private let presenter = FindFriendsPresenter()
    
    @IBOutlet weak var constrVSelectedCenterX: NSLayoutConstraint!
    @IBOutlet weak var constrBtnFacebookCenterX: NSLayoutConstraint!
    @IBOutlet weak var constrBtnTwitterCenterX: NSLayoutConstraint!
    @IBOutlet weak var constrTableViewTopToVSocialNetworkSelected: NSLayoutConstraint!
    
    @IBOutlet weak var constrBtnConnectFBTopToVSocialNetwork: NSLayoutConstraint!
    enum SocialNetworkButton: Int {
        case FACEBOOK, TWITTER, FB_INVITE_FRIENDS, NONE
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupLayout()
        setupBackgroundLabel()
        tableView.tableFooterView = UIView()
        loadBlicupGrayImages()
        registerCell()
        
        let sender = presenter.userHasFacebookId() ? btnFacebook : btnTwitter
        checkUserFbTwitter(sender, animated: false)
        self.title = NSLocalizedString("findFriends", comment: "Find Friends")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBarHidden = false
        self.tabBarController?.tabBar.hidden = true
    }
    
    func checkUserFbTwitter(btnSelected: UIButton, animated: Bool) {

        clearBeforeGetDatasource()
        
        if btnSelected == btnFacebook {
            // verificar se está logado
            if presenter.userHasFacebookId() && presenter.isUserLoggedWithFacebook() {
                
                animateSocialNetworkIndicatorSelected(btnSelected, button: .FB_INVITE_FRIENDS, animated: animated)
                getUsersFromFacebook()
                
            } else {
                presenter.lastRequestTimestamp = NSDate().timeIntervalSince1970
                animateSocialNetworkIndicatorSelected(btnSelected, button: .FACEBOOK, animated: animated)
            }
            
        } else {
            
            if presenter.userHasTwitterId() && presenter.isUserLoggedWithTwitter() {
                getUsersFromTwitter()
                animateSocialNetworkIndicatorSelected(btnSelected, button: .NONE, animated: animated)
            } else {
                presenter.lastRequestTimestamp = NSDate().timeIntervalSince1970
                animateSocialNetworkIndicatorSelected(btnSelected, button: .TWITTER, animated: animated)
            }
        }
    }
    
    func getUsersFromFacebook() {
        
        showBlicupGrayActivityIndicatorTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(FindFriendsViewController.startBlicupGrayActivityIndicator), userInfo: nil, repeats: false)
        
        presenter.getUsersFromFacebook({ (success) in
            self.stopBlicupGrayActivityIndicator()
            self.reloadData(success)
        })
    }
    
    func getUsersFromTwitter() {
     
        showBlicupGrayActivityIndicatorTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(FindFriendsViewController.startBlicupGrayActivityIndicator), userInfo: nil, repeats: false)
        
        presenter.getUsersFromTwitter({ (success) in
            self.stopBlicupGrayActivityIndicator()
            self.reloadData(success)
        })
        
    }
    
    func clearBeforeGetDatasource() {
        presenter.clearDatasource()
        stopBlicupGrayActivityIndicator()
        self.tableView.backgroundView = nil
        UIView.transitionWithView(self.tableView, duration: 0.35, options: .TransitionCrossDissolve, animations: { () -> Void in
            self.tableView.reloadData()
        }, completion: nil)
    }
    
    // MARK: Layout
    func setupLayout() {
        
        vSocialMediaSelected.layer.cornerRadius = 4
        vSocialMediaSelected.layer.masksToBounds = true
        
        btnConnectFacebook.setBackgroundColor(UIColor.blicupFacebookHighlightedColor(), forState: .Highlighted)
        btnConnectFacebook.layer.cornerRadius = 12
        btnConnectFacebook.clipsToBounds = true
        btnConnectTwitter.layer.cornerRadius = 12
        btnConnectTwitter.clipsToBounds = true
        btnFBInviteFriends.layer.cornerRadius = 12
        btnFBInviteFriends.clipsToBounds = true
        btnFBInviteFriends.setBackgroundColor(UIColor.blicupFacebookHighlightedColor(), forState: .Highlighted)
    }
    
    func registerCell() {
        let nib = UINib(nibName: "UserWithLikeTableViewCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: kUserCell)
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
    
    // Setup Label No Users
    func setupBackgroundLabel(){
        let lblBackgroundFont = UIFont(name: "SFUIText-Bold", size: 18)
        lblBackground = UILabel(frame: self.tableView.frame)
        lblBackground.font = lblBackgroundFont
        lblBackground.textAlignment = .Center
        lblBackground.textColor = UIColor.blicupLoadingColor()
    }
    
    func showOrHideBackgroundLbl() {
        
        if self.presenter.userCount() == 0 {
            
            if let reachability = try? Reachability.reachabilityForInternetConnection() {
                if reachability.isReachable() {
                    lblBackground.text = NSLocalizedString("No users", comment: "No users")
                    let userCount = presenter.userCount()
                    self.tableView.backgroundView = userCount == 0 ? lblBackground : nil
                } else {
                    lblBackground.text = NSLocalizedString("No internet", comment: "No internet")
                    self.tableView.backgroundView = lblBackground
                }
            } else {
                
                lblBackground.text = NSLocalizedString("No internet", comment: "No internet")
                self.tableView.backgroundView = lblBackground
            }
        }
    }
    
    func reloadData(success: Bool) {
        self.showOrHideBackgroundLbl()
        UIView.transitionWithView(self.tableView, duration: 0.35, options: .TransitionCrossDissolve, animations: { () -> Void in
                self.tableView.reloadData()
        }, completion: nil)
    }
    
    // MARK: - Show Loading
    
    func startBlicupGrayActivityIndicator() {
        
        UIView.animateWithDuration(1.0) { () -> Void in
            self.ivLoadingBlicupGray.alpha = 1
        }
        
        ivLoadingBlicupGray.startAnimating()
    }
    
    func stopBlicupGrayActivityIndicator() {
        
        UIView.animateWithDuration(0.7, animations: { () -> Void in
            self.ivLoadingBlicupGray.alpha = 0
            }, completion: { (finished) -> Void in
                self.ivLoadingBlicupGray.stopAnimating()
        })
        
        invalidateShowBlicupGrayTimer()
    }
    
    func invalidateShowBlicupGrayTimer() {
        if showBlicupGrayActivityIndicatorTimer != nil {
            showBlicupGrayActivityIndicatorTimer?.invalidate()
            showBlicupGrayActivityIndicatorTimer = nil
        }
    }
    
    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        let userCount = presenter.userCount()
        return userCount == 0 ? 0 : 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.userCount()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCellWithIdentifier(kUserCell) as? UserWithLikeTableViewCell else {
            return UITableViewCell()
        }
        
        if presenter.isLoggedUser(indexPath){
            cell.state = UserWithLikeTableViewCell.CellState.None
        }
        else {
            cell.state = UserWithLikeTableViewCell.CellState.UnFollow
        }
        
        if let photoProfile = presenter.photoUrlAtIndex(indexPath) {
            cell.ivUserPhoto.kf_setImageWithURL(photoProfile)
        }
        
        cell.delegate = self
        cell.lblUsername.text = presenter.usernameAtIndex(indexPath)
        cell.setFollowing(presenter.isFollowingUser(indexPath))
        cell.lblLikes.text = "\(presenter.numberOfLikesAtIndex(indexPath)) 👍"
        cell.showVerifiedBadge(presenter.isVerifiedUser(indexPath))
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
       
        guard let user = self.presenter.userAtIndex(indexPath) else {
            return
        }
        
        self.performSegueWithIdentifier(kShowUserProfile, sender: user)
    }
    
    // MARK: Actions
    
    @IBAction func connectWithFacebookPressed(sender: UIButton) {
     
        presenter.loginWithFacebook(self) { (success) in
            if success {
                self.checkUserFbTwitter(self.btnFacebook, animated: true)
            }
        }
    }
    
    @IBAction func connectWithTwitterPressed(sender: UIButton) {
        
        presenter.loginWithTwitter { (success) in
            if success {
                self.checkUserFbTwitter(self.btnTwitter, animated: true)
            }
        }
    }
    
    @IBAction func inviteFacebookFriendsPressed(sender: UIButton) {
        
        let content = FBSDKAppInviteContent()
        content.appLinkURL = NSURL(string: "https://fb.me/1162883353733435")
        content.appInvitePreviewImageURL = NSURL(string: "https://blicup.com/Blicup.hyperesources/Blicup_Banner.jpg")
        FBSDKAppInviteDialog.showFromViewController(self, withContent: content, delegate: self)
    }
   
    
    @IBAction func facebookPressed(sender: UIButton) {
        
        checkUserFbTwitter(sender, animated: true)
    }
    
    @IBAction func twitterPressed(sender: UIButton) {
    
        checkUserFbTwitter(sender, animated: true)
    }
    
    func animateSocialNetworkIndicatorSelected(btnSelected: UIButton, button: SocialNetworkButton, animated: Bool) {
        
        btnTwitter.selected = btnSelected == btnFacebook ? false : true
        btnFacebook.selected = !btnTwitter.selected
        self.constrVSelectedCenterX.constant = btnSelected == btnFacebook ? constrBtnFacebookCenterX.constant : constrBtnTwitterCenterX.constant
        let btnFacebookAlpha: CGFloat = button == .FACEBOOK ? 1 : 0
        let btnTwitterAlpha: CGFloat = button == .TWITTER ? 1 : 0
        let btnInviteFriendsAlpha: CGFloat = button == .FB_INVITE_FRIENDS ? 1 : 0
        
        let padding = self.constrBtnConnectFBTopToVSocialNetwork.constant*2 + self.btnConnectFacebook.frame.height
        self.constrTableViewTopToVSocialNetworkSelected.constant = button == .NONE ? self.constrBtnConnectFBTopToVSocialNetwork.constant : padding
        
        if animated {
            UIView.animateWithDuration(0.3) {
                self.view.layoutIfNeeded()
                self.btnConnectFacebook.alpha = btnFacebookAlpha
                self.btnConnectTwitter.alpha = btnTwitterAlpha
                self.btnFBInviteFriends.alpha = btnInviteFriendsAlpha
                
            }
        } else {
            self.btnConnectFacebook.alpha = btnFacebookAlpha
            self.btnConnectTwitter.alpha = btnTwitterAlpha
            self.btnFBInviteFriends.alpha = btnInviteFriendsAlpha
        }
    }

    func userWithLikeTableViewCellFollowPressed(cell: UserWithLikeTableViewCell) {
        
        if let index = self.tableView.indexPathForCell(cell) {
            if self.presenter.isFollowingUser(index){
                
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
                let unfollow = UIAlertAction(title: NSLocalizedString("Unfollow", comment: ""), style: .Default, handler: { (action) -> Void in
                    
                    self.followUnfollowUserCell(cell: cell, atIndex: index)
                })
                
                let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
                    
                })
                
                if #available(iOS 9.0, *) {
                    unfollow.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
                    cancel.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
                }
                
                alertController.addAction(unfollow)
                alertController.addAction(cancel)
                
                self.presentViewController(alertController, animated: true, completion: nil)
                
                alertController.view.tintColor = UIColor.blicupPink()
                
            } else {
                
                self.followUnfollowUserCell(cell: cell, atIndex: index)
            }
        }
    }
    
    func followUnfollowUserCell(cell cell: UserWithLikeTableViewCell, atIndex index: NSIndexPath) {
        
        cell.setFollowing(!self.presenter.isFollowingUser(index))
        cell.btnFollow.userInteractionEnabled = false
        
        self.presenter.followUnfollowUserAtIndex(index, completionHandler: { (success) in
            
            if !success {
                cell.setFollowing(self.presenter.isFollowingUser(index))
                self.alertNoInternet()
            }
            
            cell.btnFollow.userInteractionEnabled = true
        })
    }
    
    func alertNoInternet(){
        
        let alert = UIAlertController(title:NSLocalizedString("NoInternetTitle", comment: "No internet") , message:NSLocalizedString("NoInternetMessage", comment: "Check your network connection and try again"), preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //MARK: FBSDKAppInviteDialogDelegate
    func appInviteDialog(appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        print("invitation made")
    }
    
    func appInviteDialog(appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: NSError!) {
        print("error made")
    }
    
    // MARK : UserProfileViewControllerDelegate
    func presentUserProfileCardFromSelectedUser(user: User) {
        self.performSegueWithIdentifier(kShowUserProfile, sender: user)
    }
    
    // MARK: - Segues
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
       
        if segue.identifier == kShowUserProfile, let vcUserProfile = segue.destinationViewController as? UserProfileViewController {
            
            if let user = sender as? User {
                let userProfileCardpresenter = UserProfileCardPresenter(user: user)
                vcUserProfile.presenter = userProfileCardpresenter
                vcUserProfile.transitioningDelegate = vcUserProfile
                vcUserProfile.modalPresentationStyle = .Custom
                vcUserProfile.delegate = self
            }
        }
    }
}
