//
//  Article+CoreDataProperties.swift
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

extension Article {

    @NSManaged var pubDate: NSNumber?
    @NSManaged var isDraft: NSNumber?
    @NSManaged var creationDate: NSNumber?
    @NSManaged var name: String?
    @NSManaged var contentSize: NSNumber?
    @NSManaged var articleId: String?
    @NSManaged var chatroomId: String?
    @NSManaged var contentList: NSSet?
    @NSManaged var category: Category?
    @NSManaged var author: Author?
    @NSManaged var relatedArticleList: NSSet?
    @NSManaged var magazineList: NSSet?
    @NSManaged var articleSpec: ArticleSpecs?
    @NSManaged var location: Location?

}
