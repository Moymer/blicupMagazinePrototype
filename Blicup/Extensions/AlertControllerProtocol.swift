//
//  AlertControllerProtocol.swift
//  Blicup
//
//  Created by Guilherme Braga on 04/07/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import SafariServices

protocol AlertControllerProtocol {}

extension AlertControllerProtocol where Self: UIViewController {
    
    func showAlert(title title: String, message: String) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK", style: .Cancel) { _ in }
        alertController.addAction(okAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func showAlert(title title: String, message: String, withActions actions: [UIAlertAction], style: UIAlertControllerStyle) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)

        for action in actions {
            alertController.addAction(action)
        }
    
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func showAlertChatsOverOrUserRemoved(chatRoom: ChatRoom) {
        guard let rootViewController = self.navigationController?.viewControllers.first else {
            return
        }
        
        guard chatRoom.state == ChatRoom.ChatRoomState.Dead.rawValue
            || chatRoom.state == ChatRoom.ChatRoomState.Removed.rawValue
            || chatRoom.state == ChatRoom.ChatRoomState.Banned.rawValue else {
            return
        }
        
        var title = ""
        var message = ""
        if chatRoom.state == ChatRoom.ChatRoomState.Dead.rawValue {
            title = NSLocalizedString("DeadChatAlertTitle", comment: "The chat is over")
            message = NSLocalizedString("DeadChatAlertMessage", comment: "")
        }
        else if chatRoom.state == ChatRoom.ChatRoomState.Removed.rawValue {
            title = NSLocalizedString("RemovedChatAlertTitle", comment: "You were removed")
            message = NSLocalizedString("RemovedChatAlertMessage", comment: "Removed dialog message")
        }
        else if chatRoom.whoCreated?.userId == UserBS.getLoggedUser()?.userId {
            title = NSLocalizedString("BannedChatOwnerTitle", comment: "Your chat was banned")
            message = NSLocalizedString("BannedChatOwnerMessage", comment: "Your chat was removed message")
        }
        else {
            title = NSLocalizedString("BannedChatTitle", comment: "A chat was banned")
            message = NSLocalizedString("BannedChatMessage", comment: "A chat was banned message")
        }

        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK", style: .Cancel) { _ in
            ChatRoom.deleteChatAndAssociatedData(chatRoom)
            alertController.dismissViewControllerAnimated(true, completion: nil)
        }
        
        alertController.addAction(okAction)
        
        // Possibilita a abertura dos termos de uso
        if chatRoom.state == ChatRoom.ChatRoomState.Banned.rawValue && chatRoom.whoCreated?.userId == UserBS.getLoggedUser()?.userId {
            let terms = NSLocalizedString("Blicup_Terms", comment: "Terms link")
            if let termsUrl = NSURL(string: terms) {
                alertController.addAction(
                    UIAlertAction(title: NSLocalizedString("See_Terms", comment: "See Terms"), style: UIAlertActionStyle.Default, handler: { (action) in
                        ChatRoom.deleteChatAndAssociatedData(chatRoom) // Deleta chatroom assim como OK
                        
                        if #available(iOS 9.0, *) {
                            let svc = SFSafariViewController(URL: termsUrl)
                            rootViewController.presentViewController(svc, animated: true, completion: nil)
                        } else {
                            // Fallback on earlier versions
                            UIApplication.sharedApplication().openURL(termsUrl)
                        }
                    })
                )
            }
        }
        
        self.navigationController?.popToRootViewControllerAnimated(true)
        
        rootViewController.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func showAlertWithSettings(title title: String, message: String) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK", style: .Cancel) { _ in }
        alertController.addAction(okAction)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .Default) { _ in
            guard let url = NSURL(string: UIApplicationOpenSettingsURLString) else { return }
            UIApplication.sharedApplication().openURL(url)
        }
        alertController.addAction(settingsAction)
        
        view?.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
    }
}