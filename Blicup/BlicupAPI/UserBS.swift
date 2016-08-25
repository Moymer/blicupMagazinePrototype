//
//  UserBS.swift
//  Blicup
//
//  Created by vham on 09/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Alamofire
import CoreData

enum LoggedUserSessionState: String {
    case LoginFailed = "LoginFailed"
    case YellowCard = "NewYellowCard"
    case BannedFromBlicup = "RedCard"
    case GeneralLogout = "GeneralLogout"
    case NormalState = "SessionOk"
}


class UserBS: NSObject {
    
    private static let LOGGED_USER_KEY = "Logged_User_Key"
    
    //Verifica usuário Logado
    class func hasCompletedLogin() -> Bool {
        guard let tagList = UserBS.getLoggedUser()?.tagList else {
            return false
        }
        
        return (tagList.count >= 3) //Deve ter ao menos 3 tags salvas
    }
    
    class func getLoggedUser() -> User? {
        
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        return getLoggedUser(managedObjectContext)
    }
    
    //Verifica usuário Logado
    class func getLoggedUser(managedObjectContext: NSManagedObjectContext) -> User? {
        
        if let loggedUserId = NSUserDefaults.standardUserDefaults().stringForKey(LOGGED_USER_KEY) {
            let user  = User.userWithId(loggedUserId, managedObjectContext: managedObjectContext)
            
            if user == nil {
                NSUserDefaults.standardUserDefaults().removeObjectForKey(loggedUserId)
            }
            
            return user
        }
        else {
            return nil
        }
    }
    
    //Criar uma conta de um usuário
    class func createUserAccount( user: NSDictionary,   completionHandler: (success: Bool,  newUser: User? ) -> Void) {
        
        LDTProtocolImpl.sharedInstance.createUserAccount(user) { (success, newUser) in
            var createdUser:User?
            if success && newUser != nil {
                createdUser = User.createUser(newUser!)
                
                if createdUser != nil {
                    
                    BlicupAnalytics.sharedInstance.mark_Signup(createdUser?.facebookId != nil )
                    NSUserDefaults.standardUserDefaults().setValue(createdUser!.userId, forKey: LOGGED_USER_KEY)
                    NSUserDefaults.standardUserDefaults().synchronize()
                }
            }
            completionHandler(success: success, newUser: createdUser)
        }
    }
    
    class func restoreFacebookUser(facebookId:String, completionHandler:(state: LoggedUserSessionState, restoredUser:User?)->Void) {
        LDTProtocolImpl.sharedInstance.restoreUserAccountWithFacebookId(facebookId) { (success, restoredUser) in
            if success == false {
                completionHandler(state: LoggedUserSessionState.LoginFailed, restoredUser: nil)
            }
            else if let userDic = restoredUser {
                guard let userStatusDic  = userDic[User.Keys.UserStatus.rawValue] as? [String:AnyObject] else {
                    completionHandler(state: LoggedUserSessionState.LoginFailed, restoredUser: nil)
                    return
                }
                
                let loginStatus = checkAndUpdateLoggedUserStatus(userStatusDic)
                if loginStatus == LoggedUserSessionState.BannedFromBlicup {
                    completionHandler(state: loginStatus, restoredUser: nil)
                    return
                }
                BlicupAnalytics.sharedInstance.mark_Login( true)
                
                let createdUser = User.createUser(userDic)
                NSUserDefaults.standardUserDefaults().setValue(createdUser.userId, forKey: LOGGED_USER_KEY)
                NSUserDefaults.standardUserDefaults().synchronize()
                completionHandler(state: loginStatus, restoredUser: createdUser)
            }
            else {
                completionHandler(state: LoggedUserSessionState.NormalState, restoredUser: nil)
            }
        }
    }
    
