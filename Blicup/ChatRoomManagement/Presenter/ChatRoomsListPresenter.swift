//
//  ChatRoomsListPresenter.swift
//  Blicup
//
//  Created by Guilherme Braga on 31/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import CoreData

@objc protocol ChatRoomsListPresenterDelegate: class {
    func chatRoomsListChanged(insertedIdexes: [NSIndexPath], deletedIndexes: [NSIndexPath], reloadedIndexes: [NSIndexPath])
    optional func showMessagePrewview(photo photoUrl:NSURL?, user:String?, message:String?, isUpdating: Bool)
}

class ChatRoomsListPresenter: NSObject, NSFetchedResultsControllerDelegate {
    
    private var contextMenuImagesName = ["facebook-white", "pinterest-white", "twitter-white"]
    
    private var insertIndexes, deleteIndexes, reloadIndexes : [NSIndexPath]?
    
    weak var delegate: ChatRoomsListPresenterDelegate? {
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
        let fetchRequest = NSFetchRequest(entityName: "ChatRoom")
        fetchRequest.includesSubentities = true
        fetchRequest.includesPendingChanges = true
        fetchRequest.shouldRefreshRefetchedObjects = true
        let creationDate = NSSortDescriptor(key: "creationDate", ascending: false)
        let gradeSortDescriptor = NSSortDescriptor(key: "grade", ascending: false)
        fetchRequest.sortDescriptors = [gradeSortDescriptor,creationDate]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }()
    
    
    convenience init(withLocalChats chatIds:[String]) {
        self.init()
        
        let predicate = NSPredicate(format: "chatRoomId IN %@", chatIds)
        self.fetchedResultsController.fetchRequest.predicate = predicate
        performFetch()
    }
    
