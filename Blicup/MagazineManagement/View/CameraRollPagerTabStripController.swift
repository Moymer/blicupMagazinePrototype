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
        super.viewDidLoad()
        
        buttonBarView.selectedBar.backgroundColor = UIColor.grayColor()
        buttonBarView.backgroundColor = UIColor.whiteColor()
    }
    
    // MARK: - PagerTabStripDataSource
    
    override func viewControllersForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        
        let storyboard = UIStoryboard(name: "Magazine", bundle: nil)
        let child_1 = storyboard.instantiateViewControllerWithIdentifier("CameraRollViewController") as! CameraRollCollectionViewController
        let child_2 = storyboard.instantiateViewControllerWithIdentifier("CameraRollViewController") as! CameraRollCollectionViewController
        let child_3 = storyboard.instantiateViewControllerWithIdentifier("CameraRollViewController") as! CameraRollCollectionViewController
        
    
        child_1.itemInfo = "All"
         child_2.itemInfo = "Images"
         child_3.itemInfo = "Videos"
        
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
