//
//  ChatRoom.swift
//  Blicup
//
//  Created by Guilherme Braga on 01/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation
import CoreData

enum ChatRoomFields: String {
    
    case Name = "name"
    case ChatRoomId = "chatRoomId"
    case CreationDate = "creationDate"
    case WhoCreated = "whoCreated"
    case LastMsgDate = "lastMsgDate"
    case PhotoList = "photoList"
    case Address = "address"
    case TagList = "tagList"
    case ParticipantCount = "participantCount"
     case ParticipantList = "participantList"
     case Grade = "grade"
}

class ChatRoom: NSManagedObject {
    
    enum ChatRoomState: Int {
        case Active, Dead, Removed, Banned
    }

// Insert code here to add functionality to your managed object subclass
    class func deleteChatsAndAssociatedData(managedObjectContext:NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest(entityName: "ChatRoom")
        
        if let chatRoomBeingUsed = NSUserDefaults.standardUserDefaults().stringForKey(kCurrentOpenChatRoomIdKey) {
            fetchRequest.predicate = NSPredicate(format: "saved != true AND chatRoomId != %@", chatRoomBeingUsed)
        }
        else {
            fetchRequest.predicate = NSPredicate(format: "saved != true")
        }
        
        guard let oldChats = try? managedObjectContext.executeFetchRequest(fetchRequest) as! [ChatRoom] else {
            return
        }
        
        var deletedChatIds = [String]()
        for chat in oldChats {
            deletedChatIds.append(chat.chatRoomId!)
            managedObjectContext.deleteObject(chat)
        }
        
        if deletedChatIds.count > 0 {
            ChatRoomMessage.deleteSentChatRoomMessagesFromChats(deletedChatIds, managedObjectContext: managedObjectContext)
        }
    }
    
    class func updateMyChatsWithStateDead(managedObjectContext:NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest(entityName: "ChatRoom")
        
        fetchRequest.predicate = NSPredicate(format: "saved == true AND state == %d",ChatRoomState.Active.rawValue)
        
        
        guard let myChats = try? managedObjectContext.executeFetchRequest(fetchRequest) as! [ChatRoom] else {
            return
        }
        
        for chat in myChats {
            chat.state = ChatRoom.ChatRoomState.Dead.rawValue
        }
    }

    
    
    class func createUpdateChatRoom(chatRoomDic: NSDictionary, managedObjectContext: NSManagedObjectContext)->ChatRoom? {
        guard let chatId = chatRoomDic[ChatRoomFields.ChatRoomId.rawValue] as? String else {
            return nil
        }
        
        var chat = ChatRoom.chatRoomWithId(chatId, managedObjectContext: managedObjectContext)
        
        var saveStaticData = false
        if chat == nil {
            saveStaticData = true
            chat = NSEntityDescription.insertNewObjectForEntityForName("ChatRoom", inManagedObjectContext:managedObjectContext) as? ChatRoom
        }
        
        guard let chatRoom = chat else {
            return nil
        }
        
        //NOT CHANGEDS
        if saveStaticData {
            if let userDic = chatRoomDic[ChatRoomFields.WhoCreated.rawValue] as? NSDictionary {
                chatRoom.whoCreated = User.createUser(userDic, managedObjectContext: managedObjectContext)
            }
            
            if let chatDic = chatRoomDic[ChatRoomFields.Address.rawValue] as? NSDictionary {
                chatRoom.address = ChatAddress.newChatAddress(chatDic, managedObjectContext: managedObjectContext)
            }
            
            if let photoJsonList = chatRoomDic[ChatRoomFields.PhotoList.rawValue] as? [NSDictionary] {
                for photoDic in photoJsonList {
                    let photo = Photo.createPhoto(photoDic, managedObjectContext: managedObjectContext)
                    photo.chatRoom = chatRoom
                }
            }
        }
        
        //changable fields
        if let name = chatRoomDic[ChatRoomFields.Name.rawValue] as? String {
            if chatRoom.name != name {
                chatRoom.name = name
            }
        }
        if let chatRoomId = chatRoomDic[ChatRoomFields.ChatRoomId.rawValue] as? String {
            if chatRoom.chatRoomId != chatRoomId {
                chatRoom.chatRoomId = chatRoomId
            }
        }
        
