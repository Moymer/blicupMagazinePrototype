
//
//  LDTPWebSocketManager.swift
//  Blicup
//
//  Created by Moymer on 20/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//
import SocketRocket
import ReachabilitySwift
import Alamofire

public enum LDTPWebSocketManagerNotification: String {
    case SocketOpened = "LDTPSocketOpened"
    
}

class LDTPWebSocketManager: NSObject, SRWebSocketDelegate {
   
    var socket : SRWebSocket!
    
    // PRODUÇÃO
    // let websocketServiceAddress : String =  "wss://online.blicup.com/websocket/"
    
    // DEV -- Use this!
    let websocketServiceAddress : String =  "ws://54.227.233.101:8082/websocket/"
    
    //let websocketServiceAddress : String =  "ws://192.168.1.106:8082/websocket/" // Online - Other uses
    
    let PING_TIME = 60.0

    var queue : LDTPTaskQueue?
    var enqueue : Bool  = false
    
    let receiverManager : LDTPWebSocketReceiverManager! = LDTPWebSocketReceiverManager()
    
    
    var lastRemoteHostStatus: Reachability.NetworkStatus?
    
    var pingTimer :NSTimer?
    
    func closeSocket() {
        if socket != nil
        {
            socket.close()
        }
    }
    
    
    func moveToBackground(notification:NSNotification)
    {
        closeSocket()
    }
    
    func moveToForeground(notification:NSNotification)
    {
        initSocket()
    }
    
    func reachabilityChanged(notification:NSNotification)
    {

        let networkReachability = notification.object as! Reachability;
        let remoteHostStatus = networkReachability.currentReachabilityStatus
        
        //has changed network but is still with internet
        if lastRemoteHostStatus != nil
            && lastRemoteHostStatus != remoteHostStatus
            && lastRemoteHostStatus != .NotReachable
            && remoteHostStatus != .NotReachable
        {
            closeSocket()
        }
            
        else //from without internet to connected to Internet
            if lastRemoteHostStatus != nil
            && lastRemoteHostStatus != remoteHostStatus
            && lastRemoteHostStatus == .NotReachable
            {
                initSocket()
            }

        lastRemoteHostStatus = remoteHostStatus
    }
    
    func wantToEnqueue() {
        enqueue = true
    }
    
    func initSocket()
    {
        // Evita tentativa de abrir socket para usuário nao loggado
        guard UserBS.hasCompletedLogin() else {
            return
        }
        
        do {
            let networkReachability =  try Reachability.reachabilityForInternetConnection();
            
            if  networkReachability.currentReachabilityStatus != .NotReachable &&
                !isConnecting() && !isConnected() &&
                UIApplication.sharedApplication().applicationState == .Active {
                
                //enqueu while is connecting
                enqueue = true
                let loggedUser = UserBS.getLoggedUser()
                guard let userId = loggedUser?.userId else {return
                }
                
  
                guard let deviceId = NSUserDefaults.standardUserDefaults().stringForKey("deviceId") else {return
                }
                print("Requested socket opening")
                
                let escapedUserId = userId.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
                socket = SRWebSocket(URL: NSURL(string: websocketServiceAddress + escapedUserId! + "/" + deviceId))
                socket.delegate = self
                socket.open()
            }
        }
        catch let error as NSError {
            
            print("Erro ao deletar: \(error)")
        }
    }
    
    private func sendMsg(msg: [String: AnyObject])
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
             self.socket.send(LDTPMessageBuilder.bodyJsonBuilder(msg))
        }
    }
    
     private func addReqReturnHandle( inout msg: [String: AnyObject] , completionHandler:LDTPWebSocketReceiverManager.WebSocketCompletionHandler? )
    {
        
        var reqId = "-1#-1"
        if completionHandler != nil
        {
            let reqIdCompletion = receiverManager.addClosure(completionHandler!)
            reqId  = "-1#" + reqIdCompletion
        }
        
        msg["2REQID"] = reqId
    
    }
    
    func sendMsg(inout msg: [String: AnyObject], completionHandler:LDTPWebSocketReceiverManager.WebSocketCompletionHandler? ) {
       
        //just send msg when connected
        if isConnected() {
            addReqReturnHandle(&msg, completionHandler: completionHandler)
            sendMsg(msg)
        }
        else
        {
            if enqueue {
                //just start enqueue
                if queue == nil {
                    queue = LDTPTaskQueue(manager:self)
                }
                queue!.addSendTask(msg, completionHandler: completionHandler)
                
            } else {
                if completionHandler != nil {
                    completionHandler!(success: false, retMsg: nil)
                }
            }
 
            initSocket()
            
            
        }
    }
    
    private func startPingTimer()
    {
        stopPingTimer()
        if pingTimer == nil
        {
            pingTimer = NSTimer.scheduledTimerWithTimeInterval(PING_TIME, target: self, selector: #selector( sendPing), userInfo: nil, repeats: true)
        }
    }
    
    private func stopPingTimer()
    {
        if pingTimer != nil
        {
            pingTimer?.invalidate()
            pingTimer = nil
        }
    }

    //inform  server that socket is alive
    func sendPing()
    {
        if isConnected()
        {
            socket.sendPing(nil)
        }
    }
    
    private func isConnecting() -> Bool
    {
        return socket != nil && socket.readyState == SRReadyState.CONNECTING
        
    }
    
    private func isConnected() -> Bool
    {
        return socket != nil && socket.readyState == SRReadyState.OPEN
        
    }
    // message will either be an NSString if the server is using text
    // or NSData if the server is using binary.
    @objc internal func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!)
    {
        //print("Receive MSG " + (message as! String) )
        
        if let ret: [String: AnyObject] = LDTPMessageBuilder.convertStringToDictionary(message as! String)!
        {
            receiverManager.handleReturn(ret)
        }
        
    }
    
    @objc internal func webSocketDidOpen(webSocket: SRWebSocket!)
    {
        //socket is opened tell who has interest
        NSNotificationCenter.defaultCenter().postNotificationName(LDTPWebSocketManagerNotification.SocketOpened.rawValue, object: nil, userInfo: nil)
        
       // print("Did Open ")
       
        if queue != nil {
            queue!.sendAll()
        }
                
        enqueue = false
        startPingTimer()


        
    }
    
    @objc internal func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!)
    {

       // print("Did Fail to request socket")
        
       
        clearSocket()
    
        initSocket()
    }
    
    
    
    @objc internal func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String?, wasClean: Bool)
    {
        let reasonDefined: String! = reason != nil ? reason : "no reason defined"
        print("Did Close " + reasonDefined)
        clearSocket()
        
        /**
        if "other_session_active" == reasonDefined && UIApplication.sharedApplication().applicationState == .Active {
            NSNotificationCenter.defaultCenter().postNotificationName(BlicupAsyncHandler.UserNotification.CannotHaveSimultaneousSession.rawValue, object: nil, userInfo: nil)
        }else {
            initSocket()
        }*/

  
    }
    
    @objc  internal func webSocket(webSocket: SRWebSocket!, didReceivePong pongPayload: NSData!)
    {
        //print("Pong")
    }
    
    private func clearSocket()
    {
        if socket != nil
        {
            enqueue = false
            socket.close()
            socket.delegate = nil
            socket = nil
        }
    }

}