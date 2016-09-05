//
//  ArticleCreationViewController.swift
//  Blicup
//
//  Created by Moymer on 30/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Photos


class ArticleCreationViewController: UIViewController, UICollectionViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate, AddAssetsProtocol, SearchArticleLocationViewControllerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var btnMorePics: BCCloseButton!
    @IBOutlet weak var btnCloseArticle: BCCloseButton!
    @IBOutlet weak var btnPreviewArticle: BCCloseButton!
    
    let presenter = ArticleCreationPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        self.view.layoutIfNeeded()
        
        if let articleFlowLayout = collectionView.collectionViewLayout as? ArticleCreationCollectionViewFlowLayout {
            let verticalInsets = (collectionView.bounds.height - 330)/2
            articleFlowLayout.sectionInset = UIEdgeInsetsMake(verticalInsets, 20, verticalInsets, 20)
            let cellWidth = collectionView.bounds.width - (articleFlowLayout.sectionInset.left + articleFlowLayout.sectionInset.right)
            articleFlowLayout.estimatedItemSize = CGSizeMake(cellWidth, 330)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if self.presenter.numberOfMedias() == 6 {
            self.btnMorePics.hidden = true
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        startObservingKeyboardEvents()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopObservingKeyboardEvents()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: Location Delegate
    func setLocation(coordinate: CLLocationCoordinate2D?, title: String?) {
        guard let cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as? CardCollectionViewCell else {
            return
        }
        
        cell.content = title
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as! CardCollectionViewCell
        
        cell.btnTrash.tag = indexPath.item
        
        let cSelector = #selector(ArticleCreationViewController.handleGesture(_:))
        let gestureRecognizer = PanDirectionGestureRecognizer(direction: PanDirection.Horizontal, target: self, action: cSelector)
        gestureRecognizer.delegate = self
        cell.vContainer.addGestureRecognizer(gestureRecognizer)
        
        presenter.getImageMedia(indexPath) { (image) in
            cell.cardMedia.image = image
        }
        
        cell.title = presenter.getCardTitle(indexPath)
        cell.content = presenter.getCardContent(indexPath)
        
        return cell
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        scrollView.endEditing(true)
        let centerPoint = CGPointMake(scrollView.contentOffset.x + scrollView.bounds.width/2, scrollView.contentOffset.y + scrollView.bounds.height/2)
        returnCellToOriginalPosition(centerPoint)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let centerPoint = CGPointMake(scrollView.contentOffset.x + scrollView.bounds.width/2, scrollView.contentOffset.y + scrollView.bounds.height/2)
        
        guard let centerIndex = collectionView.indexPathForItemAtPoint(centerPoint) else {
            return
        }
        
        for cell in collectionView.visibleCells() {
            if let cardCell = cell as? CardCollectionViewCell {
                cardCell.isFocusCell = (collectionView.indexPathForCell(cell) == centerIndex)
            }
        }
    }
    
    
    //MARK: Cell Operations
    
    func handleGesture(swipeGesture: UIPanGestureRecognizer) {
        let initialPosition = swipeGesture.view!.frame.origin.x
        let centerPoint = CGPointMake(collectionView.contentOffset.x + collectionView.bounds.width/2, collectionView.contentOffset.y + collectionView.bounds.height/2)
        let translation = swipeGesture.translationInView(swipeGesture.view!)
        
        if swipeGesture.state == UIGestureRecognizerState.Began || swipeGesture.state == UIGestureRecognizerState.Changed{
            if initialPosition + translation.x <= 0 && initialPosition + translation.x >= -100{
                swipeGesture.view!.center = CGPointMake(swipeGesture.view!.center.x + translation.x, swipeGesture.view!.center.y)
                swipeGesture.setTranslation(CGPointMake(0,0), inView: self.view)
                
                if let centerIndex = collectionView.indexPathForItemAtPoint(centerPoint) {
                    if let cell = collectionView.cellForItemAtIndexPath(centerIndex) as? CardCollectionViewCell {
                        cell.btnTrash.alpha = abs(initialPosition)/100
                    }
                    
                }
            }
        }
        else if swipeGesture.state == UIGestureRecognizerState.Ended {
            var frame = swipeGesture.view!.frame
            frame.origin.x = frame.origin.x <= -62 ? -62 : 0.0
            
            UIView.animateWithDuration(0.3, delay: 0.0, options: [UIViewAnimationOptions.TransitionFlipFromLeft], animations: {
                swipeGesture.view!.frame = frame
                }, completion: nil)
            
            if let centerIndex = collectionView.indexPathForItemAtPoint(centerPoint) {
                if let cell = collectionView.cellForItemAtIndexPath(centerIndex) as? CardCollectionViewCell {
                    cell.btnTrash.alpha = abs(frame.origin.x)
                }
            }
        }
        
    }
    
    func returnCellToOriginalPosition(centerPoint: CGPoint) {
        guard let centerIndex = collectionView.indexPathForItemAtPoint(centerPoint) else {
            return
        }
        
        if let cell = collectionView.cellForItemAtIndexPath(centerIndex) as? CardCollectionViewCell {
            var frame = cell.vContainer.frame
            frame.origin.x =  0.0
            
            UIView.animateWithDuration(0.2, delay: 0.0, options: [UIViewAnimationOptions.TransitionFlipFromLeft], animations: {
                cell.vContainer.frame = frame
                }, completion: nil)
        }
    }
    
    // TextView Delegate
    private func centerTextViewCell(textView:UITextView) {
        let rect = collectionView.convertRect(textView.bounds, fromView: textView)
        collectionView.scrollRectToVisible(rect, animated: true)
    }
    
    func textViewDidChange(textView: UITextView) {
        textView.invalidateIntrinsicContentSize()
        self.collectionView.collectionViewLayout.invalidateLayout()
        centerTextViewCell(textView)
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        centerTextViewCell(textView)
    }

    func textViewDidEndEditing(textView: UITextView) {
        let point = collectionView.convertPoint(CGPointZero, fromView: textView)
        guard let index = collectionView.indexPathForItemAtPoint(point),
            let cell = collectionView.cellForItemAtIndexPath(index) as? CardCollectionViewCell else {
            return
        }
        
        presenter.setCardTexts(index, title: cell.title, content: cell.content)
    }
    
    
    // MARK: Keyboard
    private func startObservingKeyboardEvents() {
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:#selector(self.keyboardWillShow(_:)),
                                                         name:UIKeyboardWillShowNotification,
                                                         object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:#selector(self.keyboardWillHide(_:)),
                                                         name:UIKeyboardWillHideNotification,
                                                         object:nil)
        
    }
    
    private func stopObservingKeyboardEvents() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = notification.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size else {
            return
        }
        
        if let articleLayout = collectionView.collectionViewLayout as? ArticleCreationCollectionViewFlowLayout {
            articleLayout.disablePaging = true
        }
        
        var inset = collectionView.contentInset
        inset.bottom = keyboardSize.height
        collectionView.contentInset = inset
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let articleLayout = collectionView.collectionViewLayout as? ArticleCreationCollectionViewFlowLayout {
            articleLayout.disablePaging = false
        }
        collectionView.contentInset = UIEdgeInsetsZero
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
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    @IBAction func btnMorePicsPressed(sender: AnyObject) {
        UIView.animateWithDuration(0.1, delay: 0.0, options: [UIViewAnimationOptions.BeginFromCurrentState], animations: {
            self.btnMorePics.transform = CGAffineTransformIdentity
            let centerPoint = CGPointMake(self.collectionView.contentOffset.x + self.collectionView.bounds.width/2, self.collectionView.contentOffset.y + self.collectionView.bounds.height/2)
            self.returnCellToOriginalPosition(centerPoint)
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
            let centerPoint = CGPointMake(self.collectionView.contentOffset.x + self.collectionView.bounds.width/2, self.collectionView.contentOffset.y + self.collectionView.bounds.height/2)
            self.returnCellToOriginalPosition(centerPoint)
        }) { (_) in
            
        }
    }
    
    
    @IBAction func btnDeleteCellPressed(sender: UIButton) {
        if let cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: sender.tag, inSection: 0)) as? CardCollectionViewCell {
            UIView.animateWithDuration(0.1, delay: 0.0, options: [UIViewAnimationOptions.BeginFromCurrentState], animations: {
                cell.btnTrash.transform = CGAffineTransformIdentity
            }) { (_) in
                var frame = cell.vContainer.frame
                frame.origin.x = 0.0
                
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
                let delete = UIAlertAction(title: NSLocalizedString("Delete Media", comment: "") , style: .Default, handler: { (action) -> Void in
                    sender.selected = !sender.selected
                    self.presenter.deleteAsset(sender.tag, completionHandler: { (numberOfMedias) in
                        
                        self.collectionView.deleteItemsAtIndexPaths([NSIndexPath(forItem: sender.tag, inSection: 0)])
                        UIView.animateWithDuration(0.3, delay: 0.0, options: [UIViewAnimationOptions.TransitionFlipFromLeft], animations: {
                            cell.vContainer.frame = frame
                            }, completion: { (_) in
                                if numberOfMedias == 0 {
                                    self.navigationController?.popViewControllerAnimated(true)
                                }
                        })
                        
                        self.collectionView.reloadData()
                        self.collectionView.reloadSections(NSIndexSet(index: 0))
                    })
                })
                
                let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: { (action) -> Void in
                    UIView.animateWithDuration(0.3, delay: 0.0, options: [UIViewAnimationOptions.TransitionFlipFromLeft], animations: {
                        cell.vContainer.frame = frame
                        }, completion: nil)
                })
                
                alertController.addAction(delete)
                alertController.addAction(cancel)
                
                if #available(iOS 9.0, *) {
                    delete.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
                    cancel.setValue(UIColor.blicupPink(), forKey: "titleTextColor")
                }
                
                alertController.view.tintColor = UIColor.blicupPink()
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "LocationSegue", let vc = segue.destinationViewController as? SearchArticleLocationViewController {
            vc.handleMapSearchDelegate = self
        }
    }
}
