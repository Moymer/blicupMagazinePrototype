//
//  FavoritesPresenter.swift
//  Blicup
//
//  Created by Moymer on 20/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import SwiftyJSON

protocol FavoritesPresenterDelegate:class {
    func updateTagsLists(tagsToInsert:[NSIndexPath], tagsToRemove:[NSIndexPath])
    func updateTagsLists(moveItem initialIndex:NSIndexPath, toIndex:NSIndexPath)
}


class FavoritesPresenter: NSObject {
    private var addedTagsList = [String]()
    
    weak var delegate:FavoritesPresenterDelegate?
    
    override init() {
        super.init()
        
        if let tags = UserBS.getLoggedUser()?.tagList {
            addedTagsList = tags
        }
    }
    
    
    func updateUserTags(completionHandler:(success:Bool)->Void) {
        if let user = UserBS.getLoggedUser() {
            let updateJson = [
                User.Keys.UserID.rawValue: user.userId!,
                User.Keys.Username.rawValue: user.username!,
                User.Keys.PhotoUrl.rawValue: user.photoUrl!,
                User.Keys.TagList.rawValue: addedTagsList
            ]
            
            UserBS.changeUserProfile(updateJson, completionHandler: { (success) in
                completionHandler(success: success)
            })
        }
        else {
            completionHandler(success: false)
        }
    }
    
    func addedTagsArrayIsBlank() -> Bool {
        return (addedTagsList.count == 0)
    }
    
    // MARK: - CollectionViewDataSource
    func numberOftags() -> Int {
        return self.addedTagsArrayIsBlank() ? 1 : addedTagsList.count
    }
    
    func tagAtIndex(index: Int) -> String {
        return addedTagsList[index]
    }
    
    func backgroundColor() -> UIColor {
        return UIColor.blicupPink()
    }
    
    func tagImageFromSection() -> UIImage {
        return UIImage(named: "ic_remove_tag")!
    }
    
    
    // MARK: - Updates
    func removeTagAtIndex(index:Int) {
        addedTagsList.removeAtIndex(index)
    }
    
    func addNewTag(tag:String) {
        
        if addedTagsArrayIsBlank() {
            addedTagsList.insert(tag, atIndex: 0)
            delegate?.updateTagsLists([NSIndexPath(forItem: 0, inSection: 0)], tagsToRemove: [NSIndexPath(forItem: 0, inSection: 0)])
        }
        else if addedTagsList.contains(tag) {
            let index = addedTagsList.indexOf(tag)!
            addedTagsList.removeAtIndex(index)
            addedTagsList.insert(tag, atIndex: 0)
            
            delegate?.updateTagsLists(moveItem: NSIndexPath(forItem: index, inSection: 0), toIndex: NSIndexPath(forItem: 0, inSection: 0))
        }
        else {
            addedTagsList.insert(tag, atIndex: 0)
            delegate?.updateTagsLists([NSIndexPath(forItem: 0, inSection: 0)], tagsToRemove: [])
        }
    }
}
