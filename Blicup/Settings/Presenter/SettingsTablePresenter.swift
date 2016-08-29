//
//  SettingsTablePresenter.swift
//  Blicup
//
//  Created by Moymer on 20/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class SettingsTablePresenter: NSObject {
    
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
