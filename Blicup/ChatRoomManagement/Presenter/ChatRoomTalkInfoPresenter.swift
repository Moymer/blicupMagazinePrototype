//
//  ChatRoomTalkInfoPresenter.swift
//  Blicup
//
//  Created by Moymer on 23/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class ChatRoomTalkInfoPresenter: NSObject, BlockFollowUserListPresenter {
    private var userList = [User]()
    
    func loadChatRoomUsers(chatRoomID: String,  completionHandler:(success: Bool) -> Void){
        UserBS.getUsersThatParticipatesOnChat(chatRoomID) { (success, userList) in
            if success, let users = userList {
                self.userList = users
            }
            else {
                self.userList = [User]()
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
