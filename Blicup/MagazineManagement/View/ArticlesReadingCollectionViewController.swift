//
//  ArticlesReadingCollectionViewController.swift
//  Blicup
//
//  Created by Moymer on 8/31/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Photos


protocol ArticlePreviewRepositioningDelegate {
    func addImageRepositioning(key:String, zoom:CGFloat, offset :CGPoint) -> Void
    func getRepositioningFor(key:String) -> (CGFloat,CGPoint)?
}


private let reuseIdentifierOver = "CardOverCell"
private let reuseIdentifierSplited = "CardSplitCell"

enum CardMode : Int  {

    case OverCellLayout = 0
    
    case SplitCellLayout
    
    
    enum OverCellDesign : Int {
        case Dark = 0
        case Light
        case Midia
        case MidiaGradient
        
        static var count: Int { return CardMode.OverCellDesign.MidiaGradient.hashValue + 1}
    }
    enum SplitCellDesign : Int {
        case Dark = 0
        case Light
        case Midia
        static var count: Int { return CardMode.SplitCellDesign.Midia.hashValue + 1}
    }
    
    static var count: Int { return CardMode.SplitCellLayout.hashValue + 1}

}

class ArticlesReadingCollectionViewController: UICollectionViewController, ArticlePreviewRepositioningDelegate {

    let imageManager = PHCachingImageManager()
    
    private var articleCardModeLayout = CardMode.OverCellLayout
    private var articleCardModeOverDesign = CardMode.OverCellDesign.Dark
    private var articleCardModeSplitDesign = CardMode.SplitCellDesign.Dark

    private var focusedIndexPath : NSIndexPath?
    
    var presenter : ArticlePreviewPresenter = ArticlePreviewPresenter()
   
    
    var articleContent : [[String:AnyObject]] = [] {
        
        didSet{
            
            var newArticleContent : [[String:AnyObject]] = []
            var assets : [PHAsset] = []
            for var card in articleContent {
                let phAsset = card["midia"] as! PHAsset
                assets.append(phAsset)
                
                imageManager.requestImageForAsset(phAsset, targetSize: CGSize(width: 100,height: 100), contentMode: PHImageContentMode.AspectFill, options: nil, resultHandler: { (image, info) in
                     card["midiaDominantColor"] = image?.dominantColors().first
                    newArticleContent.append(card)
                })
            }
            imageManager.startCachingImagesForAssets(assets, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.AspectFill, options: nil)
            
            articleContent = newArticleContent
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
    



    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return articleContent.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let card = articleContent[indexPath.row]
        focusedIndexPath = indexPath
        
        switch articleCardModeLayout {
        case CardMode.OverCellLayout:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifierOver, forIndexPath: indexPath) as! CardContentOverCollectionCell
            
            cell.repositioningDelegate = self
            
            if presenter.onRepositioning {
                cell.startRepositioning()
            } else {
                cell.stopRepositioning()
            }
           
            
            cell.layer.shouldRasterize = true;
            cell.layer.rasterizationScale = UIScreen.mainScreen().scale;
            cell.setContentForPreview(card, imageManager: imageManager, design: articleCardModeOverDesign.rawValue)
            
            return cell
            
        case CardMode.SplitCellLayout:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifierSplited, forIndexPath: indexPath) as! CardContentSplitedCollectionCell
            
            cell.repositioningDelegate = self
            
            if presenter.onRepositioning {
                cell.startRepositioning()
            } else {
                cell.stopRepositioning()
            }
            
            cell.layer.shouldRasterize = true;
            cell.layer.rasterizationScale = UIScreen.mainScreen().scale;
            
            cell.setContentForPreview(card, imageManager: imageManager, design: articleCardModeSplitDesign.rawValue)
            
            return cell
            
        }
    
    }
    override func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
           let changeCell = cell as! CardContentOverCollectionCell
            changeCell.stopAssets()
            changeCell.stopRepositioning()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        return CGSize(width: UIScreen.mainScreen().bounds.width, height: UIScreen.mainScreen().bounds.height)
    }
    
    
     // MARK: Layout and Design change actions for content
    
    func changeLayoutAndDesign() {
        if hasMoreDesignForLayout() {
            changeDesign()
        } else {
            changeLayout()
        }
    }
    
    private func changeLayout() {
        articleCardModeLayout = CardMode(rawValue: (articleCardModeLayout.rawValue + 1 ) % CardMode.count)!
        
        articleCardModeOverDesign = CardMode.OverCellDesign(rawValue:0)!
        
        articleCardModeSplitDesign = CardMode.SplitCellDesign(rawValue:0)!
        //reload section to change with animation
        self.collectionView?.performBatchUpdates({ 
                self.collectionView?.reloadSections(NSIndexSet(index: 0))
            }, completion: nil)
        
    }
    
    
    private func changeDesign()  {
        
        switch articleCardModeLayout {
        case CardMode.OverCellLayout:
            articleCardModeOverDesign = CardMode.OverCellDesign(rawValue: (articleCardModeOverDesign.rawValue + 1 ) % CardMode.OverCellDesign.count)!
            break
        case CardMode.SplitCellLayout:
            articleCardModeSplitDesign = CardMode.SplitCellDesign(rawValue: (articleCardModeSplitDesign.rawValue + 1 ) % CardMode.SplitCellDesign.count)!
            break
            
        }
        
        //reload section to change with animation
        self.collectionView?.performBatchUpdates({
            self.collectionView?.reloadSections(NSIndexSet(index: 0))
            }, completion: nil)
        
        
    }
    
    private func hasMoreDesignForLayout() -> Bool {
        var hasMore : Bool = false
        switch articleCardModeLayout {
        case CardMode.OverCellLayout:
            hasMore = articleCardModeOverDesign.rawValue < CardMode.OverCellDesign.count - 1
            break
        case CardMode.SplitCellLayout:
            hasMore =  articleCardModeSplitDesign.rawValue < CardMode.SplitCellDesign.count - 1
            break
            
        }
        return hasMore
    }

    func doResizeAndRepositioning()
    {
        presenter.onRepositioning  = !presenter.onRepositioning
        self.collectionView?.scrollEnabled = !presenter.onRepositioning
        
        self.collectionView?.performBatchUpdates({
            self.collectionView?.reloadSections(NSIndexSet(index: 0))
            }, completion: nil)
    }
    
    //MARK: - Repositioning Delegate
    func addImageRepositioning(key:String, zoom:CGFloat, offset :CGPoint) -> Void {
        
        presenter.addArticleCardMidiaPositioning(ArticleCardMidiaPositioning(z: zoom, o: offset, k: key),cardMode: articleCardModeLayout)
    }
    
    func getRepositioningFor(key:String) -> (CGFloat,CGPoint)? {
        
        if let pos = presenter.getArticleCardMidiaPositioning(key,cardMode: articleCardModeLayout) {
            return (pos.zoom!, pos.offset!)
        }
        return nil
    }

    // MARK: UICollectionViewDelegate
    override func indexPathForPreferredFocusedViewInCollectionView(collectionView: UICollectionView) -> NSIndexPath? {
        return focusedIndexPath
    }

}
