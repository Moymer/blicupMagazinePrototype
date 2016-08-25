//
//  LoginController.swift
//  Blicup
//
//  Created by Guilherme Braga on 01/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import TwitterKit
import FBSDKLoginKit
import FBSDKShareKit
import SafariServices

typealias CompletionHandlerLoginPublish = (LoginPublishStatus)

enum LoginPublishStatus {
    case Success
    case Error(NSError?)
    case Canceled
    case Declined
}


enum LogoutReason {
    case NormalLogout
    case PerformGeneralLogout
    case ReceivedGeneralLogout
    case Banned
}

class LoginController: NSObject {
    
    // MARK: - Logout
    class func logUserOut(reason: LogoutReason) {
        if reason == .PerformGeneralLogout {
            UserBS.logUserOutFromAllDevicesOnServer({ (success) in
                if success {
                    BlicupAnalytics.sharedInstance.mark_LoggedOut(true)
                    doLocalLogOut(reason)
                }
            })
        }
        else {
            UserBS.logUserOutOnServer({ (success) in
                if success {
                    BlicupAnalytics.sharedInstance.mark_LoggedOut(false)
                    doLocalLogOut(reason)
                }
            })
        }
    }
    
    private class func doLocalLogOut(reason: LogoutReason) {
        guard let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate,
            let window = UIApplication.sharedApplication().keyWindow else {
                return
        }
        
        appDelegate.recreateLocalDataBase()
        
        if let appDomain = NSBundle.mainBundle().bundleIdentifier {
            let deviceTokenString = NSUserDefaults.standardUserDefaults().stringForKey("deviceToken")
            let pressChatTipKey = NSUserDefaults.standardUserDefaults().objectForKey(kPressChatTipKey)
            let pressUserTipKey = NSUserDefaults.standardUserDefaults().objectForKey(kPressUserTipKey)
            let gifTipKey = NSUserDefaults.standardUserDefaults().objectForKey(kGIFTipKey)
            let mentionTipKey = NSUserDefaults.standardUserDefaults().objectForKey(kMentionTipKey)
            let createChatTipKey = NSUserDefaults.standardUserDefaults().objectForKey(kCreateChatTipKey)
            let swipeCoverTipKey = NSUserDefaults.standardUserDefaults().objectForKey(kSwipeCoverTipKey)
            let swipeCoverImagesTipKey = NSUserDefaults.standardUserDefaults().objectForKey(kSwipeCoverImagesTipKey)
            
            // Remove valores especificos de user salvos anteriormente
            NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain)
            
            // Re-gera valores especificos do device necessários
            appDelegate.generateDeviceID()
            NSUserDefaults.standardUserDefaults().setObject(deviceTokenString, forKey: "deviceToken")
            NSUserDefaults.standardUserDefaults().setObject(pressChatTipKey, forKey: kPressChatTipKey)
            NSUserDefaults.standardUserDefaults().setObject(pressUserTipKey, forKey: kPressUserTipKey)
            NSUserDefaults.standardUserDefaults().setObject(gifTipKey, forKey: kGIFTipKey)
            NSUserDefaults.standardUserDefaults().setObject(mentionTipKey, forKey: kMentionTipKey)
            NSUserDefaults.standardUserDefaults().setObject(createChatTipKey, forKey:kCreateChatTipKey)
            NSUserDefaults.standardUserDefaults().setObject(swipeCoverTipKey, forKey: kSwipeCoverTipKey)
            NSUserDefaults.standardUserDefaults().setObject(swipeCoverImagesTipKey, forKey: kSwipeCoverImagesTipKey)
            
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        if LoginController.userLoggedWithFacebook() {
            FBSDKLoginManager().logOut()
        }
        
        BlicupRouter.routeLogin(window)
        