    class func restoreTwitterUser(twitterId:String, completionHandler:(state: LoggedUserSessionState, restoredUser:User?)->Void) {
        LDTProtocolImpl.sharedInstance.restoreUserAccountWithTwitterId(twitterId) { (success, restoredUser) in
            if success == false {
                completionHandler(state: LoggedUserSessionState.LoginFailed, restoredUser: nil)
            }
            else if let userDic = restoredUser {
                guard let userStatusDic  = userDic[User.Keys.UserStatus.rawValue] as? [String:AnyObject] else {
                    completionHandler(state: LoggedUserSessionState.LoginFailed, restoredUser: nil)
                    return
                }
                
                let loginStatus = checkAndUpdateLoggedUserStatus(userStatusDic)
                if loginStatus == LoggedUserSessionState.BannedFromBlicup {
                    completionHandler(state: loginStatus, restoredUser: nil)
                    return
                }
                
                BlicupAnalytics.sharedInstance.mark_Login( false )
                
                let createdUser = User.createUser(userDic)
                NSUserDefaults.standardUserDefaults().setValue(createdUser.userId, forKey: LOGGED_USER_KEY)
                NSUserDefaults.standardUserDefaults().synchronize()
                completionHandler(state: loginStatus, restoredUser: createdUser)
            }
            else {
                completionHandler(state: LoggedUserSessionState.NormalState, restoredUser: nil)
            }
        }
    }
    
    
    class func updateUsersInfo(userIds:[String], completionHandler:((success:Bool)->Void)?) {
        LDTProtocolImpl.sharedInstance.getUserInfosByIds(userIds) { (success, retMsg) in
            if success, let jsonArray = retMsg?["Ans"] as? [NSDictionary] {
                UserInfo.createUpdateUserInfosInBG(jsonArray, completionHandler: { (success) in
                    completionHandler?(success: success)
                })
            } else {
                completionHandler?(success:success)
            }
        }
    }
    
    class func registerPushSNSEndpoint(completionHandler:(success : Bool) -> Void) {
        LDTProtocolImpl.sharedInstance.registerPushEndpointForUser() { (success, retMsg) in
            
            completionHandler(success: success)
        }
    }
    
    //Verificar disponibilidade de username
    class func checkUsernameAvailability(username:String, timestamp:NSTimeInterval, completionHandler:(success: Bool,  isAvailable: Bool, timestamp:NSTimeInterval) -> Void)
    {
        LDTProtocolImpl.sharedInstance.isUsernameAvailable(username) { (success, available) in
            completionHandler(success: success, isAvailable: available, timestamp: timestamp)
        }
    }
    
    
    //Alterar perfil de usuário
    // Modo offline (nao propaga) - Usado para salvar as novas tags
    class func changeUserProfile( user: NSDictionary,   completionHandler: (success: Bool) -> Void) {
        LDTProtocolImpl.sharedInstance.changeUserAccount(user) { (success, changed) in
            let totalSuccess = (success && changed)
            
            if totalSuccess {
                // Create or update user
                let changedUserDic : NSMutableDictionary = user.mutableCopy() as! NSMutableDictionary
                changedUserDic[User.Keys.LastUpdated.rawValue]  = NSNumber( double: NSDate().timeIntervalSince1970 * 1000)
                User.createUser(changedUserDic)
            }
            
            completionHandler(success: totalSuccess)
        }
    }
    
    // Muda o profile e faz update dos dados nas conversas atuais
    class func changeUserProfileWithUpdate( user: NSDictionary,   completionHandler: (success: Bool) -> Void)
    {
        LDTProtocolImpl.sharedInstance.changeUserProfile(user) { (success, retMsg) in
            // Create or update user
            if success, let userInfoJson = retMsg?["Ans"] as? NSDictionary{
                User.createUser(userInfoJson)
            }
            
            completionHandler(success: success)
        }
    }
    
    class func getBlicupUsersWithSocialId(socialIds :[String], socialNetwork: Int, completionHandler: (success: Bool, userList: [User]?) -> Void) {
        
        LDTProtocolImpl.sharedInstance.getBlicupUsersWithSocialId(socialIds, socialNetwork: socialNetwork, completionHandler: { (success, retMsg) in
             if success, let jsonDic = retMsg?["Ans"] as? NSDictionary, userList = jsonDic["userList"] as? [NSDictionary], userInfoDic = jsonDic["userInfoList"] as? [NSDictionary] {
                
                User.createUserInBG(userList, deleteOtherEntries: false, completionHandler: { (userList) in
                    UserInfo.createUpdateUserInfosInBG(userInfoDic, completionHandler: { (success) in
                        completionHandler(success: success, userList: userList)
                    })
                })
             } else {
                completionHandler(success: success, userList: nil)
            }
        })
    }
    
    // MARK: Follow
    
    private class func addFolloweeUser(userId:String) {
        guard let userInfo = UserBS.getLoggedUser()?.userInfo else {
            return
        }
        
