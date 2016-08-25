//
//  ChatRoomContextMenuPresenter.swift
//  Blicup
//
//  Created by Guilherme Braga on 11/07/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

protocol ChatRoomContextMenuProtocol {

    var contextMenuImagesName: [String] { get set }
    var contextMenuHighlightedImagesName: [String] { get set }
    var contextMenuHighlightedImagesTitle: [String] { get set }
    
    func contextMenuNumberOfItems() -> Int
    func contextMenuImageForItem(index: Int) -> UIImage
    func contextMenuHighlightedImage(index: Int) -> UIImage?
    func contextMenuHighlightedImageTitleForItem(index: Int) -> String
}

    
extension ChatRoomContextMenuProtocol {
    
    
    //MARK: - Context Menu
    
    func contextMenuNumberOfItems() -> Int {
        return self.contextMenuImagesName.count
    }
    
    func contextMenuImageForItem(index: Int) -> UIImage {
        let imageName =  self.contextMenuImagesName[index]
        let image = UIImage(named: imageName)!
        return image
    }
    
    
    func contextMenuHighlightedImage(index: Int) -> UIImage? {
        
        let imageName = self.contextMenuHighlightedImagesName[index]
        guard let image = UIImage(named: imageName) else {
            return nil
        }
        
        return image
    }
    
    func contextMenuHighlightedImageTitleForItem(index: Int) -> String {
        
        return self.contextMenuHighlightedImagesTitle[index]
    }

}
