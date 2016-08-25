//
//  ChatRoomMessage.swift
//  Blicup
//
//  Created by Moymer on 10/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation
import CoreData


class ChatRoomMessage: NSManagedObject {

    enum MessageType: Int {
        case TEXT_MSG = 0, IMAGE_MSG = 1
    }
    
    enum MessageState:Int {
        case Sent, Sending, NotSent
    }
    
    
    class func newUserChatRoomTextMessage(message:String, chatID:String, type: MessageType)->ChatRoomMessage? {
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        guard let chatRoomMessage = NSEntityDescription.insertNewObjectForEntityForName("ChatRoomMessage", inManagedObjectContext:managedObjectContext) as? ChatRoomMessage else {
            return nil
        }
        
        chatRoomMessage.content = message
        chatRoomMessage.msgType = MessageType.TEXT_MSG.rawValue
        chatRoomMessage.chatRoomId = chatID
        chatRoomMessage.sentDate = NSDate()
        chatRoomMessage.state = MessageState.Sending.rawValue
        chatRoomMessage.msgType = type.rawValue
        chatRoomMessage.whoSent = UserBS.getLoggedUser()
        
        do {
            try managedObjectContext.save()
            return chatRoomMessage
        }
        catch {
            return nil
        }
    }
    
    
    class func createOrUpdateReceivedChatRoomMessage(msg:[String:AnyObject]) -> (ChatRoomMessage?, Bool?)? {
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        guard let chatId = msg["chatRoomId"] as? String, let msgId = msg["msgId"] as? String else {
            return (nil, nil)
        }
        
        let fetchRequest = NSFetchRequest(entityName: "ChatRoomMessage")
        fetchRequest.predicate = NSPredicate(format: "chatRoomId == %@ AND msgId == %@", chatId, msgId)
        
        var finalMessage:ChatRoomMessage? = nil
        var isUpdating: Bool!
        
        if let message = try! managedObjectContext.executeFetchRequest(fetchRequest).first as? ChatRoomMessage {
            finalMessage = updateUserChatRoomMessage(message, withData: msg)
            isUpdating = true
        }
        else {
            let chatRoomMessage = NSEntityDescription.insertNewObjectForEntityForName("ChatRoomMessage", inManagedObjectContext:managedObjectContext) as! ChatRoomMessage
            finalMessage = updateUserChatRoomMessage(chatRoomMessage, withData: msg)
            isUpdating = false
        }
        
        finalMessage?.state = MessageState.Sent.rawValue
        
        return (finalMessage, isUpdating)
    }
    
    
    class func updateReceivedChatRoomMessageOnLike(msg:[String:AnyObject]) -> ChatRoomMessage? {
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        guard let chatId = msg["chatRoomId"] as? String, let msgId = msg["msgId"] as? String else {
            return nil
        }
        
        let fetchRequest = NSFetchRequest(entityName: "ChatRoomMessage")
        fetchRequest.predicate = NSPredicate(format: "chatRoomId == %@ AND msgId == %@", chatId, msgId)
        
        var finalMessage:ChatRoomMessage? = nil
        
        if let message = try! managedObjectContext.executeFetchRequest(fetchRequest).first as? ChatRoomMessage {
            finalMessage = updateUserChatRoomMessage(message, withData: msg)
          
        }
        
        finalMessage?.state = MessageState.Sent.rawValue
        
        return finalMessage
    }

    

    class func createOrUpdateReceivedChatRoomMessageInBG(msgs:[[String:AnyObject]]) -> Void {
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
     