    convenience init(withLocalBase:Bool) {
        self.init()
        if withLocalBase {
            performFetch()
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    func chatRoomsIds()->[String] {
        if let allObjects = self.fetchedResultsController.fetchedObjects as? [ChatRoom] {
            return allObjects.map({ $0.chatRoomId! })
        }
        
        return [String]()
    }
    
    private func performFetch() {
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
    }
    
    
    // MARK: FecthedControllerDelegate
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertIndexes = [NSIndexPath]()
        deleteIndexes = [NSIndexPath]()
        reloadIndexes = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
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
            if let indexPath = indexPath {
                deleteIndexes!.append(indexPath)
            }
            
            if let newIndexPath = newIndexPath {
                insertIndexes!.append(newIndexPath)
            }
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        delegate?.chatRoomsListChanged(insertIndexes!, deletedIndexes: deleteIndexes!, reloadedIndexes: reloadIndexes!)
        insertIndexes = nil
        deleteIndexes = nil
        reloadIndexes = nil
    }
    
    
    
    // MARK: - Chat Accessors
    func chatRoomAtIndex(index:Int) -> ChatRoom {
        let indexPath = NSIndexPath(forItem: index, inSection: 0)
        let chat = fetchedResultsController.objectAtIndexPath(indexPath) as! ChatRoom
        return chat
    }
    
    
    func startUpdatingChat(index:Int) {
        let chatRoom = chatRoomAtIndex(index)
        ChatRoomBS.getChatroomMsgsSinceLastUpdate(chatRoom.chatRoomId!, completionHandler: nil)
        ChatRoomBS.enterChatRoom(chatRoom.chatRoomId!, completionHandler: nil)
        BlicupAsyncHandler.sharedInstance.addObserveToMessagesUpdates(self, rSelector: #selector(ChatRoomsListPresenter.didReceivedChatRoomMessage(_:)), chatroom: chatRoom)

    }
    
    func stopUpdatingChat(index:Int) {
        let chatRoom = chatRoomAtIndex(index)
        ChatRoomBS.leaveChatRoom(chatRoom.chatRoomId!, completionHandler: nil)
        BlicupAsyncHandler.sharedInstance.removeObserveToMessagesUpdates(self, chatroom: chatRoom)
    }
    
    func didReceivedChatRoomMessage(notification:NSNotification) {
        let message = notification.userInfo?["message"] as? ChatRoomMessage
        let isUpdating = notification.userInfo?["isUpdating"] as? Bool
        
        var userPhoto:NSURL?
        if let photoUrl = message?.whoSent?.photoUrl {
           userPhoto = NSURL(string: photoUrl)
        }
        
        var userName = message?.whoSent?.username
        if userName != nil {
            userName = "@"+userName!
        }
        
        var content = message?.content
        if message?.msgType?.integerValue == ChatRoomMessage.MessageType.IMAGE_MSG.rawValue {
            content = "🎥GIF"
        }
        
        delegate?.showMessagePrewview?(photo: userPhoto, user: userName, message: content, isUpdating: isUpdating!)
    }
    
    
    func numberOfItems() -> Int {
        if let sections = fetchedResultsController.sections {
            if let sectionInfo = sections.first {
                return sectionInfo.numberOfObjects
            }
        }
        
        return 0
    }
    
    
    func photoUrlList(index: Int) -> [String] {
        let chatRoom = chatRoomAtIndex(index)
        var urlArray = [String]()
        
        guard let photoList = chatRoom.photoList else {
            return urlArray
        }
        
        for photo in photoList {
            if let photoUrl = (photo as! Photo).photoUrl {
                urlArray.append(photoUrl)
            }
        }
        
        return urlArray
    }
    
    
    func whoCreated(index: Int) -> User? {
        let chatRoom = chatRoomAtIndex(index)
        let user = chatRoom.whoCreated
        
        return user
    }
    
    //MARK: - Context Menu
    
    func contextMenuNumberOfItems() -> Int {
        return self.contextMenuImagesName.count
    }
    
    func contextMenuImageForItem(index: Int) -> UIImage {
        let imageName =  self.contextMenuImagesName[index]
        let image = UIImage(named: imageName)!
        return image
    }
    
    
    // MARK: New Presenter Methods
    func chatRoomId(forIndex index:Int)->String? {
        let chat = chatRoomAtIndex(index)
        return chat.chatRoomId
    }
    
    func chatroomLastUpdate(forIndex index:Int) -> Double {
        let chatRoom = chatRoomAtIndex(index)
        
        if  chatRoom.lastMsgDate?.doubleValue > 0
        {
            return (chatRoom.lastMsgDate?.doubleValue)!
        }
        else
        {
            return (chatRoom.creationDate?.doubleValue)!
        }

    }
    
    func chatRoomOwnerName(forIndex index:Int)->String? {
        let user = whoCreated(index)
        return user?.username
    }
    
    func chatRoomOwnerPhotoUrl(forIndex index:Int)->NSURL? {
        guard let urlString = whoCreated(index)?.photoUrl else {
            return nil
        }
        
        return NSURL(string:urlString)
    }
    
    func chatRoomAddress(forIndex index:Int)-> NSAttributedString? {
        
        let chat = chatRoomAtIndex(index)
        
        guard let address = chat.address?.formattedAddress else {
            return nil
        }
        
        let addressComponents = address.componentsSeparatedByString(",")
        
        var stringFormatted = ""
        for string in addressComponents {
            stringFormatted += string + ", "
        }
        
        stringFormatted = String(stringFormatted.characters.dropLast().dropLast())
        
        guard let firstDataRange = stringFormatted.rangeOfString(",") else {
            return NSAttributedString(string: address, attributes: [NSFontAttributeName:UIFont(name: "SFUIText-Bold", size: 14)!])
        }
        
        let length = address.startIndex.distanceTo(firstDataRange.startIndex)
        
        let attrString = NSMutableAttributedString(string: stringFormatted, attributes:[NSFontAttributeName:UIFont(name: "SFUIText-Regular", size: 14)!])
        attrString.addAttributes([NSFontAttributeName:UIFont(name: "SFUIText-Bold", size: 14)!], range: NSMakeRange(0, length))
        
        return attrString
    }
    
    func chatRoomName(forIndex index:Int)->String? {
        let chat = chatRoomAtIndex(index)
        return chat.name
    }
    
    func chatRoomNumberOfParticipants(index:Int)->Int {
        let chat = chatRoomAtIndex(index)
        return chat.participantCount!.integerValue
    }
    
    func chatRoomHashtags(forIndex index:Int)->String? {
        let chat = chatRoomAtIndex(index)
        
        guard let hashtags = chat.tagList else{
            return nil
        }
        
        return hashtags.convertToBlicupHashtagString()
    }
    
    func chatRoomParticipantPhotoURL(chatRoomIndex index:Int, participantIndex:Int)->NSURL? {
        let chatroom = chatRoomAtIndex(index)
        
        guard let user =  chatroom.participantList?.objectAtIndex(participantIndex) as? User else {
            return nil
        }
        
        guard !isBlockingMe(user.userId!), let urlString = user.photoUrl else {
            return nil
        }
        
        return NSURL(string:urlString)
    }
    
    private func isBlockingMe(userId:String)->Bool {
        guard let blockerList = UserBS.getLoggedUser()?.userInfo?.blockerList as? [String] else {
                return false
        }
        
        return blockerList.contains(userId)
    }
    
    
    func chatRoomParticipantsCount(spaceSize:CGSize, forIndex index: Int )->Int {
        
        let chatroom = chatRoomAtIndex(index)
        let photoSideSize = spaceSize.height
        let photosSpacement:CGFloat = 8
        
        let numberOfPhotos = floor((spaceSize.width+photosSpacement)/(photoSideSize+photosSpacement))
        var participantCountWithPhotos = Int(numberOfPhotos)
        
        if let count = chatroom.participantList?.count
        {
            participantCountWithPhotos =  min(participantCountWithPhotos, count)
        }
        
        return participantCountWithPhotos
    }
    
    func mainColor(index: Int) -> UIColor? {
        let chatRoom = chatRoomAtIndex(index)
        if let photoList = chatRoom.photoList {
            
            if let photo = photoList.firstObject as? Photo {
                
                if let mainColor = photo.mainColor as? Int {
                    
                    let color = UIColor.rgbIntToUIColor(mainColor)
                    return color
                }
            }
        }
        
        return nil
    }
}




// MARK: Presenter common to all controllers that display a list of chat rooms
class ChatRoomListControllerPresenter: ChatRoomsListPresenter {
    
    
    override init() {
        super.init()
        
        let predicate = NSPredicate(format: "grade != nil")
        self.fetchedResultsController.fetchRequest.predicate = predicate

    }
    
    func getCellSize(index: Int) -> CGSize {
        
        let chatRoom = chatRoomAtIndex(index)
        if let photo = chatRoom.photoList?.firstObject as? Photo {
            let cellHeight = CGFloat(photo.height!)
            let cellWidth = CGFloat(photo.width!)
            return CGSizeMake(cellWidth, cellHeight)
        }
        
        return CGSizeMake(170, 300)
    }
    
    func getChatItemSizeForLines(totalOfLines:Int) -> CGSize{
        var sizeImage = CGSize()
        
        switch totalOfLines {
        case 1..<3:
            sizeImage = CGSize(width: 345, height: 345)
        case 3..<5:
            sizeImage = CGSize(width: 345, height: 516)
        case 5..<8:
            sizeImage = CGSize(width: 345, height: 614)
        case 8..<11:
            sizeImage = CGSize(width: 345, height: 802)
        default:
            sizeImage = CGSize(width: 345, height: 802)
        }
        return sizeImage
    }
}


// MARK: Presenter for the main Chat Rooms List
class ChatRoomMainListPresenter: ChatRoomListControllerPresenter {
    
    func updateChatRoomList(completionHandler: (success: Bool) -> Void) {
        ChatRoomBS.getChatRooms(deleteOldEntries: true) { (success, chatRoomsList) in
            self.performFetch()
            completionHandler(success: success)
        }
    }
    
    func getMoreChatRooms(completionHandler:((success:Bool)->Void)?) {
        ChatRoomBS.getChatRooms(deleteOldEntries: false) { (success, chatRoomsList) in
            completionHandler?(success: success)
        }
    }
}


// MARK: Presenter for the Chat Rooms List shown from the map
//class ChatRoomMapListPresenter: ChatRoomListControllerPresenter {
//}

// MARK: Presenter for the Search Chat Rooms
class ChatRoomSearchListPresenter: ChatRoomListControllerPresenter {
    
    var searchTerm = ""
    var searchTermTimestamp: NSTimeInterval = 0.0
    
    func clearChats() {
        let predicate = NSPredicate(format: "chatRoomId IN %@", [String]())
        self.fetchedResultsController.fetchRequest.predicate = predicate
        performFetch()
    }
    
    func searchChatRoomsWithSearchTerm(searchTerm: String, timestamp: NSTimeInterval, completionHandler:(success: Bool) -> Void) {
        self.searchTerm = searchTerm
        searchTermTimestamp = timestamp
        
        ChatRoomBS.getChatroomsThatMatchesSearchTerm(searchTerm) { (searchTerm, success, chatRoomsIdList) in
            
            if timestamp == self.searchTermTimestamp {
                
                if success {
                    var chatIds = chatRoomsIdList
                    if chatIds == nil { chatIds = [String]() }
                    self.fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "chatRoomId IN %@", chatIds!)
                    self.performFetch()
                }
                
                completionHandler(success: success)
            }
        }
    }
    
    func tagAlreadyInUserTagList(tag: String) -> Bool {
        
        guard let user = UserBS.getLoggedUser() else {
            return false
        }
        
        if let tagList = user.tagList {
            return tagList.contains(tag)
        }
        
        return false
    }
    
    func setTagInUser(completionHandler:(success: Bool) -> Void) {
        if let user = UserBS.getLoggedUser() {
            if var tagList = user.tagList {
                
                tagList.append(searchTerm)
                
                let updateJson = [
                    User.Keys.UserID.rawValue: user.userId!,
                    User.Keys.Username.rawValue: user.username!,
                    User.Keys.PhotoUrl.rawValue: user.photoUrl!,
                    User.Keys.TagList.rawValue: tagList
                ]
                
                UserBS.changeUserProfile(updateJson, completionHandler: { (success) in
                    completionHandler(success: success)
                })
            }
        } else {
            completionHandler(success: false)
        }
    }
}
