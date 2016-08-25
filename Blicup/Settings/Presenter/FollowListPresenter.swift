//
//  FollowListPresenter.swift
//  Blicup
//
//  Created by Guilherme Braga on 23/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import CoreData

class FollowListPresenter: NSObject, BlockFollowUserListPresenter, NSFetchedResultsControllerDelegate {

    var userId: String!
    var users = [User]()
    
    required init(withUserId userId: String) {
        
        self.userId = userId
    }
    
    private func updateFollowerListFromUser(userId: String) {
        
        var followerList = [String]()
        if let user = User.userWithId(userId), list = user.userInfo?.followerList as? [String] {
            followerList = list
        }
        
        self.users = User.usersWithIds(usersIds: followerList)
    }
    
    private func updateFolloweeListFromUser(userId: String) {
        
        var followeeList = [String]()
        if let user = User.userWithId(userId), list = user.userInfo?.followeeList as? [String] {
            followeeList = list
        }
        
        self.users = User.usersWithIds(usersIds: followeeList)
    }
    
    
    //MARK: Get Lists
    func getFolloweeUsers(completionHandler:(success: Bool) -> Void) {
        
        guard let userId = self.userId else {
            completionHandler(success: false)
            return
        }
        
        UserBS.getFollowees(userId) { (success, userList) in
            self.updateFolloweeListFromUser(userId)
            completionHandler(success: success)
        }
    }
    
    func getFollowerUsers(completionHandler:(success: Bool) -> Void) {
        
        guard let userId = self.userId else {
            completionHandler(success: false)
            return
        }
        
        UserBS.getFollowers(userId) { (success) in
            self.updateFollowerListFromUser(userId)
            completionHandler(success: success)
        }
    }
    
    func updateFollowerList() {
        updateFollowerListFromUser(self.userId)
    }
    
    func updateFolloweeList() {
        updateFolloweeListFromUser(self.userId)
    }
    
    // MARK: UserData
    func userCount() -> Int {
       
       return self.users.count
    }
    
    func userAtIndex(index: NSIndexPath) -> User? {
        let user = users[index.row]
        return user
    }
    
    func isLoggedUser(index: NSIndexPath) -> Bool {
        let userId = userAtIndex(index)?.userId
        let loggedId = UserBS.getLoggedUser()?.userId
        
        return (userId == loggedId)
    }
    
    func photoUrlAtIndexPath(index: NSIndexPath) -> String? {
        
        let user = userAtIndex(index)
        return user?.photoUrl
    }
    
    func usernameAtIndexPath(index: NSIndexPath) -> String? {
        
        let user = userAtIndex(index)
        var username = user?.username
        if username != nil && username!.length > 0 {
            username = "@" + username!
        }
        
        return username
    }
    
    
    func userIdAtIndexPath(index: NSIndexPath) -> String? {
        
        let user = userAtIndex(index)
        return user?.userId
    }
}
