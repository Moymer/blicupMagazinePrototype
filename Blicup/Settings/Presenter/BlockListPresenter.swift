//
//  BlockListPresenter.swift
//  Blicup
//
//  Created by Moymer on 22/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class BlockListPresenter: NSObject {
    
    private var blockList = [String]()
    private var unblocked = [String]()
    
    override init() {
        super.init()
        
        if let list = UserBS.getLoggedUser()?.userInfo?.blockedList as? [String] {
            blockList = list
        }
    }
    
    func updateUsersBlocked(completionHandler:(success:Bool)->Void) {
        guard let userId = UserBS.getLoggedUser()?.userId else {
            return
        }
        
        UserBS.getUsersBlockedByUser(userId) { (success) in
            completionHandler(success: success)
        }
    }
    
    func numberOfBlockedUsers()->Int {
        return blockList.count
    }
    
    func userPhotoUrl(index:Int)->NSURL? {
        guard index >= 0 && index < blockList.count else {
            return nil
        }
        
        let userId = blockList[index]
        guard let userPhotoString = User.userWithId(userId)?.photoUrl else {
            return nil
        }
        
        return NSURL(string: userPhotoString)
    }
    
    func username(index:Int)->String? {
        guard index >= 0 && index < blockList.count else {
            return nil
        }
        
        let userId = blockList[index]
        if let username = User.userWithId(userId)?.username {
            return "@"+username
        }
        
        return "Loading..."
    }
    
    func isBlocked(index:Int)->Bool {
        guard index >= 0 && index < blockList.count else {
            return false
        }
        
        let userId = blockList[index]
        return !(unblocked.contains(userId))
    }
    
    func blockUnblockUser(index:Int) {
        guard index >= 0 && index < blockList.count else {
            return
        }
        
        let userId = blockList[index]
        
        if let index = unblocked.indexOf(userId) {
            unblocked.removeAtIndex(index)
            UserBS.blockUser(userId, completionHandler: nil)
        }
        else {
            unblocked.append(userId)
            UserBS.unblockUser(userId, completionHandler: nil)
        }
    }
    
    func blockDialogTitleForIndex(index:Int)->String {
        var title = NSLocalizedString("Block", comment: "Block")
        
        if let username =  self.username(index) {
            title = title + " " + username
        }
        else {
            title = title + " " + NSLocalizedString("BlockUserPlaceholder", comment: "this user")
        }
        
        return title
    }
    
    func blockDialogMessageForIndex(index:Int)->String {
        var message = NSLocalizedString("BlockMessage", comment: "Block dialog message")
        
        if let username = self.username(index) {
            message = username + message + username
        }
        else {
            let placeholder = NSLocalizedString("BlockUserPlaceholder", comment: "this user")
            message = placeholder + message + placeholder
        }
        
        return message
    }
}
