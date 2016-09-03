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

class SearchUserViewController: UIViewController, IndicatorInfoProvider, UITableViewDelegate, UITableViewDataSource {

    var itemInfo = IndicatorInfo(title: "View")
    private let userSearchPresenter = UserSearchPresenter()
    private var showBlicupWhiteActivityIndicatorTimer: NSTimer?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var ivLoadingBlicupGray: UIImageView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView()
        loadBlicupWhiteImages()
    }
    
    func loadBlicupWhiteImages() {
        
        var animationArray: [UIImage] = []
        
        for index in 0...29 {
            animationArray.append(UIImage(named: "BlicMini_gray_\(index)")!)
        }

        ivLoadingBlicupGray.animationImages = animationArray
        ivLoadingBlicupGray.animationDuration = 1.0
        ivLoadingBlicupGray.alpha = 0
    }
    

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userSearchPresenter.userCount()
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
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
    
    func searchUser(text: String, shouldChangeTextInRange range: NSRange, replacementText string: String) -> Bool {
        
        if let validatedText = SignupPresenter.validateIncomingUsernameEdit(string) {
            
            var searchTerm = (text as NSString).stringByReplacingCharactersInRange(range, withString: validatedText)
            
            if searchTerm.length > USERNAME_LIMIT_LENGTH {
                searchTerm = (searchTerm as NSString).substringToIndex(USERNAME_LIMIT_LENGTH)
            }
            
            if searchTerm.hasPrefix("@") {
                searchTerm = String(searchTerm.characters.dropFirst())
            }
            print(searchTerm)
            
            if searchTerm != "" {
                searchUsersWithSearchTerm(searchTerm)
            } else {
                self.userSearchPresenter.removeAllItems()
                self.tableView.reloadData()
            }
            
            return true
        }
        
         return false

    }
    
    func searchUsersWithSearchTerm(searchTerm: String) {
        
        if searchTerm != self.userSearchPresenter.searchTerm  {
        
            if let reachability = try? Reachability.reachabilityForInternetConnection() {
                
                prepareToPerfomSearch()
                
                if reachability.isReachable() {
                    
                    let searchTermTimestamp = NSDate().timeIntervalSince1970
                    
                    userSearchPresenter.searchUsersWithSearchTerm(searchTerm, timestamp: searchTermTimestamp, completionHandler: { (success) in
                        self.stopBlicupActivityIndicator()
                        
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
    }
    
    
    func prepareToPerfomSearch() {
//        hidelblNoInternet()
        userSearchPresenter.removeAllItems()
        self.tableView.reloadData()
        
        invalidateShowBlicupWhiteTimer()
        showBlicupWhiteActivityIndicatorTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(SearchUserViewController.startBlicupActivityIndicator), userInfo: nil, repeats: false)
        
    }
 
    func invalidateShowBlicupWhiteTimer() {
        
        if showBlicupWhiteActivityIndicatorTimer != nil {
            showBlicupWhiteActivityIndicatorTimer?.invalidate()
            showBlicupWhiteActivityIndicatorTimer = nil
        }
    }
    
    func clearData() {
        userSearchPresenter.removeAllItems()
        self.tableView.reloadData()
    }
    
    // MARK: - Show Loading
    
    func startBlicupActivityIndicator() {
        
        UIView.animateWithDuration(0.6) { () -> Void in
            self.ivLoadingBlicupGray.alpha = 1
        }
        
        ivLoadingBlicupGray.startAnimating()
    }
    
    func stopBlicupActivityIndicator() {
        
        invalidateShowBlicupWhiteTimer()
        
        UIView.animateWithDuration(0.6, animations: { () -> Void in
            
            self.ivLoadingBlicupGray.alpha = 0
            
            }, completion: { (finished) -> Void in
                
                self.ivLoadingBlicupGray.stopAnimating()
        })
    }
    
    // MARK: - IndicatorInfoProvider
    
    func indicatorInfoForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }
}
