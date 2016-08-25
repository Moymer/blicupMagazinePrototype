//
//  FollowUnfollowPresenter.swift
//  Blicup
//
//  Created by Guilherme Braga on 23/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class FollowUnfollowPresenter: NSObject {

    func isUserBlocked(userId: String)->Bool {
        guard let blockedList = UserBS.getLoggedUser()?.userInfo?.blockedList as? [String]  else {
                return false
        }
        
        return blockedList.contains(userId)
    }
    
    func didFollowUser(userId: String) -> Bool {
        
        guard let user = UserBS.getLoggedUser() else {
            return false
        }
        
        guard let followeeList = user.userInfo?.followeeList as? [String] else {
            return false
        }
        
        return followeeList.contains(userId)
    }
    
    func hiddenFollowBtn(userId: String) -> Bool {
        
        if let userLoggedId = UserBS.getLoggedUser()?.userId {
            return userId == userLoggedId
        }
        
        return false
    }
    
    func followUnfollowUserWithId(userId: String, completionHandler:(success: Bool, didFollowUser: Bool) -> Void) {
        
        
        if didFollowUser(userId) {
            
            UserBS.unfollowUser(userId) { (success) in
                completionHandler(success: success, didFollowUser: false)
            }
            
        } else {
            
            UserBS.followUser(userId) { (success) in
                completionHandler(success: success, didFollowUser: true)
            }
        }
    }
}
