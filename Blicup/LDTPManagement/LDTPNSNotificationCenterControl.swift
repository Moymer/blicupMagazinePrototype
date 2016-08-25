//
//  LDTPNSNotificationCenterControl.swift
//  Blicup
//
//  Created by Moymer on 5/26/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

 public class LDTPNSNotificationCenterControl: NSObject {

   public enum  LDTPNSNotificationCenterKey : String {
        case K_RECEIVE_CHATROOM_MSG = "KeyChatroomMsg"
        case K_RECEIVE_CHATROOM_UPDATES = "KeyChatroomUpdate"
        case K_RECEIVE_CHATROOM_IS_DEAD = "KeyChatroomIsDead"
        case K_RECEIVE_CHATROOM_MSG_LIKE = "KeyChatroomMsgLike"
        case K_RECEIVE_CHATROOM_IS_BANNED = "KeyChatroomIsBanned"
    
        case K_RECEIVE_USER_BANNED_FROM_CHATROOM = "KeyUserBannedFromChatroom"
        case K_RECEIVE_USER_INFO_HASCHANGED   = "KeyUserInfoHasChanged"
        case K_RECEIVE_USER_STATUS = "KeyUserStatus"
    
    static func fromCodToKey(pos : Int) -> LDTPNSNotificationCenterKey?
        {
            switch pos {
                case 1 : return .K_RECEIVE_CHATROOM_MSG
                case 2 : return .K_RECEIVE_CHATROOM_UPDATES
                case 3 : return .K_RECEIVE_CHATROOM_IS_DEAD
                case 4 : return .K_RECEIVE_CHATROOM_MSG_LIKE
                case 5 : return .K_RECEIVE_USER_BANNED_FROM_CHATROOM
                case 6 : return .K_RECEIVE_USER_INFO_HASCHANGED
                case 7 : return .K_RECEIVE_CHATROOM_IS_BANNED
                case 8 : return .K_RECEIVE_USER_STATUS  
                default : return .K_RECEIVE_CHATROOM_MSG
            }
        }
    }
    


    
}
