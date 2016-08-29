//
//  ChatRoomsListProtocol.swift
//  Blicup
//
//  Created by Moymer on 30/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation

protocol ChatRoomsListProtocol: class {
    func chatRoomAtIndex(index:NSIndexPath) -> ChatRoom
    func chatRoomsCount() -> Int
    
    // Default Impl.
    func chatRoomLastUpdate(index:NSIndexPath) -> Double
    func chatRoomOwner(index: NSIndexPath) -> User?
    func chatRoomOwnerName(forIndex index:NSIndexPath)->String?
    func chatRoomOwnerPhotoUrl(forIndex index:NSIndexPath)->NSURL?
    func chatRoomPhotoUrlList(index: NSIndexPath) -> [NSURL]
    func chatRoomPhotoCount(index:NSIndexPath) -> Int
    func chatRoomMainImageUrl(index:NSIndexPath) -> NSURL?
    func chatRoomAddress(index:NSIndexPath)-> NSAttributedString?
    func chatRoomName(forIndex index:NSIndexPath)->String?
    func chatRoomNumberOfParticipants(index:NSIndexPath)->Int
    func chatRoomHashtags(forIndex index:NSIndexPath)->String?
    func chatRoomParticipantsCount(spaceSize:CGSize, forIndex index: NSIndexPath )->Int
    func chatRoomMainColor(index: NSIndexPath) -> UIColor?
}

protocol ChatRoomSizeProtocol: class {
    func chatRoomAtIndex(index:NSIndexPath) -> ChatRoom
    
    // Default Impl.
    func getChatCellSize(index: NSIndexPath) -> CGSize
    func getChatItemSizeForLines(totalOfLines:Int) -> CGSize
}

protocol ChatRoomReportProtocol: class {
    
    func chatRoomAtIndex(index:NSIndexPath) -> ChatRoom
    
    // Default Impl.
    //MARK: Report chat room
    func reportChatRoom(index: NSIndexPath, completionHandler:(success: Bool) -> Void)
    func reportChatDialogTitle() -> String
    func reportChatDialogMessage(index: NSIndexPath) -> String
    func thanksForReportingDialogTitle() -> String
    func thanksForReportingDialogMessage() -> String
}

protocol ChatRoomShareProtocol: class {
    func chatRoomAtIndex(index: NSIndexPath) -> ChatRoom
    func chatRoomShareCard(index: NSIndexPath) -> ChatRoomShareCard?
}


// MARK: -  Default Implementations

extension ChatRoomsListProtocol {
    func chatRoomLastUpdate(index:NSIndexPath) -> Double {
        let chatRoom = chatRoomAtIndex(index)
        
        if  chatRoom.lastMsgDate?.doubleValue > 0 {
            return (chatRoom.lastMsgDate?.doubleValue)!
        }
        else {
            return (chatRoom.creationDate?.doubleValue)!
        }
    }
    
    func chatRoomOwner(index: NSIndexPath) -> User? {
        let chatRoom = chatRoomAtIndex(index)
        return chatRoom.whoCreated
    }
    
    func chatRoomOwnerName(forIndex index:NSIndexPath)->String? {
        guard let userName = chatRoomOwner(index)?.username else {
            return nil
        }
        
        return ("@" + userName)
    }
    
    func chatRoomOwnerPhotoUrl(forIndex index:NSIndexPath)->NSURL? {
        guard let urlString = chatRoomOwner(index)?.photoUrl else {
            return nil
        }
        
        return NSURL(string:urlString)
    }
    
    func chatRoomOwnerIsVerified(forIndex index: NSIndexPath) -> Bool {
        guard let isVerified = chatRoomOwner(index)?.isVerified else {
            return false
        }
        
        return isVerified.boolValue
    }
    
    func chatRoomPhotoUrlList(index: NSIndexPath) -> [NSURL] {
        let chatRoom = chatRoomAtIndex(index)
        var urlArray = [NSURL]()
        
        guard let photoList = chatRoom.photoList?.array as? [Photo] else {
            return urlArray
        }
        
        for photo in photoList {
            guard let photoUrlString = photo.photoUrl else {
                continue
            }
            
            if let photoUrl = NSURL(string: photoUrlString) {
                urlArray.append(photoUrl)
            }
        }
        
        return urlArray
    }
    
    func chatRoomPhotoCount(index:NSIndexPath) -> Int {
        let chatRoom = chatRoomAtIndex(index)
        
        guard let photoList = chatRoom.photoList else {
            return 0
        }
        
        return photoList.count
    }
    
    func chatRoomMainImageUrl(index:NSIndexPath) -> NSURL? {
        let chatRoom = chatRoomAtIndex(index)
        
        guard let firstPhoto = chatRoom.photoList?.firstObject as? Photo,
            let photoUrlString = firstPhoto.photoUrl else {
            return nil
        }
        
        return NSURL(string: photoUrlString)
    }
    
