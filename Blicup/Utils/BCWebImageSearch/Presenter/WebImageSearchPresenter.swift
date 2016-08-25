//
//  WebImageSearchPresenter.swift
//  Blicup
//
//  Created by Guilherme Braga on 27/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import ReachabilitySwift

class WebImageSearchPresenter: NSObject {
    
    let vcWebImageSearch: WebImageSearchViewController!
    
    private var giphyImages: [WebImage] = []
    private var googleImages: [WebImage] = []
    
    var giphyPage = 0
    var googlePage = 0
    
    var query: String
    
    var fetchedImagesError: Bool = false
    
    var giphyLoading: Bool = false
    var googleLoading: Bool = false
    
    let GIPHY_NUMBER_MAX_PAGE = 3
    let GOOGLE_NUMBER_MAX_PAGE = 5
    
    private let GIPHY_PAGE_SIZE = 10
    private let GOOGLE_PAGE_SIZE = 10
    
    
    required init(vcWebImageSearch: WebImageSearchViewController) {
        self.vcWebImageSearch = vcWebImageSearch
        query = ""
    }
    
    
    // MARK: Giphy, Google images request
    
    func searchGiphyImagesWithQuery(query: String) {
        
        self.giphyLoading = true
        vcWebImageSearch.reloadCollectionView(WebImageSource.Giphy)
        let index = self.giphyPage * GIPHY_PAGE_SIZE
        WebImageSearchBS.fetchGiphyImagesForIndex(index, andQuery: query, trending: false, completionHandler: { (result, query) -> Void in
            
            if self.query == query {
                
                self.giphyLoading = false
                switch (result) {
                case .Success(let webImages):
                    if let unwrappedWebImages = webImages as? [WebImage] {
                        var arrayWebImages: [WebImage] = []
                        for image in unwrappedWebImages {
                            if image.width > 0 && image.height > 0{
                                arrayWebImages.append(image)
                            }
                        }
                        self.giphyImages += arrayWebImages
                        self.vcWebImageSearch.reloadCollectionView(WebImageSource.Giphy)
                        
                        if unwrappedWebImages.count == 0 && self.giphyNumberOfItems() == 0 {
                            self.vcWebImageSearch.showlblNoImages(true, source: .Giphy)
                        }
                    }
                    
                    break
                case .Failure(let error):
                    // TODO:
                    print("Giphy loading images error: \(error!.localizedDescription)")
                    self.showConnectionError()
                    break
                }
            }
        })
    }
    
    
    func searchGoogleImagesWithQuery(query: String) {
        
        self.query = query
        
        googleLoading = true
        vcWebImageSearch.reloadCollectionView(WebImageSource.Google)
        
        let index = (self.googlePage * GOOGLE_PAGE_SIZE) + 1
        WebImageSearchBS.fetchGoogleImagesForIndex(index, andQuery: query, completionHandler: { (result, query) -> Void in
            
            if self.googlePage < 1
            {
                self.loadMoreGoogleImages()
            }
            
            if self.query == query {
                
                self.googleLoading = false
                switch (result) {
                case .Success(let webImages):
                    
                    if let unwrappedWebImages = webImages as? [WebImage] {
                        self.googleImages.appendContentsOf(unwrappedWebImages)
                        
                        if unwrappedWebImages.count == 0 && self.googleNumberOfItems() == 0 {
                            self.vcWebImageSearch.showlblNoImages(true, source: .Google)
                        }
                    }
                    
                    break
                case .Failure(let error):
                    // TODO:
                    print("Google loading images error: \(error!.localizedDescription)")
                    self.showConnectionError()
                    break
                }
                self.vcWebImageSearch.reloadCollectionView(WebImageSource.Google)
            }
        })
    }
    
    
    func searchImagesWithQuery(query: String) {
        
        fetchedImagesError = false
        
        if let reachability = try? Reachability.reachabilityForInternetConnection() {
            if reachability.isReachable() {
                googlePage = 0
                giphyPage = 0
                removeAllObjects()
                self.vcWebImageSearch.showlblNoImages(false, source: .All)
                searchGoogleImagesWithQuery(query)
                searchGiphyImagesWithQuery(query)
            } else {
                self.showConnectionError()
                self.vcWebImageSearch.showLabelNoInternet(true)
            }
        } else {
            // TODO: tratar erro de conexão
            self.showConnectionError()
            self.vcWebImageSearch.showLabelNoInternet(true)
        }
    }
    
    func showConnectionError() {
        
        if !fetchedImagesError {
            fetchedImagesError = true
            
            // TODO: Show error ao buscar
            vcWebImageSearch.showNoInternetAlert()
        }
        
    }
    
    
    // MARK: GIPHY DATASOURCE
    
    func giphyNumberOfItems() -> Int {
        return self.giphyImages.count
    }
    
    func giphyWebImageAtIndex(index: Int) -> WebImage {
        return self.giphyImages[index]
    }
    
    func loadMoreGiphyImages() {
        
        if self.giphyPage < GIPHY_NUMBER_MAX_PAGE {
            self.giphyPage += 1
            searchGiphyImagesWithQuery(self.query)
        }
    }
    
    // MARK: GOOGLE DATASOURCE
    
    func loadMoreGoogleImages() {
        
        if self.googlePage < GOOGLE_NUMBER_MAX_PAGE {
            self.googlePage += 1
            searchGoogleImagesWithQuery(self.query)
        }
    }
    
    
    func googleNumberOfItems() -> Int {
        return self.googleImages.count
    }
    
    func googleWebImageAtIndex(index: Int) -> WebImage {
        return self.googleImages[index]
    }
    
    func removeAllObjects() {
        self.giphyImages.removeAll()
        self.googleImages.removeAll()
        self.vcWebImageSearch.reloadCollectionView(WebImageSource.All)
        
    }
    
}
