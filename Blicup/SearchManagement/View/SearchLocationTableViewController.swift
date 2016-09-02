//
//  SearchLocationViewController.swift
//  Blicup
//
//  Created by Gustavo Tiago on 18/07/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import MapKit

protocol HandleMapSearch: class {
    func setLocation(coordinate: CLLocationCoordinate2D?, title: String?)
}

class SearchLocationTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    weak var handleMapSearchDelegate: HandleMapSearch?
    var matchingItems:[MKMapItem] = []
    
    @IBOutlet weak var tvLocations: UITableView!
    var resultSearchController: CustomLocationSearchController? = nil
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Locations"
        
        resultSearchController = CustomLocationSearchController(searchResultsController: nil)
        resultSearchController?.searchResultsUpdater = self
        let resultSearchBar = resultSearchController!.searchBar
        resultSearchBar.sizeToFit()
        resultSearchBar.placeholder = "Find a location"
        self.tvLocations.tableHeaderView = resultSearchController!.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        self.activityIndicator.hidden = true
        resultSearchController?.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
    }
    
    
    func parseAddress(selectedItem:MKPlacemark) -> String {
        // put a space between "4" and "Melrose Place"
        let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
        // put a comma between street and city/state
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        // put a space between "Washington" and "DC"
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            // street number
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // street name
            selectedItem.thoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            secondSpace,
            // state
            selectedItem.administrativeArea ?? ""
        )
        return addressLine
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cellLocation")!
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = parseAddress(selectedItem)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedItem = matchingItems[indexPath.row].placemark
        handleMapSearchDelegate?.setLocation(selectedItem.coordinate, title: selectedItem.name!)
        self.view.endEditing(true)
        self.dismissViewControllerAnimated(true) {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func cancelSelectionOfLocation(sender: AnyObject) {
        handleMapSearchDelegate?.setLocation(nil, title: nil)
        self.view.endEditing(true)
        self.dismissViewControllerAnimated(true) {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
}

extension SearchLocationTableViewController : UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard
            let searchBarText = searchController.searchBar.text else { return }
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBarText
        let search = MKLocalSearch(request: request)
        
        if searchBarText.characters.count > 0 {
            self.activityIndicator.hidden = false
            self.activityIndicator.startAnimating()
            
            
            search.startWithCompletionHandler { response, _ in
                guard let response = response else {
                    return
                }
                
                self.activityIndicator.hidden = true
                self.activityIndicator.stopAnimating()
                
                self.matchingItems = response.mapItems
                self.tvLocations.reloadData()
            }
        } else {
            self.tvLocations.reloadData()
        }
    }
}

class LocationSearchBar: UISearchBar {
    
    override func setShowsCancelButton(showsCancelButton: Bool, animated: Bool) {
        super.setShowsCancelButton(false, animated: false)
    }
    
}

class CustomLocationSearchController: UISearchController, UISearchBarDelegate {
    
    lazy var _searchBar: LocationSearchBar = {
        [unowned self] in
        let customSearchBar = LocationSearchBar(frame: CGRectZero)
        customSearchBar.delegate = self
        return customSearchBar
        }()
    
    override var searchBar: UISearchBar {
        get {
            return _searchBar
        }
    }
    
}
