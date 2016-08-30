//
//  CameraRollPagerTabStripController.swift
//  Blicup
//
//  Created by Moymer on 8/29/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class CameraRollPagerTabStripController: ButtonBarPagerTabStripViewController {


    
    var isReload = false
    
    override func viewDidLoad() {
       
        
        buttonBarView.selectedBar.backgroundColor = UIColor.grayColor()
        buttonBarView.backgroundColor = UIColor.whiteColor()
        
        self.settings.style.buttonBarBackgroundColor =  UIColor.whiteColor()
        // buttonBar minimumInteritemSpacing value, note that button bar extends from UICollectionView
        //settings.style.buttonBarMinimumInteritemSpacing = 6
        // buttonBar minimumLineSpacing value
        settings.style.buttonBarMinimumLineSpacing = 10
        // buttonBar flow layout left content inset value
        self.settings.style.buttonBarLeftContentInset = 30
        // buttonBar flow layout right content inset value
        self.settings.style.buttonBarRightContentInset = 30
        
        // selected bar view is created programmatically so it's important to set up the following 2 properties properly
        self.settings.style.selectedBarBackgroundColor = UIColor.grayColor()
        self.settings.style.selectedBarHeight  = 1
        
        // each buttonBar item is a UICollectionView cell of type ButtonBarViewCell
        self.settings.style.buttonBarItemBackgroundColor = UIColor.whiteColor()
        self.settings.style.buttonBarItemFont = UIFont(name: "Avenir-Black", size: 14.0)!
        // helps to determine the cell width, it represent the space before and after the title label
        self.settings.style.buttonBarItemLeftRightMargin = 12
        self.settings.style.buttonBarItemTitleColor = UIColor.blackColor()
        // in case the barView items do not fill the screen width this property stretch the cells to fill the screen
        self.settings.style.buttonBarItemsShouldFillAvailiableWidth = true
        
        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            
            oldCell?.label.textColor = UIColor(white: 0, alpha: 0.6)
            newCell?.label.textColor = .blackColor()
            
            if animated {
                UIView.animateWithDuration(0.1, animations: { () -> Void in
                    newCell?.transform = CGAffineTransformMakeScale(1.0, 1.0)
                    oldCell?.transform = CGAffineTransformMakeScale(0.8, 0.8)
                })
            }
            else {
                newCell?.transform = CGAffineTransformMakeScale(1.0, 1.0)
                oldCell?.transform = CGAffineTransformMakeScale(0.8, 0.8)
            }
        }

        
        super.viewDidLoad()
    }
    
    // MARK: - PagerTabStripDataSource
    
    override func viewControllersForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        
        let storyboard = UIStoryboard(name: "Magazine", bundle: nil)
        let child_1 = storyboard.instantiateViewControllerWithIdentifier("CameraRollViewController") as! CameraRollCollectionViewController
        let child_2 = storyboard.instantiateViewControllerWithIdentifier("CameraRollViewController") as! CameraRollCollectionViewController
        let child_3 = storyboard.instantiateViewControllerWithIdentifier("CameraRollViewController") as! CameraRollCollectionViewController
        
    
        child_1.itemInfo = "All"
        child_2.itemInfo = "Photos"
         child_2.loadingType = LoadingType.PHOTO
        child_3.itemInfo = "Videos"
        child_3.loadingType = LoadingType.VIDEO
        
        guard isReload else {
            return [child_1, child_2, child_3]
        }
        
        var childViewControllers = [child_1, child_2, child_3]
        
        for (index, _) in childViewControllers.enumerate(){
            let nElements = childViewControllers.count - index
            let n = (Int(arc4random()) % nElements) + index
            if n != index{
                swap(&childViewControllers[index], &childViewControllers[n])
            }
        }
        let nItems = 1 + (rand() % 8)
        return Array(childViewControllers.prefix(Int(nItems)))
    }
    
    override func reloadPagerTabStripView() {
        isReload = true
        if rand() % 2 == 0 {
            pagerBehaviour = .Progressive(skipIntermediateViewControllers: rand() % 2 == 0 , elasticIndicatorLimit: rand() % 2 == 0 )
        }
        else {
            pagerBehaviour = .Common(skipIntermediateViewControllers: rand() % 2 == 0)
        }
        super.reloadPagerTabStripView()
    }

/**
    
    changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
    guard changeCurrentIndex == true else { return }
    
    oldCell?.label.textColor = UIColor(white: 1, alpha: 0.6)
    newCell?.label.textColor = .whiteColor()
    
    if animated {
    UIView.animateWithDuration(0.1, animations: { () -> Void in
    newCell?.transform = CGAffineTransformMakeScale(1.0, 1.0)
    oldCell?.transform = CGAffineTransformMakeScale(0.8, 0.8)
    })
    }
    else {
    newCell?.transform = CGAffineTransformMakeScale(1.0, 1.0)
    oldCell?.transform = CGAffineTransformMakeScale(0.8, 0.8)
    }
    }*/
}
