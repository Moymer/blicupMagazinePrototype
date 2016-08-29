//
//  CameraRollCollectionViewController.swift
//  Blicup
//
//  Created by Moymer on 8/29/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import XLPagerTabStrip

private let reuseIdentifier = "assetImageCell"

class CameraRollCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, IndicatorInfoProvider  {

    
    @IBOutlet weak var collectionView: UICollectionView!
    var presenter = CameraRollPresenter()
    
    
    var itemInfo: IndicatorInfo = "View"
    


    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        presenter.loadAll { 
            self.collectionView!.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

     func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


     func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presenter.countAssets()
    }

     func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CameraRollImageCollectionViewCell
    
        cell.representedAssetIdentifier = presenter.getAssetIdentifier(indexPath)
        
        presenter.getThumbImageFromAsset(indexPath) { (image, localIdentifier) in
            if cell.representedAssetIdentifier == localIdentifier
            {
                cell.thumbnailImage = image
            }
        }
    
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let w = (UIScreen.mainScreen().applicationFrame.width - 20)/3
        return CGSize(width: w, height: w)
        
    }
    
    // MARK: - IndicatorInfoProvider
    
    func indicatorInfoForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }

}
