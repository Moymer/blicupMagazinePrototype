//
//  InterestPresenter.swift
//  Blicup
//
//  Created by Guilherme Braga on 17/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import SwiftyJSON

private let LOCAL_TAGS_JSON_NAME = NSLocalizedString("default_tags", comment: "default_tags")
let LETTERS_AND_NUMBERS_PATTERN = "[^A-zÀ-ú0-9_]"
let TAG_LIMIT_LENGTH = 25

class InterestPresenter: NSObject {

    unowned let vcInterest: InterestListViewController
    let NUMBER_OF_SECTIONS = 2
    
    
    private var addedTags:[String] = []
    private var tags:[String] = []
    
    init(interestViewController: InterestListViewController) {
        self.vcInterest = interestViewController
        let tags = InterestPresenter.getTagsJson()
        self.tags = tags
    }
    

    func setTagsInUser(completionHandler:(success:Bool)->Void) {
        if let user = UserBS.getLoggedUser() {
            let updateJson = [
                User.Keys.UserID.rawValue: user.userId!,
                User.Keys.Username.rawValue: user.username!,
                User.Keys.PhotoUrl.rawValue: user.photoUrl!,
                User.Keys.TagList.rawValue: addedTags,
                //Will we use this same dictionary to update user, so we need this date as the server won't return it
                User.Keys.LastUpdated.rawValue: NSDate().timeIntervalSince1970*1000 // Server send time in milliseconds
            ]
            
            UserBS.changeUserProfile(updateJson, completionHandler: { (success) in
                completionHandler(success: success)
            })
        }
        else {
            completionHandler(success: false)
        }
    }
    
    // MARK: - Keyboard
    
    private class func getTagsJson() -> [String] {
        
        var tags:[String] = []
        
        if let path = NSBundle.mainBundle().pathForResource(LOCAL_TAGS_JSON_NAME, ofType: "json") {
            do {
                let data = try NSData(contentsOfURL: NSURL(fileURLWithPath: path), options: NSDataReadingOptions.DataReadingMappedIfSafe)
                
                if let jsonDic = JSON(data: data).dictionary {
                    
                    if let jsonArray = jsonDic["tags"]?.array {
                        
                        for tag in jsonArray {
                            if let tag = tag.string {
                                tags.append(tag)
                            }
                        }
                    }
                } else {
                    print("could not get json from file, make sure that file contains valid json.")
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } else {
            print("Invalid filename/path.")
        }
        
        return tags
    }

    
    // MARK: - CollectionViewDataSource
    
    func numberOfSections() -> Int {
        return NUMBER_OF_SECTIONS
    }
    
    func numberOfItemsInSection(section section: Int) -> Int {
        
        if section == 0 {
            return self.addedTagsArrayIsBlank() ? 1 : self.numberOfAddedTags()
        } else {
            return tags.count
        }
    }
    
    func numberOfAddedTags() -> Int {
        return self.addedTags.count
    }
    
    func tagAtIndex(index index: Int, section: Int) -> String {
        
        if section == 0 {
            return addedTags[index]
        } else {
            return tags[index]
        }
    }
    
    func backgroundColor(section section: Int) -> UIColor {
        return (section == 0 ? UIColor.blicupPink() : UIColor.blicupPurple())
    }
    
    func tagImageFromSection(section section: Int) -> UIImage {
        return (section == 0 ? UIImage(named: "ic_remove_tag") : UIImage(named: "ic_add_tag"))!
    }
    
    func addedTagsArrayIsBlank() -> Bool {
        return addedTags.count == 0 ? true : false
    }
    
    func insertTagToAddedArray(tag: String) {
    
        self.addedTags.insert(tag, atIndex: 0)
        self.vcInterest.updateBtnContinue()
    }
    
    func insertTag(tag: String, index: Int) {
        self.tags.insert(tag, atIndex: index)
    }
    
    func removeTagAtIndex(index: Int) {
        self.tags.removeAtIndex(index)
    }
    
    func removeTagFromAddedArray(indexPath: NSIndexPath) {
        
        self.addedTags.removeAtIndex(indexPath.row)
        self.vcInterest.updateBtnContinue()
    }
    
    func moveTagFromAddedToFirstIndex(oldIndex: NSIndexPath) {
        
        let tag = self.tagAtIndex(index: oldIndex.row, section: oldIndex.section)
        self.removeTagFromAddedArray(oldIndex)
        self.insertTagToAddedArray(tag)
    }
    
    
    func arraysContainsTag(tag: String) -> (indexPath: NSIndexPath, status: InterestListViewController.TagStatus) {
        
        if let index = addedTags.indexOf(tag) {
            
            let indexPath = NSIndexPath(forItem: index, inSection: 0)
            return (indexPath, InterestListViewController.TagStatus.Added)
            
        } else if let index = tags.indexOf(tag) {
            
            let indexPath = NSIndexPath(forItem: index, inSection: 1)
            return (indexPath, InterestListViewController.TagStatus.Suggested)
            
        } else {
            
            let indexPath = NSIndexPath(forItem: 0, inSection: 0)
            return (indexPath, InterestListViewController.TagStatus.NotFound)
        }
        
    }
}

