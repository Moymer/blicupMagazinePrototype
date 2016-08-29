//
//  CText+CoreDataProperties.swift
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

extension CText {

    @NSManaged var text: String?
    @NSManaged var wordCount: NSNumber?
    @NSManaged var isUrl: NSNumber?
    @NSManaged var layoutAndDesign: NSManagedObject?

}
