//
//  ChatMapPresenter.swift
//  Blicup
//
//  Created by Moymer on 04/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import CoreLocation

class ChatMapPresenter: NSObject {
    private var chatRoomsList = [ChatRoom]()
    private var timeStamp:NSTimeInterval = 0
    
    private func convertInCoordinates(mapCenter center:CLLocationCoordinate2D, latDelta:CLLocationDegrees, lngDelta:CLLocationDegrees) -> [Double] {
        let vertex1 = CLLocationCoordinate2D(latitude: center.latitude + latDelta/2, longitude: center.longitude - lngDelta/2)
        let vertex2 = CLLocationCoordinate2D(latitude: center.latitude + latDelta/2, longitude: center.longitude + lngDelta/2)
        let vertex3 = CLLocationCoordinate2D(latitude: center.latitude - latDelta/2, longitude: center.longitude - lngDelta/2)
        let vertex4 = CLLocationCoordinate2D(latitude: center.latitude - latDelta/2, longitude: center.longitude + lngDelta/2)
        
        let minLat = min(vertex1.latitude, vertex2.latitude, vertex3.latitude, vertex4.latitude)
        let minLng = min(vertex1.longitude, vertex2.longitude, vertex3.longitude, vertex4.longitude)
        
        let maxLat = max(vertex1.latitude, vertex2.latitude, vertex3.latitude, vertex4.latitude)
        let maxLng = max(vertex1.longitude, vertex2.longitude, vertex3.longitude, vertex4.longitude)
        
        return [minLat, maxLat, minLng, maxLng]
    }
    
    func reloadChatRoomsListInArea(mapCenter center:CLLocationCoordinate2D, latDelta:CLLocationDegrees, lngDelta:CLLocationDegrees, completionHandler: (success: Bool) -> Void) {
                
        let coordArray = convertInCoordinates(mapCenter: center, latDelta: latDelta, lngDelta: lngDelta)
        timeStamp = NSDate().timeIntervalSince1970
        
        ChatRoomBS.getChatRoomOnArea(timeStamp, minLat: coordArray[0], maxLat: coordArray[1], minLng: coordArray[2], maxLng: coordArray[3]) { (identifier, success, chatRoomsList) in
            
            guard identifier == self.timeStamp else {
                return
            }
            
            if success && chatRoomsList != nil {
                self.chatRoomsList = chatRoomsList!
            }
            else {
                //ERROR
                self.chatRoomsList = [ChatRoom]()
            }
            
            completionHandler(success: success)
        }
    }
    
    func numberOfAnnotationsToShow()->Int {
        return chatRoomsList.count
    }
    
    func coordinateForChatRoomIndex(index:Int)->CLLocationCoordinate2D? {
        guard index >= 0 && index < chatRoomsList.count else {
            return nil
        }
        
        guard let chatRoomAddress = chatRoomsList[index].address else {
            return nil
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: chatRoomAddress.latitude!.doubleValue, longitude: chatRoomAddress.longitude!.doubleValue)
        return coordinate
    }
    
    func formattedAddressForChatRoomIndex(index:Int)->String? {
        guard index >= 0 && index < chatRoomsList.count else {
            return nil
        }
        
        guard let chatRoomAddress = chatRoomsList[index].address else {
            return nil
        }
        
        return chatRoomAddress.formattedAddress
    }
    
    func chatRoomIdForIndex(index:Int)->String {
        guard index >= 0 && index < chatRoomsList.count else {
            return ""
        }
        
        let chatRoomAddress = chatRoomsList[index]
        return chatRoomAddress.chatRoomId!
    }
}
