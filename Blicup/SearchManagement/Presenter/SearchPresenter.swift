//
//  SearchPresenter.swift
//  Blicup
//
//  Created by Guilherme Braga on 31/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class SearchPresenter: NSObject {
    
    let covers = CoverMock.createMockObjects()
    
    func numberOfItems() -> Int {
        return self.covers.count
    }
    
    func coverAtIndex(index: Int) -> UIImage? {
        
        let cover = covers[index]
        
        return UIImage(named: cover.imageName)
    }
    
    func titleAtIndex(index: Int) -> String {
        
        let cover = covers[index]
        
        return cover.title
    }
    
    func btnMapAttributedTitle() -> NSAttributedString {
        
        let title1 = "Discover "
        let title2 = "Stories"
        let title3 = "Around the "
        let title4 = "World"
        let finalStr =  "\(title1)\(title2)\n\(title3)\(title4)"
        
        let attrFontBlack = [NSFontAttributeName : UIFont(name: "Avenir-Black", size: 16)!]
        let attrFontMedium = [NSFontAttributeName : UIFont(name: "Avenir-Medium", size: 16)!, NSForegroundColorAttributeName : UIColor.whiteColor()]
        
        let attrString = NSMutableAttributedString(string: finalStr, attributes: attrFontMedium)
        attrString.addAttributes(attrFontBlack, range: NSRange(location: title1.length, length: title2.length))
        attrString.addAttributes(attrFontBlack, range: NSRange(location: finalStr.length - title4.length, length: title4.length))
        
        return attrString
    }

}


class CoverObj: NSObject {
    
    var title = ""
    var imageName = ""
}

class CoverMock: NSObject {
    
    class func createMockObjects() -> [CoverObj] {
        
        let covers = ["activities_outdoors", "animals", "arts", "architecture", "beauty", "books_comics", "business", "cars", "design", "diy", "family", "fashion", "fitness", "food", "games", "health", "humor", "motivation", "movies_television", "nature", "photography", "science", "sports", "technology", "travel"]
        let coversTitle = ["Activies\n&\nOutdoors", "Animals", "Arts", "Architecture", "Beauty", "Books\n&\nComics", "Business", "Cars", "Design", "DIY", "Family", "Fashion", "Fitness", "Food", "Games", "Health", "Humor", "Motivation", "Movies\n&\nTelevision", "Nature", "Photography", "Science", "Sports", "Technology", "Travel"]
        
        var array: [CoverObj] = []
        for (index, imageName) in covers.enumerate() {
            let cover = CoverObj()
            cover.imageName = imageName
            cover.title = coversTitle[index]
            array.append(cover)
        }
        
        return array
    }
}