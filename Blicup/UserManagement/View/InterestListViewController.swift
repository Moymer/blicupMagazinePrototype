//
//  InterestListViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 16/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

class InterestListViewController: UIViewController, UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    enum TagStatus {
        case NotFound, Suggested, Added
    }
    
    var interestPresenter: InterestPresenter!
    let interestTagCellIdentifier = "InterestTagCell"
    let interestListAddedBlankCell = "InterestAddedBlank"
    let headerIdentifier = "Header"
    let kInterestToSuggestedUsersSegue = "interestToSuggestedUsersSegue"
    
    let vBlicupProgress = BCProgress()
    private var showBlicupActivityIndicatorTimer: NSTimer?
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var btnContinue: UIButton!
    @IBOutlet weak var flowLayout: FlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tfTags: CustomTextField!
    
    @IBOutlet weak var btnContinueBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var vContainerTraillingConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: true)
        
        self.title = NSLocalizedString("UM_interestListVC_title", comment: "")
        self.flowLayout.sectionInset = UIEdgeInsetsMake(8, 8, 8, 8)
        self.flowLayout.headerReferenceSize = CGSizeMake(screenWidth, 1);
        
        let lblHashtag = UILabel(frame: CGRectMake(0, 0, 20, self.tfTags.frame.height))
        lblHashtag.text = "#"
        lblHashtag.textAlignment = .Right
        lblHashtag.font = UIFont(name: "SFUIText-Bold", size: 16.0)
        tfTags.leftView = lblHashtag
        tfTags.leftViewMode = UITextFieldViewMode.Always
        
        self.collectionView!.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerIdentifier)
        
        let view = self
        let presenter = InterestPresenter(interestViewController: view)
        tfTags.delegate = self
        self.interestPresenter = presenter
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.startObservingKeyboardEvents()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.stopObservingKeyboardEvents()
    }
    
    // MARK: - Keyboard
    
    private func startObservingKeyboardEvents() {
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:#selector(InterestListViewController.keyboardWillShow(_:)),
                                                         name:UIKeyboardWillShowNotification,
                                                         object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:#selector(InterestListViewController.keyboardWillHide(_:)),
                                                         name:UIKeyboardWillHideNotification,
                                                         object:nil)
        
    }
    
    private func stopObservingKeyboardEvents() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            
            if let keyboardSize: CGSize = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size {
                self.btnContinueBottomConstraint.constant = keyboardSize.height
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.btnContinueBottomConstraint.constant = 0
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    
    // MARK: - Actions
    
    @IBAction func btnContinuePressed(sender: AnyObject) {
        self.tfTags.resignFirstResponder()
        
        invalidateShowBlicupWhiteTimer()
        showBlicupActivityIndicatorTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(InterestListViewController.startBlicupActivityIndicator), userInfo: nil, repeats: false)
        
        interestPresenter.setTagsInUser { (success) in
            self.hideActivityIndicator()
            
            if success {
                
                // Delay para aguardar dismiss do loading
                UIView.animateWithDuration(1.0, delay: 0.7, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                    self.vContainerTraillingConstraint.constant = self.containerView.bounds.size.width
                    self.btnContinueBottomConstraint.constant = -self.btnContinue.frame.height
                    self.view.layoutIfNeeded()
                    
                    }, completion: { (finished) in
                        self.performSegueWithIdentifier(self.kInterestToSuggestedUsersSegue, sender: nil)
                })
            }
            else {
                // TODO: Tratar erro de taglist
                
                let title = NSLocalizedString("NoInternetTitle", comment: "No Internet")
                let message = NSLocalizedString("NoInternetMessage", comment: "Check your network connection and try again")
                let dialog = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                dialog.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(dialog, animated: true, completion: nil)
            }
        }
    }
    
    func startBlicupActivityIndicator() {
        vBlicupProgress.showHUDAddedTo(self.view)
    }
    
    func hideActivityIndicator() {
        invalidateShowBlicupWhiteTimer()
        vBlicupProgress.hideActivityIndicator(self.view)
    }
    
    func invalidateShowBlicupWhiteTimer() {
        
        if self.showBlicupActivityIndicatorTimer != nil {
            showBlicupActivityIndicatorTimer?.invalidate()
            showBlicupActivityIndicatorTimer = nil
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return interestPresenter.numberOfSections()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return interestPresenter.numberOfItemsInSection(section: section)
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
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 && interestPresenter.addedTagsArrayIsBlank() {
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(interestListAddedBlankCell, forIndexPath: indexPath) as! InterestListAddedBlankCollectionViewCell
            
            return cell
            
        } else {
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(interestTagCellIdentifier, forIndexPath: indexPath) as! InterestTagCollectionViewCell
            self.configureCell(cell, forIndexPath: indexPath)
            
            return cell
        }
    }
    
    func configureCell(cell: InterestTagCollectionViewCell, forIndexPath indexPath: NSIndexPath) {
        
        cell.lblTagName.text = "#" + interestPresenter.tagAtIndex(index: indexPath.row, section: indexPath.section)
        cell.backgroundColor = interestPresenter.backgroundColor(section: indexPath.section)
        cell.ivTag.image = interestPresenter.tagImageFromSection(section: indexPath.section)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        if indexPath.section == 0 && interestPresenter.addedTagsArrayIsBlank() {
            
            return interestAddedBlankItemSize()
            
        } else {
            
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
        
        let tag = "#" + self.interestPresenter.tagAtIndex(index: index, section: section)
        
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
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: [UIViewAnimationOptions.BeginFromCurrentState], animations: {
            cell?.transform = CGAffineTransformIdentity
            }, completion: { (_) in
                let tag = self.interestPresenter.tagAtIndex(index: indexPath.row, section: indexPath.section)
                
                if indexPath.section == 0 {
                    
                    if !self.interestPresenter.addedTagsArrayIsBlank() {
                        
                        self.moveTagFromAddedToTags(tag, indexPath: indexPath)
                    }
                    
                } else {
                    
                    self.moveTagFromTagsToAdded(tag, indexPath: indexPath)
                }
        })
    }
    
    // MARK:- Update, Remove, Insert Tags
    
    func insertTagToAddedArray(tag: String) {
        
        self.collectionView.performBatchUpdates({[weak self] () -> Void in
            
            if let weakSelf = self {
                if weakSelf.interestPresenter.addedTagsArrayIsBlank() {
                    weakSelf.interestPresenter.insertTagToAddedArray(tag)
                    weakSelf.collectionView.reloadSections(NSIndexSet(index: 0))
                } else {
                    weakSelf.interestPresenter.insertTagToAddedArray(tag)
                    weakSelf.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
                }
            }
            
            }, completion: nil)
        
    }
    
    func moveTagFromAddedToTags(tag: String, indexPath: NSIndexPath) {
        
        self.collectionView.performBatchUpdates({ [weak self] () -> Void in
            if let weakSelf = self {
                weakSelf.interestPresenter.insertTag(tag, index: 0)
                weakSelf.interestPresenter.removeTagFromAddedArray(indexPath)
                
                if weakSelf.interestPresenter.addedTagsArrayIsBlank() {
                    weakSelf.collectionView.reloadSections(NSIndexSet(index: 0))
                } else {
                    weakSelf.collectionView.deleteItemsAtIndexPaths([indexPath])
                }
                
                weakSelf.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 1)])
            }
            }, completion: nil)
    }
    
    func moveTagFromTagsToAdded(tag: String, indexPath: NSIndexPath) {
        
        self.collectionView.performBatchUpdates({  [unowned self] () -> Void in
            
            self.interestPresenter.removeTagAtIndex(indexPath.row)
            self.collectionView.deleteItemsAtIndexPaths([indexPath])
            
            self.insertTagToAddedArray(tag)
            }, completion: nil)
    }
    
    func moveTagFromAddedToFirstIndex(oldIndex: NSIndexPath) {
        
        self.collectionView.performBatchUpdates( { [unowned self] in
            
            self.interestPresenter.moveTagFromAddedToFirstIndex(oldIndex)
            self.collectionView.deleteItemsAtIndexPaths([oldIndex])
            self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
            
            }, completion: nil)
        
    }
    
    // MARK - Continue button
    
    
    func updateBtnContinue () {
        
        let addedTagsCount = self.interestPresenter.numberOfAddedTags()
        
        if addedTagsCount < 4 {
            
            var enabled = false
            var btnControlState:UIControlState = .Disabled
            var text = ""
            var backgroundColor = UIColor.blicupGray()
            
            switch addedTagsCount {
            case 0:
                text = NSLocalizedString("UM_interestPresenter_continuebtn_case0_parte1", comment: "") + " 3 " +  NSLocalizedString("UM_interestPresenter_continuebtn_case0_parte2", comment: "")
                break
            case 1:
                text = NSLocalizedString("UM_interestPresenter_continuebtn_case1_parte1", comment: "") + " 2 " + NSLocalizedString("UM_interestPresenter_continuebtn_case1_parte2", comment: "")
                break
            case 2:
                
                text = NSLocalizedString("UM_interestPresenter_continuebtn_case2_parte1", comment: "") + " 1 " + NSLocalizedString("UM_interestPresenter_continuebtn_case2_parte2", comment: "")
                break
            default:
                enabled = true
                btnControlState = .Normal
                text = NSLocalizedString("UM_interestPresenter_continuebtn", comment: "")
                backgroundColor = UIColor.blicupPurple()
                break
            }
            
            self.btnContinue.setTitle(text, forState: btnControlState)
            self.btnContinue.enabled = enabled
            self.btnContinue.backgroundColor = backgroundColor
        }
    }
    
    
    
    // MARK: - Text Field Delegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        
        if string.rangeOfString(LETTERS_AND_NUMBERS_PATTERN, options: .RegularExpressionSearch) != nil {
            return false
        }
        
        let newLength = text.utf16.count + string.utf16.count - range.length
        let tagText = (text as NSString).stringByReplacingCharactersInRange(range, withString: string)
        
        if string == " " && newLength <= TAG_LIMIT_LENGTH {
            
            var isValidTag = false
            
            let tag = tagText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).lowercaseString
            
            if tag != "" {
                
                isValidTag = true
                textField.text = ""
                
                
                self.prepareForInsertTag(tag)
            }
            
            return isValidTag
            
        }
        
        return newLength <= TAG_LIMIT_LENGTH
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        guard let text = textField.text else { return true }
        
        if (text != " " && text != "") {
            
            let tag = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).lowercaseString
            
            textField.text = ""
            
            self.prepareForInsertTag(tag)
        }
        
        return true
    }
    
    func prepareForInsertTag(tag: String) {
        
        let response = interestPresenter.arraysContainsTag(tag)
        let status = response.status
        let indexPath = response.indexPath
        
        switch status {
            
        case .Suggested:
            
            self.moveTagFromTagsToAdded(tag, indexPath: indexPath)
            
            break;
            
        case .Added:
            
            self.moveTagFromAddedToFirstIndex(indexPath)
            
            break;
            
        case .NotFound:
            
            self.insertTagToAddedArray(tag)
            
            break;
        }
    }
}
