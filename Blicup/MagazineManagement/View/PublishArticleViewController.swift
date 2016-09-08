//
//  PublishArticleViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 06/09/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class PublishArticleViewController: UIViewController {

    private let presenter = PublishArticlePresenter()
    
    let kSpaceBetweenImages: CGFloat = 10
    let kNumberOfColumns: CGFloat = 3
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var btnPublishArticle: UIButton!
    @IBOutlet weak var ivPublishArrow: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        btnPublishArticle.layer.cornerRadius = self.btnPublishArticle.frame.height/2
        btnPublishArticle.layer.masksToBounds = true
        btnPublishArticle.hidden = true
        ivPublishArrow.hidden = true
        btnPublishArticle.alpha = 0
        ivPublishArrow.alpha = 0
    }
    
    
    // MARK: - CollectionView
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(kSpaceBetweenImages, kSpaceBetweenImages, kSpaceBetweenImages, kSpaceBetweenImages)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let sectionInsetLeft = kSpaceBetweenImages
        let sectionInsetRight = kSpaceBetweenImages
        let totalSpace = sectionInsetLeft + sectionInsetRight + (kSpaceBetweenImages * CGFloat(kNumberOfColumns - 1))
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(kNumberOfColumns))
        return CGSize(width: size, height: size)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presenter.numberOfItems()
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("publishArticleCategoryCell", forIndexPath: indexPath) as? PublishArticleCategoryCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        if indexPath == presenter.selectedCategoryIndex {
            collectionView.selectItemAtIndexPath(indexPath, animated: false, scrollPosition: UICollectionViewScrollPosition.None)
            cell.selected = true
            cell.selectionView.hidden = false
            cell.lblArticleCategoryTitle.hidden = true
            cell.lblArticleCategoryTitle.alpha = 0
            cell.lblSelectionCategory.text = presenter.titleAtIndex(indexPath.row)
        } else {
            collectionView.deselectItemAtIndexPath(indexPath, animated: false)
            cell.selected = false
            cell.selectionView.hidden = true
            cell.lblArticleCategoryTitle.hidden = false
            cell.lblArticleCategoryTitle.alpha = 1
        }
        
        cell.lblArticleCategoryTitle.text = presenter.titleAtIndex(indexPath.row)
        
        if let image = presenter.coverAtIndex(indexPath.row) {
            cell.ivArticleCategory.image = image
            
            let averageColor = image.averageColor()
            if let mainColor = averageColor.rgbToInt() {
                let color = UIColor.rgbIntToUIColor(mainColor)
                cell.ivArticleCategory.setMainColor(color.colorWithAlphaComponent(0.5))
            }
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell: PublishArticleCategoryCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath) as! PublishArticleCategoryCollectionViewCell
        
        
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
            let cell: PublishArticleCategoryCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath) as! PublishArticleCategoryCollectionViewCell
            collectionView.deselectItemAtIndexPath(indexPath, animated: false)
            cell.selected = false
            presenter.unselectCategory()
            cell.setSelectionAnimated()
        }
    }
    
    // MARK: Actions
    
    @IBAction func backPressed(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func showPublishBlicBtn(show show: Bool) {
        
        let hidden = !show
        let alpha: CGFloat = show ? 1 : 0
        
        if show {
            
            btnPublishArticle.hidden = hidden
            ivPublishArrow.hidden = hidden
            UIView.animateWithDuration(0.3, animations: {
                self.btnPublishArticle.alpha = alpha
                self.ivPublishArrow.alpha = alpha
            })
            
        } else {
            
            UIView.animateWithDuration(0.3, animations: {
                self.btnPublishArticle.alpha = alpha
                self.ivPublishArrow.alpha = alpha
            }) { (_) in
                self.btnPublishArticle.hidden = hidden
                self.ivPublishArrow.hidden = hidden
            }
        }
    }
}
