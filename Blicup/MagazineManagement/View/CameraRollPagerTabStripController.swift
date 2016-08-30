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
            
            oldCell?.label.textColor = UIColor(white: 0, alpha: 0.70)
            newCell?.label.textColor = .blackColor()
            
            if animated {
                UIView.animateWithDuration(0.1, animations: { () -> Void in
                    newCell?.transform = CGAffineTransformMakeScale(1.0, 1.0)
                    oldCell?.transform = CGAffineTransformMakeScale(0.85, 0.85)
                })
            }
            else {
                newCell?.transform = CGAffineTransformMakeScale(1.0, 1.0)
                oldCell?.transform = CGAffineTransformMakeScale(0.85, 0.85)
            }
        }

        setNavBar()
        
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation:UIStatusBarAnimation.None)
        
        super.viewDidLoad()
    }
    
    
    func setNavBar()
    {
        self.navigationController!.navigationBar.shadowImage = UIImage()
        hideNavBarSeparator()
        self.title = "Camera Roll"

        addLeftNavItemOnView()
        

    }
    
    func addLeftNavItemOnView ()
    {
        
        // hide default navigation bar button item
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.hidesBackButton = true;
        
        
        let buttonBack: UIButton = UIButton( type: UIButtonType.Custom)
        
        buttonBack.frame = CGRectMake(6, 0, 40, 40)
        buttonBack.setImage(UIImage(named:"ic_close_black"), forState: UIControlState.Normal)
        buttonBack.addTarget(self, action: #selector(closeTapped), forControlEvents: UIControlEvents.TouchUpInside)
        
        let leftBarButtonItem: UIBarButtonItem = UIBarButtonItem(customView: buttonBack)
        
        self.navigationItem.setLeftBarButtonItem(leftBarButtonItem, animated: false)
        
        
    }
    
    func hideNavBarSeparator()
    {
        //this way transparent property continues working
        if let line = findShadowImageUnderView(self.navigationController!.navigationBar) {
            line.hidden = true
        }
    }
    private func findShadowImageUnderView(view: UIView) -> UIImageView? {
        if view is UIImageView && view.bounds.size.height <= 1 {
            return (view as! UIImageView)
        }
        
        for subview in view.subviews {
            if let imageView = findShadowImageUnderView(subview) {
                return imageView
            }
        }
        return nil
    }
    
    
    func closeTapped()
    {
        
    }
    
    // MARK: - PagerTabStripDataSource
    
    override func viewControllersForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        
        let storyboard = UIStoryboard(name: "Magazine", bundle: nil)
        let child_1 = storyboard.instantiateViewControllerWithIdentifier("CameraRollViewController") as! CameraRollCollectionViewController
        let child_2 = storyboard.instantiateViewControllerWithIdentifier("CameraRollViewController") as! CameraRollCollectionViewController
        let child_3 = storyboard.instantiateViewControllerWithIdentifier("CameraRollViewController") as! CameraRollCollectionViewController
        
        let assetSelector = CameraRollAssetSelector()
        
        child_1.assetSelector = assetSelector
        child_2.assetSelector = assetSelector
        child_3.assetSelector = assetSelector
        
        
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

}