        if let creationDate = chatRoomDic[ChatRoomFields.CreationDate.rawValue] as? NSNumber {
            let creationDateInSec = creationDate.doubleValue/1000
            if chatRoom.creationDate?.doubleValue != creationDateInSec {
                chatRoom.creationDate = creationDateInSec
            }
        }
        
        
        if let lastMsgDate = chatRoomDic[ChatRoomFields.LastMsgDate.rawValue] as? NSNumber {
            let lastMsgDateInSec = lastMsgDate.doubleValue/1000
            if chatRoom.lastMsgDate?.doubleValue != lastMsgDateInSec {
                chatRoom.lastMsgDate = lastMsgDateInSec
                chatRoom.showBadge = true
            }
        }
        
        if let participantCount = chatRoomDic[ChatRoomFields.ParticipantCount.rawValue] as? NSNumber {
            if chatRoom.participantCount?.doubleValue != participantCount.doubleValue {
                chatRoom.participantCount = participantCount
            }
        }
        
        if let grade = chatRoomDic[ChatRoomFields.Grade.rawValue] as? NSNumber {
            if chatRoom.grade?.doubleValue != grade.doubleValue {
                chatRoom.grade = grade
            }
        }
        
        if let tagList = chatRoomDic[ChatRoomFields.TagList.rawValue]  as? [String] {
            if chatRoom.tagList == nil || chatRoom.tagList! != tagList {
                chatRoom.tagList = tagList
            }
        }
        
        
        if let participantJsonList = chatRoomDic[ChatRoomFields.ParticipantList.rawValue] as? [NSDictionary] {
            let participants: NSMutableOrderedSet = chatRoom.mutableOrderedSetValueForKey(ChatRoomFields.ParticipantList.rawValue)
            participants.removeAllObjects()
            for particUserDic in participantJsonList {
                let participant = User.createUser(particUserDic, managedObjectContext: managedObjectContext)
                participants.addObject(participant)
            }
        }
        
        return chatRoom
    }
    
    class func createChatRoomInBG(chatRoomDic: NSDictionary, isMyChat:Bool?, completionHandler: (chatRoom: ChatRoom?)->Void) {
        ChatRoom.createChatroomsInBG([chatRoomDic], deleteOtherEntries: false, isMyChat: isMyChat) { (chatRoomsList) in
            guard let chatRoom = chatRoomsList?.first else {
                completionHandler(chatRoom: nil)
                return
            }
            
            completionHandler(chatRoom: chatRoom)
        }
    }
    
    class func deleteChatAndAssociatedData(chatRoom: ChatRoom) {
        
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        managedObjectContext.deleteObject(chatRoom)
        ChatRoomMessage.deleteChatRoomMessagesFromChats([chatRoom.chatRoomId!], managedObjectContext: managedObjectContext)
    }
    
