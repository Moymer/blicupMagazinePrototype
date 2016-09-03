//
//  SearchArticleLocationViewController.swift
//  Blicup
//
//  Created by Gustavo Tiago on 30/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import MapKit

protocol SearchArticleLocationViewControllerDelegate: class {
    func setLocation(coordinate: CLLocationCoordinate2D?, title: String?)
}

class SearchArticleLocationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    weak var handleMapSearchDelegate: SearchArticleLocationViewControllerDelegate?
    var matchingItems:[MKMapItem] = []
    
    var resultSearchController: CustomArticleLocationSearchController? = nil
    
    @IBOutlet weak var btnClose: BCCloseButton!
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var tvLocations: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true
        self.customizeSearchBarController()
    }
    
    func customizeSearchBarController() {
        resultSearchController = CustomArticleLocationSearchController(searchResultsController: nil, searchBarFrame: CGRectMake(0.0, 0.0, self.tvLocations.frame.size.width, 50.0))
        resultSearchController?.searchResultsUpdater = self
        resultSearchController?.customSearchBar.delegate = self
        let resultSearchBar = resultSearchController!.customSearchBar
        resultSearchBar.sizeToFit()
        resultSearchBar.placeholder = "Search"
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        self.activityIndicator.hidden = true
        resultSearchController?.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        self.tvLocations.tableHeaderView = resultSearchController!.customSearchBar
        
    }
    
    //MARK: SearchBar Delegate Methods
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        updateSearchResultsForSearchController(self.resultSearchController!)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        updateSearchResultsForSearchController(self.resultSearchController!)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
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
        let cell = tableView.dequeueReusableCellWithIdentifier("cellLocation")! as? SearchArticleLocationCell
        let selectedItem = matchingItems[indexPath.row].placemark
        cell?.lblTitle?.text = selectedItem.name
        cell?.lblSubtitle?.text = parseAddress(selectedItem)
        return cell!
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
        UIView.animateWithDuration(0.1, delay: 0.0, options: [UIViewAnimationOptions.BeginFromCurrentState], animations: {
            self.btnClose.transform = CGAffineTransformIdentity
        }) { (_) in
            self.handleMapSearchDelegate?.setLocation(nil, title: nil)
            self.view.endEditing(true)
            self.dismissViewControllerAnimated(true) {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    
}

extension SearchArticleLocationViewController : UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard let searchBar = searchController as? CustomArticleLocationSearchController else {
            return
        }
        
        guard let searchBarText = searchBar.customSearchBar.text else {
            return
        }
        
        self.activityIndicator.hidden = false
        self.activityIndicator.startAnimating()
        GeocodeHelper.shared.decode(searchBarText, completion: { [weak self](places) -> () in
            
            self?.activityIndicator.hidden = true
            self?.activityIndicator.stopAnimating()
            
            guard let response = places else {
                return
            }
            
            self?.matchingItems = response
            self?.tvLocations.reloadData()
            
            })
        
        //        let request = MKLocalSearchRequest()
        //        request.naturalLanguageQuery = searchBarText
        //        let search = MKLocalSearch(request: request)
        //
        //        if searchBarText.characters.count > 0 {
        //            self.activityIndicator.hidden = false
        //            self.activityIndicator.startAnimating()
        //
        //
        //            search.startWithCompletionHandler { response, error in
        //                self.activityIndicator.hidden = true
        //                self.activityIndicator.stopAnimating()
        //
        //                guard let response = response else {
        //                    return
        //                }
        //
        //                self.matchingItems = response.mapItems
        //                self.tvLocations.reloadData()
        //            }
        //        } else {
        //            self.tvLocations.reloadData()
        //        }
        //    }
    }
}

class SearchArticleLocationCell: UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblSubtitle: UILabel!
}

class ArticleLocationSearchBar: UISearchBar {
    
    var preferredFont: UIFont!
    
    var preferredTextColor: UIColor!
    
    override func setShowsCancelButton(showsCancelButton: Bool, animated: Bool) {
        super.setShowsCancelButton(false, animated: false)
    }
    
    override func drawRect(rect: CGRect) {
        
        if let index = indexOfSearchFieldInSubviews() {
            
            let searchField: UITextField = (subviews[0] ).subviews[index] as! UITextField
            
            searchField.font = preferredFont
            searchField.textColor = preferredTextColor
            searchField.frame = CGRectMake(5.0, 4.0, frame.size.width - 10.0, 30)
            searchField.layer.cornerRadius = (30)/2
            searchField.backgroundColor = UIColor.blicupGray()
            searchField.keyboardAppearance = UIKeyboardAppearance.Light
        }
        
        self.becomeFirstResponder()
        super.drawRect(rect)
    }
    
    init(frame: CGRect, font: UIFont, textColor: UIColor) {
        super.init(frame: frame)
        self.frame = frame
        preferredFont = font
        preferredTextColor = textColor
        searchBarStyle = UISearchBarStyle.Minimal
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func indexOfSearchFieldInSubviews() -> Int! {
        var index: Int!
        let searchBarView = subviews[0]
        
        for i in 0 ..< searchBarView.subviews.count {
            if searchBarView.subviews[i].isKindOfClass(UITextField) {
                index = i
                break
            }
        }
        
        return index
    }
    
}

class CustomArticleLocationSearchController: UISearchController, UISearchBarDelegate {
    
    var customSearchBar: ArticleLocationSearchBar!
    
    init(searchResultsController: UIViewController!, searchBarFrame: CGRect) {
        super.init(searchResultsController: searchResultsController)
        
        customSearchBar = ArticleLocationSearchBar(frame: searchBarFrame, font: UIFont(name: "SFUIText-Regular", size: 16)!, textColor: UIColor.blackColor())
        customSearchBar.barTintColor = UIColor.whiteColor()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
