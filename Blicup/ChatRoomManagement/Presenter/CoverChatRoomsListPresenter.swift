//
//  CoverChatRoomsListPresenter.swift
//  Blicup
//
//  Created by Moymer on 01/07/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

protocol CoverChatRoomsListPresenterDelegate: class {
    func showMessagePreview(photo photoUrl:NSURL?, userID: String, user:String?, message:String?, isUpdating: Bool)
    func chatRoomRemovalOrDead(chatRoom: ChatRoom)
}

protocol CoverChatRoomMessengersUpdated: class {
    func didUpdateChatMessages()
}


class CoverChatRoomsListPresenter: ChatRoomFetchResultPresenter, ChatRoomContextMenuProtocol {

    internal var contextMenuImagesName = ["dots_black", "share_black"]
    internal var contextMenuHighlightedImagesName = ["dots_white", "share_white"]
    internal var contextMenuHighlightedImagesTitle = [NSLocalizedString("More", comment: "More"), NSLocalizedString("LongPressMenuShare", comment: "Share")]
    
    var isLoadingMessageChats = false
    
    var currentChatId = "" {
        didSet {
            NSUserDefaults.standardUserDefaults().setValue(currentChatId, forKey: kCurrentOpenChatRoomIdKey)
        }
    }
    
    weak var presenterDelegate: CoverChatRoomsListPresenterDelegate?
    weak var messagesDelegate: CoverChatRoomMessengersUpdated?
    
    var currentIndex: NSIndexPath {
        set {
            if let chatId = self.chatRoomAtIndex(newValue).chatRoomId {
                currentChatId = chatId
            }
            else {
                currentChatId = ""
            }
        }
        
        get {
            return indexPathOfChat(currentChatId)
        }
    }
    
    convenience init(withLocalChats chatIds:[String]) {
        self.init()
        
        let predicate = NSPredicate(format: "chatRoomId IN %@", chatIds)
        initFetchResultController(predicate: predicate, sortDescriptors: nil)
        
        performFetch()
    }
    
    convenience init(withMyChats:Bool) {
        self.init()
        
        if withMyChats {
            let predicate = NSPredicate(format: "saved == true")
            
            let lastMessage = NSSortDescriptor(key: "lastMsgDate", ascending: false)
            let creationDate = NSSortDescriptor(key: "creationDate", ascending: false)
            let gradeSortDescriptor = NSSortDescriptor(key: "grade", ascending: false)
            let sortDescriptors = [lastMessage, gradeSortDescriptor, creationDate]
            
            initFetchResultController(predicate: predicate, sortDescriptors: sortDescriptors)
        }
        else {
            let predicate = NSPredicate(format: "(grade != nil) AND (saved == false)")
            initFetchResultController(predicate: predicate, sortDescriptors: nil)
        }
        
        performFetch()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(kCurrentOpenChatRoomIdKey)

        stopUpdatingChat(currentIndex)
    }
    
    
    func stillHasChats()->Bool {
        return (chatRoomsCount() > 0)
    }
    
    func chatRoomThumbUrl(chatIndex chatIndex:NSIndexPath, photoNumber:Int)->NSURL? {
        let chatRoom = chatRoomAtIndex(chatIndex)
        
        guard let photo = chatRoom.photoList?.objectAtIndex(photoNumber) as? Photo,
            let photoUrlString = photo.photoUrl else {
                return nil
        }
        
        let thumbUrlString = AmazonManager.getThumbUrlFromMainUrl(photoUrlString)
        
        if thumbUrlString != photoUrlString {
            return NSURL(string: thumbUrlString)
        }
        else {
            return nil
        }
    }
    
    func chatRoomPhotoUrl(chatIndex chatIndex:NSIndexPath, photoNumber:Int)->NSURL? {
        let chatRoom = chatRoomAtIndex(chatIndex)
        
        guard let photo = chatRoom.photoList?.objectAtIndex(photoNumber) as? Photo,
            let photoUrlString = photo.photoUrl else {
                return nil
        }
        
        return NSURL(string: photoUrlString)
    }
    
    private func isBlockingMe(userId:String)->Bool {
        guard let blockerList = UserBS.getLoggedUser()?.userInfo?.blockerList as? [String] else {
            return false
        }
        
        return blockerList.contains(userId)
    }
    
    func userIsBlockingMe(userId:String)->Bool {
        guard let blockerList = UserBS.getLoggedUser()?.userInfo?.blockerList as? [String] else {
            return false
        }
        
        return blockerList.contains(userId)
    }
    
    func isBlockedUser(userId:String)->Bool {
        guard let blockerList = UserBS.getLoggedUser()?.userInfo?.blockedList as? [String] else {
            return false
        }
        
        return blockerList.contains(userId)
    }
    
    func chatRoomParticipantPhotoURL(chatRoomIndex index:NSIndexPath, participantIndex:Int)->NSURL? {
        let chatroom = chatRoomAtIndex(index)
        
        guard let user =  chatroom.participantList?.objectAtIndex(participantIndex) as? User else {
            return nil
        }
        
        guard !isBlockingMe(user.userId!), let urlString = user.photoUrl else {
            return nil
        }
        
        return NSURL(string:urlString)
    }
    