    func chatRoomAddress(index:NSIndexPath)-> NSAttributedString? {
        
        let chat = chatRoomAtIndex(index)
        
        guard let address = chat.address?.formattedAddress else {
            return nil
        }
        
        let addressComponents = address.componentsSeparatedByString(",")
        
        var stringFormatted = ""
        for string in addressComponents {
            stringFormatted += string + ", "
        }
        
        stringFormatted = String(stringFormatted.characters.dropLast().dropLast())
        
        guard let firstDataRange = stringFormatted.rangeOfString(",") else {
            return NSAttributedString(string: address, attributes: [NSFontAttributeName:UIFont(name: "SFUIText-Bold", size: 14)!])
        }
        
        let length = address.startIndex.distanceTo(firstDataRange.startIndex)
        
        let attrString = NSMutableAttributedString(string: stringFormatted, attributes:[NSFontAttributeName:UIFont(name: "SFUIText-Regular", size: 14)!])
        attrString.addAttributes([NSFontAttributeName:UIFont(name: "SFUIText-Bold", size: 14)!], range: NSMakeRange(0, length))
        
        return attrString
    }
    
    func chatRoomName(forIndex index:NSIndexPath)->String? {
        let chat = chatRoomAtIndex(index)
        return chat.name
    }
    
    func chatRoomNumberOfParticipants(index:NSIndexPath)->Int {
        if let chatParticipants = chatRoomAtIndex(index).participantCount {
            return chatParticipants.integerValue
        }
        
        return 0
    }
    
    func chatRoomHashtags(forIndex index:NSIndexPath)->String? {
        let chat = chatRoomAtIndex(index)
        
        guard let hashtags = chat.tagList else{
            return nil
        }
        
        return hashtags.convertToBlicupHashtagString()
    }
    
    func chatRoomParticipantsCount(spaceSize:CGSize, forIndex index: NSIndexPath )->Int {
        
        let chatroom = chatRoomAtIndex(index)
        let photoSideSize = spaceSize.height
        let photosSpacement:CGFloat = 8
        
        let numberOfPhotos = floor((spaceSize.width+photosSpacement)/(photoSideSize+photosSpacement))
        var participantCountWithPhotos = Int(numberOfPhotos)
        
        if let count = chatroom.participantList?.count
        {
            participantCountWithPhotos =  min(participantCountWithPhotos, count)
        }
        
        return participantCountWithPhotos
    }
    
    func chatRoomMainColor(index: NSIndexPath) -> UIColor? {
        let chatRoom = chatRoomAtIndex(index)
        
        guard let photo = chatRoom.photoList?.firstObject as? Photo,
            let mainColor = photo.mainColor as? Int else {
                return nil
        }
        
        let color = UIColor.rgbIntToUIColor(mainColor)
        return color
    }
}


extension ChatRoomSizeProtocol {
    func getChatCellSize(index: NSIndexPath) -> CGSize {
        
        let chatRoom = chatRoomAtIndex(index)
        if let photo = chatRoom.photoList?.firstObject as? Photo {
            let cellHeight = CGFloat(photo.height!)
            let cellWidth = CGFloat(photo.width!)
            return CGSizeMake(cellWidth, cellHeight)
        }
        
        return CGSizeMake(170, 300)
    }
    
    func getChatItemSizeForLines(totalOfLines:Int) -> CGSize {
        return CGSize(width: 345, height: 345)
    }
}

extension ChatRoomReportProtocol {
    
    //MARK: Report chat room
    func reportChatRoom(index: NSIndexPath, completionHandler:(success: Bool) -> Void) {
        
        let chatRoom = chatRoomAtIndex(index)
        
        ChatRoomBS.reportChatRoom(chatRoom) { (success) in
            // TODO: Definir comportamento caso retorno seja falso
            //print("Chat Reportado \(success)")
            completionHandler(success: success)
        }
    }

    
    // MARK: Report Chat Dialog text
    func reportChatDialogTitle() -> String {
        
        let title = NSLocalizedString("ReportChatDialogTitle", comment: "Report chat")
        
        return title
    }
    
    func reportChatDialogMessage(index: NSIndexPath) -> String {
        
        let chatRoom = chatRoomAtIndex(index)
        
        var message = NSLocalizedString("ReportChatMessage", comment: "Report dialog message")
        let report = NSLocalizedString("Report", comment: "Report")
        
        if let chatRoomName = chatRoom.name {
            message = "\(report) \"\(chatRoomName)\" \(message)"
        }
        else {
            let placeholder = NSLocalizedString("ReportChatPlaceholder", comment: "this chat")
            message = "\(report) \(placeholder) \(message)"
        }
        
        return message
    }
    
    func thanksForReportingDialogTitle() -> String {
        
        let title = NSLocalizedString("ThanksForReportingTitle", comment: "Thank your for reporting")
        
        return title
    }
    
    func thanksForReportingDialogMessage() -> String {
        
        let message = NSLocalizedString("ThanksForReportingMessage", comment: "Thank you for reporting dialog message")
        
        return message
        
    }
}

extension ChatRoomShareProtocol {
    
    func chatRoomShareCard(index: NSIndexPath) -> ChatRoomShareCard? {
        
        let chatRoom = chatRoomAtIndex(index)
        
        guard let chatRoomId = chatRoom.chatRoomId else { return nil }
        
        return ChatRoomShareCard(chatRoomId: chatRoomId)
    }
}