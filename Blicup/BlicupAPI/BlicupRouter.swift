//
//  BlicupRouter.swift
//  Blicup
//
//  Created by Moymer on 07/07/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import TwitterKit

class BlicupRouter: NSObject {
    
    enum tabBarItens: Int {
        case LIST, MAP, MYCHATS, SETTINGS
    }
    
    class func routeLogin(window:UIWindow?) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        var rootViewController:UIViewController?
        
        
        if let loggedUser = UserBS.getLoggedUser() {
            // User is already logged in, do work such as go to next view controller.
            
            if UserBS.hasCompletedLogin() == false {
                let signupStoryboard = UIStoryboard(name: "Signup", bundle: nil)
                rootViewController = signupStoryboard.instantiateViewControllerWithIdentifier("NavInterestListController")
            }
            else if let tabBarController = mainStoryboard.instantiateViewControllerWithIdentifier("BlicupTabBarControllerID") as? UITabBarController {
                LDTProtocolImpl.sharedInstance.initSocket()
                
                // Configurando Credenciais Amazon S3
                if let currentAccessToken = FBSDKAccessToken.currentAccessToken() {
                    if let fbToken = currentAccessToken.tokenString {
                        AmazonManager.setCredentialsWithFacebook(fbToken)
                    }
                }
                else if let unwrappedSession = Twitter.sharedInstance().sessionStore.session() {
                    let twitterToken = unwrappedSession.authToken + ";" + unwrappedSession.authTokenSecret
                    AmazonManager.setCredentialsWithTwitter(twitterToken)
                }
                
                AmazonManager.registerAmazonSNSEndpointAfterLogin()
                
                //Update userInfo
                UserBS.updateUsersInfo([loggedUser.userId!], completionHandler: nil)
                
                BlicupRouter.configTabBarController(tabBarController)
                rootViewController = tabBarController
            }
        }
        else {
            // LoginViewController
            rootViewController = mainStoryboard.instantiateInitialViewController()
        }
        
