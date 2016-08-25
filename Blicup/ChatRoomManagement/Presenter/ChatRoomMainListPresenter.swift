//
//  ChatRoomMainListPresenter.swift
//  Blicup
//
//  Created by Moymer on 01/07/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class ChatRoomMainListPresenter: ChatRoomFetchResultPresenter, ChatRoomSizeProtocol, ChatRoomContextMenuProtocol {
    
    internal var contextMenuImagesName = ["dots_black", "share_black", "chat_black"]
    internal var contextMenuHighlightedImagesName = ["dots_white", "share_white", "chat_white"]
    internal var contextMenuHighlightedImagesTitle = [NSLocalizedString("More", comment: "More"), NSLocalizedString("LongPressMenuShare", comment: "Share"), NSLocalizedString("Enter Chat", comment: "Enter Chat")]
    
    override init() {
        super.init()
        
        let predicate = NSPredicate(format: "(grade != nil) AND (saved == false)")
        initFetchResultController(predicate: predicate, sortDescriptors: nil)
    }
    
    func updateChatRoomList(completionHandler: (success: Bool) -> Void) {
        ChatRoomBS.getChatRooms(deleteOldEntries: true) { (success, chatRoomsList) in
            self.performFetch()
            completionHandler(success: success)
        }
    }
    
    func getMoreChatRooms(completionHandler:((success:Bool)->Void)?) {
        ChatRoomBS.getChatRooms(deleteOldEntries: false) { (success, chatRoomsList) in
            completionHandler?(success: success)
        }
    }
    
    func photoUrlList(index: NSIndexPath) -> [String] {
        let chatRoom = chatRoomAtIndex(index)
        var urlArray = [String]()
        
        guard let photoList = chatRoom.photoList else {
            return urlArray
        }
        
        for photo in photoList {
            if let photoUrl = (photo as! Photo).photoUrl {
                urlArray.append(photoUrl)
            }
        }
        
        return urlArray
    }
    
    func chatRoomMainThumbUrl(index:NSIndexPath)->NSURL? {
        let chatRoom = chatRoomAtIndex(index)
        
        guard let firstPhoto = chatRoom.photoList?.firstObject as? Photo,
            let photoUrlString = firstPhoto.photoUrl else {
                return nil
        }
        
        let thumbUrlString = AmazonManager.getThumbUrlFromMainUrl(photoUrlString)
        return NSURL(string: thumbUrlString)
    }
}
