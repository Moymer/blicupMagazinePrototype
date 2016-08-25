//
//  FolloweeViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 15/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

protocol FollowViewControllerDelegate: class {
    func presentUserProfileCardFromSelectedUser(user: User)
    func followUnfollowOnUserTableCellPressed(viewController: UIViewController)
}

class FolloweeViewController: UserListFollowBlockViewController, UserProfileViewControllerDelegate {
    
    var followPresenter: FollowListPresenter! {
        didSet {
            presenter = followPresenter
        }
    }
    
    var showBlicupGrayActivityIndicatorTimer: NSTimer?
    @IBOutlet weak var ivLoadingBlicupGray: UIImageView!
    
    weak var delegate: FollowViewControllerDelegate?
    
    private let kUserListViewCellID = "userViewCellID"
    private let kShowUserProfile = "showUserProfile"
    var isUserProfileCard = false
    
    @IBOutlet weak var ivBackground: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Following", comment: "Following")
        
        loadBlicupGrayImages()
        getDatasourceUsers()
        tableView.tableFooterView = UIView()
        
        if isUserProfileCard {
            self.ivBackground.image = nil
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBarHidden = false
        self.navigationController?.navigationBar.tintColor = UIColor.blackColor()
        self.tabBarController?.tabBar.hidden = true
    }
    
    func getDatasourceUsers() {
        
        showBlicupGrayActivityIndicatorTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(FolloweeViewController.startBlicupGrayActivityIndicator), userInfo: nil, repeats: false)

        followPresenter.getFolloweeUsers() { (success) in
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

    
    
    // MARK: TableView Datasource
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        guard let user = self.presenter.userAtIndex(indexPath) else {
            return
        }
        
        if isUserProfileCard {
            //Close the current user profile card and open a new with a selected user
            if !self.presenter.isLoggedUser(indexPath) {
                self.dismissViewControllerAnimated(true, completion: {
                    self.delegate?.presentUserProfileCardFromSelectedUser(user)
                })
            }
        } else {
            self.performSegueWithIdentifier(kShowUserProfile, sender: user)
        }
    }
    
    // Method of superclass
    override func followUnfollowUserCell(cell cell: UserTableViewCell, atIndex index: NSIndexPath) {
        super.followUnfollowUserCell(cell: cell, atIndex: index)
        self.delegate?.followUnfollowOnUserTableCellPressed(self)
    }
    
    // MARK: Update Datasource
    func updateDataSource() {
        
        if self.tableView != nil {
            followPresenter.updateFolloweeList()
            self.reloadData(true)
        }
    }
    
    func reloadData(success: Bool) {
        self.showOrHideLblNoUsers(success)
        self.tableView.reloadData()
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
