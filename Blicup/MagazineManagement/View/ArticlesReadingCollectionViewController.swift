//
//  ArticlesReadingCollectionViewController.swift
//  Blicup
//
//  Created by Moymer on 8/31/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Photos
private let reuseIdentifierOver = "CardOverCell"
private let reuseIdentifierSplited = "CardSplitCell"

class ArticlesReadingCollectionViewController: UICollectionViewController {

     let imageManager = PHCachingImageManager()
    
    var articleContent : [[String:AnyObject]] = [] {
        
        didSet{
            
            var assets : [PHAsset] = []
            for card in articleContent {
                let phAsset = card["midia"] as! PHAsset
                assets.append(phAsset)
            }
            imageManager.startCachingImagesForAssets(assets, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.AspectFill, options: nil)
            
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        self.collectionView!.decelerationRate = UIScrollViewDecelerationRateFast
        // Register cell classes
        self.collectionView!.registerClass(CardContentOverCollectionCell.self, forCellWithReuseIdentifier: reuseIdentifierOver)

        self.collectionView!.registerNib(UINib(nibName: "CardContentOverCollectionCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifierOver)
        
        
        self.collectionView!.registerClass(CardContentSplitedCollectionCell.self, forCellWithReuseIdentifier: reuseIdentifierSplited)
        
        self.collectionView!.registerNib(UINib(nibName: "CardContentSplitedCollectionCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifierSplited)
        
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation:UIStatusBarAnimation.None)
        // Do any additional setup after loading the view.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
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

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return articleContent.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifierSplited, forIndexPath: indexPath) as! CardContentSplitedCollectionCell
    
        cell.layer.shouldRasterize = true;
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale;
        
        let card = articleContent[indexPath.row]
        
        cell.setContentForPreview(card, imageManager: imageManager)
    
        return cell
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        return CGSize(width: UIScreen.mainScreen().bounds.width, height: UIScreen.mainScreen().bounds.height)
    }
    

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}
