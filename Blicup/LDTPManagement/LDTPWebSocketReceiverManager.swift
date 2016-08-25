//
//  LDTPWebSocketReceiverManager.swift
//  Blicup
//
//  Created by Moymer on 28/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import Foundation

class LDTPWebSocketReceiverManager: NSObject {

    
    
    typealias WebSocketCompletionHandler = (success:Bool, retMsg: [String: AnyObject]?) -> Void
    
    let TIMEOUT:Double! = 15 //5s
    
    
    
    var returnClosuresDict : [String: WebSocketCompletionHandler] = [String: WebSocketCompletionHandler]()
    
    var closureControllerTimer : NSTimer?
    
    func addClosure(completion: WebSocketCompletionHandler) -> String
    {
        let timeInterval  = NSDate().timeIntervalSince1970
        let reqId = timeInterval.description
        
        returnClosuresDict[reqId] = completion
        
        startTimer()
        
        return reqId
    }
    
    
    func handleReturn(retMsg: [String: AnyObject])
    {
       
        let reqId = retMsg["ReqId"] as? String
        

       // print(retMsg)
        
        var ans = retMsg
        ans["ReqId"] = nil
        
        if reqId != nil
        {
            let reqIdParts = reqId!.characters.split {$0 == "#"}
            
            let reqIdClosure: String = String(reqIdParts[1])
          
            
            if(reqIdClosure.rangeOfString("-1") == nil)
            {
                handleReturnClosure(reqIdClosure, retMsg: ans )
                
            }
            else
            {
                let reqIdNotification: String = String(reqIdParts[0])
                if(reqIdNotification.rangeOfString("-1") == nil)
                {
                     NSNotificationCenter.defaultCenter().postNotificationName((LDTPNSNotificationCenterControl.LDTPNSNotificationCenterKey.fromCodToKey(Int(reqIdNotification)!)?.rawValue)!, object: nil, userInfo: ans)
                    
                }
                
            }
        
        }
    }
    
    
    private func handleReturnClosure(reqId : String, retMsg: [String: AnyObject] )
    {
        let completion  = returnClosuresDict[reqId]
        if completion != nil
        {
            dispatch_async(dispatch_get_main_queue(), {
                completion!(success: true, retMsg: retMsg)
            });
        }
        
        
        returnClosuresDict[reqId] = nil
        
        if returnClosuresDict.count == 0
        {
            stopTimer()
        }
 

    }
    
    private func startTimer()
    {
        if closureControllerTimer == nil
        {
            closureControllerTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector( LDTPWebSocketReceiverManager.closureCleaner), userInfo: nil, repeats: true)

        }
    }
    
    private func stopTimer()
    {
        if closureControllerTimer != nil
        {
            closureControllerTimer?.invalidate()
            closureControllerTimer = nil
        }
    }
    
    
    func closureCleaner(timer: NSTimer)
    {
        let now:NSTimeInterval!  = NSDate().timeIntervalSince1970
        for (key , completion) in returnClosuresDict {
            
            let reqTime : Double! = Double(key as String)
            
            if  now > (reqTime + TIMEOUT)
            {
                dispatch_async(dispatch_get_main_queue(), {
                    completion(success: false, retMsg: nil)
                });
                
                returnClosuresDict[key] = nil
                
        
            }
            
        }
        
        if returnClosuresDict.count == 0
        {
            stopTimer()
        }
    }
}
