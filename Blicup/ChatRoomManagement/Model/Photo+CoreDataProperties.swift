//
//  Photo+CoreDataProperties.swift
//  Blicup
//
//  Created by Moymer on 05/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var height: NSNumber?
    @NSManaged var mainColor: NSNumber?
    @NSManaged var photoUrl: String?
    @NSManaged var width: NSNumber?
    @NSManaged var chatRoom: ChatRoom?

}
