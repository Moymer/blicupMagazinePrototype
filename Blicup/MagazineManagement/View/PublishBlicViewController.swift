//
//  PublishBlicViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 06/09/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class PublishBlicViewController: UIViewController {

    private let presenter = PublishBlicPresenter()
    
    let kSpaceBetweenImages: CGFloat = 10
    let kNumberOfColumns: CGFloat = 3.0
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    
    // MARK: - CollectionView
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presenter.numberOfItems()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let width = (screenWidth - ((kNumberOfColumns + 1) * kSpaceBetweenImages))/kNumberOfColumns
        
        return CGSize(width: width, height: width)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("publishBlicCategoryCell", forIndexPath: indexPath) as? PublishBlicCategoryCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        if indexPath == presenter.selectedCategoryIndex {
            collectionView.selectItemAtIndexPath(indexPath, animated: false, scrollPosition: UICollectionViewScrollPosition.None)
            cell.selected = true
            cell.selectionView.hidden = false
        } else {
            collectionView.deselectItemAtIndexPath(indexPath, animated: false)
            cell.selected = false
            cell.selectionView.hidden = true
        }
        
        
        cell.lblMagazineCategoryTitle.text = presenter.titleAtIndex(indexPath.row)
        
        if let image = presenter.coverAtIndex(indexPath.row) {
            cell.ivMagazineCategory.image = image
            
            let averageColor = image.averageColor()
            if let mainColor = averageColor.rgbToInt() {
                let color = UIColor.rgbIntToUIColor(mainColor)
                cell.ivMagazineCategory.setMainColor(color.colorWithAlphaComponent(0.5))
            }
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell : PublishBlicCategoryCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath)  as!  PublishBlicCategoryCollectionViewCell
        
        
        if let selectedCategoryIndex = presenter.selectedCategoryIndex where selectedCategoryIndex == indexPath {
            
            self.collectionView(collectionView, didDeselectItemAtIndexPath: selectedCategoryIndex)
            
        } else {
            
            collectionView.selectItemAtIndexPath(indexPath, animated: false, scrollPosition: UICollectionViewScrollPosition.None)
            cell.selected = true
            presenter.selectCategory(indexPath)
            cell.lblSelectionCategory.text = presenter.titleAtIndex(indexPath.row)
            cell.setSelectionAnimated()
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        if presenter.selectedCategoryIndex != nil {
            let cell : PublishBlicCategoryCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath)  as!  PublishBlicCategoryCollectionViewCell
            collectionView.deselectItemAtIndexPath(indexPath, animated: false)
            cell.selected = false
            presenter.unselectCategory()
            cell.setSelectionAnimated()
        }
    }
}
