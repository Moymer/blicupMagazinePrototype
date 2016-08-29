//
//  CImage+CoreDataProperties.swift
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

extension CImage {

    @NSManaged var thumbUrl: String?
    @NSManaged var mainUrl: String?
    @NSManaged var width: NSNumber?
    @NSManaged var height: NSNumber?
    @NSManaged var mainColor: NSNumber?
    @NSManaged var layoutAndDesign: NSManagedObject?
    @NSManaged var caption: Caption?

}
