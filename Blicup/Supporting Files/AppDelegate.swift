//
//  AppDelegate.swift
//  Blicup
//
//  Created by Guilherme Braga on 29/02/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import CoreData
import Kingfisher
import TwitterKit
import Fabric
import Crashlytics
import FBSDKLoginKit
import FBSDKShareKit
import KeychainAccess

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    //serialize coredata access to same list of object in background
    var coreDataSerialBGQueue = dispatch_queue_create("CoreDataSerialQueue",DISPATCH_QUEUE_SERIAL)
    var coreDataSerialSemaphore = dispatch_semaphore_create(1)

    //sessions marl
    var entered_by_push = false
    var entered_by_deeplink = false
    
    func waitForCoreDataBG() -> Void
    {
        dispatch_semaphore_wait(coreDataSerialSemaphore , DISPATCH_TIME_FOREVER)
    }
    
    func signalForCoreDataBG() -> Void
    {
        dispatch_semaphore_signal(coreDataSerialSemaphore);
        
    }

    func generateDeviceID()-> Void
    {
        var devID =  UIDevice.currentDevice().identifierForVendor!.UUIDString as String
        
        do {
            let keychain = Keychain(service: "com.blicup")
            if let storedDevId = try keychain.get("deviceId")
            {
                devID = storedDevId
            }
            else
            {
                try keychain.set(devID, key: "deviceId")
            }
        }
        catch let error {
            print(error)
        }
        
        NSUserDefaults.standardUserDefaults().setObject(devID, forKey: "deviceId")
        NSUserDefaults.standardUserDefaults().synchronize()
        
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        UITextField.appearance().keyboardAppearance = UIKeyboardAppearance.Dark
        
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions:launchOptions)
        
        Twitter.sharedInstance().startWithConsumerKey("SJVn8wmZiNyQ2A0bBYhMThm8A", consumerSecret: "OxcA7Q3PjiVWZ8Bl3txgAR1BjRFVTVERjZ0xtlpAydJba1T50o")
        
        Fabric.with([Twitter.sharedInstance(), Crashlytics.self, Answers.self])
        
        // Initializes de handler
        BlicupAsyncHandler.sharedInstance
        
       BlicupRouter.routeLogin(self.window)

       // BlicupRouter.routeTest(self.window)
        
        let cache = KingfisherManager.sharedManager.cache
        cache.maxCachePeriodInSecond = 60 * 60 * 24 * 365 * 50
        //cache.maxMemoryCost = 1000000 * 10
        
        setupPush()
        
        configureFirstTimeInAppUserDefault()
        
        hasOpenedFromPush(launchOptions)
        
        generateDeviceID()
   
        return true
    }
    
    private func hasOpenedFromPush(launchOptions: [NSObject: AnyObject]?)
    {
        if let notification = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as? [String: AnyObject] {
            
            let payload :[NSObject : AnyObject] = notification["aps"] as! [NSObject : AnyObject]
            
            if let chatroomId = payload["id"] as? String {
                
                //print("Opened Push for chatroom \(chatroomId)")
                entered_by_push = true
                BlicupRouter.routeBlicupToChatRoom(chatroomId, checkSavedStatus: true)
                
            }
            
        }
    }
    
    private func configureFirstTimeInAppUserDefault(){
        if NSUserDefaults.standardUserDefaults().objectForKey("firstTimeInApp") == nil{
            NSUserDefaults.standardUserDefaults().setObject(true, forKey: "firstTimeInApp")
        }
        
        if NSUserDefaults.standardUserDefaults().objectForKey(kIsFirstCreatedChatKey) == nil{
            NSUserDefaults.standardUserDefaults().setObject(false, forKey: kIsFirstCreatedChatKey)
        }
    }
    
    private func setupPush()
    {
        // Sets up Mobile Push Notification
        let readAction = UIMutableUserNotificationAction()
        readAction.identifier = "READ_IDENTIFIER"
        readAction.title = "Read"
        readAction.activationMode = UIUserNotificationActivationMode.Foreground
        readAction.destructive = false
        readAction.authenticationRequired = true
        
        let deleteAction = UIMutableUserNotificationAction()
        deleteAction.identifier = "DELETE_IDENTIFIER"
        deleteAction.title = "Delete"
        deleteAction.activationMode = UIUserNotificationActivationMode.Foreground
        deleteAction.destructive = true
        deleteAction.authenticationRequired = true
        
        let ignoreAction = UIMutableUserNotificationAction()
        ignoreAction.identifier = "IGNORE_IDENTIFIER"
        ignoreAction.title = "Ignore"
        ignoreAction.activationMode = UIUserNotificationActivationMode.Foreground
        ignoreAction.destructive = false
        ignoreAction.authenticationRequired = false
        
        let messageCategory = UIMutableUserNotificationCategory()
        messageCategory.identifier = "MESSAGE_CATEGORY"
        messageCategory.setActions([readAction, deleteAction], forContext: UIUserNotificationActionContext.Minimal)
        messageCategory.setActions([readAction, deleteAction, ignoreAction], forContext: UIUserNotificationActionContext.Default)
        
        let notificationSettings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Badge, UIUserNotificationType.Sound, UIUserNotificationType.Alert], categories: (NSSet(array: [messageCategory])) as? Set<UIUserNotificationCategory>)
        
        UIApplication.sharedApplication().registerForRemoteNotifications()
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let deviceTokenString = "\(deviceToken)"
            .stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString:"<>"))
            .stringByReplacingOccurrencesOfString(" ", withString: "")
        print("deviceTokenString: \(deviceTokenString)")
        NSUserDefaults.standardUserDefaults().setObject(deviceTokenString, forKey: "deviceToken")
        
    }
    

    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        if UIApplication.sharedApplication().applicationState != UIApplicationState.Inactive {
            completionHandler(UIBackgroundFetchResult.NoData)
            
            return
        }
        
        
        let payload :[NSObject : AnyObject] = userInfo["aps"] as! [NSObject : AnyObject]
        //print("Push payload \(payload)")
        
        if let chatroomId = payload["id"] as? String
        {
            entered_by_push = true
            BlicupRouter.routeBlicupToChatRoom(chatroomId, checkSavedStatus: true)
        }

        completionHandler(UIBackgroundFetchResult.NoData)
    }
    
    
    
    // MARK: - Open URL Scheme and Universal link way
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        
        if (url.scheme == "blicup"), let chatroomId = url.host {
             entered_by_deeplink = true
            BlicupRouter.routeBlicupToChatRoom(chatroomId, checkSavedStatus: true)
        }
        
        /*
         let parsedURL = BFURL(inboundURL: url, sourceApplication: sourceApplication)
         if ((parsedURL.appLinkData) != nil){
         let targetURL = parsedURL.targetURL
         }
         */
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: ([AnyObject]?) -> Void) -> Bool {
        
        if  userActivity.activityType == NSUserActivityTypeBrowsingWeb  {
            
            if let url = userActivity.webpageURL
            {
                let file : String = (url.pathComponents?.last)!
                let chatroomId =  file.stringByReplacingOccurrencesOfString(".html", withString: "")
                entered_by_deeplink = true
                
                BlicupRouter.routeBlicupToChatRoom(chatroomId, checkSavedStatus: true)
            }
            
        }
        
        return true;
    }
    
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        entered_by_deeplink = false
        entered_by_push = false
        BlicupAnalytics.sharedInstance.endSession()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        BlicupAnalytics.sharedInstance.initSession()
        
        application.applicationIconBadgeNumber = 0
        BlicupAnalytics.sharedInstance.mark_EnterApp(entered_by_push, fromDeepLink: entered_by_deeplink)
        
        //App activation code
        FBSDKAppEvents.activateApp()
        
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        NSUserDefaults.standardUserDefaults().removeObjectForKey(kCurrentOpenChatRoomIdKey)
        NSUserDefaults.standardUserDefaults().removeObjectForKey("lastSearch")
        self.saveContext()
    }
    
    
    // MARK: - Core Data stack
    
    private class func newApplicationDocumentsDirectory()->NSURL {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.Blicup" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }
    
    private class func newManagedObjectModel()->NSManagedObjectModel {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Blicup", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }
    
    private class func newPersistentStoreCoordinator()->NSPersistentStoreCoordinator {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: AppDelegate.newManagedObjectModel())
        let url = AppDelegate.newApplicationDocumentsDirectory().URLByAppendingPathComponent("BlicupCoreData.sqlite")
        let failureReason = "There was an error creating or loading the application's saved data."
        let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                       NSInferMappingModelAutomaticallyOption: true]
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as! NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }
    
    private class func newManagedObjectContext()->NSManagedObjectContext {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = AppDelegate.newPersistentStoreCoordinator()
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        return AppDelegate.newManagedObjectContext()
    }()
    
    func recreateLocalDataBase() {
        guard let storeCoordinator = self.managedObjectContext.persistentStoreCoordinator else {
            return
        }
        
        for store in storeCoordinator.persistentStores {
            do {
                try storeCoordinator.removePersistentStore(store)
                try NSFileManager.defaultManager().removeItemAtURL(store.URL!)
            }
            catch {
                continue
            }
        }
        
        self.managedObjectContext = AppDelegate.newManagedObjectContext()
    }
    
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as! NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
}

