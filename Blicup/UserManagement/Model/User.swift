//
//  User.swift
//  Blicup
//
//  Created by Guilherme Braga on 02/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation
import CoreData

@objc(User)
class User: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    
    enum Keys:String {
        case UserID = "userId"
        case PhotoUrl = "photoUrl"
        case FacebookId = "facebookId"
        case TwitterId = "twitterId"
        case Username = "username"
        case TagList = "tagList"
        case Bio = "bio"
        case UserInfo = "userInfo"
        case LastUpdated = "lastTimeUpdated"
        case UserStatus = "userStatus"
        case isVerified = "isVerified"
    }
    
    class func createUser(info : NSDictionary) -> User {
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
     
        return createUser(info, managedObjectContext: managedObjectContext)
    }
    
    class func createUser(info : NSDictionary, managedObjectContext: NSManagedObjectContext) -> User {
        
        let userId = info[Keys.UserID.rawValue] as! String
        var user = User.userWithId(userId, managedObjectContext: managedObjectContext)
        
        var lastUpdate = 0.0
        if let updateTime = info[Keys.LastUpdated.rawValue]?.doubleValue {
            lastUpdate = updateTime/1000 //time in miliseconds to seconds
        }
        
        
        if user == nil {
            user = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext:managedObjectContext) as? User
        }
        else if user!.lastTimeUpdated?.doubleValue >= lastUpdate && user!.userInfo != nil {
            return user!
        }
        
        user!.userId = userId
        user!.lastTimeUpdated = lastUpdate
        
        if let unwrappedPhotoUrl = info[Keys.PhotoUrl.rawValue] as? String {
            user!.photoUrl = unwrappedPhotoUrl
        }
        
        if let unwrappedFacebookId = info[Keys.FacebookId.rawValue] as? String {
            user!.facebookId = unwrappedFacebookId
        }
        
        if let unwrappedTwitterId = info[Keys.TwitterId.rawValue] as? String {
            user!.twitterId = unwrappedTwitterId
        }
   
        if let unwrappedUsername = info[Keys.Username.rawValue] as? String {
            user!.username = unwrappedUsername
        }
        
        if let unwrappedTagList = info[Keys.TagList.rawValue] as? [String] {
            user!.tagList = unwrappedTagList
        }
        
        if let unwrappedBio = info[Keys.Bio.rawValue] as? String {
            user!.bio = unwrappedBio
        }
        
        if let unwrappedIsVerified = info[Keys.isVerified.rawValue] as? Bool {
            user!.isVerified = unwrappedIsVerified
        }
        
        if let userInfoDic = info[Keys.UserInfo.rawValue] as? NSDictionary {
            UserInfo.createUpdateUserInfo(userInfoDic)
        }
        
        return user!
        
    }
    
 

    
    
    class func createUserInBG(jsons: [NSDictionary], deleteOtherEntries: Bool, completionHandler: (userList: [User]?) -> Void) -> Void {
        
        //avoid multiple access to background (EX: MAP CALL SEVERAL TIMES)
        dispatch_async((UIApplication.sharedApplication().delegate as! AppDelegate).coreDataSerialBGQueue) {
              (UIApplication.sharedApplication().delegate as! AppDelegate).waitForCoreDataBG()
            let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
            
            let backgroundManagedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            backgroundManagedObjectContext.parentContext = managedObjectContext
            
            var userIds = [NSManagedObjectID]()
            //PERFORM MESSAGES GET ON BACKGROUND THREAD AND CONTEXT
            backgroundManagedObjectContext.performBlock {
                
//                if deleteOtherEntries {
//                    ChatRoom.deleteChatsAndAssociatedData(backgroundManagedObjectContext)
//                }
                
                for json in jsons {
                    
                    guard let userId = json[Keys.UserID.rawValue] as? String else {
                        continue
                    }
                    
                    var user = User.userWithId(userId, managedObjectContext: backgroundManagedObjectContext)
                    
                    if user == nil {
                        user = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext:backgroundManagedObjectContext) as? User
                    
                        
                        //NOT CHANGEDS
                        if let facebookId = json[Keys.FacebookId.rawValue] as? String {
                            user!.facebookId = facebookId
                        }
                        
                        if let twitterId = json[Keys.TwitterId.rawValue] as? String {
                            user!.twitterId = twitterId
                        }
                        
                        if let userId = json[Keys.UserID.rawValue] as? String {
                            user!.userId = userId
                        }
                    }
                    
                    guard let unwrappedUser = user else {
                        continue
                    }
                    
                    //changable fields
                    if let username = json[Keys.Username.rawValue] as? String {
                        if unwrappedUser.username != username {
                            unwrappedUser.username = username
                        }
                    }
                    
                    if let bio = json[Keys.Bio.rawValue] as? String {
                        if unwrappedUser.bio != bio {
                            unwrappedUser.bio = bio
                        }
                    }
                    
                    if let photoUrl = json[Keys.PhotoUrl.rawValue] as? String {
                        if unwrappedUser.photoUrl != photoUrl {
                            unwrappedUser.photoUrl = photoUrl
                        }
                    }

                    if let tagList = json[Keys.TagList.rawValue] as? [String] {
                        
                        if unwrappedUser.tagList != nil && unwrappedUser.tagList! != tagList {
                            unwrappedUser.tagList = tagList
                        }
                    }
                    
                    if let isVerified = json[Keys.isVerified.rawValue] as? Bool {
                        
                        if unwrappedUser.isVerified == nil || (unwrappedUser.isVerified != nil && unwrappedUser.isVerified != isVerified) {
                            unwrappedUser.isVerified = isVerified
                        }
                    }
                    
                    if let userInfo = json[Keys.UserInfo.rawValue] as? NSDictionary {
                        
                        if unwrappedUser.userInfo == nil || (unwrappedUser.userInfo != nil && unwrappedUser.userInfo != userInfo) {
                            UserInfo.createUpdateUserInfo(userInfo, managedObjectContext: backgroundManagedObjectContext)
                        }
                    }
                    
                    userIds.append(unwrappedUser.objectID)
                }
                
                do{
                    
                    if backgroundManagedObjectContext.hasChanges
                    {
                        try backgroundManagedObjectContext.save()
                    }
                    
                    
                    //MUST DO THAT TO RETURN CHANGES TO MAIN CONTEXT
                    managedObjectContext.performBlock {
                        do{
                            if managedObjectContext.hasChanges
                            {
                                try managedObjectContext.save()
                            }
                            var userList = [User]()
                            
                            for ObjId in userIds
                            {
                                userList.append( managedObjectContext.objectWithID(ObjId) as! User)
                            }
                            
                            //send back users
                           (UIApplication.sharedApplication().delegate as! AppDelegate).signalForCoreDataBG()
                            completionHandler(userList: userList)
                            
                        } catch let error as NSError {
                            (UIApplication.sharedApplication().delegate as! AppDelegate).signalForCoreDataBG()
                            print("Erro ao salvar Main: \(error)")
                            completionHandler(userList: nil)
                        }
                    }
                   
                    
                } catch let error as NSError {
                     (UIApplication.sharedApplication().delegate as! AppDelegate).signalForCoreDataBG()
                    print("Erro ao salvar Private: \(error)")
                    completionHandler(userList: nil)
                }
            }
        }
    }
    
    class func createOrUpdateLoggedUserStatus(statusDic : NSDictionary ) ->  (Int , Int )    {
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
       
        let loggedUser = UserBS.getLoggedUser()
        
        
        if loggedUser != nil
        {
            let oldUserStatus = loggedUser!.userStatus
            if oldUserStatus != nil
            {
                let lastChangeTime = statusDic[UserStatusFields.LastChangeTime.rawValue] as? NSNumber
                if oldUserStatus!.lastChangeTime!.doubleValue < lastChangeTime?.doubleValue
                {
                    
                    //status hasChanged
                    loggedUser!.userStatus = UserStatus.updateUserStatus(oldUserStatus!, statusDic : statusDic)
                    
                    return (Int(loggedUser!.userStatus!.status!.intValue), Int(loggedUser!.userStatus!.sessionState!.intValue))
                }
                
                let sessionState = statusDic[UserStatusFields.SessionState.rawValue]?.integerValue
                if  sessionState != SessionState.Logged.rawValue {
                    return (Int(oldUserStatus!.status!.intValue), sessionState!)
                }
                
                if oldUserStatus!.status!.integerValue == UserState.Notified.rawValue {
                    return (UserState.Active.rawValue, SessionState.Logged.rawValue)
                }
            }
            else
            {
                //new Status
                loggedUser!.userStatus = UserStatus.newUserStatus(statusDic, managedObjectContext: managedObjectContext)
                
                return ( Int(loggedUser!.userStatus!.status!.intValue), Int(loggedUser!.userStatus!.sessionState!.intValue))
            }
        
        }
        return (statusDic[UserStatusFields.Status.rawValue]!.integerValue, statusDic[UserStatusFields.SessionState.rawValue]!.integerValue)
    }
    
    
    class func userWithId(userId:String) -> User? {
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
       return userWithId(userId, managedObjectContext: managedObjectContext)
    }


    class func userWithId(userId:String, managedObjectContext: NSManagedObjectContext) -> User? {
        
        let request = NSFetchRequest(entityName: "User")
        request.predicate = NSPredicate(format: "userId == %@", userId)
        
        if let users = try? managedObjectContext.executeFetchRequest(request) {
            return users.first as? User
        }
        
        return nil
    }
    
    class func usersWithIds(usersIds ids: [String]) -> [User] {
        
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

        let fetchRequest = NSFetchRequest(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "userId IN %@", ids)
        
        do {
            let users = try managedObjectContext.executeFetchRequest(fetchRequest) as! [User]
            
            return users
            
        } catch {
            
            fatalError("Failed to fetch users: \(error)")
        }
        
        return []
    }
    
    class func usersWithTwitterIds(usersTwitterIds ids: [String]) -> [User] {
        
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        let fetchRequest = NSFetchRequest(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "twitterId IN %@", ids)
        
        do {
            let users = try managedObjectContext.executeFetchRequest(fetchRequest) as! [User]
            
            return users
            
        } catch {
            
            fatalError("Failed to fetch users: \(error)")
        }
        
        return []
    }
    
    func toDictionary() -> NSDictionary
    {
        let userDic:NSMutableDictionary = [
            User.Keys.UserID.rawValue: self.userId!,
            User.Keys.Username.rawValue: self.username!,
            User.Keys.PhotoUrl.rawValue: self.photoUrl!,
            User.Keys.isVerified.rawValue: self.isVerified!
        ]
        
        if self.tagList != nil
        {
            userDic[User.Keys.TagList.rawValue] = self.tagList
        }
        
        if self.bio != nil
        {
            userDic[User.Keys.Bio.rawValue] = self.bio
        }
        
        return userDic
    }
}