        var loggedUserFolloweeList = UserBS.getLoggedUser()?.userInfo?.followeeList as? [String]
        if loggedUserFolloweeList == nil {
            loggedUserFolloweeList = [String]()
        }
        
        if !loggedUserFolloweeList!.contains(userId) {
            loggedUserFolloweeList!.append(userId)
        }
        
        userInfo.followeeList = loggedUserFolloweeList
    }
    
    private class func removeFolloweeUser(userId:String) {
        guard let userInfo = UserBS.getLoggedUser()?.userInfo else {
            return
        }
        
        var loggedUserFolloweeList = UserBS.getLoggedUser()?.userInfo?.followeeList as? [String]
        if loggedUserFolloweeList == nil {
            loggedUserFolloweeList = [String]()
        }
        
        if let index = loggedUserFolloweeList!.indexOf(userId) {
            loggedUserFolloweeList!.removeAtIndex(index)
        }
        
        userInfo.followeeList = loggedUserFolloweeList
    }

    
    //Seguir um usuário
    class func followUser(userId: String, completionHandler: (success: Bool) -> Void) {
        UserBS.addFolloweeUser(userId)
        LDTProtocolImpl.sharedInstance.followUser(userId) { (success, retMsg) in
            if success, let userInfoJson = retMsg?["Ans"] as? [NSDictionary] {
                
     
                BlicupAnalytics.sharedInstance.mark_FollowedUser()
                
                for userInfoDic in userInfoJson {
                    UserInfo.createUpdateUserInfo(userInfoDic)
                }
            } else {
                UserBS.removeFolloweeUser(userId)
            }
            
            completionHandler(success: success)
        }
    }
 
    //Deixar de seguir um usuário
    class func unfollowUser(userId: String, completionHandler: (success: Bool) -> Void) {
        
        UserBS.removeFolloweeUser(userId)
        LDTProtocolImpl.sharedInstance.unfollowUser(userId) { (success, retMsg) in
            if success, let userInfoJson = retMsg?["Ans"] as? [NSDictionary] {
                
                 BlicupAnalytics.sharedInstance.mark_UnfollowedUser()
                
                for userInfoDic in userInfoJson {
                    UserInfo.createUpdateUserInfo(userInfoDic)
                }
            } else {
                UserBS.addFolloweeUser(userId)
            }
            
            completionHandler(success: success)
        }
    }
    
    // MARK: Block
    private class func addBlockedUser(userId:String) {
        guard let userInfo = UserBS.getLoggedUser()?.userInfo else {
                return
        }
        
        var loggedUserBlockList = UserBS.getLoggedUser()?.userInfo?.blockedList as? [String]
        if loggedUserBlockList == nil {
            loggedUserBlockList = [String]()
        }
        
        if !loggedUserBlockList!.contains(userId) {
            loggedUserBlockList!.append(userId)
        }
        
        userInfo.blockedList = loggedUserBlockList
    }
    
    private class func removeBlockedUser(userId:String) {
        guard let userInfo = UserBS.getLoggedUser()?.userInfo else {
                return
        }
        
        var loggedUserBlockList = UserBS.getLoggedUser()?.userInfo?.blockedList as? [String]
        if loggedUserBlockList == nil {
            loggedUserBlockList = [String]()
        }
        
        if let index = loggedUserBlockList!.indexOf(userId) {
            loggedUserBlockList!.removeAtIndex(index)
        }
        
        userInfo.blockedList = loggedUserBlockList
    }
    
    class func getUsersBlockedByUser(userId:String, completionHandler:(success:Bool)->Void) {
        LDTProtocolImpl.sharedInstance.getBlockeds(userId) { (success, retMsg) in
            if let list =  retMsg?["Ans"] as? [NSDictionary] {
                User.createUserInBG(list, deleteOtherEntries: false, completionHandler: { (userList) in
                    completionHandler(success: true)
                })
            }
            else {
                completionHandler(success: success)
            }
        }
    }
    
    //Bloquear um usuário
    class func blockUser(blockedUserId: String, completionHandler: ((success: Bool) -> Void)? )
    {
        UserBS.addBlockedUser(blockedUserId)
        
        LDTProtocolImpl.sharedInstance.blockUser(blockedUserId) { (success, retMsg) in
            if success, let userInfoJson = retMsg?["Ans"] as? [NSDictionary] {
                
                 BlicupAnalytics.sharedInstance.mark_BlockedUser()
                for userInfoDic in userInfoJson {
                    UserInfo.createUpdateUserInfo(userInfoDic)
                }
            }
            else {
                removeBlockedUser(blockedUserId)
            }
            
            completionHandler?(success: success)
        }
    }
    
