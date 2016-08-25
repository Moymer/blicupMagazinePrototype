//
//  BlicupAnalytics.swift
//  Blicup
//
//  Created by Guilherme Braga on 14/07/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import Crashlytics

class BlicupAnalytics: NSObject {

    static let sharedInstance = BlicupAnalytics()
    
    private var sessionMetrics :SessionMetrics = SessionMetrics()
    
    
    
    private func logEvent(eventName event: String) {
        
       // FBSDKAppEvents.logEvent(event)
       // Answers.logCustomEventWithName(event, customAttributes: [:])
        
    }
    
    private func logEvent(eventName event: String, parameters: [String : AnyObject]) {
        
        //FBSDKAppEvents.logEvent(event, parameters: parameters)
        //Answers.logCustomEventWithName(event, customAttributes: parameters )
    }
    
    
     //MARK: Event Metrics
   
    //MARK: Entrar na App
    
    func mark_EnterApp( fromPush: Bool, fromDeepLink: Bool)
    {
        let user = UserBS.getLoggedUser()
        var status = "not Logged"
        
        if user?.facebookId != nil && user?.twitterId != nil {
            status = "Facebook Twitter"
        }
        else if user?.facebookId != nil {
            status = "Facebook"
        }
        else if user?.twitterId != nil {
            status = "Twitter"
        }
        
        let parameters = ["statusLogin" : status , "from": fromPush ? "push" :(fromDeepLink ? "deeplink" : "any")  ]
    
        logEvent(eventName: "Entered App", parameters: parameters)
    }
    
    
    func mark_Signup( fromFacebook: Bool)
    {

        let parameters = ["signupWith" : fromFacebook ? "Facebook" : "Twitter" ]
        
        logEvent(eventName: "Signed up", parameters: parameters)
    }
    
    func mark_Login( fromFacebook: Bool)
    {
        
        let parameters = ["loginWith" : fromFacebook ? "Facebook" : "Twitter" ]
        
        logEvent(eventName: "Logged in", parameters: parameters)
    }
    
    //MARK: Criação de chats
    
    
    func mark_CreatedChat( shareFacebook: Bool, sharedTwitter : Bool, totalTags : Int , totalPhotos : Int)
    {
        var sharing : String = ""
        if shareFacebook {
            sharing = "Facebook"
        }
        if sharedTwitter {
            sharing = sharing + "Twitter"
        }
        
        if sharing == "" {
            sharing = "None"
        }
        let parameters = ["sharing" : sharing , "amountOfTags" : totalTags , "amountOfPhotos" : totalPhotos ]
        
        logEvent(eventName: "Created Chat", parameters: parameters as! [String : AnyObject] )
    }
    
     //MARK: Interagir com Chats
    func mark_SearchedChat( searchedTerm: String)
    {
        
        let parameters = ["searchedTerm" : searchedTerm ]
        
        logEvent(eventName: "Searched Chat", parameters: parameters )
    }
   
    func mark_SearchedUser( searchedTerm: String)
    {
        
        let parameters = ["searchedUser" : searchedTerm ]
        
        logEvent(eventName: "Searched User", parameters: parameters )
    }

    func mark_SentMsg( msgType: Int, msgSize: Int, withMention: Bool)
    {
        
        let parameters = ["msgType": (msgType == ChatRoomMessage.MessageType.TEXT_MSG.rawValue) ? "Text":"Gif",  "msgSize" : msgSize , "hadMention" : withMention]
        
        logEvent(eventName: "Sent Msg", parameters: parameters as! [String : AnyObject])
    }

    
    func mark_SavedChat()
    {
        logEvent(eventName: "Saved Chat" )
    }
    
    func mark_LeftChat()
    {
        logEvent(eventName: "Left Chat" )
    }

     //MARK: Interagir com outros usuários
    
    func mark_FollowedUser()
    {
        logEvent(eventName: "Followed User" )
    }

    func mark_UnfollowedUser()
    {
        logEvent(eventName: "Unfollowed User " )
    }
   
    
    func mark_BlockedUser()
    {
        logEvent(eventName: "Blocked User" )
    }
    
    func mark_UnblockedUser()
    {
        logEvent(eventName: "Unblocked User" )
    }
    
    func mark_BanAndBlockedUser()
    {
        logEvent(eventName: "Ban and Blocked User" )
    }
   
    
     //MARK: Report
    func mark_ReportedUser()
    {
        logEvent(eventName: "Reported User" )
    }
    func mark_ReportedChat()
    {
        logEvent(eventName: "Reported Chat" )
    }
    
    
    //MARK: Settings
    func mark_ChangedProfile()
    {
        logEvent(eventName: "Changed Profile" )
    }
    func mark_ChangedTags()
    {
        logEvent(eventName: "Changed Tags" )
    }
    
