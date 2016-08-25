//
//  ChatRoomShareCard.swift
//  Blicup
//
//  Created by Guilherme Braga on 15/07/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class ChatRoomShareCard: NSObject, UIActivityItemSource {

    let chatRoomId: String
    
    required init(chatRoomId id: String) {
        self.chatRoomId = id
    }
    
    func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
        return ""
    }
    
    func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
        
        let chatAmazonHtml = AmazonManager.getChatAmazonUrl(whithChatId: self.chatRoomId)
        
        if activityType == UIActivityTypePostToTwitter {
        
            let chatRoomShareMessage = NSLocalizedString("ChatRoomShare_Message_Twitter", comment: "Hey! Check it out @blicupapp")
            return "\(chatRoomShareMessage)\n\n \(chatAmazonHtml)"
        }
    
        return chatAmazonHtml
    }
}