    //Desbloquear um usuário
    class func unblockUser(unblockedUserId: String, completionHandler: ((success: Bool) -> Void)? )
    {
        UserBS.removeBlockedUser(unblockedUserId)
        
        LDTProtocolImpl.sharedInstance.unblockUser(unblockedUserId) { (success, retMsg) in
            if success, let userInfoJson = retMsg?["Ans"] as? [NSDictionary] {
                
                BlicupAnalytics.sharedInstance.mark_UnblockedUser()
                
                for userInfoDic in userInfoJson {
                    UserInfo.createUpdateUserInfo(userInfoDic)
                }
            }
            else {
                UserBS.addBlockedUser(unblockedUserId)
            }
            
            completionHandler?(success: success)
        }
    }
    
    //Bane usuário e o remove do chatroom
    class func banAndBlockUserFromChatroom(toBlockUserId: String, chatRoomId: String, completionHandler: ((success: Bool) -> Void)?) {
        
        LDTProtocolImpl.sharedInstance.banAndBlockUserFromChatroom(toBlockUserId, chatRoomId: chatRoomId) { (success, retMsg) in
            if success, let userInfoJson = retMsg?["Ans"] as? [NSDictionary] {
                
                BlicupAnalytics.sharedInstance.mark_BanAndBlockedUser()
                
                for userInfoDic in userInfoJson {
                    UserInfo.createUpdateUserInfo(userInfoDic)
                }
            }
            
            completionHandler?(success: success)
        }
    }
    
    //Listar chat rooms de interesse de um usuário
    func getChatRoomsOfUserInterest(completionHandler: (success: Bool, chatRoomsList: [AnyObject]?) -> Void) {
        
        // SERVIÇO MOCK, AO TROCAR PARA O REAL, REFAZER TRATAMENTO DE ERRO.
        Alamofire.request(.GET, "http://private-2a2af-getchatroomslist.apiary-mock.com/questions").responseJSON { response in
            
            //            print(response.request)  // original URL request
            //            print(response.result)   // result of response serialization
            if response.result.error != nil {
                
                completionHandler(success: false, chatRoomsList: nil)
                
            } else {
                
                if let JSON = response.result.value {
                    
                    if let chatrooms = JSON[0]["chatrooms"] as? NSMutableArray {
                        
                        completionHandler(success: true, chatRoomsList: chatrooms as [AnyObject])
                    }
                    
                    completionHandler(success: true, chatRoomsList: nil)
                    
                } else {
                    completionHandler(success: false, chatRoomsList: nil)
                }
            }
        }
    }
    
    //List users that username matches search term
    class func getUsersThatMatchesSearchTerm(searchTerm: String ,completionHandler: (searchTerm: String, success: Bool, userList: [User]?) -> Void) {
        
        LDTProtocolImpl.sharedInstance.getUsersThatMatchesSearchTerm(searchTerm, completionHandler: { (success, retMsg) in
            
            if success && retMsg != nil {
                
                BlicupAnalytics.sharedInstance.mark_SearchedUser(searchTerm)
                
                guard let usersDicArray = (retMsg!["Ans"] as? [NSDictionary]) else {
                    completionHandler(searchTerm: searchTerm, success: false, userList: nil)
                    return
                }
                
                User.createUserInBG(usersDicArray, deleteOtherEntries: false, completionHandler: { (userList) in
                    completionHandler(searchTerm: searchTerm, success: true, userList: userList)
                })
                
            }
            else {
                completionHandler(searchTerm: searchTerm, success: false, userList: nil)
            }
        })
        
    }
    
    //Listar chat rooms that matches search term
    class func getUsersThatParticipatesOnChat( chatroomId: String, completionHandler:( success: Bool, userList: [User]?) -> Void) {
        
        LDTProtocolImpl.sharedInstance.getUsersThatParticipatesOnChatroom(chatroomId) { (success, retMsg) in
            
            if success && retMsg != nil {
                guard let usersDicArray = (retMsg!["Ans"] as? [NSDictionary]) else {
                    completionHandler(success: false, userList: nil)
                    return
                }
                
                var userList = [User]()
                
                for userDic in usersDicArray {
                    let user = User.createUser(userDic)
                    userList.append(user)
                }
                completionHandler(success: true, userList: userList)
            }
            else {
                completionHandler(success: false, userList: nil)
            }
        }
        
    }
    
