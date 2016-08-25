//
//  ChatRoomBS.swift
//  Blicup
//
//  Created by Guilherme Braga on 05/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Alamofire
import CoreData

class ChatRoomBS: NSObject {

    class func createPublishHTMLDic(chatRoom: ChatRoom) -> NSDictionary {
        
        var imageURL = ""
        if let photo = chatRoom.photoList?.firstObject as? Photo {
            if let unwrappedImageURL = photo.photoUrl {
                imageURL = unwrappedImageURL
            }
        }
        
        let htmlDic: NSDictionary = ["pathMessage" : chatRoom.chatRoomId!,
                                     "title"       : chatRoom.name!,
                                     "description" : NSLocalizedString("publish_Description", comment: "") + (chatRoom.tagList!).convertToBlicupHashtagString(),
                                     "image"       : imageURL]
        
        return htmlDic   
    }
    
    
    class func getChatRooms(deleteOldEntries shouldDeleteOld:Bool, completionHandler:((success: Bool, chatRoomsList: [ChatRoom]?) -> Void)? ){
        LDTProtocolImpl.sharedInstance.getChatroomOfInterest(!shouldDeleteOld , completionHandler: { (success, retMsg) in
            //print(retMsg)
            
            if success
            {
                guard let chatRoomsDicArray = (retMsg!["Ans"] as? [NSDictionary]) else {
                    completionHandler?(success: false, chatRoomsList: nil)
                    return
                }
                
                ChatRoom.createChatroomsInBG(chatRoomsDicArray, deleteOtherEntries: shouldDeleteOld, isMyChat: false, completionHandler: { (chatRoomsList) in
                    completionHandler?(success: true, chatRoomsList: chatRoomsList)
                })
            }
            else {
                completionHandler?(success: false, chatRoomsList: nil)
            }
        })
    }
    
    // Pega chat rooms da lista de meus chats
    class func getMyChatRooms(completionHandler:((success: Bool, chatRoomsList: [ChatRoom]?)->Void)?) {
        LDTProtocolImpl.sharedInstance.getMyChatrooms { (success, retMsg) in
            if success {
                guard let chatRoomsDicArray = (retMsg!["Ans"] as? [NSDictionary]) else {
                    completionHandler?(success: false, chatRoomsList: nil)
                    return
                }
                
                ChatRoom.createChatroomsInBG(chatRoomsDicArray, deleteOtherEntries: false, isMyChat: true, completionHandler: { (chatRoomsList) in
                    completionHandler?(success: true, chatRoomsList: chatRoomsList)
                })
            }
            else {
                completionHandler?(success: false, chatRoomsList: nil)
            }
        }
    }
    
    //Listar chat rooms em determinada área geográfica
    class func getChatRoomOnArea(requestIndentifier:Double, minLat:Double, maxLat:Double, minLng:Double, maxLng: Double,completionHandler: (identifier:Double, success: Bool, chatRoomsList: [ChatRoom]?) -> Void)
    {
        
        
        LDTProtocolImpl.sharedInstance.getChatroomOnArea(minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng, completionHandler: { (success, retMsg) in
            
            if success && retMsg != nil {
                guard let chatRoomsDicArray = (retMsg!["Ans"] as? [NSDictionary]) else {
                    completionHandler(identifier: requestIndentifier, success: false, chatRoomsList: nil)
                    return
                }
                
                ChatRoom.createChatroomsInBG(chatRoomsDicArray, deleteOtherEntries: false, isMyChat: nil, completionHandler: { (chatRoomsList) in
                    completionHandler(identifier: requestIndentifier, success: true, chatRoomsList: chatRoomsList)
                })
            }
            else {
                completionHandler(identifier: requestIndentifier, success: false, chatRoomsList: nil)
            }
        })

    }
    

    // Pega lista do servidor baseado nos IDs
    class func getChatRoomsWithIds(chatRoomIdList:[String], completionHandler:(success: Bool, chatRoomsList: [ChatRoom]?)->Void) {
        LDTProtocolImpl.sharedInstance.getChatrooms(chatRoomIdList) { (success, retMsg) in
            if success && retMsg != nil {
                guard let chatRoomsDicArray = (retMsg!["Ans"] as? [NSDictionary]) else {
                    completionHandler(success: false, chatRoomsList: nil)
                    return
                }
                
                ChatRoom.createChatroomsInBG(chatRoomsDicArray, deleteOtherEntries: false, isMyChat: nil, completionHandler: { (chatRoomsList) in
                    completionHandler(success: true, chatRoomsList: chatRoomsList)
                })
            }
            else {
                completionHandler(success: false, chatRoomsList: nil)
            }
        }
    }
    
