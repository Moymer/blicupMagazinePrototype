//
//  SearchPagerTabStripController.swift
//  Blicup
//
//  Created by Guilherme Braga on 01/09/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class SearchPagerTabStripController: ButtonBarPagerTabStripViewController, UISearchBarDelegate {

    private var alreadyAnimated = false
    var isReload = false
    
    @IBOutlet weak var tfSearch: CustomTextField!
    @IBOutlet weak var vContainerTFSearch: UIView!
    
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var vContainerSearch: UIView!
    
    @IBOutlet weak var constrTFSearchWidth: NSLayoutConstraint!
    @IBOutlet weak var constrTFSearchCenterX: NSLayoutConstraint!
    @IBOutlet weak var constrCancelTrailing: NSLayoutConstraint!
    
    private let kCancelButtonTrailingDefault: CGFloat = 10

    override func viewDidLoad() {
        
        if let navBar = self.navigationController?.navigationBar {
            
            let navBorder = UIView(frame: CGRectMake(0,navBar.frame.size.height,navBar.frame.size.width, 1))
            navBorder.backgroundColor = UIColor.whiteColor()
            navBar.addSubview(navBorder)
            
            navBar.barTintColor = UIColor.whiteColor()
        }
        
        buttonBarView.selectedBar.backgroundColor = UIColor.grayColor()
        buttonBarView.backgroundColor = UIColor.whiteColor()
        
        self.settings.style.buttonBarBackgroundColor =  UIColor.whiteColor()
        // buttonBar minimumLineSpacing value
        self.settings.style.buttonBarMinimumLineSpacing = 10
        // buttonBar flow layout left content inset value
        self.settings.style.buttonBarLeftContentInset = 70
        // buttonBar flow layout right content inset value
        self.settings.style.buttonBarRightContentInset = 70
        
        // selected bar view is created programmatically so it's important to set up the following 2 properties properly
        self.settings.style.selectedBarBackgroundColor = UIColor.grayColor()
        self.settings.style.selectedBarHeight  = 1
        
        // each buttonBar item is a UICollectionView cell of type ButtonBarViewCell
        self.settings.style.buttonBarItemBackgroundColor = UIColor.whiteColor()
        self.settings.style.buttonBarItemFont = UIFont(name: "Avenir-Black", size: 14.0)!
        // helps to determine the cell width, it represent the space before and after the title label
        self.settings.style.buttonBarItemLeftRightMargin = 12
        self.settings.style.buttonBarItemTitleColor = UIColor.blackColor()
        // in case the barView items do not fill the screen width this property stretch the cells to fill the screen
        self.settings.style.buttonBarItemsShouldFillAvailiableWidth = true
        
        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            
            oldCell?.label.textColor = UIColor(white: 0, alpha: 0.70)
            newCell?.label.textColor = .blackColor()
            
            if animated {
                UIView.animateWithDuration(0.1, animations: { () -> Void in
                    newCell?.transform = CGAffineTransformMakeScale(1.0, 1.0)
                    oldCell?.transform = CGAffineTransformMakeScale(0.85, 0.85)
                })
            }
            else {
                newCell?.transform = CGAffineTransformMakeScale(1.0, 1.0)
                oldCell?.transform = CGAffineTransformMakeScale(0.85, 0.85)
            }
        }
        
        customizeTextFieldSearch()
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        
        BlicupAnalytics.sharedInstance.mark_EnteredScreenSearch()
        
        if alreadyAnimated == false {
            
            self.constrCancelTrailing.constant = kCancelButtonTrailingDefault
            
            UIView.animateWithDuration(0.3, animations: {
                
                self.view.backgroundColor = UIColor.whiteColor()
                self.vContainerSearch.alpha = 1
                self.view.layoutIfNeeded()
                
            }) { (finished) in
                self.alreadyAnimated = true
            }
            
            self.constrTFSearchWidth.constant = self.vContainerTFSearch.frame.width
            self.constrTFSearchCenterX.constant = 0
            
            UIView.animateWithDuration(0.1, delay: 0.0, options: [.CurveEaseIn], animations: {
                
                self.view.layoutIfNeeded()
                
                }, completion: { (finished) in
                    let string = "Search"
                    let str = NSAttributedString(string: string, attributes: [NSForegroundColorAttributeName : UIColor.blicupGray()])
                    self.tfSearch.attributedPlaceholder = str
            })
        }
    }
    
    func customizeTextFieldSearch() {
        
        let paddingX: CGFloat = 30
        let vPadding = UIView(frame: CGRect(x: 0, y: 0, width: paddingX, height: self.tfSearch.frame.height))
        let ivIconSearchPadding = UIImageView(frame: CGRectMake(10, 0, 16, self.tfSearch.frame.height))
        ivIconSearchPadding.contentMode = .ScaleAspectFit
        ivIconSearchPadding.image = UIImage(named: "ic_search")?.imageWithRenderingMode(.AlwaysOriginal)
        vPadding.addSubview(ivIconSearchPadding)
        tfSearch.paddingPosX = paddingX
        tfSearch.leftView = vPadding
        tfSearch.leftViewMode = UITextFieldViewMode.Always
        vContainerTFSearch.layer.cornerRadius = vContainerTFSearch.frame.height/2
        vContainerTFSearch.clipsToBounds = true
        
        tfSearch.performSelector(#selector(UIResponder.becomeFirstResponder), withObject: nil, afterDelay: 0.5)
        
    }
    
    // MARK: - PagerTabStripDataSource
    
    override func viewControllersForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        
        let storyboard = UIStoryboard(name: "Search", bundle: nil)
        let child_1 = storyboard.instantiateViewControllerWithIdentifier("SearchStoryViewController") as! SearchStoryViewController
        let child_2 = storyboard.instantiateViewControllerWithIdentifier("SearchUserViewController") as! SearchUserViewController
        
        child_1.itemInfo = "Stories"
        child_2.itemInfo = "People"
        
        guard isReload else {
            return [child_1, child_2]
        }
        
        var childViewControllers = [child_1, child_2]

        for (index, _) in childViewControllers.enumerate(){
            let nElements = childViewControllers.count - index
            let n = (Int(arc4random()) % nElements) + index
            if n != index{
                swap(&childViewControllers[index], &childViewControllers[n])
            }
        }
        let nItems = 1 + (rand() % 8)
        return Array(childViewControllers.prefix(Int(nItems)))
    }
    
    override func pagerTabStripViewController(pagerTabStripViewController: PagerTabStripViewController, updateIndicatorFromIndex fromIndex: Int, toIndex: Int, withProgressPercentage progressPercentage: CGFloat, indexWasChanged: Bool) {
        
        if indexWasChanged  {
            let controller = self.viewControllers[self.currentIndex]
            if controller.isKindOfClass(SearchUserViewController) {
                (controller as! SearchUserViewController).searchUsersWithSearchTerm(tfSearch.text!)
            } else {
                (controller as! SearchStoryViewController).searchChatRoomWithSearchTerm(tfSearch.text!)
            }
        }
    }
    

    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
//        dismissKeyboard(nil)
        return false
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        
        let controller = self.viewControllers[self.currentIndex]
        
        if controller.isKindOfClass(SearchUserViewController) {
            return (controller as! SearchUserViewController).searchUser(text, shouldChangeTextInRange: range, replacementText: string)
        }
        
        return (controller as! SearchStoryViewController).searchStory(text, shouldChangeTextInRange: range, replacementText: string)
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        
//        removeAllItems()
        
//        reloadData()
        return true
    }
    
    
    // MARK: - Actions
    
    @IBAction func cancelPressed(sender: AnyObject) {
        
        self.view.endEditing(true)
        self.tfSearch.textAlignment = .Center
        UIView.animateWithDuration(0.5, animations: {
            self.view.backgroundColor = UIColor.clearColor()
            self.constrCancelTrailing.constant = -(self.kCancelButtonTrailingDefault + self.btnCancel.frame.width)
            self.constrTFSearchWidth.constant = 150
            self.constrTFSearchCenterX.constant = 0
            self.tfSearch.text = ""
            self.tfSearch.placeholder = "Search"
            self.view.layoutIfNeeded()
            
        }) { (finished) in
            self.performSegueWithIdentifier("unwindFromSecondary", sender: self)
        }
    }
}
