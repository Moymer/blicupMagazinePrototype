//
//  CVideo+CoreDataProperties.swift
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

extension CVideo {

    @NSManaged var mainUrl: String?
    @NSManaged var smallUrl: String?
    @NSManaged var durationSecs: NSNumber?
    @NSManaged var sizeInMB: NSNumber?
    @NSManaged var width: NSNumber?
    @NSManaged var height: NSNumber?
    @NSManaged var layoutAndDesign: NSManagedObject?
    @NSManaged var captionList: Caption?

}
