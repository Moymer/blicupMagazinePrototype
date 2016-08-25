//
//  SettingsPresenter.swift
//  Blicup
//
//  Created by Moymer on 15/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class SettingsPresenter: NSObject {
    let kDefaultDescriptionMesage = NSLocalizedString("(Write a short description about you)", comment: "(Write a short description about you)")
    private var usernameCheckTimestamp:NSTimeInterval = 0.0
    
    
    func userPhotoUrl()->NSURL? {
        guard let photoUrl = UserBS.getLoggedUser()?.photoUrl else {
            return nil
        }
        
        return NSURL(string: photoUrl)
    }
    
    func username()->String? {
        return UserBS.getLoggedUser()?.username    
    }
    
    func numberOfLikes()->Int {
        guard let userInfo = UserBS.getLoggedUser()?.userInfo else {
            return 0
        }
        
        return userInfo.likeCount!.integerValue
    }
    
    func isVerifiedUser() -> Bool {
        guard let isVerified = UserBS.getLoggedUser()?.isVerified else {
            return false
        }
        
        return isVerified.boolValue
    }
    
    func userBio()->String? {
        return UserBS.getLoggedUser()?.bio
    }
    
    func canSaveNewData(username: String?, description:String, newPhoto:Bool)->Bool {
        if username?.length == 0 {
            return false
        }
        
        let loggedUser = UserBS.getLoggedUser()
        var userBio = loggedUser?.bio
        if userBio == nil { userBio = "" } // TextView never return nil, so we have to adpat te comparisson of the description
        
        let hasChanges = (username != loggedUser?.username || description != userBio || newPhoto)
        
        return hasChanges
    }
    
    func hasInitialBio()->Bool {
        guard let userBio = UserBS.getLoggedUser()?.bio else {
            return false
        }
        
        return (userBio.length > 0)
    }
    
    func validateIncomingUsernameEdit(text: String) -> String? {
        var replaceString = text.stringByFoldingWithOptions(.DiacriticInsensitiveSearch, locale: NSLocale.currentLocale())
        replaceString = replaceString.stringByReplacingOccurrencesOfString(" ", withString: "_")
        replaceString = replaceString.lowercaseString
        
        if replaceString.rangeOfString("[^a-z0-9._]", options: .RegularExpressionSearch) != nil {
            return nil
        }
        
        if replaceString.length > USERNAME_LIMIT_LENGTH {
            replaceString = replaceString.substringToIndex(replaceString.startIndex.advancedBy(USERNAME_LIMIT_LENGTH))
        }
        
        return replaceString
    }
    
    
    func checkUsernameOnServer(username:String, completionHandler:(isAvailable:Bool)->Void) {
        let timestamp = NSDate().timeIntervalSince1970
        usernameCheckTimestamp = timestamp
        let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * NSTimeInterval(NSEC_PER_SEC)))
        
        dispatch_after(delay, dispatch_get_main_queue()) {
            if timestamp == self.usernameCheckTimestamp {
                UserBS.checkUsernameAvailability(username, timestamp: self.usernameCheckTimestamp, completionHandler: { (success, isAvailable, timestamp) in
                    if timestamp == self.usernameCheckTimestamp {
                        completionHandler(isAvailable: isAvailable)
                    }
                })
            }
        }
    }
    
    
    func updateUser(username:String, bio:String?, photoImage:UIImage?, completionHandler:(success:Bool)->Void) {
        guard let user = UserBS.getLoggedUser() else {
            return
        }
        
        let updateJson:NSMutableDictionary = [
            User.Keys.UserID.rawValue: user.userId!,
            User.Keys.Username.rawValue: username,
            User.Keys.PhotoUrl.rawValue: user.photoUrl!,
            User.Keys.TagList.rawValue: user.tagList!
        ]
        
        if bio != nil {
            updateJson[User.Keys.Bio.rawValue] = bio!
        }
        
        if photoImage != nil {
            AmazonManager.uploadImageToAmazonBucket(photoImage!, key: "userImage") { (urlImagem) in
                if urlImagem != nil {
                    updateJson[User.Keys.PhotoUrl.rawValue] = urlImagem
                    
                    UserBS.changeUserProfileWithUpdate(updateJson, completionHandler: { (success) in
                        completionHandler(success: success)
                    })
                }
                else {
                    completionHandler(success: false)
                }
            }
        }
        else {
            UserBS.changeUserProfileWithUpdate(updateJson, completionHandler: { (success) in
                completionHandler(success: success)
            })
        }
    }
}