    func mark_ToldFriend(how : String)
    {
        let parameters = ["how" : how ]
        
        logEvent(eventName: "Told a Friend", parameters: parameters )
    }
    
    func mark_ContactedBlicup()
    {
        logEvent(eventName: "Contacted Blicup" )
    }
    
    
    func mark_LoggedOut(isGeneral : Bool)
    {
        let parameters = ["scope" : isGeneral ? "General" : "Device" ]
        logEvent(eventName: "Logged out" , parameters: parameters )
    }

    //MARK: Entradas de tela
    func mark_EnteredScreenChatList()
    {
        logEvent(eventName: "EnteredScreen ChatList" )
    }
    func mark_EnteredScreenMyChats()
    {
        logEvent(eventName: "EnteredScreen MyChats" )
    }
    func mark_EnteredScreenChatMap()
    {
        logEvent(eventName: "EnteredScreen ChatMap" )
    }
    
    func mark_EnteredScreenChatListFromMap()
    {
        logEvent(eventName: "EnteredScreen ChatListFromMap" )
    }

    func mark_EnteredScreenSearch()
    {
        logEvent(eventName: "EnteredScreen Search" )
    }

    
    func mark_EnteredScreenSettings()
    {
        logEvent(eventName: "EnteredScreen Settings" )
    }
    
    func mark_EnteredScreenChatCover()
    {
        logEvent(eventName: "EnteredScreen ChatCover" )
    }
    
    func mark_EnteredScreenChatRoom()
    {
        logEvent(eventName: "EnteredScreen ChatRoom" )
    }
    
    func mark_EnteredScreenUserProfile()
    {
        logEvent(eventName: "EnteredScreen UserProfile" )
    }
   
    func mark_EnteredScreenMyProfile()
    {
        logEvent(eventName: "EnteredScreen MyProfile" )
    }

    func mark_EnteredScreenMyTags()
    {
        logEvent(eventName: "EnteredScreen MyTags" )
    }

    func mark_EnteredScreenChatMembers()
    {
        logEvent(eventName: "EnteredScreen ChatMembers" )
    }
    
    func mark_EnteredScreenNotification()
    {
        logEvent(eventName: "EnteredScreen Notification" )
    }
    
    func mark_EnteredScreenTermsOfUse()
    {
        logEvent(eventName: "EnteredScreen TermsOfUse" )
    }
    
    func mark_EnteredScreenPrivacyPolicy()
    {
        logEvent(eventName: "EnteredScreen PrivacyPolicy" )
    }

    
    
    //MARK: Session Metrics
    func initSession()
    {
        sessionMetrics.initSession()
    }
    
    func endSession()
    {
        
        logEndSessionEvents()
        sessionMetrics.endSession()
    }
    
    
    func seenChatFromMain(chatroomId :String)
    {
        sessionMetrics.seenChats_fromMain[chatroomId] = chatroomId
    }
    func seenChatFromMap(chatroomId :String)
    {
        sessionMetrics.seenChats_fromMap[chatroomId] = chatroomId
    }
    
    func seenChatFromSearch(chatroomId :String)
    {
        sessionMetrics.seenChats_fromSearch[chatroomId] = chatroomId
    }
    
    func seenChatCover(chatroomId :String)
    {
        sessionMetrics.seenChats_cover[chatroomId] = chatroomId
    }
    
    func seenChatRoom(chatroomId :String)
    {
        sessionMetrics.seenChats_room[chatroomId] = chatroomId
    }
    
    func sentMsg(chatroomId : String)
    {
        sessionMetrics.msgSentCount =  sessionMetrics.msgSentCount + 1
        sessionMetrics.msgSentChats[chatroomId] = chatroomId
    }
    
    private func logEndSessionEvents()
    {
        logSentMsg()
        logSeenChatsFromMain()
        logSeenChatsFromMap()
        logSeenChatsFromSearch()
        logSeenChatsCover()
        logSeenChatsRoom()
    }
    
    private func logSentMsg()
    {
        let msgSentChatsSize = sessionMetrics.msgSentChats.count
         let parameters = ["inHowManyChats" : msgSentChatsSize ]
        
        if sessionMetrics.msgSentCount == 0 {
            logEvent(eventName: "Session MsgSent 0", parameters: parameters)
        }else if sessionMetrics.msgSentCount > 0 &&  sessionMetrics.msgSentCount <= 5 {
            logEvent(eventName: "Session MsgSent 1_5", parameters: parameters)
        }else if sessionMetrics.msgSentCount > 5 &&  sessionMetrics.msgSentCount <= 20 {
            logEvent(eventName: "Session MsgSent 6_20", parameters: parameters)
        }else if sessionMetrics.msgSentCount > 20 &&  sessionMetrics.msgSentCount <= 50 {
            logEvent(eventName: "Session MsgSent 21_50", parameters: parameters)
        }else if sessionMetrics.msgSentCount > 50  {
            logEvent(eventName: "Session MsgSent +50", parameters: parameters)
        }
    }

