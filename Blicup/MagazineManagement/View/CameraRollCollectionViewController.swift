//
//  CameraRollCollectionViewController.swift
//  Blicup
//
//  Created by Moymer on 8/29/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import XLPagerTabStrip

private let reuseIdentifier = "assetCell"


enum LoadingType: Int {
    case ALL, PHOTO, VIDEO
}

class CameraRollCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, IndicatorInfoProvider, AlertControllerProtocol {
    


    @IBOutlet weak var collectionView: UICollectionView!
    
    var presenter = CameraRollPresenter()
    var assetSelector : CameraRollAssetSelector?
    
    var loadingType = LoadingType.ALL
    
    var itemInfo: IndicatorInfo = "View"
    
    let c_all_space_between_images:CGFloat = 8.0
    let c_number_of_columns: CGFloat = 3.0
    
    var selectedIndexesSet : Set<NSIndexPath> = Set()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        self.collectionView.allowsMultipleSelection = true
        
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

    override func viewWillAppear(animated: Bool) {
         self.collectionView.reloadData()
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
        cell.duration = presenter.getAssetDuration(indexPath)
        if cell.checkSelection(assetSelector!) {
            collectionView.selectItemAtIndexPath(indexPath, animated: false, scrollPosition: UICollectionViewScrollPosition.None)
            cell.selected = true
            selectedIndexesSet.insert(indexPath)
        } else {
            selectedIndexesSet.remove(indexPath)
            collectionView.deselectItemAtIndexPath(indexPath, animated: false)
            cell.selected = false
        }
        
        presenter.getThumbImageFromAsset(indexPath) { (image, localIdentifier) in
            if cell.representedAssetIdentifier == localIdentifier {
                cell.thumbnailImage = image
            }
        }
    
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let w = (UIScreen.mainScreen().applicationFrame.width - c_all_space_between_images) / c_number_of_columns
        return CGSize(width: w, height: w)
    }
    
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell : CameraRollImageCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath)  as!  CameraRollImageCollectionViewCell
        let asset = presenter.getAsset(indexPath)
        

        collectionView.selectItemAtIndexPath(indexPath, animated: false, scrollPosition: UICollectionViewScrollPosition.None)
        cell.selected = true
        assetSelector!.selectAsset(asset)
        cell.setSelectionAnimated(assetSelector!)
        selectedIndexesSet.insert(indexPath)
    }
    func collectionView(collectionView: UICollectionView,
                          shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        let asset = presenter.getAsset(indexPath)
        
        if assetSelector!.hasReachedMidiaLimit() {
            showAlert(title: "Keep it short 😜", message:"Add up to 6 medias!" )
            return false
        }
        if !assetSelector!.isAssetDurationOk(asset) {
            showAlert(title: "Keep it short 😜", message:"Add videos up to 1 min duration!" )
            return false
        }
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell : CameraRollImageCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath)  as!  CameraRollImageCollectionViewCell
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        cell.selected = false
        let asset = presenter.getAsset(indexPath)
        assetSelector!.unselectAsset(asset)
        cell.setSelectionAnimated(assetSelector!)
        selectedIndexesSet.remove(indexPath)
        reloadSelectedIndex()
    }

    
    func reloadSelectedIndex() {
        if self.selectedIndexesSet.count > 0 {
            self.collectionView.performBatchUpdates({ [weak self] in
                self!.collectionView.reloadItemsAtIndexPaths(Array(self!.selectedIndexesSet) )
            }) { (finish: Bool) in
                
            }
        }
    }
    // MARK: - IndicatorInfoProvider
    
    func indicatorInfoForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }

}
