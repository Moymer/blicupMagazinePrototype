//
//  ChatRoomPresenter.swift
//  Blicup
//
//  Created by Moymer on 13/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import CoreData

protocol ChatRoomPresenterDelegate: class {
    func updateMessagesData(insertedIdexes: [NSIndexPath], deletedIndexes: [NSIndexPath], reloadedIndexes: [NSIndexPath])
    
    func updatedChatroom()
}

class ChatRoomPresenter: NSObject, NSFetchedResultsControllerDelegate, ChatRoomContextMenuProtocol {
    private var chatRoom:ChatRoom! {
        didSet {
            chatRoom.showBadge = false
        }
    }
    
    private var insertIndexes, deleteIndexes, reloadIndexes : [NSIndexPath]?
    internal var contextMenuImagesName = ["dots_black", "profile_black"]
    internal var contextMenuHighlightedImagesName = ["dots_white", "profile_white"]
    internal var contextMenuHighlightedImagesTitle = [NSLocalizedString("More", comment: "More"), NSLocalizedString("Profile", comment: "Profile")]
    
    private var firtChatInAppMessages = [NSLocalizedString("Message_First_Chat", comment: ""), NSLocalizedString("Message_First_Chat_1", comment: ""), NSLocalizedString("Message_First_Chat_2", comment: ""), NSLocalizedString("Message_Greetings_1", comment: "")]
    
    private let BATCH_SIZE = 50
    private let MAX_MESSAGE_SIZE = 100
    
