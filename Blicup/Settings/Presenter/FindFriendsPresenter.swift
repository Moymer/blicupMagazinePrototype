//
//  FindFriendsPresenter.swift
//  Blicup
//
//  Created by Guilherme Braga on 10/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import FBSDKCoreKit

class FindFriendsPresenter: NSObject, BlockFollowUserListPresenter {
    // From server 0 = Facebook and 1 = Twitter
    enum SocialNetwork: Int {
        case FACEBOOK, TWITTER
    }
    
    private var userList = [User]()
    private var fbUserList = [User]()
    private var twitterUserList = [User]()
    
    private var loadedFbUsers = false
    private var loadedTwitterUsers = false
    
    private let kUserDefaultTwitterKey = "TimestampFriendsRequestTwitter"
    private let kUserDefaultTwitterUserIdsKey = "UserIdsFriendsRequestTwitter"
    
    var lastRequestTimestamp: NSTimeInterval = 0.0
    
    func getUsersFromFacebook(completionHandler:(success: Bool) -> Void) {

        let timestamp = NSDate().timeIntervalSince1970
        self.lastRequestTimestamp = timestamp
        
        if loadedFbUsers {
            
            self.userList = self.fbUserList
            completionHandler(success: true)
            
        } else {
        
            LoginController.getUserIdFromFacebookFriends { (userIds, error) in
                
                if error == nil {
                    
                    self.getBlicupUsersWithSocialId(userIds, socialNetwork: SocialNetwork.FACEBOOK.rawValue, timestamp: timestamp,completionHandler: { (success) in
                        
                        if timestamp == self.lastRequestTimestamp {
                            if success {
                                self.loadedFbUsers = true
                                self.fbUserList = self.userList
                            }
                            
                            completionHandler(success: success)
                        }
                    })
                    
                } else {
                    //TODO: tratar erro
                    completionHandler(success: false)
                }
            }
        }
    }
    
    func getUsersFromTwitter(completionHandler:(success: Bool) -> Void) {
        
        let timestamp = NSDate().timeIntervalSince1970
        self.lastRequestTimestamp = timestamp
        
        if loadedTwitterUsers {
            
            self.userList = self.twitterUserList
            completionHandler(success: true)
            
        } else {
            
            if checkIfTimestampFriendsRequestTwitterNeedUpdate() {
                
                LoginController.getUserIdFromTwitterFriends { (userIds, error) in
                    
                    if error == nil {
                        
                        self.updateTimestampAndUserIdsFriendsRequestTwitter(userIds)
                        self.getBlicupUsersWithSocialId(userIds, socialNetwork: SocialNetwork.TWITTER.rawValue, timestamp: timestamp, completionHandler: { (success) in
                            
                            if timestamp == self.lastRequestTimestamp {
                                if success {
                                    self.loadedTwitterUsers = true
                                    self.twitterUserList = self.userList
                                }
                                
                                completionHandler(success: success)
                             }
                        })
                        
                    } else {
                        //TODO: tratar erro
                        completionHandler(success: false)
                    }
                }
            } else {
                getUsersFromTwitter()
                completionHandler(success: true)
            }
        }
    }
    
    private func getBlicupUsersWithSocialId(userIds: [String], socialNetwork: Int, timestamp: NSTimeInterval, completionHandler:(success: Bool) -> Void) {
        
        if userIds.count > 0 {
            
            UserBS.getBlicupUsersWithSocialId(userIds, socialNetwork: socialNetwork, completionHandler: { (success, userList) in
                
                if timestamp == self.lastRequestTimestamp {
                    if success {
                        
                        if let users = userList {
                            self.userList = users
                        } else {
                            self.userList = [User]()
                        }
                    }
                    completionHandler(success: success)
                }
            })

        } else {
            self.userList = [User]()
            completionHandler(success: true)
        }
    }
    
    func loginWithFacebook(fromController: UIViewController, completionHandler:(success: Bool) -> Void) {
        
        LoginController.loginWithFacebook(fromController: fromController) { (profile, error) in
            
            if error == nil {
                if let profile = profile, facebookId = profile["facebookId"] as? String, user = UserBS.getLoggedUser() {
                    if user.facebookId == nil {
                        user.facebookId = facebookId
                    }
                }
                completionHandler(success: true)
            } else {
                completionHandler(success: false)
            }
        }
    }
    
    func loginWithTwitter(completionHandler:(success: Bool) -> Void) {
        
        LoginController.loginWithTwitter { (profile, error) in
            if error == nil {
                
                if let profile = profile, twitterId = profile["twitterId"] as? String, user = UserBS.getLoggedUser() {
                    if user.twitterId == nil {
                        user.twitterId = twitterId
                    }
                }
                completionHandler(success: true)
                
            } else {
                completionHandler(success: false)
            }
        }
    }
    
    
    func userAtIndex(index:NSIndexPath)->User? {
        return userList[index.row]
    }
    
    func userCount()->Int {
        return userList.count
    }
    
    func userHasFacebookId() -> Bool {
        
        return UserBS.getLoggedUser()?.facebookId != nil
    }
    
    func userHasTwitterId() -> Bool {
        return UserBS.getLoggedUser()?.twitterId != nil
    }
    
    func isUserLoggedWithFacebook() -> Bool {
        return LoginController.userLoggedWithFacebook()
    }
    
    func isUserLoggedWithTwitter() -> Bool {
        return LoginController.userLoggedWithTwitter()
    }
    
    func clearDatasource() {
        self.userList.removeAll()
    }
    
    private func updateTimestampAndUserIdsFriendsRequestTwitter(userIds: [String]) {
        
        let now = NSDate().timeIntervalSince1970
        let userDefault = NSUserDefaults.standardUserDefaults()
        userDefault.setDouble(now, forKey: kUserDefaultTwitterKey)
        userDefault.setValue(userIds, forKey: kUserDefaultTwitterUserIdsKey)
        userDefault.synchronize()
    }
    
    private func checkIfTimestampFriendsRequestTwitterNeedUpdate() -> Bool {
        
        let userDefault = NSUserDefaults.standardUserDefaults()
        let lastTimestamp = userDefault.doubleForKey(kUserDefaultTwitterKey)
        let now = NSDate().timeIntervalSince1970
        let oneMinuteInSeconds: Double = 60
        let diff = (now - lastTimestamp) > oneMinuteInSeconds
        print(now - lastTimestamp)
        
        return diff
    }
    
    private func getUsersFromTwitter() {
    
        let userDefault = NSUserDefaults.standardUserDefaults()
        guard let usersTwitterIds = userDefault.valueForKey(kUserDefaultTwitterUserIdsKey) as? [String] where usersTwitterIds.count > 0 else {
            return
        }
        
        self.userList = User.usersWithTwitterIds(usersTwitterIds: usersTwitterIds)
        self.loadedTwitterUsers = true
        self.twitterUserList = self.userList
    }
}
