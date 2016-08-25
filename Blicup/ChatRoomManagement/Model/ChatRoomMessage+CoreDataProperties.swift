//
//  ChatRoomMessage+CoreDataProperties.swift
//  Blicup
//
//  Created by Moymer on 02/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ChatRoomMessage {

    @NSManaged var chatRoomId: String?
    @NSManaged var content: String?
    @NSManaged var likeCount: NSNumber?
    @NSManaged var mentionList: [String]?
    @NSManaged var liked: NSNumber?
    @NSManaged var msgId: String?
    @NSManaged var msgType: NSNumber?
    @NSManaged var sentDate: NSDate?
    @NSManaged var updatedDate: NSNumber?
    @NSManaged var state: NSNumber?
    @NSManaged var whoSent: User?

}
