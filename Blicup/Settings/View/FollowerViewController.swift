//
//  FollowerViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 18/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class FollowerViewController: FolloweeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Followers", comment: "Followers")
    }
    
    override func getDatasourceUsers() {
        
        showBlicupGrayActivityIndicatorTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(FollowerViewController.startBlicupGrayActivityIndicator), userInfo: nil, repeats: false)
        followPresenter.getFollowerUsers() { (success) in
            self.stopBlicupGrayActivityIndicator()
            self.reloadData(success)
        }
    }
    
    // MARK: Update Datasource
    override func updateDataSource() {
        
        if self.tableView != nil {
            followPresenter.updateFollowerList()
            self.reloadData(true)
        }
    }
}