    //Buscar lista de seguidores daquele userId
    class func getFollowers(userId: String, completionHandler:(success: Bool) -> Void) {
    
        LDTProtocolImpl.sharedInstance.getFollowers(userId) { (success, retMsg) in
            
            if success && retMsg != nil {
                guard let usersDicArray = (retMsg!["Ans"] as? [NSDictionary]) else {
                    completionHandler(success: false)
                    return
                }
                
                User.createUserInBG(usersDicArray, deleteOtherEntries: false, completionHandler: { (userList) in
                    completionHandler(success: success)
                })
            }
            else {
                completionHandler(success: success)
            }
        }
    }
    
    //Buscar lista de quem o userId está seguindo
    class func getFollowees(userId: String, completionHandler:(success: Bool, userList: [User]?) -> Void) {
        
        LDTProtocolImpl.sharedInstance.getFollowees(userId) { (success, retMsg) in
            
            if success && retMsg != nil {
                guard let usersDicArray = (retMsg!["Ans"] as? [NSDictionary]) else {
                    completionHandler(success: false, userList: [User]())
                    return
                }
                
                User.createUserInBG(usersDicArray, deleteOtherEntries: false, completionHandler: { (userList) in
                    completionHandler(success: success, userList: userList)
                })
            }
            else {
                completionHandler(success: success, userList: [User]())
            }
        }
    }
    
    
    //Reportar usuário
    class func reportUser(user: User, completionHandler: (success: Bool) -> Void) {
        
        let userDic = user.toDictionary()
        
        LDTProtocolImpl.sharedInstance.reportUser(userDic, completionHandler: { (success, retMsg) in
            completionHandler(success: success)
        })
        
    }
    
    // MARK: Log Out
    class func logUserOutOnServer(completionBlock:((success:Bool)->Void)?) {
        LDTProtocolImpl.sharedInstance.logoutFromDevice { (success, retMsg) in
            if success {
               LDTProtocolImpl.sharedInstance.closeSocket()
            }
            
            completionBlock?(success:success)
        }
    }
    
    class func logUserOutFromAllDevicesOnServer(completionBlock:((success:Bool)->Void)?) {
        LDTProtocolImpl.sharedInstance.logoutAllDevice { (success, retMsg) in
            if success {
                LDTProtocolImpl.sharedInstance.closeSocket()
            }
            
            completionBlock?(success:success)
        }
    }
    
    //Internal - Aux for status checking and update
    
    class func checkAndUpdateLoggedUserStatus(userStatusDic :[String:AnyObject]) -> LoggedUserSessionState {
        let userStatus = User.createOrUpdateLoggedUserStatus(userStatusDic)
        
        let userState = userStatus.0
        let sessionState = userStatus.1
        
        
        if userState == UserState.Banned.rawValue {
           // print("You are Banned from blicup!!!!")
            return LoggedUserSessionState.BannedFromBlicup
        }
        else if userState == UserState.Notified.rawValue{
            //print("Yellow Card Notification!!!!")
            return LoggedUserSessionState.YellowCard
        }
        else if sessionState == SessionState.LoggedOut.rawValue {
            //print("General Logout!!!!")
            return LoggedUserSessionState.GeneralLogout
        }
        else {
            return LoggedUserSessionState.NormalState
        }
    }
    
    
    // MARK: - User Follow Suggestion
    class func getSuggestedUsersToFollow(completionHandler:(success:Bool, users:[User]?)->Void) {
        guard let userId = UserBS.getLoggedUser()?.userId else {
            completionHandler(success: false, users: nil)
            return
        }
        
        LDTProtocolImpl.sharedInstance.getUserToFollowSuggestions(userId) { (success, suggestions) in
            var userSuggestions = [User]()
            
            if success {
                if let usersDic = suggestions?["suggestedUserList"] as? [NSDictionary] {
                    for dictionary in usersDic {
                        let user = User.createUser(dictionary)
                        userSuggestions.append(user)
                    }
                }
                
                if let usersInfoDic = suggestions?["userInfoList"] as? [NSDictionary] {
                    for dictionary in usersInfoDic {
                        UserInfo.createUpdateUserInfo(dictionary)
                    }
                }
            }
            
            completionHandler(success: success, users: userSuggestions)
        }
    }
    
}