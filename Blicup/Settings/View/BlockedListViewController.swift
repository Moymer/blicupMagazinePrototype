//
//  BlockedListViewController.swift
//  Blicup
//
//  Created by Moymer on 22/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class BlockedListViewController: UITableViewController {
    
    private let presenter = BlockListPresenter()
    var lblUsers: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("Blocked", comment: "Blocked")
        
        setupLblNoUsers()
        
        presenter.updateUsersBlocked { (success) in
            if success {
                if let indexes = self.tableView.indexPathsForVisibleRows {
                    self.tableView.reloadRowsAtIndexPaths(indexes, withRowAnimation: UITableViewRowAnimation.Fade)
                }
                if self.presenter.numberOfBlockedUsers() == 0 {
                    self.lblUsers.alpha = 1
                }
                
            }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.lblUsers.removeFromSuperview()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Setup Label No Users
    
    func setupLblNoUsers() {
        
        lblUsers = UILabel(frame: CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y - 64, width: self.view.frame.width, height: self.view.frame.height))
        lblUsers.textAlignment = .Center
        lblUsers.text =  NSLocalizedString("No users", comment: "No users")
        lblUsers.font = UIFont(name: "SFUIText-Bold", size: 16.0)!
        lblUsers.textColor = UIColor.blicupLoadingColor()
        lblUsers.alpha = 0
        
        self.view.addSubview(lblUsers)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.numberOfBlockedUsers()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 66
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BlockedUserCell", forIndexPath: indexPath) as! UserBlockedCell
        
        if let photoUrl = presenter.userPhotoUrl(indexPath.row) {
            cell.ivUserPhoto.kf_setImageWithURL(photoUrl)
        }
        cell.lblUsername.text = presenter.username(indexPath.row)
        cell.btnBlock.selected = presenter.isBlocked(indexPath.row)
        cell.btnBlock.tag = indexPath.row
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    @IBAction func blockPressed(sender: UIButton) {
        if presenter.isBlocked(sender.tag) {
            
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            let unblock = UIAlertAction(title: NSLocalizedString("Unblock", comment: "") , style: .Default, handler: { (action) -> Void in
                sender.selected = !sender.selected
                self.presenter.blockUnblockUser(sender.tag)
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
        else {
            showBlockDialog(sender)
        }
    }
    
    private func showBlockDialog(sender:UIButton) {
        let alertController = UIAlertController(title: presenter.blockDialogTitleForIndex(sender.tag), message: presenter.blockDialogMessageForIndex(sender.tag), preferredStyle: UIAlertControllerStyle.Alert)
        
        let title = NSLocalizedString("Block", comment: "")
        let blockAction = UIAlertAction(title: title, style: .Default, handler: { (action) -> Void in
            self.presenter.blockUnblockUser(sender.tag)
            sender.selected = !sender.selected
        })
        
        alertController.addAction(blockAction)
        
        let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
            //print("Cancel Button Pressed")
        })
        alertController.addAction(cancel)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
}

class UserBlockedCell: UITableViewCell {
    @IBOutlet weak var ivUserPhoto: UIImageView!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var btnBlock: UIButton!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        ivUserPhoto.image = nil
        lblUsername.text = nil
        btnBlock.selected = true
        btnBlock.tag = -1
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        ivUserPhoto.layer.cornerRadius = ivUserPhoto.bounds.width/2
        
        btnBlock.layer.cornerRadius = btnBlock.bounds.height/2
        btnBlock.layer.borderWidth = 2
        let selectedColor = UIColor(hexString: "#B0B1B1FF")!
        btnBlock.layer.borderColor = selectedColor.CGColor
        btnBlock.setBackgroundImage(UIImage(color: selectedColor), forState: UIControlState.Selected)
        let normalColor = UIColor.clearColor()
        btnBlock.setBackgroundImage(UIImage(color: normalColor), forState: UIControlState.Normal)
    }
}
