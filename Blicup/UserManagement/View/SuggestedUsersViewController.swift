//
//  SuggestedUsersViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 04/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class SuggestedUsersViewController: UIViewController, UserWithLikeTableViewCellProtocol {

    @IBOutlet weak var tableView: UITableView!
    private let kUserCell = "userWithLikeCell"
    private let presenter = SuggestUsersPresenter()
    private var lblBackground: UILabel = UILabel()
    var showBlicupGrayActivityIndicatorTimer: NSTimer?
    
    @IBOutlet weak var btnContinue: UIButton!
    @IBOutlet weak var constrVContainerLeading: NSLayoutConstraint!
    @IBOutlet weak var constrVContainerTrailing: NSLayoutConstraint!
    @IBOutlet weak var ivLoadingBlicupGray: UIImageView!
    
    @IBOutlet weak var constrBtnContinueBottom: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        loadSuggestedUsers()
        loadBlicupGrayImages()
        setupBackgroundLabel()
        registerCell()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.constrVContainerLeading.constant = screenWidth
        self.constrVContainerTrailing.constant = -screenWidth
        self.constrBtnContinueBottom.constant = -self.btnContinue.frame.height
        self.view.layoutIfNeeded()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        UIView.animateWithDuration(1.0, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            
            self.constrVContainerLeading.constant = 0
            self.constrVContainerTrailing.constant = 0
            self.constrBtnContinueBottom.constant = 0
            self.view.layoutIfNeeded()
            
        }, completion: { (_) in})
    }
    
    func registerCell() {
        let nib = UINib(nibName: "UserWithLikeTableViewCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: kUserCell)
    }
    
    func loadSuggestedUsers() {
        
        showBlicupGrayActivityIndicatorTimer = NSTimer.scheduledTimerWithTimeInterval(1.5, target: self, selector: #selector(SuggestedUsersViewController.startBlicupGrayActivityIndicator), userInfo: nil, repeats: false)
        
        LDTProtocolImpl.sharedInstance.initSocket()
        presenter.loadSuggestedUsers { (success) in
            self.stopBlicupGrayActivityIndicator()
            self.reloadData(success)
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
    
    // Setup Label No Users
    func setupBackgroundLabel(){
        let lblBackgroundFont = UIFont(name: "SFUIText-Bold", size: 18)
        lblBackground = UILabel(frame: self.tableView.frame)
        lblBackground.font = lblBackgroundFont
        lblBackground.textAlignment = .Center
        lblBackground.textColor = UIColor.blicupLoadingColor()
        lblBackground.sizeToFit()
    }
    
    func showOrHideBackgroundLbl(hasInternet: Bool) {
        
        if self.presenter.userCount() == 0 {
            if !hasInternet {
                lblBackground.text = NSLocalizedString("No internet", comment: "No internet")
                self.tableView.backgroundView = lblBackground
            } else {
                lblBackground.text = NSLocalizedString("No users", comment: "No users")
                let userCount = presenter.userCount()
                self.tableView.backgroundView = userCount == 0 ? lblBackground : nil
            }
        }
    }

    func reloadData(success: Bool) {
        self.showOrHideBackgroundLbl(success)
        self.tableView.reloadData()
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

    // MARK: Actions
    
    @IBAction func btnContinuePressed(sender: AnyObject) {
        
         UIView.animateWithDuration(1.0, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            
            self.constrVContainerLeading.constant = -screenWidth
            self.constrVContainerTrailing.constant = screenWidth
            self.constrBtnContinueBottom.constant = -self.btnContinue.frame.height
            self.view.layoutIfNeeded()
         
         }, completion: { (finished) in
            BlicupRouter.routeLogin(self.view.window)
         })
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
}