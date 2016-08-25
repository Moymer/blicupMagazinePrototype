//
//  LDTPTaskQueue.swift
//  Blicup
//
//  Created by Moymer on 03/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class LDTPTaskQueue: NSObject {
    
    
    private var queueArray:[Task] = []
    var manager : LDTPWebSocketManager
    
    required init(manager:LDTPWebSocketManager)
    {
        self.manager = manager
    }
    
    
    func addSendTask(msg: [String: AnyObject], completionHandler:LDTPWebSocketReceiverManager.WebSocketCompletionHandler?)
    {
        queueArray.append(Task(msg: msg,completionHandler: completionHandler ))
    }
    
    func sendAll()
    {
        for task in queueArray {
            
            manager.sendMsg(&task.msg, completionHandler: task.completionHandler)
        }
        
        queueArray = []
    }
    
    
    private class Task : NSObject {
        
        var msg:[String: AnyObject]
        
        var completionHandler:LDTPWebSocketReceiverManager.WebSocketCompletionHandler?
        
        required init(msg: [String: AnyObject], completionHandler:LDTPWebSocketReceiverManager.WebSocketCompletionHandler?) {
        
                self.msg = msg
                self.completionHandler = completionHandler
            
        }
        
    }
    
}