    class func createChatroomsInBG(jsons : [NSDictionary], deleteOtherEntries:Bool, isMyChat:Bool?, completionHandler: ( chatRoomsList: [ChatRoom]?) -> Void ) -> Void {
        
        
        dispatch_async((UIApplication.sharedApplication().delegate as! AppDelegate).coreDataSerialBGQueue) {
          
            (UIApplication.sharedApplication().delegate as! AppDelegate).waitForCoreDataBG()
            
            let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
            
            let backgroundManagedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            backgroundManagedObjectContext.parentContext = managedObjectContext
            
            var chatRoomsIds = [NSManagedObjectID]()
            //PERFORM MESSAGES GET ON BACKGROUND THREAD AND CONTEXT
            backgroundManagedObjectContext.performBlock {
                
                if isMyChat != nil && isMyChat! {
                    ChatRoom.updateMyChatsWithStateDead(backgroundManagedObjectContext)
                }
                
                if deleteOtherEntries {
                    ChatRoom.deleteChatsAndAssociatedData(backgroundManagedObjectContext)
                }
                
                for json in jsons {
                    if let chatRoom = ChatRoom.createUpdateChatRoom(json, managedObjectContext: backgroundManagedObjectContext) {
                        if isMyChat != nil && chatRoom.saved != isMyChat! {
                            chatRoom.saved = isMyChat
                        }
                        if isMyChat != nil && isMyChat! {
                            chatRoom.state = ChatRoom.ChatRoomState.Active.rawValue
                        }
                        chatRoomsIds.append(chatRoom.objectID)
                    }
                }
                
                do {
                    if backgroundManagedObjectContext.hasChanges {
                        try backgroundManagedObjectContext.save()
                    }
                    
                    
                    //MUST DO THAT TO RETURN CHANGES TO MAIN CONTEXT
                    managedObjectContext.performBlock {
                        do{
                            if managedObjectContext.hasChanges
                            {
                                try managedObjectContext.save()
                            }
                            var chatRoomsList = [ChatRoom]()
                            
                            for ObjId in chatRoomsIds
                            {
                                chatRoomsList.append( managedObjectContext.objectWithID(ObjId) as! ChatRoom)
                            }
                            
                            //send back chatrooms
                            (UIApplication.sharedApplication().delegate as! AppDelegate).signalForCoreDataBG()
                            
                            completionHandler(chatRoomsList: chatRoomsList)
                            
                        } catch let error as NSError {
                            print("Erro ao salvar Main: \(error)")
                           (UIApplication.sharedApplication().delegate as! AppDelegate).signalForCoreDataBG()
                            completionHandler(chatRoomsList: nil)
                        }
                    }
                    
                    
                } catch let error as NSError {
                    (UIApplication.sharedApplication().delegate as! AppDelegate).signalForCoreDataBG()
                    print("Erro ao salvar Private: \(error)")
                    completionHandler(chatRoomsList: nil)
                }
            }
        }
    }
    
    class func chatRoomWithId(chatId:String, managedObjectContext: NSManagedObjectContext) -> ChatRoom? {
        
        let request = NSFetchRequest(entityName: "ChatRoom")
        request.predicate = NSPredicate(format: "chatRoomId == %@", chatId)
        
        if let chats = try? managedObjectContext.executeFetchRequest(request) {
            return chats.first as? ChatRoom
        }
        
        return nil
    }
   
    
    class func chatRoomWithId(chatId:String) -> ChatRoom? {
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        return chatRoomWithId(chatId, managedObjectContext: managedObjectContext)
    }

    
    class func updateChatRoomsSavedStatus(myChatsList:[String], managedObjectContext:NSManagedObjectContext) {
        let request = NSFetchRequest(entityName: "ChatRoom")
        
        request.predicate = NSPredicate(format: "(chatRoomId IN %@) AND (saved == false)", myChatsList)
        if let chatsList = try? managedObjectContext.executeFetchRequest(request) as! [ChatRoom] {
            for chat in chatsList {
                chat.saved = true
            }
        }
                
        request.predicate = NSPredicate(format: "NOT(chatRoomId IN %@) AND (saved == true)", myChatsList)
        if let chatsList = try? managedObjectContext.executeFetchRequest(request) as! [ChatRoom] {
            for chat in chatsList {
                chat.saved = false
            }
        }
    }

    func toDictionary() -> NSDictionary
    {
        let chatRoomDic : NSMutableDictionary = [ChatRoomFields.Name.rawValue : self.name!,
                           ChatRoomFields.ChatRoomId.rawValue : self.chatRoomId!,
                           ChatRoomFields.CreationDate.rawValue : self.creationDate!,
                            ChatRoomFields.WhoCreated.rawValue : self.whoCreated!.toDictionary(),
                            ChatRoomFields.PhotoList.rawValue : Photo.toDictionary(self.photoList!.array as! [Photo]),
                            ChatRoomFields.TagList.rawValue : self.tagList!,
                            ChatRoomFields.ParticipantCount.rawValue : self.participantCount!]
        
        if self.address != nil
        {
            chatRoomDic[ChatAddressFields.FormattedAddress.rawValue] = self.address!.toDictionary()
        }

        return chatRoomDic
        
    }

}
