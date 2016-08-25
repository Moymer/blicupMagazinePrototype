//
//  MyChatsPresenter.swift
//  Blicup
//
//  Created by Moymer on 30/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import CoreData

class MyChatsPresenter: ChatRoomFetchResultPresenter, ChatRoomContextMenuProtocol {
    
    internal var contextMenuImagesName = ["dots_black", "share_black", "chat_black"]
    internal var contextMenuHighlightedImagesName = ["dots_white", "share_white", "chat_white"]
    internal var contextMenuHighlightedImagesTitle = [NSLocalizedString("More", comment: "More"), NSLocalizedString("LongPressMenuShare", comment: "Share"), NSLocalizedString("Enter Chat", comment: "Enter Chat")]
    
    override init() {
        super.init()
        
        let lastMessage = NSSortDescriptor(key: "lastMsgDate", ascending: false)
        let creationDate = NSSortDescriptor(key: "creationDate", ascending: false)
        let gradeSortDescriptor = NSSortDescriptor(key: "grade", ascending: false)
        let sortDescriptors = [lastMessage, gradeSortDescriptor, creationDate]
        
        let predicate = NSPredicate(format: "saved == true")
        
        initFetchResultController(predicate: predicate, sortDescriptors: sortDescriptors)        
    }
    
    func loadMyChats(completionHandler:((success:Bool, chatRoomsList: [ChatRoom]?)->Void)?) {
        ChatRoomBS.getMyChatRooms { (success, chatRoomsList) in
            self.performFetch()
            completionHandler?(success: success, chatRoomsList: chatRoomsList)
        }
    }
    
    func reloadMyChatsList(completionHandler:((success:Bool,  chatRoomsList: [ChatRoom]?)->Void)?) {
        ChatRoomBS.getMyChatRooms { (success, chatRoomsList) in
            completionHandler?(success: success, chatRoomsList: chatRoomsList)
        }
    }
    
    func chatRoomHasNewMessages(index:NSIndexPath)->Bool {
        let chat = chatRoomAtIndex(index)
        return chat.showBadge!.boolValue
    }
    
    override func controllerDidChangeContent(controller: NSFetchedResultsController) {
        super.controllerDidChangeContent(controller)
        BlicupRouter.updateMyChatsTabBadge()
    }
    
    
    func chatRoomThumbUrlList(index:NSIndexPath)->[NSURL] {
        let chatRoom = chatRoomAtIndex(index)
        var urlArray = [NSURL]()
        
        guard let photoList = chatRoom.photoList else {
            return urlArray
        }
        
        for photo in photoList {
            guard let photoUrl = (photo as! Photo).photoUrl else {
                continue
            }
            
            if let thumbUrl = NSURL(string: AmazonManager.getThumbUrlFromMainUrl(photoUrl)) {
                urlArray.append(thumbUrl)
            }
        }
        
        return urlArray
    }
    
    func isChatRoomOver(index:NSIndexPath)->Bool {
        guard let chatState = chatRoomAtIndex(index).state else {
            return false
        }
        
        return (chatState.integerValue != ChatRoom.ChatRoomState.Active.rawValue)
    }
    
    func chatOverText(index:NSIndexPath)->String? {
        guard let chatState = chatRoomAtIndex(index).state else {
            return nil
        }
        
        if chatState.integerValue == ChatRoom.ChatRoomState.Dead.rawValue {
            return NSLocalizedString("DeadChatOverlayText", comment: "Over")
        }
        else if chatState.integerValue == ChatRoom.ChatRoomState.Removed.rawValue {
            return NSLocalizedString("RemovedChatOverlayText", comment: "Removed")
        }
        else if chatState.integerValue == ChatRoom.ChatRoomState.Banned.rawValue {
            return NSLocalizedString("BannedOverlayText", comment: "Banned")
        }
        else {
            return nil
        }
    }
    
    func removeChatRoomOfInterest(index: NSIndexPath, completionHandler:(success: Bool) -> Void) {
        guard let chatRoomId = chatRoomAtIndex(index).chatRoomId else { return }
        
        ChatRoomBS.removeChatRoomOfInterest(chatRoomId) { (success) in
            // TODO: Definir comportamento caso retorno seja falso
            if success {
                self.removeChatRoomSaved(indexPath: index)
            }
            //print("Chat Removido \(success)")
            completionHandler(success: success)
        }
    }

    private func removeChatRoomSaved(indexPath index: NSIndexPath) {
        
        let chatRoom = chatRoomAtIndex(index)
        
        chatRoom.saved = false
        
        if let userInfo = UserBS.getLoggedUser()?.userInfo {
            if var myChats = userInfo.myChatroomList as? [String], let index = myChats.indexOf(chatRoom.chatRoomId!) {
                
                myChats.removeAtIndex(index)
                userInfo.myChatroomList = myChats
            }
            else {
                userInfo.myChatroomList = [chatRoom.chatRoomId!]
            }
        }
    }
    
    
    // MARK: Leave Chat Dialog text
    func removeChatRoomOfInterestDialogTitle() -> String {
        
        let title = NSLocalizedString("removeChatRoomOfInterestDialogTitle", comment: "Leave chat")
        
        return title
    }
    
    func removeChatRoomOfInterestDialogMessage(index: NSIndexPath) -> String {
        
        var message = NSLocalizedString("removeChatRoomOfInterestDialogMessagePart1", comment: "Leave chat dialog message")
        let message2 = NSLocalizedString("removeChatRoomOfInterestDialogMessagePart2", comment: "Leave chat dialog message")
        
        if let chatRoomName = chatRoomAtIndex(index).name {
            message = "\(message) \"\(chatRoomName)\"? \(message2)"
        }
        else {
            let placeholder = NSLocalizedString("removeChatRoomOfInterestPlaceholder", comment: "this chat")
            message = "\(message) \(placeholder)? \(message2)"
        }
        
        return message
    }
}
