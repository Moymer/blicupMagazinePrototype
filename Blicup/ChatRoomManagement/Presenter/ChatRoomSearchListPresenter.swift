//
//  ChatRoomSearchListPresenter.swift
//  Blicup
//
//  Created by Moymer on 01/07/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class ChatRoomSearchListPresenter: ChatRoomFetchResultPresenter, ChatRoomSizeProtocol, ChatRoomContextMenuProtocol {
    private var chatIds = [String]()
    var searchTerm = ""
    var searchTermTimestamp: NSTimeInterval = 0.0
    internal var contextMenuImagesName = ["dots_black", "share_black", "chat_black"]
    internal var contextMenuHighlightedImagesName = ["dots_white", "share_white", "chat_white"]
    internal var contextMenuHighlightedImagesTitle = [NSLocalizedString("More", comment: "More"), NSLocalizedString("LongPressMenuShare", comment: "Share"), NSLocalizedString("Enter Chat", comment: "Enter Chat")]
    
    override init() {
        super.init()
        initFetchResultController(predicate: nil, sortDescriptors: nil)
    }
    
    func clearChats() {
        self.chatIds = [String]()
        let predicate = NSPredicate(format: "chatRoomId IN %@", self.chatIds)
        self.fetchedResultsController.fetchRequest.predicate = predicate
        performFetch()
    }
    
    func searchChatRoomsWithSearchTerm(searchTerm: String, timestamp: NSTimeInterval, completionHandler:(success: Bool) -> Void) {
        self.searchTerm = searchTerm
        searchTermTimestamp = timestamp
        
        ChatRoomBS.getChatroomsThatMatchesSearchTerm(searchTerm) { (searchTerm, success, chatRoomsIdList) in
            
            if timestamp == self.searchTermTimestamp {
                
                if success {
                    if chatRoomsIdList == nil {
                        self.chatIds = [String]()
                    }
                    else {
                        self.chatIds = chatRoomsIdList!
                    }
                    
                    self.fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "chatRoomId IN %@", self.chatIds)
                    self.performFetch()
                }
                
                completionHandler(success: success)
            }
        }
    }
    
    func currentChatIds()->[String] {
        return chatIds
    }
    
    func tagAlreadyInUserTagList(tag: String) -> Bool {
        
        guard let user = UserBS.getLoggedUser() else {
            return false
        }
        
        if let tagList = user.tagList {
            return tagList.contains(tag)
        }
        
        return false
    }
    
    func setTagInUser(completionHandler:(success: Bool) -> Void) {
        if let user = UserBS.getLoggedUser() {
            if var tagList = user.tagList {
                
                tagList.append(searchTerm)
                
                let updateJson = [
                    User.Keys.UserID.rawValue: user.userId!,
                    User.Keys.Username.rawValue: user.username!,
                    User.Keys.PhotoUrl.rawValue: user.photoUrl!,
                    User.Keys.TagList.rawValue: tagList
                ]
                
                UserBS.changeUserProfile(updateJson, completionHandler: { (success) in
                    completionHandler(success: success)
                })
            }
        } else {
            completionHandler(success: false)
        }
    }
}
