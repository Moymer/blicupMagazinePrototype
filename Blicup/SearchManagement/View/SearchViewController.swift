//
//  SearchViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 29/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var btnSearchBar: BCButton!
    @IBOutlet weak var collectionView: UICollectionView!
    private let searchPresenter = SearchPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        btnSearchBar.layer.cornerRadius = btnSearchBar.frame.height/2
        btnSearchBar.clipsToBounds = true
    }
    
    
    @IBAction func searchPressed(sender: AnyObject) {
        
        self.view.userInteractionEnabled = false
        btnSearchBar.transform = CGAffineTransformMakeScale(0.95, 0.95)
        UIView.animateWithDuration(0.3, animations: {
            self.btnSearchBar.transform = CGAffineTransformMakeScale(1, 1)
        }) { (_) in
            self.performSegueWithIdentifier("showSearchPagerTabStripController", sender: nil)
            self.view.userInteractionEnabled = true
        }
    }
    
    
    // MARK: - CollectionView
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchPresenter.numberOfItems()
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "headerCell", forIndexPath: indexPath)
            if let btnMap = headerView.viewWithTag(999) as? UIButton {
                
                btnMap.setAttributedTitle(searchPresenter.btnMapAttributedTitle(), forState: .Normal)
                btnMap.titleLabel?.textAlignment = NSTextAlignment.Center
                btnMap.titleLabel?.numberOfLines = 0
            }
            
            return headerView
            
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        guard let collectionCell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionCell", forIndexPath: indexPath) as? ArticleCoverCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        collectionCell.layer.cornerRadius = 10
        collectionCell.layer.masksToBounds = true
        
        collectionCell.lblArticleCoverTitle.text = searchPresenter.titleAtIndex(indexPath.row)
        
        if let image = searchPresenter.coverAtIndex(indexPath.row) {
            collectionCell.ivArticleCover.image = image
            
            
            let averageColor = image.averageColor()
            if let mainColor = averageColor.rgbToInt() {
                let color = UIColor.rgbIntToUIColor(mainColor)
                collectionCell.ivArticleCover.setMainColor(color.colorWithAlphaComponent(0.5))
            }
        }
        
        
        return collectionCell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
     
        let width = (screenWidth-40)/3
        
        return CGSize(width: width, height: width)
    }
    
    
    @IBAction func unwindFromSecondary(segue: UIStoryboardSegue) {
        
    }

}


