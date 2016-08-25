//
//  UserListFollowBlockViewController.swift
//  Blicup
//
//  Created by Moymer on 27/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class UserListFollowBlockViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UserTableViewCellProtocol {
    
    private let kUserInfoCell = "UserInfoCell"
    private let kUserBlockCell = "UserBlockCell"
    private var lblNoUsers: UILabel = UILabel()
    
    @IBOutlet weak var tableView: UITableView!
    
    var presenter: BlockFollowUserListPresenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "UserTableViewCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: kUserInfoCell)
        
        let nib2 = UINib(nibName: "UserBlockCell", bundle: nil)
        self.tableView.registerNib(nib2, forCellReuseIdentifier: kUserBlockCell)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UserListFollowBlockViewController.reloadVisibleCells), name: "UserProfileClosed", object: nil)
        
        self.setupLabelNoUsers()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func reloadVisibleCells() {
        if let visibleIndexes = tableView?.indexPathsForVisibleRows {
            tableView.reloadRowsAtIndexPaths(visibleIndexes, withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    // Setup Label No Users
    
    func setupLabelNoUsers(){
        let lblNoUsersFont = UIFont(name: "SFUIText-Bold", size: 18)
        lblNoUsers = UILabel(frame: self.tableView.frame)
        lblNoUsers.font = lblNoUsersFont
        lblNoUsers.textAlignment = .Center
        lblNoUsers.textColor = UIColor.blicupLoadingColor()
        lblNoUsers.sizeToFit()
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
        
        if presenter.isBlockingMe(indexPath) {
            let cell = tableView.dequeueReusableCellWithIdentifier(kUserBlockCell)!
            let imageArea = cell.viewWithTag(1)!
            imageArea.layer.cornerRadius = imageArea.bounds.width/2
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier(kUserInfoCell) as! UserTableViewCell
            
            if presenter.isLoggedUser(indexPath){
                cell.state = UserTableViewCell.CellState.None
            }
            else if presenter.isUserBlocked(indexPath) {
                cell.state = UserTableViewCell.CellState.Block
            }
            else {
                cell.state = UserTableViewCell.CellState.UnFollow
            }
            
            if let photoProfile = presenter.photoUrlAtIndex(indexPath) {
                cell.ivUserPhoto.kf_setImageWithURL(photoProfile)
            }
            
            cell.delegate = self
            cell.lblUsername.text = presenter.usernameAtIndex(indexPath)
            cell.setFollowing(presenter.isFollowingUser(indexPath))
            cell.showVerifiedBadge(presenter.isVerifiedUser(indexPath))
            
            return cell
        }
    }
    
    // MARK: Show No users
    func showOrHideLblNoUsers(hasInternet: Bool) {
        if self.presenter.userCount() == 0 {
            if !hasInternet {
                lblNoUsers.text = NSLocalizedString("No internet", comment: "No internet")
                self.tableView.backgroundView = lblNoUsers
            } else {
                lblNoUsers.text = NSLocalizedString("No users", comment: "No users")
                let userCount = presenter.userCount()
                self.tableView.backgroundView = userCount == 0 ? lblNoUsers : nil
            }
        }
    }
    
    
    // MARK: - Cell Delegate
    func startListeningUserInfoChanges() {
        
    }
    
    func userTableViewCellFollowPressed(cell: UserTableViewCell) {
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
    
    //Métodos sendo sobrescrito na classe de Followee e Followers para dar reload na table
    func followUnfollowUserCell(cell cell: UserTableViewCell, atIndex index: NSIndexPath) {
        
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
    
    func userTableViewCellUnblockPressed(cell: UserTableViewCell) {
        if let index = tableView.indexPathForCell(cell) {
            
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            let unblock = UIAlertAction(title: NSLocalizedString("Unblock", comment: "") , style: .Default, handler: { (action) -> Void in
                cell.setFollowing(!self.presenter.isFollowingUser(index))
                cell.btnBlock.enabled = false
                self.presenter.unblockUserAtIndex(index, completionHandler: { (success) in
                    if success {
                        cell.state = .UnFollow
                        cell.setFollowing(self.presenter.isFollowingUser(index))
                    }
                    else {
                        cell.setFollowing(self.presenter.isFollowingUser(index))
                        self.alertNoInternet()
                    }
                    
                    cell.btnBlock.enabled = true
                })
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
    }
    
    func alertNoInternet(){
        let alert = UIAlertController(title:NSLocalizedString("NoInternetTitle", comment: "No internet") , message:NSLocalizedString("NoInternetMessage", comment: "Check your network connection and try again"), preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
