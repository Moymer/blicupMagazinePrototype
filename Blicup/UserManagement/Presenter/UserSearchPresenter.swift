//
//  UserSearchPresenter.swift
//  Blicup
//
//  Created by Guilherme Braga on 24/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class UserSearchPresenter: BlockFollowUserListPresenter {

    var usersList = [User]()
    var searchTerm = ""
    
    func userCount() -> Int {
        return self.usersList.count
    }
    
    func removeAllItems() {
        self.usersList.removeAll()
    }
    
    func userAtIndex(index: NSIndexPath) -> User? {
        return usersList[index.row]
    }
    
    // Extra methods
    func numberOfLikesAtIndex(index: NSIndexPath) -> Int {
        let user = userAtIndex(index)
        guard let userInfo = user?.userInfo else {
            return 0
        }
        
        return userInfo.likeCount!.integerValue
    }
    
    func userIdAtIndex(index: NSIndexPath) -> String? {
        guard index.row >= 0 && index.row < usersList.count else {
            return nil
        }
        
        let userRoom = userAtIndex(index)
        return userRoom?.userId
    }
    
    func clearSearchTerm() {
        searchTerm = ""
    }
    
    var searchTermTimestamp: NSTimeInterval = 0.0
    
    func searchUsersWithSearchTerm(searchTerm: String, timestamp: NSTimeInterval, completionHandler:(success: Bool) -> Void) {
        
        searchTermTimestamp = timestamp
        self.searchTerm = searchTerm
        
        UserBS.getUsersThatMatchesSearchTerm(searchTerm) { (searchTerm, success, userList) in
            
            if timestamp == self.searchTermTimestamp {
                if success {
                    
                    if let users = userList {
                        self.usersList = users
                    } else {
                        self.usersList = [User]()
                    }
                }
                completionHandler(success: success)
            }
        }
    }
    
    func getUserFolloweeList(timestamp: NSTimeInterval, completionHandler:(success: Bool) -> Void) {
        
        guard let userId = UserBS.getLoggedUser()?.userId else {
            return
        }
        
        searchTermTimestamp = timestamp
        
        UserBS.getFollowees(userId) { (success, userList) in
           
            if timestamp == self.searchTermTimestamp {
                
                if success {
                    
                    if let users = userList {
                        self.usersList = users
                    } else {
                        self.usersList = [User]()
                    }
                }
                completionHandler(success: success)
            }
        }
        
    }
}
