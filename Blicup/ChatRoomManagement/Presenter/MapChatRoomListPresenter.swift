//
//  MapChatRoomListPresenter.swift
//  Blicup
//
//  Created by Moymer on 01/07/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class MapChatRoomListPresenter: ChatRoomFetchResultPresenter, ChatRoomSizeProtocol, ChatRoomContextMenuProtocol {
    private var chatIds = [String]()
    
    internal var contextMenuImagesName = ["dots_black", "share_black", "chat_black"]
    internal var contextMenuHighlightedImagesName = ["dots_white", "share_white", "chat_white"]
    internal var contextMenuHighlightedImagesTitle = [NSLocalizedString("More", comment: "More"), NSLocalizedString("LongPressMenuShare", comment: "Share"), NSLocalizedString("Enter Chat", comment: "Enter Chat")]
    
    convenience init(withLocalChats chatIds:[String]) {
        self.init()
        
        self.chatIds = chatIds
        let predicate = NSPredicate(format: "chatRoomId IN %@", chatIds)
        initFetchResultController(predicate: predicate, sortDescriptors: nil)
        
        performFetch()
    }
    
    func currentChatIds()->[String] {
        return chatIds
    }
}