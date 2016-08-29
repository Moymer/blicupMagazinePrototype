//
//  Caption+CoreDataProperties.swift
//  Blicup
//
//  Created by Moymer on 8/29/16.
//  Copyright © 2016 Moymer. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Caption {

    @NSManaged var entryTime: NSNumber?
    @NSManaged var entryTransition: NSNumber?
    @NSManaged var text: NSManagedObject?

}
