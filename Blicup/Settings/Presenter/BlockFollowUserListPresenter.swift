//
//  BlockFollowUserListPresenter.swift
//  Blicup
//
//  Created by Moymer on 24/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

protocol BlockFollowUserListPresenter: class {
    // MUST BE OVERRIDEN
    func userCount()->Int
    func userAtIndex(index:NSIndexPath)->User?
    
    // Default implementations
    func photoUrlAtIndex(index:NSIndexPath)->NSURL?
    func usernameAtIndex(index:NSIndexPath)->String?
    func isLoggedUser(index:NSIndexPath)->Bool
    func isBlockingMe(index:NSIndexPath)->Bool
    func isUserBlocked(index:NSIndexPath)->Bool
    func isFollowingUser(index:NSIndexPath)->Bool
    func followUnfollowUserAtIndex(index:NSIndexPath, completionHandler:(success:Bool)->Void)
    func unblockUserAtIndex(index:NSIndexPath, completionHandler:(success:Bool)->Void)
}

extension BlockFollowUserListPresenter {
    // Default implementations
    func photoUrlAtIndex(index:NSIndexPath)->NSURL? {
        guard let urlString = userAtIndex(index)?.photoUrl else {
            return nil
        }
        
        return NSURL(string: urlString)
    }
    
    func usernameAtIndex(index:NSIndexPath)->String? {
        if let username = userAtIndex(index)?.username {
            return "@"+username
        }
        return nil
    }
    
    func isLoggedUser(index:NSIndexPath)->Bool {
        let userId = userAtIndex(index)?.userId
        let loggedId = UserBS.getLoggedUser()?.userId
        
        return (userId == loggedId)
    }
    
    
    func isVerifiedUser(index: NSIndexPath) -> Bool {
        guard let isVerified = userAtIndex(index)?.isVerified else {
            return false
        }
        
        return isVerified.boolValue
    }
    
    func isBlockingMe(index:NSIndexPath)->Bool {
        guard let blockerList = UserBS.getLoggedUser()?.userInfo?.blockerList as? [String],
            let user = userAtIndex(index) else {
            return false
        }
        
        return blockerList.contains(user.userId!)
    }
    
    func isUserBlocked(index:NSIndexPath)->Bool {
        guard let blockedList = UserBS.getLoggedUser()?.userInfo?.blockedList as? [String],
            let user = userAtIndex(index) else {
            return false
        }
        
        return blockedList.contains(user.userId!)
    }
    
    func isFollowingUser(index:NSIndexPath)->Bool {
        guard let followList = UserBS.getLoggedUser()?.userInfo?.followeeList as? [String],
            let user = userAtIndex(index) else {
            return false
        }
        
        return followList.contains(user.userId!)
    }
    
    
    func followUnfollowUserAtIndex(index:NSIndexPath, completionHandler:(success:Bool)->Void) {
        guard !isUserBlocked(index),
            let userId = userAtIndex(index)?.userId else {
            completionHandler(success: false)
            return
        }
        
        if isFollowingUser(index) {
            UserBS.unfollowUser(userId, completionHandler: completionHandler)
        }
        else {
            UserBS.followUser(userId, completionHandler: completionHandler)
        }
    }
    
    func unblockUserAtIndex(index:NSIndexPath, completionHandler:(success:Bool)->Void) {
        guard let userId = userAtIndex(index)?.userId,
            let loggedUserBlockList = UserBS.getLoggedUser()?.userInfo?.blockedList as? [String]else {
            return
        }
        
        if loggedUserBlockList.contains(userId) {
            UserBS.unblockUser(userId, completionHandler: completionHandler)
        }
    }
    
    // Extra methods
    func numberOfLikesAtIndex(index: NSIndexPath) -> Int {
        let user = userAtIndex(index)
        guard let userInfo = user?.userInfo else {
            return 0
        }
        
        return userInfo.likeCount!.integerValue
    }
}