    private func logSeenChatsFromMain()
    {
        let seenChats = sessionMetrics.seenChats_fromMain.count
         if seenChats > 0  && seenChats <= 20 {
            logEvent(eventName: "Session SeenChatsFromMain 1_20")
        }else if seenChats > 20  && seenChats <= 40 {
            logEvent(eventName: "Session SeenChatsFromMain 21_40")
        }else if seenChats > 40  && seenChats <= 60 {
            logEvent(eventName: "Session SeenChatsFromMain 41_60")
         }else if seenChats > 60 {
            logEvent(eventName: "Session SeenChatsFromMain +60")
        }
    }
    
    private func logSeenChatsFromMap()
    {
        let seenChats = sessionMetrics.seenChats_fromMap.count
        if seenChats > 0  && seenChats <= 20 {
            logEvent(eventName: "Session SeenChatsFromMap 1_20")
        }else if seenChats > 20  && seenChats <= 40 {
            logEvent(eventName: "Session SeenChatsFromMap 21_40")
        }else if seenChats > 40  && seenChats <= 60 {
            logEvent(eventName: "Session SeenChatsFromMap 41_60")
        }else if seenChats > 60 {
            logEvent(eventName: "Session SeenChatsFromMap +60")
        }
    }
    private func logSeenChatsFromSearch()
    {
        let seenChats = sessionMetrics.seenChats_fromSearch.count
        if seenChats > 0  && seenChats <= 20 {
            logEvent(eventName: "Session SeenChatsFromSearch 1_20")
        }else if seenChats > 20  && seenChats <= 40 {
            logEvent(eventName: "Session SeenChatsFromSearch 21_40")
        }else if seenChats > 40  && seenChats <= 60 {
            logEvent(eventName: "Session SeenChatsFromSearch 41_60")
        }else if seenChats > 60 {
            logEvent(eventName: "Session SeenChatsFromSearch +60")
        }
    }
    
    private func logSeenChatsCover()
    {
        let seenChats = sessionMetrics.seenChats_cover.count
        if seenChats == 0  {
            logEvent(eventName: "Session SeenChatsCover 0")
        }else if seenChats > 0  && seenChats <= 5 {
            logEvent(eventName: "Session SeenChatsCover 1_5")
        }else if seenChats > 5  && seenChats <= 10 {
            logEvent(eventName: "Session SeenChatsCover 6_10")
        }else if seenChats > 10  && seenChats <= 20 {
            logEvent(eventName: "Session SeenChatsCover 11_20")
        }else if seenChats > 20 {
            logEvent(eventName: "Session SeenChatsCover +20")
        }
    }

    private func logSeenChatsRoom()
    {
        let seenChats = sessionMetrics.seenChats_room.count
        if seenChats == 0  {
            logEvent(eventName: "Session SeenChatsRoom 0")
        }else if seenChats > 0  && seenChats <= 5 {
            logEvent(eventName: "Session SeenChatsRoom 1_5")
        }else if seenChats > 5  && seenChats <= 10 {
            logEvent(eventName: "Session SeenChatsRoom 6_10")
        }else if seenChats > 10  && seenChats <= 20 {
            logEvent(eventName: "Session SeenChatsRoom 11_20")
        }else if seenChats > 20 {
            logEvent(eventName: "Session SeenChatsRoom +20")
        }
    }

    private class SessionMetrics: NSObject {
        
        var  msgSentCount : Int = 0
        var  msgSentChats : [String:String]  = [:]
        var  seenChats_fromMain : [String:String]  = [:]
        var  seenChats_fromMap : [String:String]  = [:]
        var  seenChats_fromSearch : [String:String]  = [:]
        var  seenChats_cover : [String:String]  = [:]
        var  seenChats_room : [String:String]  = [:]


        func clear()
        {
            msgSentCount  = 0
            msgSentChats = [:]
            seenChats_fromMain = [:]
            seenChats_fromMap  = [:]
            seenChats_fromSearch = [:]
            seenChats_cover = [:]
            seenChats_room   = [:]

        }
        
        func initSession()
        {
            clear()
            
        }
        
        func endSession()
        {
            clear()
        }
        
       
        
    }
}



