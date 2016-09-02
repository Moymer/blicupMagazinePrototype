//
//  SearchPagerTabStripController.swift
//  Blicup
//
//  Created by Guilherme Braga on 01/09/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class SearchPagerTabStripController: ButtonBarPagerTabStripViewController {

    var isReload = false

    override func viewDidLoad() {
        
        buttonBarView.selectedBar.backgroundColor = UIColor.grayColor()
        buttonBarView.backgroundColor = UIColor.whiteColor()
        
        self.settings.style.buttonBarBackgroundColor =  UIColor.whiteColor()
        // buttonBar minimumLineSpacing value
        self.settings.style.buttonBarMinimumLineSpacing = 10
        // buttonBar flow layout left content inset value
        self.settings.style.buttonBarLeftContentInset = 70
        // buttonBar flow layout right content inset value
        self.settings.style.buttonBarRightContentInset = 70
        
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
        
        super.viewDidLoad()
    }

    // MARK: - PagerTabStripDataSource
    
    override func viewControllersForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        
        let storyboard = UIStoryboard(name: "Search", bundle: nil)
        let child_1 = storyboard.instantiateViewControllerWithIdentifier("SearchUserTableViewController") as! SearchUserTableViewController
        let child_2 = storyboard.instantiateViewControllerWithIdentifier("SearchUserTableViewController") as! SearchUserTableViewController
        
        child_1.itemInfo = "Stories"
        child_2.itemInfo = "People"
        
        guard isReload else {
            return [child_1, child_2]
        }
        
        var childViewControllers = [child_1, child_2]

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

}
