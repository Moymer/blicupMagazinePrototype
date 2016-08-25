//
//  User+CoreDataProperties.swift
//  Blicup
//
//  Created by Guilherme Braga on 02/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension User {

    @NSManaged var bio: String?
    @NSManaged var facebookId: String?
    @NSManaged var lastTimeUpdated: NSNumber?
    @NSManaged var photoUrl: String?
    @NSManaged var tagList: [String]?
    @NSManaged var twitterId: String?
    @NSManaged var userId: String?
    @NSManaged var username: String?
    @NSManaged var isVerified: NSNumber?
    @NSManaged var myChats: NSSet?
    @NSManaged var userInfo: UserInfo?
    @NSManaged var userStatus: UserStatus?

}
