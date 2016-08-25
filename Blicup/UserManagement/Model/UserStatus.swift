//
//  UserStatus.swift
//  Blicup
//
//  Created by Moymer on 7/14/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation
import CoreData

enum UserStatusFields: String {
    
    case Status = "status"
    case SessionState = "sessionState"
    case LastChangeTime = "lastChangeTime"
    
    
}
enum UserState: Int {
    case Active
    case Notified
    case Banned
}
enum SessionState: Int {
    case Logged
    case LoggedOut
}

class UserStatus: NSManagedObject {



    class func newUserStatus(statusDic : NSDictionary, managedObjectContext: NSManagedObjectContext) -> UserStatus? {
        
        let userStatus = NSEntityDescription.insertNewObjectForEntityForName("UserStatus", inManagedObjectContext:managedObjectContext) as! UserStatus
 
        return updateUserStatus(userStatus, statusDic : statusDic)
    }
    
    class func updateUserStatus(userStatus:UserStatus, statusDic : NSDictionary) -> UserStatus? {
       
        userStatus.status = statusDic[UserStatusFields.Status.rawValue]?.integerValue
        userStatus.sessionState = statusDic[UserStatusFields.SessionState.rawValue]?.integerValue
        userStatus.lastChangeTime = statusDic[UserStatusFields.LastChangeTime.rawValue]?.doubleValue
        
        return userStatus
    }

}
