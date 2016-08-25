//
//  UserInfo+CoreDataProperties.swift
//  Blicup
//
//  Created by Moymer on 21/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension UserInfo {

    @NSManaged var blockedList: NSObject?
    @NSManaged var createdChatroomList: NSObject?
    @NSManaged var followeeList: NSObject?
    @NSManaged var followerList: NSObject?
    @NSManaged var likeCount: NSNumber?
    @NSManaged var myChatroomList: NSObject?
    @NSManaged var blockerList: NSObject?
    @NSManaged var followeeCount: NSNumber?
    @NSManaged var followerCount: NSNumber?
    @NSManaged var pushEndpoints: NSObject?
    @NSManaged var snsSubscriptionList: NSObject?
    @NSManaged var user: User?

}
