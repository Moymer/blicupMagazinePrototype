//
//  PublishBlicPresenter.swift
//  Blicup
//
//  Created by Guilherme Braga on 06/09/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class PublishBlicPresenter: NSObject {

    let covers = CoverMock.createMockObjects()
    var selectedCategoryIndex: NSIndexPath?
    
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
    
    func selectCategory(categoryIndex: NSIndexPath) {
        selectedCategoryIndex = categoryIndex
    }
    
    func unselectCategory() {
        selectedCategoryIndex = nil
    }
}