        dispatch_async((UIApplication.sharedApplication().delegate as! AppDelegate).coreDataSerialBGQueue) {
             (UIApplication.sharedApplication().delegate as! AppDelegate).waitForCoreDataBG()
            
            let backgroundManagedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            backgroundManagedObjectContext.parentContext = managedObjectContext
            
            //PERFORM MESSAGES GET ON BACKGROUND THREAD AND CONTEXT
            backgroundManagedObjectContext.performBlock {
                
                for msg in msgs {
                    guard let chatId = msg["chatRoomId"] as? String, let msgId = msg["msgId"] as? String else {
                        continue
                    }
                    
                    let fetchRequest = NSFetchRequest(entityName: "ChatRoomMessage")
                    fetchRequest.predicate = NSPredicate(format: "chatRoomId == %@ AND msgId == %@", chatId, msgId)
                    
                    var finalMessage:ChatRoomMessage? = nil
                    if let message = try! backgroundManagedObjectContext.executeFetchRequest(fetchRequest).first as? ChatRoomMessage
                    {
                        finalMessage = updateUserChatRoomMessage(message, withData: msg)
                    }
                    else {
                        let chatRoomMessage = NSEntityDescription.insertNewObjectForEntityForName("ChatRoomMessage", inManagedObjectContext:backgroundManagedObjectContext) as! ChatRoomMessage
                        finalMessage = updateUserChatRoomMessage(chatRoomMessage, withData: msg)
                    }
                    
                    finalMessage?.state = MessageState.Sent.rawValue
                    
                    
                }
                
                do{
                    try backgroundManagedObjectContext.save()
                    
                    
                    //MUST DO THAT TO RETURN CHANGES TO MAIN CONTEXT
                    managedObjectContext.performBlock {
                        do{
                            try managedObjectContext.save()
                        } catch let error as NSError {
                            print("Erro ao salvar Main: \(error)")
                        }
                         (UIApplication.sharedApplication().delegate as! AppDelegate).signalForCoreDataBG()
                    }
                    
                    
                } catch let error as NSError {
                     (UIApplication.sharedApplication().delegate as! AppDelegate).signalForCoreDataBG()
                    print("Erro ao salvar Private: \(error)")
                }
                
            }
        }
    }

    
    class func updateChatRoomMessageInBG(chatRoomMessage:ChatRoomMessage, updateDic:[String:AnyObject]) {
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        dispatch_async((UIApplication.sharedApplication().delegate as! AppDelegate).coreDataSerialBGQueue) {
            (UIApplication.sharedApplication().delegate as! AppDelegate).waitForCoreDataBG()
            
            let backgroundManagedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            backgroundManagedObjectContext.parentContext = managedObjectContext
            
            //PERFORM MESSAGES GET ON BACKGROUND THREAD AND CONTEXT
            backgroundManagedObjectContext.performBlock {
                guard let message = backgroundManagedObjectContext.objectWithID(chatRoomMessage.objectID) as? ChatRoomMessage else {
                    return
                }
                
                let finalMessage = updateUserChatRoomMessage(message, withData: updateDic)
                finalMessage!.state = MessageState.Sent.rawValue
                
                do {
                    try backgroundManagedObjectContext.save()
                    
                    //MUST DO THAT TO RETURN CHANGES TO MAIN CONTEXT
                    managedObjectContext.performBlock {
                        do{
                            try managedObjectContext.save()
                        }
                        catch let error as NSError {
                            print("Erro ao salvar Main: \(error)")
                        }
                        (UIApplication.sharedApplication().delegate as! AppDelegate).signalForCoreDataBG()
                    }
                }
                catch let error as NSError {
                    (UIApplication.sharedApplication().delegate as! AppDelegate).signalForCoreDataBG()
                    print("Erro ao salvar Private: \(error)")
                }
                
            }
        }
    }
    
    
    class func updateUserChatRoomMessage(chatRoomMessage:ChatRoomMessage, withData msg:[String:AnyObject]) -> ChatRoomMessage? {
        
        chatRoomMessage.chatRoomId = msg["chatRoomId"] as? String
        chatRoomMessage.content = msg["content"] as? String
        if let likeCount = msg["likeCount"]?.integerValue {
           chatRoomMessage.likeCount = NSNumber( integer: max(0, likeCount))
        }
        chatRoomMessage.msgId = msg["msgId"] as? String
        chatRoomMessage.msgType = msg["msgType"]?.integerValue
        chatRoomMessage.mentionList = msg["mentionList"] as? [String]
        
        if let timeInterval = msg["sentDate"]?.doubleValue {
            chatRoomMessage.sentDate = NSDate(timeIntervalSince1970: timeInterval/1000)
        }
        else {
            chatRoomMessage.sentDate = NSDate()
        }
        
        
        guard let userDic = msg["whoSent"] as? NSDictionary else {
            return chatRoomMessage
        }
        
        chatRoomMessage.whoSent = User.createUser(userDic, managedObjectContext: chatRoomMessage.managedObjectContext!)
        
        return chatRoomMessage
    }
    
    
    class func deleteSentChatRoomMessagesFromChats(chatIds:[String], managedObjectContext:NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest(entityName: "ChatRoomMessage")
        let chatStateNumber = NSNumber(integer: MessageState.Sent.rawValue)
        fetchRequest.predicate = NSPredicate(format: "chatRoomId IN %@ AND state == %@", chatIds, chatStateNumber)
        
        if let chatsSentMessages = try? managedObjectContext.executeFetchRequest(fetchRequest) as! [NSManagedObject] {
            for message in chatsSentMessages {
                managedObjectContext.deleteObject(message)
            }
        }
    }

    class func deleteChatRoomMessagesFromChats(chatsIds: [String], managedObjectContext: NSManagedObjectContext) {
        
        let fetchRequest = NSFetchRequest(entityName: "ChatRoomMessage")
        
        if let chatsMessages = try? managedObjectContext.executeFetchRequest(fetchRequest) as! [NSManagedObject] {
            for message in chatsMessages {
                managedObjectContext.deleteObject(message)
            }
        }
        
        do {
            try managedObjectContext.save()
        } catch let error as NSError {
            print("Erro ao salvar Main: \(error)")
        }
        
    }
}
