//
//  SettingsTablePresenter.swift
//  Blicup
//
//  Created by Moymer on 20/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class SettingsTablePresenter: NSObject {
    
    func updateUserInfoData(completion:((success:Bool)->Void)?) {
        guard let loggedId = UserBS.getLoggedUser()?.userId else {
            completion?(success:false)
            return
        }
        
        UserBS.updateUsersInfo([loggedId]) { (success) in
            completion?(success:success)
        }
    }
    
    func followersText()->String {
        guard let followersCount = UserBS.getLoggedUser()?.userInfo?.followerCount else {
            return "-"
        }
        
        return followersCount.stringValue
    }
    
    func followeeText()->String {
        guard let followeeCount = UserBS.getLoggedUser()?.userInfo?.followeeCount else {
            return "-"
        }
        
        return followeeCount.stringValue
    }
    
    func createdChatsText()->String {
        guard let chatsCreatedList = UserBS.getLoggedUser()?.userInfo?.createdChatroomList as? [String] else {
            return "-"
        }
        
        return "\(chatsCreatedList.count)"
    }
    
    func tagsText()->String {
        guard let tagsList = UserBS.getLoggedUser()?.tagList else {
            return "-"
        }
        
        return "\(tagsList.count)"
    }
}
