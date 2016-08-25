//
//  ChatRoom+CoreDataProperties.swift
//  Blicup
//
//  Created by Moymer on 26/07/16.
//  Copyright © 2016 Moymer. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ChatRoom {

    @NSManaged var chatRoomId: String?
    @NSManaged var creationDate: NSNumber?
    @NSManaged var grade: NSNumber?
    @NSManaged var lastMsgDate: NSNumber?
    @NSManaged var showBadge: NSNumber?
    @NSManaged var lastUpdateTimestamp: NSNumber?
    @NSManaged var name: String?
    @NSManaged var participantCount: NSNumber?
    @NSManaged var saved: NSNumber?
    @NSManaged var tagList: [String]?
    @NSManaged var state: NSNumber?
    @NSManaged var address: ChatAddress?
    @NSManaged var participantList: NSOrderedSet?
    @NSManaged var photoList: NSOrderedSet?
    @NSManaged var whoCreated: User?

}
