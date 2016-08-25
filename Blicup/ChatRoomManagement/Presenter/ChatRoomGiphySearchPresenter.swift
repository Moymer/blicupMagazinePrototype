//
//  ChatRoomGiphySearchPresenter.swift
//  Blicup
//
//  Created by Guilherme Braga on 26/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class ChatRoomGiphySearchPresenter: NSObject {

    private var giphyImages: [WebImage] = []

    var giphyPage = 0
    
    var query: String = ""
    var giphyLoading: Bool = false
    var trending: Bool = false

    let GIPHY_NUMBER_MAX_PAGE = 3
    private let GIPHY_PAGE_SIZE = 10
    private let GIPHY_ITEM_HEIGHT: CGFloat = 100

    
    // DataSource
    
    func numberOfItems() -> Int {
        return giphyImages.count
    }
    
    func removeAllItems() {
        giphyImages.removeAll()
    }
    
    func imageTmbUrlAtIndex(index: Int) -> NSURL? {
        
        let image = giphyImages[index]
            
        return image.tmbUrl
    }
    
    func imageTmbSizeAtIndex(index: Int) -> CGSize {
        
        let webImage = giphyImages[index]
        if let webImageWidth = webImage.width, let webImageHeight = webImage.height {
            
            let imageWidth:CGFloat = (webImageWidth * GIPHY_ITEM_HEIGHT) / webImageHeight
            return CGSize(width: imageWidth, height: GIPHY_ITEM_HEIGHT)
        }
        
        return CGSize(width: GIPHY_ITEM_HEIGHT, height: GIPHY_ITEM_HEIGHT)
    }
    
    func imageUrlAtIndex(index:Int) -> NSURL {
        let webImage = giphyImages[index]
        return webImage.imgUrl!
    }
    
    func imageSizeAtIndex(index:Int)->CGSize {
        let webImage = giphyImages[index]
        
        if let webImageWidth = webImage.width, let webImageHeight = webImage.height {
            return CGSize(width: webImageWidth, height: webImageHeight)
        }
        else {
            return CGSize(width: GIPHY_ITEM_HEIGHT, height: GIPHY_ITEM_HEIGHT)
        }
    }
    
    // MARK: Giphy images request
    
    func searchImagesWithQuery(query: String, trending: Bool, completionHandler: (success: Bool) -> Void) {
        
        var searchTerm = query
        if searchTerm.hasPrefix("/") {
            searchTerm.removeAtIndex(searchTerm.startIndex)
        }
        
        giphyPage = 0
        self.searchGiphyImagesWithQuery(searchTerm, trending: trending, completionHandler: { (success) in
            completionHandler(success: success)
        })
    }
    
    func loadMoreGiphyImages(completionHandler: (success: Bool) -> Void) {
        
        if self.giphyPage < GIPHY_NUMBER_MAX_PAGE {
            giphyPage += 1
            searchGiphyImagesWithQuery(self.query, trending: self.trending, completionHandler: { (success) in
                completionHandler(success: success)
            })
        }
    }
    
    func searchGiphyImagesWithQuery(query: String, trending: Bool, completionHandler: (success: Bool) -> Void) {
        
        self.query = query
        self.trending = trending
        self.giphyLoading = true
        let index = self.giphyPage * GIPHY_PAGE_SIZE
        WebImageSearchBS.fetchGiphyImagesForIndex(index, andQuery: query, trending: trending, completionHandler: { (result, query) -> Void in
            
            if self.query == query {
                
                self.giphyLoading = false
                switch (result) {
                case .Success(let webImages):
                    
                    if let unwrappedWebImages = webImages as? [WebImage] {
                        self.giphyImages += unwrappedWebImages
                    }
                    
                    completionHandler(success: true)
                    
                    break
                case .Failure(let error):
                    // TODO:
                    print("Giphy loading images error: \(error!.localizedDescription)")
                    completionHandler(success: false)
                    break
                }
            }
        })
    }
}
