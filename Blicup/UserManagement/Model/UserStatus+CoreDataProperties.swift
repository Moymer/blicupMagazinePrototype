//
//  UserStatus+CoreDataProperties.swift
//  Blicup
//
//  Created by Moymer on 7/15/16.
//  Copyright © 2016 Moymer. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension UserStatus {

    @NSManaged var status: NSNumber?
    @NSManaged var lastChangeTime: NSNumber?
    @NSManaged var sessionState: NSNumber?

}
