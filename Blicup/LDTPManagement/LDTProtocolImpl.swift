//
//  LDTProtocolImpl.swift
//  Blicup
//
//  Created by vham on 11/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation
import SocketRocket
import Alamofire
import ReachabilitySwift

class LDTProtocolImpl: NSObject {

    // PRODUÇÃO
    // let serviceAddress : String =  "https://offline.blicup.com/blicup/services"
    
    // DEV -- Use this!
    let serviceAddress : String =  "http://54.227.233.101:8081/blicup/services"
    
    //let serviceAddress : String =  "http://192.168.1.106:8081/blicup/services" //online - other uses
    
    
    let ldtpWSmanager :LDTPWebSocketManager = LDTPWebSocketManager()
    static let sharedInstance = LDTProtocolImpl()
    var networkReachability :Reachability?
    
    
    
    private override init() {
        super.init()
        
        NSURLSession.sharedSession().configuration.timeoutIntervalForResource = 30
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        do {
            networkReachability =  try Reachability.reachabilityForInternetConnection();
            
           notificationCenter.addObserver(ldtpWSmanager, selector: #selector(LDTPWebSocketManager.reachabilityChanged(_:)), name: ReachabilityChangedNotification, object: networkReachability)
            
            try networkReachability!.startNotifier()
        }
        catch let error as NSError {
            
            print("Erro ao deletar: \(error)")
        }
        
      
        notificationCenter.addObserver(ldtpWSmanager, selector: #selector(LDTPWebSocketManager.moveToBackground(_:)), name: UIApplicationWillResignActiveNotification, object: nil)
        
        notificationCenter.addObserver(ldtpWSmanager, selector: #selector(LDTPWebSocketManager.moveToForeground(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
        
    }
    
    
  
    
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(ldtpWSmanager, name: ReachabilityChangedNotification, object: networkReachability)
        
        NSNotificationCenter.defaultCenter().removeObserver(ldtpWSmanager, name: UIApplicationWillResignActiveNotification, object: nil   )
        NSNotificationCenter.defaultCenter().removeObserver(ldtpWSmanager, name: UIApplicationDidBecomeActiveNotification, object: nil   )
    }
    

    
    
    //MARK: - LDTP REST SERVICES - ON LOGIN
    
    func createUserAccount(userData: NSDictionary, completionHandler:(success:Bool, newUser:NSDictionary?)->Void) {
        
        let jsonObjectAll: [String: AnyObject] = [ "1COD" : 1 , "2REQ" : 332, "3USER" :  userData]
        
        
        
        Alamofire.request(.POST, serviceAddress, parameters:jsonObjectAll, encoding:.JSON).responseString { response in
            
            if response.result.error != nil {
//          if let httpError = response.result.error {
                //ERROR
               // let statusCode = httpError.code
                //print(statusCode) // URL response
                
                completionHandler(success: false, newUser: nil)
                
            } else {
                //SUCCESS
                
                let statusCode = (response.response?.statusCode)!
                print(statusCode)
                if let JSON = response.result.value {
                    
                    
                    if JSON.isEmpty {
                        
                        completionHandler(success: true, newUser: nil)
                    }
                    else {
                        //WITH DATA
                       // print("Resposta: \(JSON)")
                        let newUser =   LDTPMessageBuilder.convertStringToDictionary(JSON)
                        
                        completionHandler(success: true, newUser: newUser)
                    }
                    
                    
                }
            }
            
         }
           
    }
    
    
    func changeUserAccount(userData: NSDictionary, completionHandler:(success:Bool, changed:Bool)->Void) {
        
        let jsonObjectAll: [String: AnyObject] = [ "1COD" : 3 , "2REQ" : 332, "3USERID": userData["userId"]! ,"4USER" :  userData]
        
        
        
        Alamofire.request(.POST, serviceAddress, parameters:jsonObjectAll, encoding:.JSON).responseString { response in
            
            if let httpError = response.result.error {
                //ERROR
                let statusCode = httpError.code
                print(statusCode) // URL response
                
                completionHandler(success: false, changed: false)
                
            } else {
                //SUCCESS
                
                let statusCode = (response.response?.statusCode)!
                print(statusCode)
                if let JSON = response.result.value {
                    //print("Resposta: \(JSON)")
                    var changed: Bool = false
                    if(JSON.lowercaseString == "true"){
                        changed = true
                    }
                    completionHandler(success: true, changed: changed)
                }
                
            }
            
        }
        
        
    }

    
    func restoreUserAccountWithFacebookId(facebookId:String, completionHandler:(success:Bool, restoredUser:NSDictionary?)->Void) {
    
        let jsonObjectAll: [String: AnyObject] = [ "1COD" : 4 , "2REQ" : 332, "3ID" :  facebookId, "4DEVICEID":NSUserDefaults.standardUserDefaults().stringForKey("deviceId")!]
        
        
        
        Alamofire.request(.POST, serviceAddress, parameters:jsonObjectAll, encoding:.JSON).responseString { response in
            
            if let httpError = response.result.error {
                //ERROR
                let statusCode = httpError.code
                print(statusCode) // URL response
                
                completionHandler(success: false, restoredUser: nil)
                
            } else {
                //SUCCESS
                
                let statusCode = (response.response?.statusCode)!
                print(statusCode)
                if let JSON = response.result.value {
                
                    if JSON.isEmpty {
                        
                        completionHandler(success: true, restoredUser: nil)
                        
                    }
                    else {
                        //WITH DATA
                        //print("Resposta: \(JSON)")
                        let user =   LDTPMessageBuilder.convertStringToDictionary(JSON)
                        
                        completionHandler(success: true, restoredUser: user)
                    }

                }
            }

        }
        

    }
    
    
    func restoreUserAccountWithTwitterId(twitterId:String, completionHandler:(success:Bool, restoredUser:NSDictionary?)-> Void) {
        
        let jsonObjectAll: [String: AnyObject] = [ "1COD" : 5 , "2REQ" : 332, "3ID" :  twitterId, "4DEVICEID":NSUserDefaults.standardUserDefaults().stringForKey("deviceId")!]
        
        
        
        Alamofire.request(.POST, serviceAddress, parameters:jsonObjectAll, encoding:.JSON).responseString { response in
            
            if let httpError = response.result.error {
                //ERROR
                let statusCode = httpError.code
                print(statusCode) // URL response
                
                completionHandler(success: false, restoredUser: nil)
                
            } else {
                //SUCCESS
                
                let statusCode = (response.response?.statusCode)!
                print(statusCode)
                if let JSON = response.result.value {
                    
                    if JSON.isEmpty {
                        
                        completionHandler(success: true, restoredUser: nil)
                        
                    }
                    else {
                        //WITH DATA
                        //print("Resposta: \(JSON)")
                        let user =   LDTPMessageBuilder.convertStringToDictionary(JSON)
                        
                        completionHandler(success: true, restoredUser: user)
                    }
                }
                
            }
            
        }
        
        
    }

    
    
    
    func isUsernameAvailable(username:String, completionHandler:(success:Bool, available:Bool)->Void) {
    
        let jsonObjectAll: [String: AnyObject] = [ "1COD" : 2
            , "2REQ" : 332, "3ID" :  username]
        
        
        
        Alamofire.request(.POST, serviceAddress, parameters:jsonObjectAll, encoding:.JSON).responseString { response in
            
            if response.result.error != nil {
                //          if let httpError = response.result.error {
                //ERROR
                //let statusCode = httpError.code
//                print(statusCode) // URL response
                
                completionHandler(success: false, available: false)
                
            } else {
                //SUCCESS
                
                //let statusCode = (response.response?.statusCode)!
//                print(statusCode)
                if let JSON = response.result.value {
//                     print("Resposta: \(JSON)")
                    var available: Bool = false
                    if(JSON.lowercaseString == "true"){
                        available = true
                    }
                    
                    completionHandler(success: true, available: available)
                }
                
            }
            
        }

    }
  
    
    
    func getUserToFollowSuggestions(userId:String, completionHandler:(success:Bool, suggestions:NSDictionary?)->Void) {
        
        let jsonObjectAll: [String: AnyObject] = [ "1COD" : 7
            , "2REQ" : -1, "3ID" :  userId ]
        
        
        
        Alamofire.request(.POST, serviceAddress, parameters:jsonObjectAll, encoding:.JSON).responseString { response in
            
            if response.result.error != nil {
                //          if let httpError = response.result.error {
                //ERROR
                //let statusCode = httpError.code
                //                print(statusCode) // URL response
                
                completionHandler(success: false, suggestions: nil)
                
            } else {
                //SUCCESS
                
                //let statusCode = (response.response?.statusCode)!
                //print(statusCode)
                if let JSON = response.result.value {
                    print("Resposta: \(JSON)")
                    let sugDict = LDTPMessageBuilder.convertStringToDictionary(JSON)
                    
                    completionHandler(success: true, suggestions: sugDict)
                }
                
            }
            
        }
        
    }
    

    
    
    //MARK: - LDTP ONLINE SERVICES - WEB SOCKET BASED - AFTER LOGIN
    func initSocket()
    {
        ldtpWSmanager.initSocket()
        
    }
    
    func closeSocket() {
        ldtpWSmanager.closeSocket()
    }
    
    func wantToEnqueue() {
        ldtpWSmanager.wantToEnqueue()
    }
    
    
    func createChatroom(chatroom: [String : AnyObject], completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 6
            , "3USERID" :  loggedUser!.userId! , "4CHATROOM": chatroom]

            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }
    
      

    func enterChatroom(chatroomId: String, completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {

        
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 7,
                "3CHATROOMID": chatroomId]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
        
    }
    
    func leaveChatroom(chatroomId: String, completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 8,
                                             "3CHATROOMID": chatroomId]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
        
    }
    
