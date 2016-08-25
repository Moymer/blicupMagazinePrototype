//
//  LDTPMockImpl.swift
//  Blicup
//
//  Created by Moymer on 12/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class LDTPMockImpl: NSObject {

    class func createUserAccount(userData: NSDictionary, completionHandler:(success:Bool, newUser:NSDictionary?)->Void) {
        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 4 * Int64(NSEC_PER_SEC))
        dispatch_after(time, dispatch_get_main_queue()) {
            let jsonDic = NSMutableDictionary(dictionary: userData)
            jsonDic["userId"] = "newUserID"
            completionHandler(success: true, newUser: jsonDic)
        }
    }
    
    
    class func restoreUserAccountWithFacebookId(facebookId:String, completionHandler:(success:Bool, restoredUser:NSDictionary?)->Void) {
        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 4 * Int64(NSEC_PER_SEC))
        dispatch_after(time, dispatch_get_main_queue()) {
            let jsonDic = [
                "username":"gustavoazevedodeoliveira",
                "email":"gustavo.az.ol@gmail.com",
                "photoUrl":"https://scontent.xx.fbcdn.net/hprofile-xat1/v/t1.0-1/p200x200/12246631_10206747841126176_843307350504561463_n.jpg?oh=2521304bb386c73d699724e3bf3bb87d&oe=5777EDC5",
                "userId":"newUserID",
                "facebookId":facebookId,
                "isVerified":false
            ]
        
            completionHandler(success: true, restoredUser: jsonDic)
        }
    }
    
    
    class func restoreUserAccountWithTwitterId(twitterId:String, completionHandler:(success:Bool, restoredUser:NSDictionary?)->Void) {
        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 4 * Int64(NSEC_PER_SEC))
        dispatch_after(time, dispatch_get_main_queue()) {
            let jsonDic = [
                "username":"guh_azevedo",
                "email":"gustavo.az.ol@gmail.com",
                "photoUrl":"https://pbs.twimg.com/profile_images/453606818/twitter_reasonably_small.JPG",
                "userId":"newUserID",
                "twitterId":twitterId,
                "isVerified":false
            ]
            
            completionHandler(success: false, restoredUser: jsonDic)
        }
    }
    
    
    class func isUsernameAvailable(username:String, completionHandler:(success:Bool, available:Bool)->Void) {
        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 2 * Int64(NSEC_PER_SEC))
        dispatch_after(time, dispatch_get_main_queue()) {
            let available = (username == "guh_azevedo") || (username == "usuario_teste")
            completionHandler(success: true, available: available)
        }
    }
}
