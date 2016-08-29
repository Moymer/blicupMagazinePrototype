//
//  CImageLD+CoreDataProperties.swift
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

extension CImageLD {

    @NSManaged var zoom: NSNumber?
    @NSManaged var motion: NSNumber?
    @NSManaged var scale: NSNumber?
    @NSManaged var positioning: NSManagedObject?

}
