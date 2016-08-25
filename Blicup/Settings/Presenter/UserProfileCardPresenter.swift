//
//  UserProfileCardPresenter.swift
//  Blicup
//
//  Created by Guilherme Braga on 18/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class UserProfileCardPresenter: FollowUnfollowPresenter {
    
    var user: User
    var hasShownTheList = false
    
    var currentIndex: Int = 0
    var nextIndex: Int = 0
    
    init(user: User) {
        self.user = user
    }
    
    func updateUserInfoData(completion:((success:Bool)->Void)?) {
        guard let userId = self.user.userId else {
            completion?(success:false)
            return
        }
        
        UserBS.updateUsersInfo([userId]) { (success) in
            if let updatedUser = User.userWithId(userId) {
                self.user = updatedUser
            }
            completion?(success:success)

        }
    }
    
    func userId() -> String? {
        return self.user.userId
    }
    
    func username() -> String? {
        
        var username = self.user.username
        if username != nil && username!.length > 0 {
            username = "@" + username!
        }
        
        return username
    }
    
    func bio() -> String? {
        return self.user.bio
    }
    
    func numberOfLikes() -> Int {
        guard let userInfo = self.user.userInfo else {
            return 0
        }
        
        return userInfo.likeCount!.integerValue
    }
    
    func photoUrl() -> NSURL? {
        
        guard let photoUrl = self.user.photoUrl else {
            return nil
        }
        
        return NSURL(string: photoUrl)
    }
    
    func followersText()-> String {
        guard let followersCount = self.user.userInfo?.followerCount else {
            return "-"
        }
        
        return followersCount.stringValue
    }
    
    func followeeText()-> String {
        guard let followeeCount = self.user.userInfo?.followeeCount else {
            return "-"
        }
        
        return followeeCount.stringValue
    }
    
    func heightForUserBio(constrainedToWidth width: CGFloat) -> CGFloat {
        
        guard let bio = bio() else {
            return 0
        }
        
        let padding: CGFloat = 8 + 8 // 8 left and 8 right
        let font = UIFont(name: "SFUIText-Regular", size: 15.0)
        let mockLabel = UILabel()
        mockLabel.numberOfLines = 0
        mockLabel.textAlignment = .Center
        mockLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        mockLabel.font = font
        mockLabel.text = bio
        let maxSize = CGSizeMake(width - padding, CGFloat.max)
        let height = mockLabel.sizeThatFits(maxSize).height
        return height
    }

    func isVerifiedUser() -> Bool {
        guard let isVerified = self.user.isVerified else {
            return false
        }
        
        return isVerified.boolValue
    }
    
    
    // MARK: - (Un)Block
    func isCurrentUserBlocked() -> Bool {
        if let userId = self.userId() {
            return isUserBlocked(userId)
        }
        
        return false
    }
    
    func blockBtnTitle()->String? {
        guard let userId = self.user.userId where userId != UserBS.getLoggedUser()?.userId else {
            return nil
        }
        
        if let loggedUserBlockList = UserBS.getLoggedUser()?.userInfo?.blockedList as? [String] where loggedUserBlockList.contains(userId) {
            return NSLocalizedString("Unblock", comment: "")
        }
        
        return NSLocalizedString("Block", comment: "")
    }
    
    func blockDialogTitle()->String {
        var title = NSLocalizedString("Block", comment: "Block")
        
        if let username =  self.username() {
            title = title + " " + username
        }
        else {
            title = title + " " + NSLocalizedString("BlockUserPlaceholder", comment: "this user")
        }
        
        return title
    }
    
    func blockDialogMessage()->String {
        var message = NSLocalizedString("BlockMessage", comment: "Block dialog message")
        
        if let username = self.username() {
            message = username + message + username
        }
        else {
            let placeholder = NSLocalizedString("BlockUserPlaceholder", comment: "this user")
            message = placeholder + message + placeholder
        }
        
        return message
    }
    
    func blockUnblockUser(completionHandler:(success:Bool)->Void) {
        guard let userId = self.user.userId else {
            return
        }
        
        if let loggedUserBlockList = UserBS.getLoggedUser()?.userInfo?.blockedList as? [String] where loggedUserBlockList.contains(userId) {
            UserBS.unblockUser(userId, completionHandler: { (success) in
                completionHandler(success: success)
            })
        }
        else {
            UserBS.blockUser(userId, completionHandler: { (success) in
                completionHandler(success: success)
            })
        }
    }
    
    // MARK: Report User
    func reportUser(completionHandler:(success: Bool) -> Void) {
        
        UserBS.reportUser(self.user) { (success) in
            completionHandler(success: success)
        }
    }
    
    
    func reportUserDialogTitle() -> String {
        
        let title = NSLocalizedString("ReportUserDialogTitle", comment: "Report user")
        
        return title
    }
    
    func reportUserDialogMessage() -> String {
        
        var message = NSLocalizedString("ReportUserMessage", comment: "Report dialog message")
        let report = NSLocalizedString("Report", comment: "Report")
        
        if let username = self.username() {
            message = "\(report) \(username) \(message)"
        }
        else {
            let placeholder = NSLocalizedString("ReportUserPlaceholder", comment: "this user")
            message = "\(report) \(placeholder) \(message)"
        }
        
        return message
    }
    
    func thanksForReportingDialogTitle() -> String {
        
        let title = NSLocalizedString("ThanksForReportingTitle", comment: "Thank your for reporting")
        
        return title
    }
    
    func thanksForReportingDialogMessage() -> String {
        
        let message = NSLocalizedString("ThanksForReportingMessage", comment: "Thank you for reporting dialog message")
        
        return message
        
    }
}
