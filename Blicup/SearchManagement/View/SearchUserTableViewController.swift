//
//  SearchUserTableViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 01/09/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import ReachabilitySwift

class SearchUserTableViewController: UITableViewController, IndicatorInfoProvider {

    var itemInfo = IndicatorInfo(title: "View")
    private let userSearchPresenter = UserSearchPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        let string = "@g"
        if let validatedText = SignupPresenter.validateIncomingUsernameEdit("i") {
            
            var searchTerm = string//(text as NSString).stringByReplacingCharactersInRange(range, withString: validatedText)
            
            if searchTerm.length > USERNAME_LIMIT_LENGTH {
                searchTerm = (searchTerm as NSString).substringToIndex(USERNAME_LIMIT_LENGTH)
            }
            
//            textField.text = searchTerm as String
            
            searchTerm = String(searchTerm.characters.dropFirst())
            
            if searchTerm != "" {
                searchUsersWithSearchTerm(searchTerm)
            } else {
                self.userSearchPresenter.removeAllItems()
                self.tableView.reloadData()
            }
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userSearchPresenter.userCount()
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let kReuseIdentifier = "userCell"
        
        guard let userCell = tableView.dequeueReusableCellWithIdentifier(kReuseIdentifier, forIndexPath: indexPath) as? UserTableCell else {
            return UITableViewCell()
        }
        
        if let userPhotoUrl = userSearchPresenter.photoUrlAtIndex(indexPath) {
            userCell.ivUserPhoto.kf_setImageWithURL(userPhotoUrl)
        }
        
        userCell.lblUsername.text = userSearchPresenter.usernameAtIndex(indexPath)
        userCell.lblBio.text = userSearchPresenter.userBio(indexPath)
        userCell.showVerifiedBadge(userSearchPresenter.isVerifiedUser(indexPath))

        return userCell
    }

    // MARK: SearchUsers
    
    func searchUsersWithSearchTerm(searchTerm: String) {
        
        if let reachability = try? Reachability.reachabilityForInternetConnection() {
            
//            prepareToPerfomSearch()
            
            if reachability.isReachable() {
                
                let searchTermTimestamp = NSDate().timeIntervalSince1970
                
                userSearchPresenter.searchUsersWithSearchTerm(searchTerm, timestamp: searchTermTimestamp, completionHandler: { (success) in
//                    self.stopBlicupActivityIndicator()
                    
                    if success {
                        
                        if self.userSearchPresenter.userCount() > 0 {
                            self.tableView.reloadData()
                        }
                        
                    } else {
//                        self.showlblNoInternet()
                        
                    }
                })
                
            } else {
//                showlblNoInternet()
            }
        } else {
//            showlblNoInternet()
        }
    }
 
    
    // MARK: - IndicatorInfoProvider
    
    func indicatorInfoForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }
}