        if reason == .Banned {
            let alert = UIAlertController(title: NSLocalizedString("Banned", comment: "You are banned") , message:NSLocalizedString("Banned_Message", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(
                UIAlertAction(title: NSLocalizedString("See_Terms", comment: "See Terms"), style: UIAlertActionStyle.Default, handler: { (action) in
                    let terms = NSLocalizedString("Blicup_Terms", comment: "Terms link")
                    if let termsUrl = NSURL(string: terms) {
                        if #available(iOS 9.0, *) {
                            let svc = SFSafariViewController(URL: termsUrl)
                            window.rootViewController?.presentViewController(svc, animated: true, completion: nil)
                        } else {
                            // Fallback on earlier versions
                            UIApplication.sharedApplication().openURL(termsUrl)
                        }
                    }
                })
            )
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
            window.rootViewController?.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - Facebook
    class func loginWithFacebook(fromController controller:UIViewController, completionHandler:(profile: NSDictionary?, error:NSError?) -> Void) {
        
        FBSDKLoginManager().logOut()
        let facebookReadPermissions = ["public_profile", "user_friends"]
        
        FBSDKLoginManager().logInWithReadPermissions(facebookReadPermissions, fromViewController: controller) { (result, error) -> Void in
            if (error != nil) {
                completionHandler(profile: nil, error: error)
            }
            else if result.isCancelled {
                completionHandler(profile: nil, error: nil)
            }
            else {
                let token = FBSDKAccessToken.currentAccessToken().tokenString
                AmazonManager.setCredentialsWithFacebook(token)
                
                let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email, is_verified"])
                
                graphRequest.startWithCompletionHandler({ (connection, profileResult, error) -> Void in
                    if error != nil {
                        completionHandler(profile: nil, error: error)
                    }
                    else {
                        let dicProfile = NSMutableDictionary()
                        
                        if let id = profileResult["id"] as? String {
                            dicProfile["facebookId"] = id
                        }
                        
                        var username = ""
                        
                        if let name = profileResult["name"] as? String {
                            username = name
                        }
                        else {
                            if let firstName = profileResult["first_name"] as? String {
                                username = firstName
                            }
                            
                            if let lastName = profileResult["last_name"] as? String {
                                username = username + lastName
                            }
                        }
                        
                        username = username.stringByReplacingOccurrencesOfString(" ", withString: "")
                        dicProfile["username"] = username.lowercaseString
                        
                        
                        if let picture = profileResult["picture"] as? NSDictionary {
                            var photoUrl = picture["data"]!["url"] as! String
                            
                            if (photoUrl.rangeOfString("s200x200") != nil) {
                                photoUrl = ""
                            }
                            
                            dicProfile["photoUrl"] = photoUrl
                        }
                        
                        if let email = profileResult["email"] as? String {
                            dicProfile["email"] = email
                        }
                        
                        if let isVerified = profileResult["is_verified"] as? Bool {
                            dicProfile["isVerified"] = isVerified
                        }
                        
                        completionHandler(profile: dicProfile, error: nil)
                    }
                })
            }
        }
    }
    
    
    // MARK: - Twitter
    class func loginWithTwitter(completionHandler:(profile: NSDictionary?, error: NSError?) -> Void) {
        
        Twitter.sharedInstance().logInWithCompletion { session, error in
            if error != nil && error!.code == TWTRLogInErrorCode.Canceled.rawValue {
                completionHandler(profile: nil, error: nil)
            }
            else if let unwrappedSession = session {
                let token = unwrappedSession.authToken + ";" + unwrappedSession.authTokenSecret
                AmazonManager.setCredentialsWithTwitter(token)
                
                let client = TWTRAPIClient(userID: unwrappedSession.userID)
                
                let statusesShowEndpoint = "https://api.twitter.com/1.1/users/show.json"
                let params = ["user_id": unwrappedSession.userID]
                var clientError : NSError?
                let request = client.URLRequestWithMethod("GET", URL: statusesShowEndpoint, parameters: params, error: &clientError)
                
                client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
                    if connectionError == nil {
                        do {
                            let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                            let dicProfile = NSMutableDictionary()
                            dicProfile["bio"] = json["description"]! as! String
                            dicProfile["twitterId"] = (json["id"]! as! NSNumber).stringValue
                            dicProfile["username"] = (json["screen_name"]! as! String).lowercaseString
                            var validProfileImageURL = json["profile_image_url_https"]! as! String
                            if (validProfileImageURL.rangeOfString("default_profile_images") != nil) {
                                validProfileImageURL = ""
                            } else {
                                validProfileImageURL = validProfileImageURL.stringByReplacingOccurrencesOfString("_normal", withString: "")
                            }
                            dicProfile["photoUrl"] = validProfileImageURL
                            
                            dicProfile["isVerified"] = json["verified"]!
                            completionHandler(profile: dicProfile, error: nil)
                        } catch{
                            completionHandler(profile: nil, error: connectionError)
                        }
                    } else {
                        completionHandler(profile: nil, error: connectionError)
                    }
                }
                
            } else {
                print("Twitter Session error: \(error!.localizedDescription)")
                completionHandler(profile: nil, error: error)
            }
        }
    }
    
    class func userLoggedWithFacebook() -> Bool {
        return FBSDKAccessToken.currentAccessToken() != nil
    }
    
    class func userLoggedWithTwitter() -> Bool {
        return Twitter.sharedInstance().sessionStore.session() != nil
    }
    
    class func getUserIdFromFacebookFriends(completionHandler:(userIds: [String], error: NSError?) -> Void ) {
        
        let params = ["fields": "id"]
        let request = FBSDKGraphRequest(graphPath: "me/friends", parameters: params)
        request.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
            
            if error != nil {
                // let errorMessage = error.localizedDescription
                /* Handle error */
                completionHandler(userIds: [String](), error: error)
            }
            else if let result = result as? NSDictionary, data = result["data"] as? NSArray {
                /*  handle response */
               
                var userIds = [String]()

                for ids in data {
                    
                    if let id = ids["id"] as? String {
                        userIds.append(id)
                    }
                }
                
                completionHandler(userIds: userIds, error: nil)
            }
        }
    }
    
