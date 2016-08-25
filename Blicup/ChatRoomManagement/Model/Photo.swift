//
//  Photo.swift
//  Blicup
//
//  Created by Guilherme Braga on 13/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation
import CoreData

enum PhotoFields: String {
    
    case PhotoUrl = "photoUrl"
    case Height = "height"
    case Width = "width"
    case MainColor = "mainColor"
    
}

class Photo: NSManagedObject {

    // Insert code here to add functionality to your managed object subclass
    
    class func createPhoto(photoDic : NSDictionary,managedObjectContext: NSManagedObjectContext ) -> Photo {
        
        let photo = NSEntityDescription.insertNewObjectForEntityForName("Photo", inManagedObjectContext:managedObjectContext) as! Photo
        
        photo.photoUrl = photoDic[PhotoFields.PhotoUrl.rawValue] as? String
        photo.height = photoDic[PhotoFields.Height.rawValue] as? Int
        photo.width = photoDic[PhotoFields.Width.rawValue] as? Int
        photo.mainColor = photoDic[PhotoFields.MainColor.rawValue] as? Int
        
        return photo
    }

    class func createPhoto(photoDic : NSDictionary) -> Photo {
        
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
     
        return createPhoto(photoDic, managedObjectContext: managedObjectContext)
    }
    
    
    func toDictionary() -> NSDictionary {
        
        let photoDic :NSMutableDictionary = [PhotoFields.PhotoUrl.rawValue : self.photoUrl!,
                                               PhotoFields.Height.rawValue : self.height!,
                                               PhotoFields.Width.rawValue : self.width!,
                                                 PhotoFields.MainColor.rawValue : self.mainColor!]
        
        return photoDic
    }
    
    
    class func toDictionary(photoList: [Photo]) -> [NSDictionary]
    {
        var photosDics: [NSDictionary] = []
        
        for photo in photoList
        {
            photosDics.append(photo.toDictionary())
        }
        return photosDics
    }
}
