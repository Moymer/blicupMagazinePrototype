//
//  CTextLD+CoreDataProperties.swift
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

extension CTextLD {

    @NSManaged var fontFamily: String?
    @NSManaged var fontSize: String?
    @NSManaged var fontColor: String?
    @NSManaged var backgroundColor: String?
    @NSManaged var fontStrength: String?
    @NSManaged var textPositioning: String?
    @NSManaged var positioning: NSManagedObject?

}
