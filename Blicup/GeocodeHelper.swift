//  The MIT License (MIT)
//
//  Copyright (c) 2015 Arni Dexian
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import CoreLocation
import MapKit

typealias GeocodeHelperResultHandler = (places: [MKMapItem]?) -> ()

private let MIN_REQUEST_DELAY = 0.5

class GeocodeHelper {
    static let shared = GeocodeHelper()
    
    var completionHandler: GeocodeHelperResultHandler?
    
    var minRequestDelay = MIN_REQUEST_DELAY
    
    private weak var lastSearch: MKLocalSearch?
    private var performBlock: PerformAfterClosure?
    private var cache = NSCache()
    
    func decode(searchTerm: String, completion: GeocodeHelperResultHandler) {
        completionHandler = completion
        if searchTerm.characters.count > 0 {
            cancel()
            if let cached = cachedResult(searchTerm) {
                completeRequest(cached)
            } else {
                performBlock = performAfter(minRequestDelay, closure: {[weak self] () -> Void in
                    self?.startGeocodeSearch(searchTerm)
                    })
            }
        } else {
            completeRequest(nil)
        }
    }
    
    func cancel() {
        cancelPerformAfter(performBlock)
        lastSearch?.cancel()
    }
    
    // MARK: Private
    
    private func completeRequest(places: [MKMapItem]?) {
        completionHandler?(places: places)
    }
    
    private func startGeocodeSearch(searchTerm: String) {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchTerm
        let search = MKLocalSearch(request: request)
        search.startWithCompletionHandler { [weak self](response, error) -> Void in
            guard let response = response else {
                self?.didFailDecode(searchTerm, error: error)
                return
            }
            
            self?.didDecode(searchTerm, places: response.mapItems)
            
        }
        lastSearch = search
    }
    
    private func didFailDecode(searchTerm: String, error: NSError!) {
        switch MKErrorCode(rawValue: UInt(error.code)) {
        case .Some(.PlacemarkNotFound):
            fallthrough
        case .Some(.DirectionsNotFound):
            didDecode(searchTerm, places: nil)
        default:
            print("GeocodeHelper error decode \(searchTerm) \(error.localizedDescription)")
        }
    }
    
    private func didDecode(searchTerm: String, places: [MKMapItem]?) {
        cacheResult(searchTerm, places: places)
        completeRequest(places)
    }
    
    private func cacheResult(searchTerm: String, places: [MKMapItem]?) {
        let cachePlace = places == nil ? [MKMapItem]() : places!
        cache.setObject(cachePlace , forKey: searchTerm)
    }
    
    private func cachedResult(searchTerm: String) -> [MKMapItem]? {
        let cahced = cache.objectForKey(searchTerm) as? [MKMapItem]
        return cahced?.count > 0 ? cahced : nil
    }
}

