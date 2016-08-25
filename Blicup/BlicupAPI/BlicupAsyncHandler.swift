//
//  BlicupAsyncHandler.swift
//  Blicup
//
//  Created by Moymer on 30/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

/*
 This class/singleton is responsible for listening to incoming messages, saving them in local database and tell any listenning class that reveived message was sucessifuly created
 */


import UIKit
import SafariServices


class BlicupAsyncHandler: NSObject {
    
    enum ChatMessageNotification: String {
        case MessageReceived = "ReceivedMessage"
        case ChatroomReceived = "ReceivedChatroom"
        case ChatroomIsDead = "ChatroomIsDead"
        case MessageLikeReceived = "MessageLikeReceived"
        case ChatroomBannedForUser = "UserRemovedFromChatroom"
        case ChatroomIsBanned = "ChatroomIsBanned"
    }
    
    enum UserNotification: String {
        case NewYellowCard = "NewYellowCard"
        case YouAreBannedFromBlicup = "RedCard"
        case CannotHaveSimultaneousSession = "CannotHaveSimultaneousSession"
        case GeneralLogout = "GeneralLogout"
    }
    
    static let sharedInstance = BlicupAsyncHandler()
    
    override init() {
        super.init()
        //chatroom driven assync msgs
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(receivedIncomingMessageNotification), name: LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.K_RECEIVE_CHATROOM_MSG.rawValue, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(receivedChatRoomUpdateNotification), name: LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.K_RECEIVE_CHATROOM_UPDATES.rawValue, object: nil)
    
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(receivedChatRoomDeathNotification), name: LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.K_RECEIVE_CHATROOM_IS_DEAD.rawValue, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(receivedIncomingMessageLikeNotification), name: LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.K_RECEIVE_CHATROOM_MSG_LIKE.rawValue, object: nil)
    
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(receivedChatRoomBannedNotification), name: LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.K_RECEIVE_CHATROOM_IS_BANNED.rawValue, object: nil)
        
        
        //user driven assync msgs

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(receivedUserBannedFromChatRoomNotification), name: LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.K_RECEIVE_USER_BANNED_FROM_CHATROOM.rawValue, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(receivedUserInfoChangedNotification), name: LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.K_RECEIVE_USER_INFO_HASCHANGED.rawValue, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(receivedUserStatusUpdatedNotification), name: LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.K_RECEIVE_USER_STATUS.rawValue, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showSimultaneousSessionAlert), name: UserNotification.CannotHaveSimultaneousSession.rawValue, object: nil)
        
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self,  name: LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.K_RECEIVE_CHATROOM_MSG.rawValue, object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.K_RECEIVE_CHATROOM_UPDATES.rawValue, object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.K_RECEIVE_CHATROOM_IS_DEAD.rawValue, object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self,  name: LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.K_RECEIVE_CHATROOM_MSG_LIKE.rawValue, object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self,  name: LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.K_RECEIVE_USER_BANNED_FROM_CHATROOM.rawValue, object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self,  name: LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.K_RECEIVE_USER_INFO_HASCHANGED.rawValue, object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self,  name: LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.K_RECEIVE_CHATROOM_IS_BANNED.rawValue, object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self,  name: LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.K_RECEIVE_USER_STATUS.rawValue, object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UserNotification.CannotHaveSimultaneousSession.rawValue, object: nil)
        
    }
    
    func receivedIncomingMessageNotification(notification:NSNotification) {
        guard let msg = notification.userInfo?["Ans"] as? [String:AnyObject] else {
            return
        }
        
        if let message = ChatRoomMessage.createOrUpdateReceivedChatRoomMessage(msg) {
            let chatRoom = ChatRoom.chatRoomWithId(message.0!.chatRoomId!)
            chatRoom?.showBadge = true
             NSNotificationCenter.defaultCenter().postNotificationName(ChatMessageNotification.MessageReceived.rawValue, object: chatRoom, userInfo: ["message":message.0!, "isUpdating": message.1!])
        }
    }
    
    func receivedIncomingMessageLikeNotification(notification:NSNotification) {
        guard let msg = notification.userInfo?["Ans"] as? [String:AnyObject] else {
            return
        }
        
        if let message = ChatRoomMessage.updateReceivedChatRoomMessageOnLike(msg) {
            let chatRoom = ChatRoom.chatRoomWithId(message.chatRoomId!)
            NSNotificationCenter.defaultCenter().postNotificationName(ChatMessageNotification.MessageLikeReceived.rawValue, object: chatRoom, userInfo: ["message":message])
        }
    }

    
    
    func receivedChatRoomUpdateNotification(notification:NSNotification) {
        guard let msg = notification.userInfo?["Ans"] as? [String:AnyObject] else {
            return
        }
        
        ChatRoom.createChatRoomInBG(msg, isMyChat: nil) { (chatRoom) in
            if let updatedChatRoom = chatRoom {
                 NSNotificationCenter.defaultCenter().postNotificationName(ChatMessageNotification.ChatroomReceived.rawValue, object: updatedChatRoom, userInfo: ["chatroom":updatedChatRoom])
            }
        }
    }
    
    
    func receivedChatRoomDeathNotification(notification:NSNotification) {
        guard let chatroomId = notification.userInfo?["Ans"] as? String else {
            return
        }
        // print("ChatRoom is dead \(chatroomId)")
        if let chatRoom = ChatRoom.chatRoomWithId(chatroomId) {
            
            chatRoom.state = ChatRoom.ChatRoomState.Dead.rawValue
            NSNotificationCenter.defaultCenter().postNotificationName(ChatMessageNotification.ChatroomIsDead.rawValue, object: chatRoom, userInfo: ["chatroom":chatRoom])
        }
    }
    
    func receivedChatRoomBannedNotification(notification:NSNotification) {
        guard let chatroomId = notification.userInfo?["Ans"] as? String else {
            return
        }
        //print("ChatRoom is banned \(chatroomId)")
        if let chatRoom = ChatRoom.chatRoomWithId(chatroomId) {
            
            chatRoom.state = ChatRoom.ChatRoomState.Banned.rawValue
            NSNotificationCenter.defaultCenter().postNotificationName(ChatMessageNotification.ChatroomIsBanned.rawValue, object: chatRoom, userInfo: ["chatroom":chatRoom])
        }
    }

    
    
    
    func receivedUserBannedFromChatRoomNotification(notification:NSNotification) {
        guard let chatroomId = notification.userInfo?["Ans"] as? String else {
            return
        }
        //print("User banned from chatroom \(chatroomId)")
        if let chatroom = ChatRoom.chatRoomWithId(chatroomId) {
            chatroom.state = ChatRoom.ChatRoomState.Removed.rawValue
            NSNotificationCenter.defaultCenter().postNotificationName(ChatMessageNotification.ChatroomBannedForUser.rawValue, object: chatroom, userInfo: ["chatroom":chatroom])
        }
    }

    func receivedUserInfoChangedNotification(notification:NSNotification) {
        guard let userInfoDic = notification.userInfo?["Ans"] as? [String:AnyObject] else {
            return
        }
        
        UserInfo.createUpdateUserInfo(userInfoDic)
    }

    
    func receivedUserStatusUpdatedNotification(notification:NSNotification) {
        guard let userStatusDic = notification.userInfo?["Ans"] as? [String:AnyObject] else {
            return
        }
    
        //print("User status updated \(userStatusDic)")
        
        // TO DO: Converter e tratar casos
        let returnStatus = UserBS.checkAndUpdateLoggedUserStatus(userStatusDic)
        
        if returnStatus == LoggedUserSessionState.BannedFromBlicup {
            LoginController.logUserOut(LogoutReason.Banned)
        }
        else if returnStatus == LoggedUserSessionState.GeneralLogout {
            LoginController.logUserOut(LogoutReason.ReceivedGeneralLogout)
        }
        else if returnStatus == LoggedUserSessionState.YellowCard {
            guard let rootController = UIApplication.sharedApplication().keyWindow?.rootViewController else {
                return
            }
            
            let alert = UIAlertController(title: NSLocalizedString("Warning", comment: "Yellow Card") , message:NSLocalizedString("Warning_Message", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(
                UIAlertAction(title: NSLocalizedString("See_Terms", comment: "See Terms"), style: UIAlertActionStyle.Default, handler: { (action) in
                    let terms = NSLocalizedString("Blicup_Terms", comment: "Terms link")
                    if let termsUrl = NSURL(string: terms) {
                        if #available(iOS 9.0, *) {
                            let svc = SFSafariViewController(URL: termsUrl)
                            rootController.presentViewController(svc, animated: true, completion: nil)
                        } else {
                            // Fallback on earlier versions
                            UIApplication.sharedApplication().openURL(termsUrl)
                        }
                    }
                })
            )
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
            rootController.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func showSimultaneousSessionAlert(notification:NSNotification) {
        guard let rootController = UIApplication.sharedApplication().keyWindow?.rootViewController else {
                return
        }
        
        let alert = UIAlertController(title: "Sessão ja ativa" , message:nil, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(
            UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action) in
                LDTProtocolImpl.sharedInstance.initSocket()
            })
        )
        rootController.presentViewController(alert, animated: true, completion: nil)
    }

    
    // MARK: Observers handling for assync events on chatrooms
    func addObserveToMessagesUpdates(observer: AnyObject,
                                     rSelector: Selector, chatroom: ChatRoom)    {
        NSNotificationCenter.defaultCenter().addObserver(observer, selector: rSelector, name: ChatMessageNotification.MessageReceived.rawValue, object: chatroom)
    }
    
    func removeObserveToMessagesUpdates(observer: AnyObject,  chatroom: ChatRoom?)    {
        NSNotificationCenter.defaultCenter().removeObserver(observer, name: ChatMessageNotification.MessageReceived.rawValue, object: chatroom)
    }
    
    func addObserveToMessagesLikeUpdates(observer: AnyObject,
                                     rSelector: Selector, chatroom: ChatRoom)    {
        NSNotificationCenter.defaultCenter().addObserver(observer, selector: rSelector, name: ChatMessageNotification.MessageLikeReceived.rawValue, object: chatroom)
    }
    
    func removeObserveToMessagesLikeUpdates(observer: AnyObject,  chatroom: ChatRoom)    {
        NSNotificationCenter.defaultCenter().removeObserver(observer, name: ChatMessageNotification.MessageLikeReceived.rawValue, object: chatroom)
    }
    
    
    func addObserveToChatroomUpdates(observer: AnyObject,
                                     rSelector: Selector, chatroom: ChatRoom)    {
        NSNotificationCenter.defaultCenter().addObserver(observer, selector: rSelector, name: ChatMessageNotification.ChatroomReceived.rawValue, object: chatroom)
    }
    
    func removeObserveToChatroomUpdates(observer: AnyObject,  chatroom: ChatRoom)    {
        NSNotificationCenter.defaultCenter().removeObserver(observer, name: ChatMessageNotification.ChatroomReceived.rawValue, object: chatroom)
    }
    
    func addObserveToChatroomDeath(observer: AnyObject,
                                   rSelector: Selector, chatRoom: ChatRoom)    {
        NSNotificationCenter.defaultCenter().addObserver(observer, selector: rSelector, name: ChatMessageNotification.ChatroomIsDead.rawValue, object: chatRoom)
    }
    
    func removeObserveToChatroomDeath(observer: AnyObject, chatRoom: ChatRoom?)    {
        NSNotificationCenter.defaultCenter().removeObserver(observer, name: ChatMessageNotification.ChatroomIsDead.rawValue, object: chatRoom)
    }

    
    func addObserveToChatroomRemoval(observer: AnyObject,
                                   rSelector: Selector, chatRoom: ChatRoom)    {
        NSNotificationCenter.defaultCenter().addObserver(observer, selector: rSelector, name: ChatMessageNotification.ChatroomBannedForUser.rawValue, object: chatRoom)
    }
    
    func removeObserveToChatroomRemoval(observer: AnyObject, chatRoom: ChatRoom?)    {
        NSNotificationCenter.defaultCenter().removeObserver(observer, name: ChatMessageNotification.ChatroomBannedForUser.rawValue, object: chatRoom)
    }
    
    func addObserveToChatroomBanned(observer: AnyObject,
                                     rSelector: Selector, chatRoom: ChatRoom)    {
        NSNotificationCenter.defaultCenter().addObserver(observer, selector: rSelector, name: ChatMessageNotification.ChatroomIsBanned.rawValue, object: chatRoom)
    }
    
    func removeObserveToChatroomBanned(observer: AnyObject, chatRoom: ChatRoom?)    {
        NSNotificationCenter.defaultCenter().removeObserver(observer, name: ChatMessageNotification.ChatroomIsBanned.rawValue, object: chatRoom)
    }
    
}
