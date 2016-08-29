//
//  Magazine+CoreDataProperties.swift
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

extension Magazine {

    @NSManaged var name: String?
    @NSManaged var coverThumbUrl: String?
    @NSManaged var coverMainUrl: String?
    @NSManaged var refDate: NSNumber?
    @NSManaged var magazineId: String?
    @NSManaged var articleList: NSSet?
    @NSManaged var owner: NSManagedObject?

}
