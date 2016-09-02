//
//  ArticleCreationViewController.swift
//  Blicup
//
//  Created by Moymer on 30/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Photos


class ArticleCreationViewController: UIViewController, UICollectionViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate, AddAssetsProtocol {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var btnMorePics: BCCloseButton!
    @IBOutlet weak var btnCloseArticle: BCCloseButton!
    @IBOutlet weak var btnPreviewArticle: BCCloseButton!
    
    let presenter = ArticleCreationPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true
        self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        
    }
    
    override func viewWillAppear(animated: Bool) {
        if self.presenter.numberOfMedias() == 6 {
            self.btnMorePics.hidden = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidLayoutSubviews() {
        if let articleFlowLayout = collectionView.collectionViewLayout as? ArticleCreationCollectionViewFlowLayout {
            let cellWidth = collectionView.bounds.width - (articleFlowLayout.sectionInset.left + articleFlowLayout.sectionInset.right)
            articleFlowLayout.estimatedItemSize = CGSizeMake(cellWidth, 330)
        }
        
        super.viewDidLayoutSubviews()
    }
    
    // MARK: UICollectionViewDataSource
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presenter.numberOfMedias()
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let identifier = indexPath.row==0 ? "CoverCell" : "ContentCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! CoverCollectionViewCell
        
        let container = cell.viewWithTag(1)!
        container.layer.cornerRadius = 20
        
        cell.layer.shadowColor = UIColor.lightGrayColor().CGColor
        cell.layer.shadowOffset = CGSizeMake(2, 2)
        cell.layer.shadowOpacity = 0.5
        cell.layer.shadowRadius = 3.0
        cell.clipsToBounds = false
        cell.layer.masksToBounds = false
        cell.btnTrash.tag = indexPath.item
        
        let cSelector = #selector(ArticleCreationViewController.handleGesture(_:))
        let gestureRecognizer = PanDirectionGestureRecognizer(direction: PanDirection.Horizontal, target: self, action: cSelector)
        gestureRecognizer.delegate = self
        cell.vContainer.addGestureRecognizer(gestureRecognizer)
        
        presenter.getImageMedia(indexPath) { (image) in
            cell.cardMedia.image = image
        }
        
        return cell
    }
    
    
    func handleGesture(swipeGesture: UIPanGestureRecognizer) {
        let initialPosition = swipeGesture.view!.frame.origin.x
        
        if swipeGesture.state == UIGestureRecognizerState.Began || swipeGesture.state == UIGestureRecognizerState.Changed{
            let translation = swipeGesture.translationInView(swipeGesture.view!)
            if initialPosition + translation.x <= 0 && initialPosition + translation.x >= -100{
                swipeGesture.view!.center = CGPointMake(swipeGesture.view!.center.x + translation.x, swipeGesture.view!.center.y)
                swipeGesture.setTranslation(CGPointMake(0,0), inView: self.view)
            }
        }
        
        
        if swipeGesture.state == UIGestureRecognizerState.Ended {
            
            var frame = swipeGesture.view!.frame
            frame.origin.x = frame.origin.x <= -62 ? -62 : 0.0
            
            UIView.animateWithDuration(0.3, delay: 0.0, options: [UIViewAnimationOptions.TransitionFlipFromLeft], animations: {
                swipeGesture.view!.frame = frame
                }, completion: nil)
        }
        
    }
    
    // TextView Delegate
    func textViewDidChange(textView: UITextView) {
        textView.invalidateIntrinsicContentSize()
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    //MARK: Assets Protocol
    func setAssets(assets: [PHAsset]?){
        if let assets = assets {
            self.presenter.addAssets(assets)
            self.collectionView.reloadData()
        }
    }
    
    //MARK: Actions
    
    @IBAction func btnCloseArticlePressed(sender: AnyObject) {
        UIView.animateWithDuration(0.1, delay: 0.0, options: [UIViewAnimationOptions.BeginFromCurrentState], animations: {
            self.btnCloseArticle.transform = CGAffineTransformIdentity
        }) { (_) in
            
        }
    }
    
    @IBAction func btnMorePicsPressed(sender: AnyObject) {
        UIView.animateWithDuration(0.1, delay: 0.0, options: [UIViewAnimationOptions.BeginFromCurrentState], animations: {
            self.btnMorePics.transform = CGAffineTransformIdentity
        }) { (_) in
            if let viewSelectCamera = self.storyboard?.instantiateViewControllerWithIdentifier("CameraRollPager") as? CameraRollPagerTabStripController {
                viewSelectCamera.selectMoreContent = 6 - self.presenter.numberOfMedias()
                viewSelectCamera.delegateAssets = self
                self.navigationController?.presentViewController(viewSelectCamera, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func btnPreviewArticlePressed(sender: AnyObject) {
        UIView.animateWithDuration(0.1, delay: 0.0, options: [UIViewAnimationOptions.BeginFromCurrentState], animations: {
            self.btnPreviewArticle.transform = CGAffineTransformIdentity
        }) { (_) in
            
        }
    }
    
    
    @IBAction func btnDeleteCellPressed(sender: UIButton) {
        if let cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: sender.tag, inSection: 0)) as? CoverCollectionViewCell {
            UIView.animateWithDuration(0.1, delay: 0.0, options: [UIViewAnimationOptions.BeginFromCurrentState], animations: {
                cell.btnTrash.transform = CGAffineTransformIdentity
            }) { (_) in
                var frame = cell.vContainer.frame
                frame.origin.x = 0.0
                
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
                let unblock = UIAlertAction(title: NSLocalizedString("Delete Media", comment: "") , style: .Default, handler: { (action) -> Void in
                    sender.selected = !sender.selected
                    self.presenter.deleteAsset(sender.tag)
                    self.collectionView.deleteItemsAtIndexPaths([NSIndexPath(forItem: sender.tag, inSection: 0)])
                    UIView.animateWithDuration(0.3, delay: 0.0, options: [UIViewAnimationOptions.TransitionFlipFromLeft], animations: {
                        cell.vContainer.frame = frame
                        }, completion: nil)
                    
                    self.collectionView.reloadData()
                    self.collectionView.reloadSections(NSIndexSet(index: 0))
                })
                
                let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
                    UIView.animateWithDuration(0.3, delay: 0.0, options: [UIViewAnimationOptions.TransitionFlipFromLeft], animations: {
                        cell.vContainer.frame = frame
                        }, completion: nil)
                })
                
                alertController.addAction(unblock)
                alertController.addAction(cancel)
                alertController.view.tintColor = UIColor.blicupPink()
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let x = scrollView.tag
    }
    
}
