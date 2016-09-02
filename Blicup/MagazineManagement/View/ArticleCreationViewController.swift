//
//  ArticleCreationViewController.swift
//  Blicup
//
//  Created by Moymer on 30/08/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import Photos


class ArticleCreationViewController: UIViewController, UICollectionViewDataSource, UITextViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
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

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        startObservingKeyboardEvents()
        // Just to adjust initial cells alpha
        scrollViewDidScroll(collectionView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
        let container = cell.viewWithTag(1)!
        container.layer.cornerRadius = 20
        
        cell.layer.shadowColor = UIColor.lightGrayColor().CGColor
        cell.layer.shadowOffset = CGSizeMake(2, 2)
        cell.layer.shadowOpacity = 0.5
        cell.layer.shadowRadius = 3.0
        cell.clipsToBounds = false
        cell.layer.masksToBounds = false
        
        presenter.getImageMedia(indexPath) { (image) in
            cell.cardMedia.image = image
        }
        
        cell.title = presenter.getCardTitle(indexPath)
        cell.content = presenter.getCardContent(indexPath)
        
        return cell
    }
    
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        scrollView.endEditing(true)
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
}
