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


enum LoadingType: Int {
    case ALL, PHOTO, VIDEO
}

class CameraRollCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, IndicatorInfoProvider {
    


    @IBOutlet weak var collectionView: UICollectionView!
    var presenter = CameraRollPresenter()
    var loadingType = LoadingType.ALL
    
    var itemInfo: IndicatorInfo = "View"
    
    let c_all_space_between_images:CGFloat = 8.0
    let c_number_of_columns: CGFloat = 3.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        switch loadingType {
        case LoadingType.ALL:
            presenter.loadAll {
                self.collectionView!.reloadData()
            }
            break
            
        case LoadingType.PHOTO:
            presenter.loadPhotos {
                self.collectionView!.reloadData()
            }
            break
        case LoadingType.VIDEO:
            presenter.loadVideos {
                self.collectionView!.reloadData()
            }
            break

        }
        
    }

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
        
        let w = (UIScreen.mainScreen().applicationFrame.width - c_all_space_between_images) / c_number_of_columns
        return CGSize(width: w, height: w)
        
    }
    
    // MARK: - IndicatorInfoProvider
    
    func indicatorInfoForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }

}
