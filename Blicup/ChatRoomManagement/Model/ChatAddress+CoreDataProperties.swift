//
//  ChatAddress+CoreDataProperties.swift
//  Blicup
//
//  Created by Moymer on 04/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ChatAddress {

    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var formattedAddress: String?
    @NSManaged var chat: ChatRoom?

}