    //Listar chat rooms por ids da base local
    class func getChatRoomsFromDatabaseWithIds(chatRoomIdList:[String], completionHandler:(success: Bool, chatRoomsList: [ChatRoom]?)->Void) {
        dispatch_async(dispatch_get_main_queue()) {
            let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
            
            let request = NSFetchRequest(entityName: "ChatRoom")
            request.predicate = NSPredicate(format: "chatRoomId IN %@", chatRoomIdList)
            
            if let chats = try? managedObjectContext.executeFetchRequest(request) {
                completionHandler(success: true, chatRoomsList: (chats as? [ChatRoom]))
            }
            else {
                completionHandler(success: false, chatRoomsList: nil)
            }
        }
    }
    
    //Criar um chat room
    class func createChatRoom( chatRoom: [String : AnyObject],  completionHandler: (success: Bool, newChatRoom: ChatRoom?) -> Void) {
        LDTProtocolImpl.sharedInstance.createChatroom(chatRoom) { (success, newChatRoom) in
            
            if success && newChatRoom != nil {
                
                guard let chatRoomDic = (newChatRoom!["Ans"] as? NSDictionary) else {
                    completionHandler(success: false, newChatRoom: nil)
                    return
                }
        
                let mainContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
                
                let createdChat = ChatRoom.createUpdateChatRoom(chatRoomDic, managedObjectContext: mainContext)
                createdChat?.saved = true
                createdChat?.participantCount = 1
                
                completionHandler(success: success, newChatRoom: createdChat)
            }
            else {
                completionHandler(success: success, newChatRoom: nil)
            }
        }
        
    }
    
    
    //Listar chat rooms that matches search term
    class func getChatroomsThatMatchesSearchTerm(searchTerm: String, completionHandler:(searchTerm: String, success: Bool, chatRoomsIdList: [String]?) -> Void) {
        
        LDTProtocolImpl.sharedInstance.getChatroomsThatMatchesSearchTerm(searchTerm, completionHandler: { (success, retMsg) in
            
            BlicupAnalytics.sharedInstance.mark_SearchedChat(searchTerm)
            
            if success && retMsg != nil {
                guard let chatRoomsDicArray = (retMsg!["Ans"] as? [NSDictionary]) else {
                    completionHandler(searchTerm: searchTerm, success: false, chatRoomsIdList: nil)
                    return
                }
                
                ChatRoom.createChatroomsInBG(chatRoomsDicArray, deleteOtherEntries: false, isMyChat: nil, completionHandler: { (chatRoomsList) in
                    var chatRoomsIdList:[String]?
                    if chatRoomsList != nil {
                        chatRoomsIdList = chatRoomsList!.map({ $0.chatRoomId! })
                    }
                    completionHandler(searchTerm: searchTerm, success: true, chatRoomsIdList: chatRoomsIdList)
                })
            }
            else {
                completionHandler(searchTerm: searchTerm, success: false, chatRoomsIdList: nil)
            }
        })
        
    }
    
    //Listar chat rooms msg
    class func getChatroomMsgsSinceLastUpdate(chatRoomId: String, completionHandler:((success:Bool)->Void)?) {
        var fromDate:Double = 0.0
        
        let chatRoom = ChatRoom.chatRoomWithId(chatRoomId)
        if chatRoom != nil {
            fromDate = (chatRoom!.lastUpdateTimestamp?.doubleValue)!
        }
        
        LDTProtocolImpl.sharedInstance.getChatroomMsgsWhenEnterChat(chatRoomId,from: fromDate) { (success, retMsg) in
            
            if success {
                if retMsg != nil, let ansArray = retMsg!["Ans"] as? [[String:AnyObject]] {
                    ChatRoomMessage.createOrUpdateReceivedChatRoomMessageInBG(ansArray)
                }
                
                if chatRoom != nil {
                    chatRoom!.lastUpdateTimestamp =  NSNumber( double: (NSDate().timeIntervalSince1970 * 1000) )
                }
            }
            
            completionHandler?(success: success)
        }
        
    }
    
    //Listar chat rooms that matches search term
    class func likeMsgFromChatroom(msgId:String, chatroomId: String, completionHandler:( success: Bool) -> Void) {
        
        LDTProtocolImpl.sharedInstance.likeOrUnlikeMsg(msgId, chatroomId: chatroomId, likeOrUnlike: 1) { (success, retMsg) in
            if success {
                //TO DO: tratar caso de erro
            }
        }
        
    }

    //Listar chat rooms that matches search term
    class func unlikeMsgFromChatroom(msgId:String, chatroomId: String, completionHandler:( success: Bool) -> Void) {
        