        if window != nil && rootViewController != nil {
            UIView.transitionWithView(window!, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                window?.setRootViewController(rootViewController!)
                }, completion: nil)
        }
    }
    
    class func routeTest(window:UIWindow?)
    {
        let storyboard = UIStoryboard(name: "Magazine", bundle: nil)
        let rootViewController = storyboard.instantiateViewControllerWithIdentifier("ArticleCreationController")
//            storyboard.instantiateViewControllerWithIdentifier("initNavController")
        
        if window != nil  {
            UIView.transitionWithView(window!, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                window?.setRootViewController(rootViewController)
                }, completion: nil)
        }

    }
    
    private class func configTabBarController(tabBarController:UITabBarController) {
        guard let chatViewController = UIStoryboard(name: "Chat", bundle: nil).instantiateInitialViewController(),
            let mapViewController = UIStoryboard(name: "Map", bundle: nil).instantiateInitialViewController(),
            let settingsViewController = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController(),
            let myChatsViewController = UIStoryboard(name: "MyChats", bundle: nil).instantiateInitialViewController() as? ChatRoomListNavigationController else {
                return
        }
        
        UITabBar.appearance().shadowImage = UIImage()
        
        let chatTabBarItem = UITabBarItem(title: nil, image: UIImage(named: "ic_tab_chat")?.imageWithRenderingMode(.AlwaysOriginal), selectedImage: UIImage(named: "ic_tab_chat_selected")?.imageWithRenderingMode(.AlwaysOriginal))
        chatTabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
        chatViewController.tabBarItem = chatTabBarItem
        
        let mapTabBarItem = UITabBarItem(title: nil, image: UIImage(named: "ic_tab_world")?.imageWithRenderingMode(.AlwaysOriginal), selectedImage: UIImage(named: "ic_tab_world_selected")?.imageWithRenderingMode(.AlwaysOriginal))
        mapTabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
        mapViewController.tabBarItem = mapTabBarItem
        
        let myChatsTabBarItem = UITabBarItem(title: nil, image: UIImage(named: "ic_tab_myChats")?.imageWithRenderingMode(.AlwaysOriginal), selectedImage: UIImage(named: "ic_tab_myChats_selected")?.imageWithRenderingMode(.AlwaysOriginal))
        myChatsTabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
        myChatsViewController.tabBarItem = myChatsTabBarItem
        setBadgeInTabBarItem(myChatsTabBarItem)
        
        // Force MyChats Load
        if let myChatsScreen = myChatsViewController.viewControllers.first as? MyChatsViewController {
            let _ = myChatsScreen.view
        }
        
        
        let settingsTabBarItem = UITabBarItem(title: nil, image: UIImage(named: "ic_tab_settings")?.imageWithRenderingMode(.AlwaysOriginal), selectedImage: UIImage(named: "ic_tab_settings_selected")?.imageWithRenderingMode(.AlwaysOriginal))
        settingsTabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
        settingsViewController.tabBarItem = settingsTabBarItem
        
        tabBarController.setViewControllers([chatViewController, mapViewController, myChatsViewController, settingsViewController], animated: false)
        tabBarController.tabBar.backgroundImage = UIImage(color: UIColor.whiteColor().colorWithAlphaComponent(0.95))
    }
    
    class func routeChatRoomBack(chatRoomController: ChatRoomViewController, chatRoomId:String) {
        guard let chatRoom = ChatRoom.chatRoomWithId(chatRoomId),
            let navigationControllerRoot = chatRoomController.navigationController?.viewControllers.first else {
                chatRoomController.navigationController?.popViewControllerAnimated(false)
                return
        }
        
        if chatRoom.saved == true && (navigationControllerRoot is ChatRoomsListViewController) {
            
            chatRoomController.navigationController?.popToRootViewControllerAnimated(false)
            
            guard let tabBarController = UIApplication.sharedApplication().keyWindow?.rootViewController as? UITabBarController,
                let myChatsNavController = tabBarController.viewControllers?[tabBarItens.MYCHATS.rawValue] as? ChatRoomListNavigationController,
                let pageViewController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("CoverController") as? ChatRoomsListHorizontalPageViewController else {
                    
                    chatRoomController.navigationController?.popViewControllerAnimated(false)
                    return
            }
            
            myChatsNavController.popToRootViewControllerAnimated(false)
            
            let presenter = CoverChatRoomsListPresenter(withMyChats: true)
            presenter.currentChatId = chatRoomId
            pageViewController.initCover(coverPresenter: presenter)
            myChatsNavController.pushViewController(pageViewController, animated: false)
            
            tabBarController.selectedIndex = tabBarItens.MYCHATS.rawValue
            
            
        }
        else {
            chatRoomController.navigationController?.popViewControllerAnimated(false)
        }
    }
    
    
    class func routeCreateChatRoomBackToChat(createChatModalController: CreateChatRoomViewController, chatRoomId:String) {
        guard let chatRoom = ChatRoom.chatRoomWithId(chatRoomId),
            let parentController = createChatModalController.parentView else {
                createChatModalController.closePressed(createChatModalController.btnDismissView)
                return
        }
        
        if chatRoom.saved == true {
            guard let tabBarController = UIApplication.sharedApplication().keyWindow?.rootViewController as? UITabBarController,
                let myChatsNavController = tabBarController.viewControllers?[tabBarItens.MYCHATS.rawValue] as? ChatRoomListNavigationController,
                let pageViewController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("CoverController") as? ChatRoomsListHorizontalPageViewController,
                let chatViewController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("ChatRoomViewController") as? ChatRoomViewController else {
                    
                    createChatModalController.closePressed(createChatModalController.btnDismissView)
                    return
            }
            
            let transitionView = createChatModalController.view.snapshotViewAfterScreenUpdates(false)
            createChatModalController.view.window?.addSubview(transitionView)
            
            createChatModalController.resignFirstResponder()
            createChatModalController.dismissViewControllerAnimated(false, completion: {
                parentController.navigationController?.popToRootViewControllerAnimated(false)
                myChatsNavController.popToRootViewControllerAnimated(false)
                
                let presenter = CoverChatRoomsListPresenter(withMyChats: true)
                presenter.currentChatId = chatRoomId
                pageViewController.initCover(coverPresenter: presenter)
                let _ = pageViewController.view //force loading of cover controller view
                
                chatViewController.setChatRoom(chatRoom)
                
                myChatsNavController.viewControllers.appendContentsOf([pageViewController, chatViewController])
                tabBarController.tabBar.hidden = true
                tabBarController.selectedIndex = tabBarItens.MYCHATS.rawValue
                
                UIView.animateWithDuration(0.5, animations: {
                    transitionView.alpha = 0
                    }, completion: { (_) in
                        transitionView.removeFromSuperview()
                })
            })
        }
        else {
            createChatModalController.closePressed(createChatModalController.btnDismissView)
        }
    }
    
    
    class func routeBlicupToChatRoom(chatRoomId: String, checkSavedStatus:Bool) {
        guard let window = UIApplication.sharedApplication().windows.first,
            let tabBarController = window.rootViewController as? UITabBarController,
            let selectedController = tabBarController.selectedViewController as? UINavigationController else {
                return
        }
        
        LDTProtocolImpl.sharedInstance.wantToEnqueue() // Enqueue requisitions even if the socket isn't openning
        selectedController.popToRootViewControllerAnimated(false)
        
        if let chatRoom = ChatRoom.chatRoomWithId(chatRoomId) where (chatRoom.saved == true || chatRoom.grade != nil) {
            if selectedController.presentedViewController != nil {
                selectedController.dismissViewControllerAnimated(false, completion: {
                    BlicupRouter.routeChatRoomOpen(chatRoom, validateSavedStatus: checkSavedStatus)
                })
            }
            else {
                BlicupRouter.routeChatRoomOpen(chatRoom, validateSavedStatus: checkSavedStatus)
            }
        }
        else {
            let animatingBlicView = createCustomBlicupLoadingViewWithFrame(tabBarController.view.bounds)
            tabBarController.view.addSubview(animatingBlicView)
            
            ChatRoomBS.getChatRoomsWithIds([chatRoomId], completionHandler: { (success, chatRoomsList) in
                guard success == true, let chatRoom = chatRoomsList?.first, let myChatList = UserBS.getLoggedUser()?.userInfo?.myChatroomList as? [String] else {
                    BlicupRouter.animateBlicAnimationViewOut(animatingBlicView)
                    return
                }
                
                chatRoom.saved = myChatList.contains(chatRoom.chatRoomId!)
                BlicupRouter.routeChatRoomOpen(chatRoom, validateSavedStatus: checkSavedStatus)
                BlicupRouter.animateBlicAnimationViewOut(animatingBlicView)
            })
        }
    }
    
    private class func animateBlicAnimationViewOut(view:UIView) {
        UIView.animateWithDuration(0.5, animations: {
            view.alpha = 0.0
            }) { (_) in
                view.removeFromSuperview()
        }
    }
    
    private class func routeChatRoomOpen(chatRoom: ChatRoom, validateSavedStatus:Bool) {
        let interestsIndex = 0
        let myChatsIndex = 2
        
        guard let tabBarController = UIApplication.sharedApplication().windows.first?.rootViewController as? UITabBarController,
            let pageViewController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("CoverController") as? ChatRoomsListHorizontalPageViewController else {
                return
        }
        
        let isMyChat = (chatRoom.saved == true)
        
        let presenter = CoverChatRoomsListPresenter(withMyChats: isMyChat)
        presenter.currentChatId = chatRoom.chatRoomId!
        pageViewController.initCover(coverPresenter: presenter)
    
        
        var navController: UINavigationController?
        var selectedIndex = interestsIndex
        var pushingControllers:[UIViewController] = [pageViewController]
        
        if isMyChat {
            selectedIndex = myChatsIndex
            navController = tabBarController.viewControllers?[selectedIndex] as? UINavigationController
        }
        else {
            selectedIndex = interestsIndex
            navController = tabBarController.viewControllers?[selectedIndex] as? UINavigationController
            
            if let interestChatList = navController?.viewControllers.first as? ChatRoomsListViewController {
                interestChatList.shouldAnimateCell = false
            }
        }
        
        if (isMyChat || validateSavedStatus == false),
            let chatViewController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("ChatRoomViewController") as? ChatRoomViewController {
                chatViewController.setChatRoom(chatRoom)
                pushingControllers = [pageViewController, chatViewController]
        }
        
        
        navController?.viewControllers.first?.view.layoutIfNeeded() // force loading of lists
        pageViewController.view.layoutIfNeeded() //force loading of cover controller view
        
        navController?.popViewControllerAnimated(false)
        navController!.viewControllers.appendContentsOf(pushingControllers)
        tabBarController.tabBar.hidden = true
        tabBarController.selectedIndex = selectedIndex
    }
    
    
    private class func createCustomBlicupLoadingViewWithFrame(frame:CGRect)->UIView {
        let ivBlic = UIImageView(image: UIImage(named: "BlicUpdate_grey_0"))
        ivBlic.contentMode = UIViewContentMode.ScaleAspectFit
        
        var animationArray = [UIImage]()
        
        for index in 0...30 {
            animationArray.append(UIImage(named: "BlicUpdate_grey_\(index)")!)
        }
        
        ivBlic.animationImages = animationArray
        ivBlic.animationDuration = 1.0
        
        let loadingBlic = UIView(frame: frame)
        loadingBlic.backgroundColor = UIColor.whiteColor()
        
        loadingBlic.addSubview(ivBlic)
        ivBlic.center = loadingBlic.center
        ivBlic.startAnimating()
        
        return loadingBlic
    }
    
    
    class func updateMyChatsTabBadge() {
        guard let tabBarController = UIApplication.sharedApplication().windows.first?.rootViewController as? UITabBarController,
            let myChatsTabItem = tabBarController.tabBar.items?[tabBarItens.MYCHATS.rawValue] else {
            return
        }
                
        setBadgeInTabBarItem(myChatsTabItem)
    }
    
    private class func setBadgeInTabBarItem(tabBarItem:UITabBarItem) {
        guard let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate else {
            return
        }
        
        let fetchRequest = NSFetchRequest(entityName: "ChatRoom")
        fetchRequest.predicate = NSPredicate(format: "saved == true AND showBadge == true")
        fetchRequest.includesSubentities = false
        
        let count = appDelegate.managedObjectContext.countForFetchRequest(fetchRequest, error: nil)
        
        if count > 0 {
            tabBarItem.badgeValue = String(count)
        }
        else {
            tabBarItem.badgeValue = nil
        }
    }
}
