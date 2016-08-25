//
//  ChatAddress.swift
//  Blicup
//
//  Created by Moymer on 04/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation
import CoreData

enum ChatAddressFields: String {
    
    case Latitude = "lat"
    case Longitude = "lng"
    case FormattedAddress = "formattedAddress"

    
}
class ChatAddress: NSManagedObject {

    
    class func newChatAddress(addressDic : NSDictionary, managedObjectContext: NSManagedObjectContext) -> ChatAddress? {
        
        let address = NSEntityDescription.insertNewObjectForEntityForName("ChatAddress", inManagedObjectContext:managedObjectContext) as! ChatAddress
        
        address.latitude = addressDic[ChatAddressFields.Latitude.rawValue] as? NSNumber
        address.longitude = addressDic[ChatAddressFields.Longitude.rawValue] as? NSNumber
        address.formattedAddress = addressDic[ChatAddressFields.FormattedAddress.rawValue] as? String
        
        return address
    }
    
    class func newChatAddress(addressDic : NSDictionary) -> ChatAddress? {
        
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
       
        return newChatAddress(addressDic, managedObjectContext: managedObjectContext)
       
    }

    func toDictionary() -> NSDictionary {
        
        let addressDic :NSMutableDictionary = [ChatAddressFields.Latitude.rawValue : self.latitude!,
                                               ChatAddressFields.Longitude.rawValue : self.longitude!,
                                               ChatAddressFields.FormattedAddress.rawValue : self.formattedAddress!]
        
        return addressDic
    }
}
