//
//  UserInfo.swift
//  Blicup
//
//  Created by Moymer on 5/26/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation
import CoreData


class UserInfo: NSManagedObject {
    
    enum UserInfoFields: String {
        case blockedList = "blockedList"
        case blockerList = "blockerList"
        case createdChatroomList = "createdChatroomList"
        case followeeCount = "followeeCount"
        case followeeList = "followeeList"
        case followerCount = "followerCount"
        case followerList = "followerList"
        case likeCount = "likeCount"
        case myChatroomList = "myChatroomList"
        case pushEndpoints = "pushEndpoints"
        case snsSubscriptionList = "snsSubscriptionList"
    }
    
    class func createUpdateUserInfo(info : NSDictionary) {
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        return createUpdateUserInfo(info, managedObjectContext: managedObjectContext)
    }
    
    class func createUpdateUserInfo(info : NSDictionary, managedObjectContext: NSManagedObjectContext) {
        
        guard let userId = info["userId"] as? String else {
            return
        }
        
        guard let user = User.userWithId(userId, managedObjectContext: managedObjectContext) else {
            return
        }
        
        if user.userInfo == nil {
            let userInfo = NSEntityDescription.insertNewObjectForEntityForName("UserInfo", inManagedObjectContext: managedObjectContext) as? UserInfo
            user.userInfo = userInfo
        }
        
        guard let userInfo = user.userInfo else {
            return
        }
        
        UserInfo.updateUserInfoFields(userInfo, json: info)
        
    
    }

    
    class func createUpdateUserInfosInBG(userInfos:[NSDictionary], completionHandler:((success:Bool)->Void)? ) {
        //avoid multiple access to background
        dispatch_async((UIApplication.sharedApplication().delegate as! AppDelegate).coreDataSerialBGQueue) {
             (UIApplication.sharedApplication().delegate as! AppDelegate).waitForCoreDataBG()
            
            let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
            
            let backgroundManagedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            backgroundManagedObjectContext.parentContext = managedObjectContext
            
            //PERFORM MESSAGES GET ON BACKGROUND THREAD AND CONTEXT
            backgroundManagedObjectContext.performBlock {
                for json in userInfos {
                    guard let userId = json["userId"] as? String else {
                        continue
                    }
                    
                    guard let user = User.userWithId(userId, managedObjectContext: backgroundManagedObjectContext) else {
                        continue
                    }
                    
                    if user.userInfo == nil {
                        let userInfo = NSEntityDescription.insertNewObjectForEntityForName("UserInfo", inManagedObjectContext:backgroundManagedObjectContext) as? UserInfo
                        user.userInfo = userInfo
                    }
                    
                    guard let userInfo = user.userInfo else {
                        continue
                    }
                    
                    UserInfo.updateUserInfoFields(userInfo, json: json)
                }
                
                
                do {
                    if backgroundManagedObjectContext.hasChanges {
                        try backgroundManagedObjectContext.save()
                    }
                    

                    
                    //MUST DO THAT TO RETURN CHANGES TO MAIN CONTEXT
                    managedObjectContext.performBlock {
                        do {
                            
                            
                            if managedObjectContext.hasChanges {
                                try managedObjectContext.save()
                            }

                        (UIApplication.sharedApplication().delegate as! AppDelegate).signalForCoreDataBG()
                        completionHandler?(success:true)
                            
                        }
                        catch let error as NSError {
                            print("Erro ao salvar Main: \(error)")
                              (UIApplication.sharedApplication().delegate as! AppDelegate).signalForCoreDataBG()
                        
                            completionHandler?(success:false)
                        }
                    }
                    
                 
                }
                catch let error as NSError {
                    
                    (UIApplication.sharedApplication().delegate as! AppDelegate).signalForCoreDataBG()
                    print("Erro ao salvar Private: \(error)")
                    completionHandler?(success:false)
                }
            }
        }
    }
    
    class func updateUserInfoFields(userInfo: UserInfo, json: NSDictionary) {
        
        
        //changable fields
        if let blockedList = json[UserInfoFields.blockedList.rawValue] as? [String] {
            if userInfo.blockedList != blockedList {
                userInfo.blockedList = blockedList
            }
        }
        
        if let blockerList = json[UserInfoFields.blockerList.rawValue] as? [String] {
            if userInfo.blockerList != blockerList {
                userInfo.blockerList = blockerList
            }
        }
        
        if let createdChatroomList = json[UserInfoFields.createdChatroomList.rawValue] as? [String] {
            if userInfo.createdChatroomList != createdChatroomList {
                userInfo.createdChatroomList = createdChatroomList
            }
        }
        
        if let followeeCount = json[UserInfoFields.followeeCount.rawValue] as? NSNumber {
            if userInfo.followeeCount?.doubleValue != followeeCount.doubleValue {
                userInfo.followeeCount = followeeCount
            }
        }
        
        if let followeeList = json[UserInfoFields.followeeList.rawValue] as? [String] {
            if userInfo.followeeList == nil || userInfo.followeeList! != followeeList {
                userInfo.followeeList = followeeList
            }
        }
        
        if let followerCount = json[UserInfoFields.followerCount.rawValue] as? NSNumber {
            if userInfo.followerCount?.doubleValue != followerCount.doubleValue {
                userInfo.followerCount = followerCount
            }
        }
        
        if let followerList = json[UserInfoFields.followerList.rawValue] as? [String] {
            if userInfo.followerList == nil || userInfo.followerList! != followerList {
                userInfo.followerList = followerList
            }
        }
        
        if let likeCount = json[UserInfoFields.likeCount.rawValue] as? NSNumber {
            if userInfo.likeCount?.doubleValue != likeCount.doubleValue {
                userInfo.likeCount = likeCount
            }
        }
        
        if let myChatroomList = json[UserInfoFields.myChatroomList.rawValue] as? [String] {
            if userInfo.myChatroomList != myChatroomList {
                userInfo.myChatroomList = myChatroomList
                
              //  ChatRoom.updateChatRoomsSavedStatus(myChatroomList, managedObjectContext: userInfo.managedObjectContext!)
            }
        }
        
        if let pushEndpoints = json[UserInfoFields.pushEndpoints.rawValue] as? [String] {
            if userInfo.pushEndpoints != pushEndpoints {
                userInfo.pushEndpoints = pushEndpoints
            }
        }
        
        if let snsSubscriptionList = json[UserInfoFields.snsSubscriptionList.rawValue] as? [String] {
            if userInfo.snsSubscriptionList != snsSubscriptionList {
                userInfo.snsSubscriptionList = snsSubscriptionList
            }
        }
    }
    
}
