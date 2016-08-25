//
//  FavoritesViewController.swift
//  Blicup
//
//  Created by Moymer on 20/06/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class FavoritesViewController: UIViewController, UITextFieldDelegate, FavoritesPresenterDelegate {
    
    enum TagStatus {
        case NotFound, Suggested, Added
    }
    
    let interestTagCellIdentifier = "InterestTagCell"
    let interestListAddedBlankCell = "InterestAddedBlank"
    let headerIdentifier = "Header"
    
    @IBOutlet weak var btnContinue: UIButton!
    @IBOutlet weak var flowLayout: FlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tfTags: CustomTextField!
    
    private let vBlicupProgress = BCProgress()
    private let presenter = FavoritesPresenter()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("UM_interestListVC_title", comment: "")
        
        self.flowLayout.sectionInset = UIEdgeInsetsMake(8, 8, 8, 8)
        self.flowLayout.headerReferenceSize = CGSizeMake(screenWidth, 1);
        
        let lblHashtag = UILabel(frame: CGRectMake(0, 0, 20, self.tfTags.frame.height))
        lblHashtag.text = "#"
        lblHashtag.textAlignment = .Right
        lblHashtag.font = UIFont(name: "SFUIText-Bold", size: 16.0)
        tfTags.leftView = lblHashtag
        tfTags.leftViewMode = UITextFieldViewMode.Always
        
        presenter.delegate = self
        btnContinue.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBarHidden = false
        self.navigationController?.navigationBar.tintColor = UIColor.blackColor()
        self.tabBarController?.tabBar.hidden = true
        
        self.becomeFirstResponder()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        BlicupAnalytics.sharedInstance.mark_EnteredScreenMyTags()
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override var inputAccessoryView: UIView? {
        return btnContinue
    }
    
    
    // MARK: - Actions
    
    @IBAction func btnContinuePressed(sender: AnyObject) {
        self.view.endEditing(true)
        
        vBlicupProgress.performSelector(#selector(BCProgress.showHUDAddedTo(_:)), withObject: self.view.window!, afterDelay: 1.0)
        self.btnContinue.enabled = false
        presenter.updateUserTags { (success) in
            NSObject.cancelPreviousPerformRequestsWithTarget(self.vBlicupProgress)
            self.vBlicupProgress.hideActivityIndicator(self.view.window!)
            
            if success {
                self.animateSaveTagsBtn()
                BlicupAnalytics.sharedInstance.mark_ChangedTags()
            }
            else {
                self.btnContinue.enabled = true
                let title = NSLocalizedString("NoInternetTitle", comment: "No Internet")
                let message = NSLocalizedString("NoInternetMessage", comment: "Check your network connection and try again")
                let dialog = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                dialog.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(dialog, animated: true, completion: nil)
            }
        }
    }
    
    func animateSaveTagsBtn() {
        self.btnContinue.setTitle(nil, forState: .Normal)
        self.btnContinue.setTitle(nil, forState: .Disabled)
        self.btnContinue.setImage(UIImage(named: "ic_check_gray")?.imageWithRenderingMode(.AlwaysOriginal), forState: .Normal)
        
        self.btnContinue.transform = CGAffineTransformMakeScale(0.9, 0.9)
        UIView.animateWithDuration(0.6, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 3, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
            self.btnContinue.transform = CGAffineTransformIdentity
            self.btnContinue.backgroundColor = UIColor.blicupGreenLemon()
            
            }, completion: { (finished) in
                
                self.btnContinue.imageView?.transform = CGAffineTransformMakeScale(0.8, 0.8)
                
                UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 4, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                    self.btnContinue.imageView?.transform = CGAffineTransformIdentity
                    }, completion: { (finished) in
                        UIView.animateWithDuration(0.5, animations: {
                            self.btnContinue.alpha = 0
                            }, completion: { (_) in
                                self.btnContinue.setImage(nil, forState: .Normal)
                                self.btnContinue.enabled = true
                                self.btnContinue.hidden = true
                        })
                })
        })
    }
    
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presenter.numberOftags()
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        switch kind {
            
        case UICollectionElementKindSectionHeader:
            
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: headerIdentifier, forIndexPath: indexPath)
            headerView.backgroundColor = UIColor.blicupLightGray2()
            headerView.frame.origin.x = 0
            
            return headerView
            
        default:
            assert(false, "Unexpected element kind")
            return UICollectionReusableView()
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if presenter.addedTagsArrayIsBlank() {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(interestListAddedBlankCell, forIndexPath: indexPath) as! InterestListAddedBlankCollectionViewCell
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(interestTagCellIdentifier, forIndexPath: indexPath) as! InterestTagCollectionViewCell
            self.configureCell(cell, forIndexPath: indexPath)
            return cell
        }
    }
    
    func configureCell(cell: InterestTagCollectionViewCell, forIndexPath indexPath: NSIndexPath) {
        cell.lblTagName.text = "#" + presenter.tagAtIndex(indexPath.row)
        cell.backgroundColor = presenter.backgroundColor()
        cell.ivTag.image = presenter.tagImageFromSection()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if indexPath.section == 0 && presenter.addedTagsArrayIsBlank() {
            return interestAddedBlankItemSize()
        }
        else {
            return interestTagItemSize(index: indexPath.row, section: indexPath.section)
        }
    }
    
    func interestAddedBlankItemSize() -> CGSize {
        
        let insets = 16
        let widthCell = collectionView.frame.width - CGFloat(insets)
        let padding = 50
        
        let text = NSLocalizedString("UM_interestListVC_added_blank", comment: "")
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, widthCell - CGFloat(padding), CGFloat.max))
        label.numberOfLines = 0
        label.textAlignment = .Center
        label.font = UIFont(name: "SFUIText-Regular", size: 16.0)!
        label.text = text
        
        label.sizeToFit()
        
        return CGSizeMake(widthCell, label.frame.size.height)
    }
    
    func interestTagItemSize(index index: Int, section: Int) -> CGSize {
        
        let tag = "#" + self.presenter.tagAtIndex(index)
        
        let addTagimage = UIImage(named: "ic_add_tag")!
        var size: CGSize = tag.sizeWithAttributes([NSFontAttributeName: UIFont(name: "SFUIText-Regular", size: 16.0)!])
        size.height = 38
        size.width += 16 + addTagimage.size.width + 4
        
        return size
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if section == 0 {
            return CGSize.zero
        } else {
            return CGSizeMake(collectionView.frame.width, 1)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard !presenter.addedTagsArrayIsBlank() else {
            return
        }
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: [UIViewAnimationOptions.BeginFromCurrentState], animations: {
            cell?.transform = CGAffineTransformIdentity
            }, completion: { (_) in
                self.presenter.removeTagAtIndex(indexPath.row)
                
                if self.presenter.addedTagsArrayIsBlank() {
                    collectionView.reloadData()
                }
                else {
                    collectionView.deleteItemsAtIndexPaths([indexPath])
                }
                
                self.updateBtnContinue()
        })
    }
    
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = self.collectionView.cellForItemAtIndexPath(indexPath)
        UIView.animateWithDuration(0.1, animations: {
            cell?.transform = CGAffineTransformMakeScale(0.9, 0.9)
        }) { (_) in
            
        }
    }
    
    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = self.collectionView.cellForItemAtIndexPath(indexPath)
        UIView.animateWithDuration(0.2, delay: 0.0, options: [UIViewAnimationOptions.BeginFromCurrentState], animations: {
            cell?.transform = CGAffineTransformIdentity
            }, completion: nil)
    }
    
    // MARK:- Presenter Delegate
    func updateTagsLists(tagsToInsert:[NSIndexPath], tagsToRemove:[NSIndexPath]) {
        
        collectionView.performBatchUpdates( { [weak self] in
            self?.collectionView.insertItemsAtIndexPaths(tagsToInsert)
            self?.collectionView.deleteItemsAtIndexPaths(tagsToRemove)
            }, completion: nil)
    }
    
    func updateTagsLists(moveItem initialIndex:NSIndexPath, toIndex:NSIndexPath) {
        collectionView.moveItemAtIndexPath(initialIndex, toIndexPath: toIndex)
    }
    
    // MARK - Continue button
    
    
    func updateBtnContinue () {
        let addedTagsCount = presenter.addedTagsArrayIsBlank() ? 0 : presenter.numberOftags()
        
        var enabled = false
        var btnControlState:UIControlState = .Disabled
        var text = ""
        var backgroundColor = UIColor.blicupGray()
        
        switch addedTagsCount {
        case 0:
            text = NSLocalizedString("Savebtn_at_least", comment: "") + " 3 " +  NSLocalizedString("Savebtn_at_least_2", comment: "")
            break
        case 1:
            text = NSLocalizedString("Savebtn_add_more", comment: "") + " 2 " + NSLocalizedString("Savebtn_add_more_2", comment: "")
            break
        case 2:
            
            text = NSLocalizedString("Savebtn_add_more", comment: "") + " 1 " + NSLocalizedString("Savebtn_add_more_2", comment: "")
            break
        default:
            enabled = true
            btnControlState = .Normal
            text = NSLocalizedString("Savebtn_enable", comment: "")
            backgroundColor = UIColor.blicupPurple()
            break
        }
        
        self.btnContinue.setTitle(text, forState: btnControlState)
        self.btnContinue.enabled = enabled
        self.btnContinue.backgroundColor = backgroundColor
        
        if btnContinue.hidden {
            btnContinue.alpha = 0
            btnContinue.hidden = false
            
            UIView.animateWithDuration(0.5, animations: {
                self.btnContinue.alpha = 1
            })
        }
    }
    
    
    
    // MARK: - Text Field Delegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        let text = (textField.text != nil) ? textField.text! : ""
        
        if string.rangeOfString(LETTERS_AND_NUMBERS_PATTERN, options: .RegularExpressionSearch) != nil {
            return false
        }
        
        let tagText = (text as NSString).stringByReplacingCharactersInRange(range, withString: string)
        var tag = tagText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).lowercaseString
        
        if tag.length > TAG_LIMIT_LENGTH {
            tag = tag.substringToIndex(tag.startIndex.advancedBy(TAG_LIMIT_LENGTH))
        }
        
        textField.text = tag
        
        return false
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        guard textField.text?.length > 0 else {
            return true
        }
        
        let text = textField.text!
        let tag = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).lowercaseString
        textField.text = nil
        presenter.addNewTag(tag)
        updateBtnContinue()
        
        return true
    }
}