    private func indexPathOfChat(chatId:String)->NSIndexPath {
        guard let chat = ChatRoom.chatRoomWithId(chatId) else {
            return NSIndexPath(forRow: 0, inSection: 0)
        }
        
        guard let index = fetchedResultsController.indexPathForObject(chat) else {
            return NSIndexPath(forRow: 0, inSection: 0)
        }
        
        return index
    }

    func checkIfChatRoomRemovalOrDead(chatRoomIndex index: NSIndexPath)  {
    
        let chatRoom = chatRoomAtIndex(index)
        
        if chatRoom.state == ChatRoom.ChatRoomState.Dead.rawValue
            || chatRoom.state == ChatRoom.ChatRoomState.Removed.rawValue
            || chatRoom.state == ChatRoom.ChatRoomState.Banned.rawValue {
                presenterDelegate?.chatRoomRemovalOrDead(chatRoom)
        }
    }
    
    func isLoggedUserChatOwner(chatRoomIndex index: NSIndexPath) -> Bool {
        
        let chatRoom = chatRoomAtIndex(index)
        let whoCreated = chatRoom.whoCreated?.userId
        let loggedUser = UserBS.getLoggedUser()?.userId
        
        return whoCreated == loggedUser
    }
    
    func isBlockingMe(chatRoomIndex index: NSIndexPath) -> Bool {
        
        let chatRoom = chatRoomAtIndex(index)
        
        guard let blockerList = UserBS.getLoggedUser()?.userInfo?.blockerList as? [String],
            whoCreatedUserId = chatRoom.whoCreated?.userId else {
                return false
        }
        
        return blockerList.contains(whoCreatedUserId)
    }
    
    // MARK: - Chat Accessors
    func startUpdatingChat(index:NSIndexPath) {
        guard stillHasChats() else {
            return
        }
        
        let chatRoom = chatRoomAtIndex(index)
        BlicupAnalytics.sharedInstance.seenChatCover(chatRoom.chatRoomId!)
        ChatRoomBS.enterChatRoom(chatRoom.chatRoomId!, completionHandler: nil)
        BlicupAsyncHandler.sharedInstance.addObserveToMessagesUpdates(self, rSelector: #selector(CoverChatRoomsListPresenter.didReceivedChatRoomMessage(_:)), chatroom: chatRoom)
        BlicupAsyncHandler.sharedInstance.addObserveToChatroomDeath(self, rSelector: #selector(CoverChatRoomsListPresenter.receiveChatRoomRemovalOrChatRoomDeath(_:)), chatRoom: chatRoom)
        BlicupAsyncHandler.sharedInstance.addObserveToChatroomRemoval(self, rSelector: #selector(CoverChatRoomsListPresenter.receiveChatRoomRemovalOrChatRoomDeath(_:)), chatRoom: chatRoom)
        BlicupAsyncHandler.sharedInstance.addObserveToChatroomBanned(self, rSelector: #selector(CoverChatRoomsListPresenter.receiveChatRoomRemovalOrChatRoomDeath(_:)), chatRoom: chatRoom)
        
        let chatId = self.currentChatId
        isLoadingMessageChats = true
        ChatRoomBS.getChatroomMsgsSinceLastUpdate(chatRoom.chatRoomId!) { (success) in
            if chatId == self.currentChatId {
                self.messagesDelegate?.didUpdateChatMessages()
                self.isLoadingMessageChats = false
            }
        }
    }
    
    func stopUpdatingChat(index:NSIndexPath) {
        var chatRoom: ChatRoom?
        
        if stillHasChats() {
            chatRoom = chatRoomAtIndex(index)
            ChatRoomBS.leaveChatRoom(chatRoom!.chatRoomId!, completionHandler: nil)
        }
        
        BlicupAsyncHandler.sharedInstance.removeObserveToMessagesUpdates(self, chatroom: chatRoom)
        BlicupAsyncHandler.sharedInstance.removeObserveToChatroomDeath(self, chatRoom: chatRoom)
        BlicupAsyncHandler.sharedInstance.removeObserveToChatroomRemoval(self, chatRoom: chatRoom)
        BlicupAsyncHandler.sharedInstance.removeObserveToChatroomBanned(self, chatRoom: chatRoom)
    }
    
    func receiveChatRoomRemovalOrChatRoomDeath(notification: NSNotification) {
        
        let chatRoom = notification.userInfo!["chatroom"] as! ChatRoom
        presenterDelegate?.chatRoomRemovalOrDead(chatRoom)
    }
    
    func didReceivedChatRoomMessage(notification:NSNotification) {
        guard let message = notification.userInfo?["message"] as? ChatRoomMessage,
            let isUpdating = notification.userInfo?["isUpdating"] as? Bool,
            let userID = message.whoSent?.userId else {
                return
        }
        
        var userPhoto:NSURL?
        if let photoUrl = message.whoSent?.photoUrl {
            userPhoto = NSURL(string: photoUrl)
        }
        
        var userName = message.whoSent?.username
        if userName != nil {
            userName = "@"+userName!
        }
        
        var content = message.content
        if message.msgType?.integerValue == ChatRoomMessage.MessageType.IMAGE_MSG.rawValue {
            content = "🎥GIF"
        }
        
        presenterDelegate?.showMessagePreview(photo: userPhoto, userID: userID, user: userName, message: content, isUpdating: isUpdating)
    }

}
