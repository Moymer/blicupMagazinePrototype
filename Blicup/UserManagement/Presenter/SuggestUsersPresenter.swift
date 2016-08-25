//
//  SuggestUsersPresenter.swift
//  Blicup
//
//  Created by Guilherme Braga on 04/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class SuggestUsersPresenter: NSObject, BlockFollowUserListPresenter {

    private var userList = [User]()
    
    func loadSuggestedUsers(completionHandler:(success: Bool) -> Void){
        UserBS.getSuggestedUsersToFollow { (success, users) in
            if success {
                if let users = users {
                    self.userList = users
                } else {
                    self.userList = [User]()
                }
            }
            completionHandler(success: success)
        }
    }
    
    func userAtIndex(index:NSIndexPath)->User? {
        return userList[index.row]
    }
    
    func userCount()->Int {
        return userList.count
    }
}