    func sendMessageOnChatroom(msg:[String : AnyObject], chatroomId: String, completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 9,
                                             "3MSG":msg ,"4CHATROOMID": chatroomId]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
        
    }
    

    
    func getChatroomOfInterest( allowCircular: Bool, completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 10, "3CIRCULAR" : allowCircular ]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }

    
    func getChatroomOnArea(minLat:Double, maxLat:Double, minLng:Double, maxLng: Double, completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            let area:[String: AnyObject] = [ "minLat" : minLat, "maxLat":maxLat,"minLng":minLng,"maxLng":maxLng]
            var msg: [String: AnyObject] = [ "1COD" : 11, "3AREA":area]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }


    
    func saveChatroom(chatroomId: String, completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        
        
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 12,
                                             "3CHATROOMID": chatroomId]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
        
    }

    
    func removeChatroom(chatroomId: String, completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        
        
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 13,
                                             "3CHATROOMID": chatroomId]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
        
    }

    
    func getChatroomsThatMatchesSearchTerm(searchTerm:String , completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 14, "3SEARCHTERM": searchTerm]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }
    

    func getUsersThatMatchesSearchTerm(searchTerm:String , completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 15, "3SEARCHTERM": searchTerm]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }
    
    func getUsersThatParticipatesOnChatroom(chatroomId:String , completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 16, "3CHATROOMID": chatroomId]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }

    func followUser(userId:String , completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 17, "3FOLLOWEEID": userId]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }
    func unfollowUser(userId:String , completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 18, "3FOLLOWEEID": userId]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }
    
    func likeOrUnlikeMsg(msgId:String , chatroomId:String , likeOrUnlike : Int , completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 19, "3MSGID": msgId, "4CHATROOMID" : chatroomId, "5INCDEC": likeOrUnlike]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
        
    }
    
    
    func getChatroomMsgsWhenEnterChat( chatroomId:String ,from: Double,  completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 20,  "3CHATROOMID" : chatroomId, "4SINCE": from]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }

    
    func getUserInfosByIds( userIds: [String] ,  completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 21,  "3USERSIDS" : userIds]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }

    
    func getUserInfoByUsername( username:String,  completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 22,  "3USERNAME" : username]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }

    
    
    func getFollowers( userId:String, completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 23, "3USERID" : userId]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }

    func getFollowees( userId:String, completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 24,  "3USERID" : userId]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }
    

    
    func blockUser(userId:String , completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 25, "3BLOCKEDID": userId]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }
    func unblockUser(userId:String , completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 26, "3BLOCKEDID": userId]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }
    
    func changeUserProfile(userData: NSDictionary, completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            
            var msg: [String: AnyObject] = [ "1COD" : 27, "3UPDATEDUSER": userData]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }
    
    func getBlockeds( userId:String, completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            
            var msg: [String: AnyObject] = [ "1COD" : 28,  "3USERID" : userId]
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }
    
    
    func banAndBlockUserFromChatroom( toBlockUserId:String, chatRoomId:String, completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 29,  "3USERID" : toBlockUserId, "4CHATROOMID" : chatRoomId]
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }

    
    func reportUser(user:NSDictionary , completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 30, "3USER": user]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }


    func reportChatroom(chatroom:NSDictionary , completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 31, "3CHATROOM": chatroom]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }


    
    func getMyChatrooms( completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 32]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }
    
    func getChatrooms( chatroomIds :[String], completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg : [String: AnyObject] = [ "1COD" : 33, "3CHATROOMIDS": chatroomIds]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }
    
    
    
    func registerPushEndpointForUser(completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler ) {
        
        let endpoint :  [String: AnyObject] = ["deviceId" :  NSUserDefaults.standardUserDefaults().stringForKey("deviceId")!,
        "apns_devicetoken" :  NSUserDefaults.standardUserDefaults().stringForKey("deviceToken")! ,
        "sns_arn" : NSUserDefaults.standardUserDefaults().stringForKey("endpointArn")!]
        
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 34 , "3ENDPOINT":endpoint]
        
            ldtpWSmanager.wantToEnqueue()
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
        
    }
    
    
    func logoutFromDevice( completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler ) {
        
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 35 , "3DEVICEID":NSUserDefaults.standardUserDefaults().stringForKey("deviceId")!]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
        
    }
    
    
    func logoutAllDevice( completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler ) {
        
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg: [String: AnyObject] = [ "1COD" : 36 , "3DEVICEID":NSUserDefaults.standardUserDefaults().stringForKey("deviceId")!]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
        
    }

    
    
    func getBlicupUsersWithSocialId( socialIds :[String], socialNetwork: Int, completionHandler : LDTPWebSocketReceiverManager.WebSocketCompletionHandler )
    {
        let loggedUser = UserBS.getLoggedUser()
        
        if loggedUser != nil
        {
            var msg : [String: AnyObject] = [ "1COD" : 37, "3CHATROOMIDS": socialIds, "4SOCIALNET" : socialNetwork ]
            
            ldtpWSmanager.sendMsg(&msg, completionHandler: completionHandler)
        }
    }

}