    class func getUserIdFromTwitterFriends(completionHandler:(userIds: [String], error: NSError?) -> Void ) {
        
        if let session = Twitter.sharedInstance().sessionStore.session() {
            
            let client = TWTRAPIClient(userID: session.userID)
            let statusesShowEndpoint = "https://api.twitter.com/1.1/friends/ids.json"
            let params = ["user_id": session.userID]
            var clientError : NSError?
            let request = client.URLRequestWithMethod("GET", URL: statusesShowEndpoint, parameters: params, error: &clientError)
            client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
                
                if connectionError != nil {
                    print("Error: \(connectionError)")
                    completionHandler(userIds: [String](), error: connectionError)
                } else {
                    
                    if let data = data {
                        do {
                            if let jsonDic = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String:AnyObject], friendsIds = jsonDic["ids"] as? NSArray {
                                
                                let userFriendsIds = friendsIds.map { String($0)} 
                                
                                completionHandler(userIds: userFriendsIds , error: connectionError)
                            } else {
                                completionHandler(userIds: [String](), error: connectionError)
                            }
                        }
                        catch let error as NSError {
                            completionHandler(userIds: [String](), error: error)
                            print(error)
                        }
                    }
                }
            }
        }
    }
    
    class func checkFacebookPublishPermissions(fromController controller: UIViewController, completionHandler: CompletionHandlerLoginPublish -> Void) {
        
        if (FBSDKAccessToken.currentAccessToken() == nil || !FBSDKAccessToken.currentAccessToken().hasGranted("publish_actions"))
        {
            FBSDKLoginManager().logInWithPublishPermissions(["publish_actions"], fromViewController: controller) { (result, error) -> Void in
                
                if (error != nil) {
                    
                    completionHandler(LoginPublishStatus.Error(error))
                    
                }
                else if result.isCancelled {
                    
                    completionHandler(LoginPublishStatus.Canceled)
                    return
                    
                } else {
                    
                    guard result.grantedPermissions.contains("publish_actions") else {
                        completionHandler(LoginPublishStatus.Declined)
                        return
                    }
                    
                    
                    if let loggedUser = UserBS.getLoggedUser() {
                        
                        if loggedUser.facebookId == nil {
                            loggedUser.facebookId = result.token.userID
                        }
                        
                        completionHandler(LoginPublishStatus.Success)
                    }
                }
            }
        } else {
            completionHandler(LoginPublishStatus.Success)
        }
        
    }
    
    class func checkTwitterPublishPermissions(completionHandler: CompletionHandlerLoginPublish -> Void) {
        
        if Twitter.sharedInstance().sessionStore.session() == nil {
            
            Twitter.sharedInstance().logInWithCompletion { session, error in
                
                if error != nil && error!.code == TWTRLogInErrorCode.Canceled.rawValue {
                    completionHandler(LoginPublishStatus.Canceled)
                    
                } else if let unwrappedSession = session {
                    
                    let client = TWTRAPIClient(userID: unwrappedSession.userID)
                    client.loadUserWithID(unwrappedSession.userID) { (user, error) -> Void in
                        
                        if error == nil && user != nil {
                            
                            if let loggedUser = UserBS.getLoggedUser() {
                                
                                if loggedUser.twitterId == nil {
                                    loggedUser.twitterId = user?.userID
                                }
                                
                                completionHandler(LoginPublishStatus.Success)
                                
                            }
                        } else {
                            print("Load User With ID error: \(error!.localizedDescription)")
                            completionHandler(LoginPublishStatus.Error(error))
                        }
                    }
                    
                    
                } else {
                    print("Twitter Session error: \(error!.localizedDescription)")
                    completionHandler(LoginPublishStatus.Error(error))
                }
            }
        } else {
            completionHandler(LoginPublishStatus.Success)
        }
    }
    
    
    class func publishCreatedChatOnFacebook(fromController controller: UIViewController, delegate: FBSDKSharingDelegate, chatRoom: ChatRoom, urlFile: String) {
        
        if (FBSDKAccessToken.currentAccessToken() != nil && FBSDKAccessToken.currentAccessToken().hasGranted("publish_actions"))
        {
            let content = LoginController.createFacebookPublishContent(chatRoom, urlFile: urlFile)
            FBSDKShareAPI.shareWithContent(content, delegate: delegate)
            
        } else {
            
            FBSDKLoginManager().logInWithPublishPermissions(["publish_actions"], fromViewController: controller) { (result, error) -> Void in
                
                if error == nil {
                    let content = LoginController.createFacebookPublishContent(chatRoom, urlFile: urlFile)
                    FBSDKShareAPI.shareWithContent(content, delegate: delegate)
                }
            }
        }
    }
    
    class func createFacebookPublishContent(chatRoom: ChatRoom, urlFile: String) -> FBSDKShareLinkContent {
        
        let content : FBSDKShareLinkContent = FBSDKShareLinkContent()
        content.contentURL = NSURL(string: urlFile)
        content.contentTitle = chatRoom.name
        content.contentDescription = NSLocalizedString("publish_Description", comment: "") + (chatRoom.tagList!).convertToBlicupHashtagString()
        if let photo = chatRoom.photoList?.firstObject as? Photo {
            content.imageURL = NSURL(string: photo.photoUrl!)
        }
        
        return content
    }
    
    class func publishCreatedChatOnTwitter(chatRoom chatRoom: ChatRoom, urlFile: String) {
        
        Twitter.sharedInstance().logInWithCompletion { session, error in
            
            if session != nil {
                
                let client = TWTRAPIClient(userID: session?.userID)
                let statusesShowEndpoint = "https://api.twitter.com/1.1/statuses/update.json"
                let params = ["status": urlFile]
                var clientError : NSError?
                let request = client.URLRequestWithMethod("POST", URL: statusesShowEndpoint, parameters: params, error: &clientError)
                client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
                    
                    if connectionError != nil {
                        print("Error: \(connectionError)")
                    } else {
                        print("Tweet sent")
                    }
                }
            } else { // report error
            }
        }
    }
    
}

