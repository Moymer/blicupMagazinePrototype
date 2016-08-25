//
//  ChatRoomFetchResultPresenter.swift
//  Blicup
//
//  Created by Moymer on 30/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import CoreData

protocol ChatRoomFetchResultPresenterDelegate: class {
    func chatRoomsListChanged(insertedIdexes: [NSIndexPath], deletedIndexes: [NSIndexPath], reloadedIndexes: [NSIndexPath])
}

class ChatRoomFetchResultPresenter: NSObject, NSFetchedResultsControllerDelegate, ChatRoomsListProtocol, ChatRoomReportProtocol, ChatRoomShareProtocol {
    private var insertIndexes, deleteIndexes, reloadIndexes : [NSIndexPath]?
    
    var fetchedResultsController: NSFetchedResultsController!
    
    weak var delegate: ChatRoomFetchResultPresenterDelegate? {
        didSet {
            if delegate != nil {
                fetchedResultsController.delegate = self
            }
            else {
                fetchedResultsController.delegate = nil
            }
        }
    }
    
    private func defaultSortDescriptors()->[NSSortDescriptor] {
        let creationDate = NSSortDescriptor(key: "creationDate", ascending: false)
        let gradeSortDescriptor = NSSortDescriptor(key: "grade", ascending: false)
        let sortDescriptors = [gradeSortDescriptor,creationDate]
        
        return sortDescriptors
    }
    
    func initFetchResultController(predicate predicate:NSPredicate?, sortDescriptors:[NSSortDescriptor]?) {
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "ChatRoom")
        fetchRequest.shouldRefreshRefetchedObjects = true
        
        fetchRequest.predicate = predicate
        
        if sortDescriptors != nil {
            fetchRequest.sortDescriptors = sortDescriptors
        }
        else {
            fetchRequest.sortDescriptors = self.defaultSortDescriptors()
        }
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    }

    
    internal func performFetch() {
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
        
        
        // Prevent the iOS SDK 9 bug from NSFetchedResultsChangeType with invalid type
        guard type.rawValue > 0 else {
            return
        }
        
        switch (type) {
        case .Insert:
            if let index = newIndexPath {
                insertIndexes!.append(index)
            }
            break;
        case .Delete:
            if let index = indexPath {
                deleteIndexes!.append(index)
            }
            break
        case .Update:
            if let index = indexPath {
                insertIndexInReload(index)
            }
            break
        case .Move:
            if indexPath != newIndexPath {
                if let indexPath = indexPath {
                    deleteIndexes!.append(indexPath)
                }
                
                if let newIndexPath = newIndexPath {
                    insertIndexes!.append(newIndexPath)
                }
            }
            else if indexPath != nil {
                insertIndexInReload(indexPath!)
            }
            break
        }
 
    }
    
    private func insertIndexInReload(indexPath:NSIndexPath) {
        guard reloadIndexes?.contains(indexPath) == false else {
            return
        }
        
        reloadIndexes?.append(indexPath)
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        delegate?.chatRoomsListChanged(insertIndexes!, deletedIndexes: deleteIndexes!, reloadedIndexes: reloadIndexes!)
        insertIndexes = nil
        deleteIndexes = nil
        reloadIndexes = nil
 
    }

    
    // MARK: - Chat Rooms Access
    func chatRoomsCount() -> Int {
        if let sections = fetchedResultsController.sections {
            if let sectionInfo = sections.first {
                return sectionInfo.numberOfObjects
            }
        }
        
        return 0
    }
    
    func chatRoomAtIndex(index:NSIndexPath) -> ChatRoom {
        let chat = fetchedResultsController.objectAtIndexPath(index) as! ChatRoom
        //print("Index \(index.row) Grade \(chat.grade) CreationDate \(chat.creationDate) \n")
        return chat
    }
    
    func chatRoomId(indexPath index: NSIndexPath) -> String? {
        
        guard let chatRoomId = chatRoomAtIndex(index).chatRoomId else {
            return nil
        }
        
        return chatRoomId
    }
}