        LDTProtocolImpl.sharedInstance.likeOrUnlikeMsg(msgId, chatroomId: chatroomId, likeOrUnlike: -1) { (success, retMsg) in
            if success {
                //TO DO: tratar caso de erro
            }
        }
        
    }

    

    
    //Entrar em chat room 
    class func enterChatRoom(chatRoomId: String, completionHandler:((success:Bool) -> Void)?) {
        LDTProtocolImpl.sharedInstance.enterChatroom(chatRoomId) { (success, retMsg) in
            if success && retMsg != nil {
                guard let chatRoomDic = (retMsg!["Ans"] as? NSDictionary) else {
                    completionHandler?(success: false)
                    return
                }
                
                ChatRoom.createChatRoomInBG(chatRoomDic, isMyChat: nil, completionHandler: { (chatRoom) in
                    completionHandler?(success: success)
                })
            }
            else {
                completionHandler?(success: success)
            }
        }
    }

    //Sair de um chat room
    class func leaveChatRoom(chatRoomId:String, completionHandler:((success: Bool) -> Void)?) {
        LDTProtocolImpl.sharedInstance.leaveChatroom(chatRoomId) { (success, retMsg) in
            completionHandler?(success: success)
        }
    }

    //Remover usuário de um chat room
    func removeUserFromChatRoom( removerUsername: AnyObject?, removedUsername: AnyObject?,  completionHandler: (success: Bool) -> Void) {
        // TODO:
    }
    
    //Enviar uma mensagem no chat room
    class func sendMsgOnChatRoom(content: String, type:ChatRoomMessage.MessageType, chatRoomId: String,  completionHandler:((success: Bool)->Void)?) {
        if let message = ChatRoomMessage.newUserChatRoomTextMessage(content, chatID: chatRoomId, type: type) {
            ChatRoomBS.sendMessage(message, completionHandler: completionHandler)
        }
        else {
            completionHandler?(success: false)
        }
    }

    class func sendMessage(message:ChatRoomMessage, completionHandler:((success:Bool)->Void)?) {
        var msg = ["chatRoomId":message.chatRoomId!, "msgType":message.msgType!.integerValue, "likeCount":message.likeCount!, "content": message.content!, "whoSent":["userId":message.whoSent!.userId!, "username":message.whoSent!.username!, "photoUrl":message.whoSent!.photoUrl!]]
        
        if (message.msgType?.integerValue == ChatRoomMessage.MessageType.TEXT_MSG.rawValue), let mentionList = message.content!.getMentions() {
            if mentionList.count > 0 {
                message.mentionList = Array(Set(mentionList))
                msg["mentionList"] = message.mentionList
            }
            
        }
        
        var contentSize = 0
        if  message.msgType?.integerValue == ChatRoomMessage.MessageType.TEXT_MSG.rawValue
        {
            contentSize = message.content!.characters.split{$0 == " "}.map(String.init).count
        }
        
        BlicupAnalytics.sharedInstance.sentMsg(message.chatRoomId!)
        BlicupAnalytics.sharedInstance.mark_SentMsg((message.msgType?.integerValue)!, msgSize: contentSize, withMention: message.mentionList?.count > 0)
        
        
        LDTProtocolImpl.sharedInstance.sendMessageOnChatroom(msg, chatroomId: message.chatRoomId!, completionHandler: { (success, retMsg) in
            if success, let msgDic = retMsg!["Ans"] as? [String:AnyObject] {
                ChatRoomMessage.updateChatRoomMessageInBG(message, updateDic: msgDic)
            }
            else {
                message.state = ChatRoomMessage.MessageState.NotSent.rawValue
            }
            
            completionHandler?(success: success)
        })

    }
    
    //Reportar chat room
    class func reportChatRoom( chatroom: ChatRoom,  completionHandler: (success: Bool) -> Void) {
        
        let chatRoomsDic = chatroom.toDictionary()
        
        LDTProtocolImpl.sharedInstance.reportChatroom(chatRoomsDic, completionHandler: { (success, retMsg) in
            completionHandler(success: success)
        })
    }
    
    //Salvar chat room de interesse
    class func saveChatRoomOfInterest(chatRoomId: String,  completionHandler: (success: Bool) -> Void) {
        LDTProtocolImpl.sharedInstance.saveChatroom(chatRoomId) { (success, retMsg) in
            if success {
                BlicupAnalytics.sharedInstance.mark_SavedChat()
            }
            completionHandler(success: success)
        }
    }
    
    //Remover chat room de interesse
    class func removeChatRoomOfInterest(chatRoomId: String, completionHandler: (success: Bool) -> Void) {
        LDTProtocolImpl.sharedInstance.removeChatroom(chatRoomId) { (success, retMsg) in
            if success {
                BlicupAnalytics.sharedInstance.mark_LeftChat()
            }
            completionHandler(success: success)
        }
    }
    
    
    //Listar chat rooms por ids
    func getChatRoomsWithIds( username: AnyObject? , chatRoomIdList: [AnyObject]?,  completionHandler: (success: Bool,chatRoomsList: [AnyObject]?) -> Void) {
        // TODO:
    }

    
    
}