    weak var delegate: ChatRoomPresenterDelegate? {
        didSet {
            if delegate != nil {
                fetchedResultsController.delegate = self
            }
            else {
                fetchedResultsController.delegate = nil
            }
        }
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "ChatRoomMessage")
        let predicate = NSPredicate(format: "chatRoomId == %@", self.chatRoom.chatRoomId!)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "sentDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.fetchOffset = max( self.countFromDatabase() - self.BATCH_SIZE, 0)
        fetchRequest.fetchLimit = self.BATCH_SIZE
        fetchRequest.fetchBatchSize = self.BATCH_SIZE
        fetchRequest.includesSubentities = true
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        
        return fetchedResultsController
    }()
    
    
    private func countFromDatabase() -> Int
    {
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "ChatRoomMessage")
        let predicate = NSPredicate(format: "chatRoomId == %@", self.chatRoom.chatRoomId!)
        fetchRequest.predicate = predicate
        let count = managedObjectContext.countForFetchRequest(fetchRequest, error: nil )
        return count
    }
    
    
    func loadChatRoom(chatRoom:ChatRoom) {
        self.chatRoom = chatRoom
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
        
        startListenToChatroomUpdates()
    }
    
    deinit {
        stopListenToChatroomUpdates()
        fetchedResultsController.delegate = nil
        delegate = nil
        self.chatRoom.showBadge = false
    }
    
    func loadMoreMessages() -> Int{
        
         let before = self.fetchedResultsController.fetchRequest.fetchOffset
        do{
           
            self.fetchedResultsController.fetchRequest.fetchOffset = max( self.fetchedResultsController.fetchRequest.fetchOffset - self.BATCH_SIZE, 0)
            self.fetchedResultsController.fetchRequest.fetchLimit = self.fetchedResultsController.fetchRequest.fetchLimit + self.BATCH_SIZE
            try self.fetchedResultsController.performFetch()
            
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
        return before - self.fetchedResultsController.fetchRequest.fetchOffset
    }

    func loadLessMessages() -> Bool{
        
        let count = messagesNumber()
        if count > MAX_MESSAGE_SIZE
        {
            do {
                self.fetchedResultsController.fetchRequest.fetchOffset = max( self.countFromDatabase() - self.BATCH_SIZE, 0)
                self.fetchedResultsController.fetchRequest.fetchLimit = self.BATCH_SIZE
                try self.fetchedResultsController.performFetch()
                
            } catch {
                let fetchError = error as NSError
                print("\(fetchError), \(fetchError.userInfo)")
            }
            return true
        }
        return false
    }

    
    func stopListenToChatroomUpdates()
    {
        BlicupAsyncHandler.sharedInstance.removeObserveToChatroomUpdates(self, chatroom: self.chatRoom)
        
    }
    
    func startListenToChatroomUpdates()
    {
        BlicupAsyncHandler.sharedInstance.addObserveToChatroomUpdates(self, rSelector: #selector(receiveChatroomUpdate(_:)), chatroom: self.chatRoom)
        
    }
    
    func receiveChatroomUpdate( notification: NSNotification)
    {
        self.chatRoom = notification.userInfo!["chatroom"] as! ChatRoom
        
        delegate?.updatedChatroom()
    }
    
    
    func chatBackgroundColor()->UIColor {
        guard let photo = self.chatRoom?.photoList?.firstObject as? Photo else {
            return UIColor.blackColor()
        }
        
        guard let mainColor = photo.mainColor?.integerValue  else {
            return UIColor.blackColor()
        }
        
        return UIColor.rgbIntToUIColor(mainColor)
    }
    
    func chatBackgroundImageUrl()->NSURL? {
        guard let photo = self.chatRoom?.photoList?.firstObject as? Photo else {
            return nil
        }
        
        guard let photoString = photo.photoUrl else {
            return nil
        }
        
        return NSURL(string: photoString)
    }
    
    func chatRoomID() -> String?{
        return chatRoom?.chatRoomId
    }
    
    func chatName()->String? {
        return chatRoom?.name
    }
    
    func chatParticipantsNumber()->Int32 {
        if let participants = chatRoom?.participantCount?.intValue {
            return participants
        }
        else {
            return 0
        }
    }
    
    func getLastChatroomUpdate() -> Double
    {
        if  chatRoom.lastMsgDate?.doubleValue > 0
        {
            return (chatRoom.lastMsgDate?.doubleValue)!
        }
        else
        {
            return (chatRoom.creationDate?.doubleValue)!
        }
        
    }
    
    func userPhotoUrl()->NSURL? {
        guard let urlString = UserBS.getLoggedUser()?.photoUrl else { return nil }
        return NSURL(string: urlString)
    }
    
    func isLoggedUser(index:NSIndexPath) -> Bool {
        
        let message = messageObjectAtIndex(index)
        let userId = message.whoSent?.userId
        let loggedId = UserBS.getLoggedUser()?.userId
        
        return (userId == loggedId)
    }

    func isLoggedUserChatOwner() -> Bool {
        
        let whoCreated = chatRoom.whoCreated?.userId
        let loggedUser = UserBS.getLoggedUser()?.userId
        
        return whoCreated == loggedUser
    }
    
    func isSavedChatRoom() -> Bool {
        guard let saved = self.chatRoom.saved else {
            return false
        }
        return saved.boolValue
    }
    
    // MARK: MessagesData
    private func messageObjectAtIndex(index: NSIndexPath)->ChatRoomMessage {

        // TODO: Retornar nil caso não consiga pegar mensagem
        // FIXME:
        let message = fetchedResultsController.objectAtIndexPath(index) as! ChatRoomMessage
        return message
    }
    
    func isMyMessageAtIndex(index:NSIndexPath)->Bool {
        let message = messageObjectAtIndex(index)
        
        guard let messageUserId = message.whoSent?.userId, let myId = UserBS.getLoggedUser()?.userId else {
            return false
        }
        
        return (messageUserId == myId)
    }
    
    func isMessageBlock(index:NSIndexPath)->Bool {
        let message = messageObjectAtIndex(index)
        
        guard let senderId = message.whoSent?.userId,
            let blockedList = UserBS.getLoggedUser()?.userInfo?.blockedList as? [String] else {
                return false
        }
        
        return blockedList.contains(senderId)
    }
    
    func userForMention(username: String, completionHandler:(user: User?) -> Void){
        let usernameClean =  String(username.characters.dropFirst())
        UserBS.getUsersThatMatchesSearchTerm(usernameClean) { (searchTerm, success, userList) in
            if success {
                if let users = userList {
                    for user in users {
                        if user.username == usernameClean {
                            completionHandler(user: user)
                            break
                        }
                    }
                }
            }
            completionHandler(user: nil)
        }
    }
    
    func isLoggedUserMentioned(userID: String) -> Bool {
        
        let loggedUser = UserBS.getLoggedUser()?.userId
        
        return userID == loggedUser
    }
    
    func isBlockingMe(index:NSIndexPath)->Bool {
        let message = messageObjectAtIndex(index)
        
        guard let blockerList = UserBS.getLoggedUser()?.userInfo?.blockerList as? [String],
            senderId = message.whoSent?.userId else {
                return false
        }
        
        return blockerList.contains(senderId)
    }
    
    func messagesNumber()->Int {
        if let sections = fetchedResultsController.sections {
            let sectionInfo = sections.first!
            return sectionInfo.numberOfObjects
        }
        
        return 0
    }
    
    func messageUserPhotoAtIndex(index:NSIndexPath)->NSURL? {
        let message = messageObjectAtIndex(index)
        
        if let urlString = message.whoSent?.photoUrl {
            return NSURL(string: urlString)
        }
        else {
            return nil
        }
    }
    
    func messageUserNameAtIndex(index:NSIndexPath)->String? {
        let message = messageObjectAtIndex(index)
        
        guard let user = message.whoSent?.username else {
            return nil
        }
        
        return ("@"+user)
    }
    
    func messageUserIsVerified(index: NSIndexPath) -> Bool {
        let message = messageObjectAtIndex(index)
        
        guard let isVerified = message.whoSent?.isVerified else {
            return false
        }
        
        return isVerified.boolValue
    }
    
    func messageAtIndex(index:NSIndexPath)-> String? {
        let message = messageObjectAtIndex(index)
        
        guard message.msgType?.integerValue == ChatRoomMessage.MessageType.TEXT_MSG.rawValue else {
            return nil
        }
        
        return message.content
    }
    
    func defaultMessageAtIndex(index:NSIndexPath)-> String {
        return firtChatInAppMessages[index.row]
    }
    
    func whoSentMessageAtIndex(index: NSIndexPath) -> User? {
        
        let message = messageObjectAtIndex(index)

        return message.whoSent
    }
    
    
    func messageWithMentionAtIndex(index: NSIndexPath)-> NSMutableAttributedString? {
        
        let message = messageObjectAtIndex(index)
        let mentionList = message.mentionList!
        
        guard let text = message.content else {
            return NSMutableAttributedString()
        }
        
        return text.convertMentionsToLinkAttributtedString(mentionList)
    }
    
    func isMessageWithMention(index: NSIndexPath) -> Bool {
        let message = messageObjectAtIndex(index)
        
        return (message.mentionList?.count > 0)
    }
    
    func messageStateAtIndex(index:NSIndexPath)->ChatRoomMessage.MessageState {
        let message = messageObjectAtIndex(index)
        
        if let state = ChatRoomMessage.MessageState(rawValue: message.state!.integerValue) {
            return state
        }
        else {
            return ChatRoomMessage.MessageState.Sent
        }
    }
    
    func messageImageUrlAtIndex(index:NSIndexPath)->NSURL? {
        let message = messageObjectAtIndex(index)
        
        guard message.msgType?.integerValue == ChatRoomMessage.MessageType.IMAGE_MSG.rawValue,
            let content = message.content else {
                return nil
        }
        
        if let data = content.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                let jsonDic = try NSJSONSerialization.JSONObjectWithData(data, options: []) as! [String:AnyObject]
                let urlString = jsonDic["link"] as! String
                return NSURL(string:urlString)
            }
            catch let error as NSError {
                print(error)
            }
        }
        
        return nil
    }
    
    func messageImageSizeAtIndex(index:NSIndexPath)->CGSize? {
        let message = messageObjectAtIndex(index)
        
        guard message.msgType?.integerValue == ChatRoomMessage.MessageType.IMAGE_MSG.rawValue,
            let content = message.content else {
                return nil
        }
        
        if let data = content.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                let jsonDic = try NSJSONSerialization.JSONObjectWithData(data, options: []) as! [String:AnyObject]
                let width = jsonDic["width"] as! CGFloat
                let height = jsonDic["height"] as! CGFloat
                return CGSizeMake(width, height)
            }
            catch let error as NSError {
                print(error)
            }
        }
        
        return nil
    }
    
    func messageSentTimeAtIndex(index:NSIndexPath)->String? {
        let message = messageObjectAtIndex(index)
        
        guard let date = message.sentDate else {
            return nil
        }
        
        let df = NSDateFormatter()
        df.dateFormat = "HH:mm"
        
        return df.stringFromDate(date)
    }
    
    func messageLikesCountAtIndex(index:NSIndexPath)->NSInteger {
        let message = messageObjectAtIndex(index)
        return message.likeCount!.integerValue
    }
    
    func setLikeAtMessageIndex(index:NSIndexPath) {
        let message = messageObjectAtIndex(index)
        
        let didLike = !message.liked!.boolValue
        message.liked = didLike
        message.likeCount = NSNumber(int: didLike ? message.likeCount!.intValue+1 : message.likeCount!.intValue-1)
        
        guard let msgId = message.msgId, let chatId = message.chatRoomId else {
            return
        }
        
        if didLike {
            ChatRoomBS.likeMsgFromChatroom(msgId, chatroomId: chatId, completionHandler: { (success) in
                // Tratar o que for necessario
            })
        }
        else {
            ChatRoomBS.unlikeMsgFromChatroom(msgId, chatroomId: chatId, completionHandler: { (success) in
                // Tratar o que for necessario
            })
        }
    }
    
    func didLikedMessageAtIndex(index:NSIndexPath)->Bool {
        let message = messageObjectAtIndex(index)
        return message.liked!.boolValue
    }
    
    // MARK: Servicos
    func saveChatRoom() {
        guard let chatID = chatRoom?.chatRoomId else { return }
        
        ChatRoomBS.saveChatRoomOfInterest(chatID) { (success) in
            // TODO: Definir comportamento caso retorno seja falso
            
            if success {
                print("Chat Salvo")
                self.setChatRoomSaved()
            } else {
                print("Falha ao salvar Chat")
            }
        }
    }
    
    func reportChatRoom(completionHandler:(success: Bool) -> Void) {
        guard let chatRoom = chatRoom else { return }
        
        ChatRoomBS.reportChatRoom(chatRoom) { (success) in
            // TODO: Definir comportamento caso retorno seja falso
            print("Chat Reportado \(success)")
            completionHandler(success: success)
        }
    }
    
    func removeChatRoomOfInterest(completionHandler:(success: Bool) -> Void) {
        guard let chatRoomId = chatRoom.chatRoomId else { return }
        
        ChatRoomBS.removeChatRoomOfInterest(chatRoomId) { (success) in
            // TODO: Definir comportamento caso retorno seja falso
            if success {
                self.removeChatRoomSaved()
            }
            print("Chat Removido \(success)")
            completionHandler(success: success)
        }
    }
    
    func sendMessage(message:String) {
        ChatRoomBS.sendMsgOnChatRoom(message, type: ChatRoomMessage.MessageType.TEXT_MSG, chatRoomId: chatRoom.chatRoomId!) { (success) in
            if success {
                self.setChatRoomSaved()
            }
        }
    }
    
    func sendGiphy(gifUrl:NSURL, gifSize:CGSize) {
        let json = ["width":gifSize.width, "height":gifSize.height, "link":gifUrl.absoluteString]
        
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions.PrettyPrinted)
            if let message = String(data: jsonData, encoding: NSUTF8StringEncoding) {
                ChatRoomBS.sendMsgOnChatRoom(message, type: ChatRoomMessage.MessageType.IMAGE_MSG, chatRoomId: chatRoom.chatRoomId!, completionHandler: { (success) in
                    if success {
                        self.setChatRoomSaved()
                    }
                })
            }
        }
        catch let error as NSError {
            print(error)
        }
    }
    
    func resentMessageAtIndex(index:NSIndexPath) {
        let message = messageObjectAtIndex(index)
        ChatRoomBS.sendMessage(message, completionHandler: nil)
    }
    
    private func setChatRoomSaved() {
        guard self.chatRoom.saved != true else {
            return
        }
        
        
        self.chatRoom.saved = true
        
        if let userInfo = UserBS.getLoggedUser()?.userInfo {
            if var myChats = userInfo.myChatroomList as? [String] {
                myChats.append(chatRoom.chatRoomId!)
                userInfo.myChatroomList = myChats
            }
            else {
                userInfo.myChatroomList = [chatRoom.chatRoomId!]
            }
        }
    }
    
    private func removeChatRoomSaved() {
        self.chatRoom.saved = false
        
        if let userInfo = UserBS.getLoggedUser()?.userInfo {
            if var myChats = userInfo.myChatroomList as? [String], let index = myChats.indexOf(chatRoom.chatRoomId!) {
                
                myChats.removeAtIndex(index)
                userInfo.myChatroomList = myChats
            }
            else {
                userInfo.myChatroomList = [chatRoom.chatRoomId!]
            }
        }
    }
    
    // MARK: FecthedControllerDelegate
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        insertIndexes = [NSIndexPath]()
        deleteIndexes = [NSIndexPath]()
        reloadIndexes = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        // Prevent the iOS SDK 9 bug from NSFetchedResultsChangeType with invalid type
        guard type.rawValue > 0 else {
            return
        }
        
        
        switch (type) {
        case .Insert:
            if let indexPath = newIndexPath {
                insertIndexes!.append(indexPath)
            }
            break;
        case .Delete:
            if let indexPath = indexPath {
                deleteIndexes!.append(indexPath)
            }
            break
        case .Update:
            if let indexPath = indexPath {
                reloadIndexes!.append(indexPath)
            }
            break
        case .Move:
            if indexPath != nil && indexPath == newIndexPath {
                reloadIndexes!.append(indexPath!)
            }
            else {
                if let indexPath = indexPath {
                    deleteIndexes!.append(indexPath)
                }
                
                if let newIndexPath = newIndexPath {
                    insertIndexes!.append(newIndexPath)
                }
            }
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        delegate?.updateMessagesData(insertIndexes!, deletedIndexes: deleteIndexes!, reloadedIndexes: reloadIndexes!)
        insertIndexes = nil
        deleteIndexes = nil
        reloadIndexes = nil
    }
    
    // MARK: - (Un)Block
    func isCurrentUserBlocked(user: User) -> Bool {
        if let userId = user.userId {
            return isUserBlocked(userId)
        }
        
        return false
    }
    
    func isUserBlocked(userId: String)->Bool {
        guard let blockedList = UserBS.getLoggedUser()?.userInfo?.blockedList as? [String]  else {
            return false
        }
        
        return blockedList.contains(userId)
    }
    
    func blockBtnTitle(user: User)->String? {
        
        guard let userId = user.userId where userId != UserBS.getLoggedUser()?.userId else {
            return nil
        }
        
        if let loggedUserBlockList = UserBS.getLoggedUser()?.userInfo?.blockedList as? [String] where loggedUserBlockList.contains(userId) {
            return NSLocalizedString("Unblock", comment: "")
        }
        
        return NSLocalizedString("Block", comment: "")
    }
    
    func blockDialogTitle(user: User) -> String {
        var title = NSLocalizedString("Block", comment: "Block")
        
        if let username =  user.username {
            title = title + " " + username
        }
        else {
            title = title + " " + NSLocalizedString("BlockUserPlaceholder", comment: "this user")
        }
        
        return title
    }
    
    func blockDialogMessage(user: User)->String {
        var message = NSLocalizedString("BlockMessage", comment: "Block dialog message")
        
        if let username = user.username {
            message = username + message + username
        }
        else {
            let placeholder = NSLocalizedString("BlockUserPlaceholder", comment: "this user")
            message = placeholder + message + placeholder
        }
        
        return message
    }
    
    func blockUnblockUser(user: User, completionHandler:(success:Bool)->Void) {
        guard let userId = user.userId else {
            return
        }
        
        if let loggedUserBlockList = UserBS.getLoggedUser()?.userInfo?.blockedList as? [String] where loggedUserBlockList.contains(userId) {
            UserBS.unblockUser(userId, completionHandler: { (success) in
                completionHandler(success: success)
            })
        }
        else {
            UserBS.blockUser(userId, completionHandler: { (success) in
                completionHandler(success: success)
            })
        }
    }
    
    // MARK: Remove and block User
    func removeAndBlockUser(user: User, completionHandler:(success: Bool) -> Void) {
        
        guard let userId = user.userId, chatRoomId = chatRoom.chatRoomId else {
            completionHandler(success: false)
            return
        }
        
        UserBS.banAndBlockUserFromChatroom(userId, chatRoomId: chatRoomId) { (success) in
            completionHandler(success: success)
        }
    }
    
    func removeAndBlockUserDialogTitle() -> String {
        
        let title = NSLocalizedString("RemoveAndBlockDialogTitle", comment: "Remove and Block")
        
        return title
    }
    
    func removeAndBlockUserDialogMessage(user: User) -> String {
        
        var message = NSLocalizedString("RemoveAndBlockDialogMessage", comment: "Remove and block dialog message")
        
        if let username = user.username {
            message = "@\(username) \(message) @\(username)."
        }
        else {
            let placeholder = NSLocalizedString("RemoveAndBlockUserPlaceholder", comment: "this user")
            message = "\(placeholder) \(message) \(placeholder)."
        }
        
        return message
    }
    
    // MARK: Report User
    func reportUser(user: User, completionHandler:(success: Bool) -> Void) {
        
        UserBS.reportUser(user) { (success) in
            completionHandler(success: success)
        }
    }
    
    func reportUserDialogTitle() -> String {
        
        let title = NSLocalizedString("ReportUserDialogTitle", comment: "Report user")
        
        return title
    }
    
    func reportUserDialogMessage(user: User) -> String {
        
        var message = NSLocalizedString("ReportUserMessage", comment: "Report dialog message")
        let report = NSLocalizedString("Report", comment: "Report")
        
        if let username = user.username {
            message = "\(report) @\(username) \(message)"
        }
        else {
            let placeholder = NSLocalizedString("ReportUserPlaceholder", comment: "this user")
            message = "\(report) \(placeholder) \(message)"
        }
        
        return message
    }
    
    func thanksForReportingDialogTitle() -> String {
        
        let title = NSLocalizedString("ThanksForReportingTitle", comment: "Thank your for reporting")
        
        return title
    }
    
    func thanksForReportingDialogMessage() -> String {
        
        let message = NSLocalizedString("ThanksForReportingMessage", comment: "Thank you for reporting dialog message")
        
        return message
        
    }
    
    // MARK: Report Chat Dialog text
    func reportChatDialogTitle() -> String {
        
        let title = NSLocalizedString("ReportChatDialogTitle", comment: "Report chat")
        
        return title
    }
    
    func reportChatDialogMessage() -> String {
        
        var message = NSLocalizedString("ReportChatMessage", comment: "Report dialog message")
        let report = NSLocalizedString("Report", comment: "Report")
        
        if let chatRoomName = chatRoom.name {
            message = "\(report) \"\(chatRoomName)\" \(message)"
        }
        else {
            let placeholder = NSLocalizedString("ReportChatPlaceholder", comment: "this chat")
            message = "\(report) \(placeholder) \(message)"
        }
        
        return message
    }
    
    // MARK: Leave Chat Dialog text
    func removeChatRoomOfInterestDialogTitle() -> String {
        
        let title = NSLocalizedString("removeChatRoomOfInterestDialogTitle", comment: "Leave chat")
        
        return title
    }
    
    func removeChatRoomOfInterestDialogMessage() -> String {
        
        var message = NSLocalizedString("removeChatRoomOfInterestDialogMessagePart1", comment: "Leave chat dialog message")
        let message2 = NSLocalizedString("removeChatRoomOfInterestDialogMessagePart2", comment: "Leave chat dialog message")
        
        if let chatRoomName = chatRoom.name {
            message = "\(message) \"\(chatRoomName)\"? \(message2)"
        }
        else {
            let placeholder = NSLocalizedString("removeChatRoomOfInterestPlaceholder", comment: "this chat")
            message = "\(message) \(placeholder)? \(message2)"
        }
        
        return message
    }
    
    //MARK: Share Chat
    
    func chatRoomShareCard() -> ChatRoomShareCard? {
        
        guard let chatRoomId = chatRoom.chatRoomId else { return nil }
        
        return ChatRoomShareCard(chatRoomId: chatRoomId)
    }

}
