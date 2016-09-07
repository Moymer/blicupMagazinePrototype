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
    @IBOutlet weak var btnPublishBlic: UIButton!
    @IBOutlet weak var ivPublishArrow: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.title = "Publish Blic to:"
        btnPublishBlic.layer.cornerRadius = self.btnPublishBlic.frame.height/2
        btnPublishBlic.layer.masksToBounds = true
        btnPublishBlic.hidden = true
        ivPublishArrow.hidden = true
        btnPublishBlic.alpha = 0
        ivPublishArrow.alpha = 0
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
            cell.lblMagazineCategoryTitle.hidden = true
            cell.lblMagazineCategoryTitle.alpha = 0
            cell.lblSelectionCategory.text = presenter.titleAtIndex(indexPath.row)
        } else {
            collectionView.deselectItemAtIndexPath(indexPath, animated: false)
            cell.selected = false
            cell.selectionView.hidden = true
            cell.lblMagazineCategoryTitle.hidden = false
            cell.lblMagazineCategoryTitle.alpha = 1
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
            
            showPublishBlicBtn(show: false)
            self.collectionView(collectionView, didDeselectItemAtIndexPath: selectedCategoryIndex)
            
        } else {
            
            collectionView.selectItemAtIndexPath(indexPath, animated: false, scrollPosition: UICollectionViewScrollPosition.None)
            cell.selected = true
            presenter.selectCategory(indexPath)
            cell.lblSelectionCategory.text = presenter.titleAtIndex(indexPath.row)
            cell.setSelectionAnimated()
            showPublishBlicBtn(show: true)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        let indexPathsForVisibleItems = collectionView.indexPathsForVisibleItems()

        if let selectedCategoryIndex = presenter.selectedCategoryIndex where indexPathsForVisibleItems.contains(selectedCategoryIndex) {
            let cell : PublishBlicCategoryCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath)  as!  PublishBlicCategoryCollectionViewCell
            collectionView.deselectItemAtIndexPath(indexPath, animated: false)
            cell.selected = false
            presenter.unselectCategory()
            cell.setSelectionAnimated()
        }
    }
    
    
    func showPublishBlicBtn(show show: Bool) {
        
        let hidden = !show
        let alpha: CGFloat = show ? 1 : 0
        
        if show {
            
            self.btnPublishBlic.hidden = hidden
            ivPublishArrow.hidden = hidden
            UIView.animateWithDuration(0.3, animations: {
                self.btnPublishBlic.alpha = alpha
                self.ivPublishArrow.alpha = alpha
            })
            
        } else {
            
            UIView.animateWithDuration(0.3, animations: {
                self.btnPublishBlic.alpha = alpha
                self.ivPublishArrow.alpha = alpha
            }) { (_) in
                self.btnPublishBlic.hidden = hidden
                self.ivPublishArrow.hidden = hidden
            }
        }
    }
}
