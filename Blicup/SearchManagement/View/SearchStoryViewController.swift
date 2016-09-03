//
//  SearchStoryViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 02/09/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import Kingfisher
import ReachabilitySwift

class SearchStoryViewController: UIViewController, IndicatorInfoProvider, UITextFieldDelegate {

    var itemInfo = IndicatorInfo(title: "View")
    private let presenter = SearchStoryPresenter()
    private let chatRoomListViewCellID = "chatRoomListViewCellID"
    private var showBlicupWhiteActivityIndicatorTimer: NSTimer?
    
    @IBOutlet weak var ivLoadingBlicupGray: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadBlicupImages()
        (self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset = UIEdgeInsetsMake(10, 10, kTabBarHeight + 2, 10)   
    }

   
    func loadBlicupImages() {
        
        var animationArray: [UIImage] = []
        
        for index in 0...29 {
            animationArray.append(UIImage(named: "BlicMini_gray_\(index)")!)
        }
        
        ivLoadingBlicupGray.animationImages = animationArray
        ivLoadingBlicupGray.animationDuration = 1.0
        ivLoadingBlicupGray.alpha = 0
    }
    
    func chatRoomsListChanged(insertedIdexes: [NSIndexPath], deletedIndexes: [NSIndexPath], reloadedIndexes: [NSIndexPath]) {
        
        collectionView.performBatchUpdates({ [weak self] in
            self?.collectionView.insertItemsAtIndexPaths(insertedIdexes)
            self?.collectionView.deleteItemsAtIndexPaths(deletedIndexes)
            self?.collectionView.reloadItemsAtIndexPaths(reloadedIndexes)
        }, completion: nil)
    }
    
    // MARK: - CollectionView
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let totalLines = getNameAndTagListTotalAndTaglLines(indexPath).0
        let size = self.presenter.getChatItemSizeForLines(totalLines)
        
        let imageHeight = size.height*(GRID_WIDTH/size.width)*1.5
        return CGSize(width: GRID_WIDTH, height: imageHeight)
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
        return self.presenter.chatRoomsCount()
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let collectionCell: ChatRoomListCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(chatRoomListViewCellID, forIndexPath: indexPath) as! ChatRoomListCollectionViewCell
        
        collectionCell.layer.shouldRasterize = true
        collectionCell.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        collectionCell.lblName.text = self.presenter.chatRoomName(forIndex: indexPath)
        collectionCell.vContainer.backgroundColor = self.presenter.chatRoomMainColor(indexPath)
        collectionCell.showVerifiedBadge(presenter.chatRoomOwnerIsVerified(forIndex: indexPath))
        collectionCell.ivBackground.setMainColor(self.presenter.chatRoomMainColor(indexPath))
        collectionCell.lblWhoCreatedUsername.text = presenter.chatRoomOwnerName(forIndex: indexPath)
        
        if let photoUrl = presenter.chatRoomMainImageUrl(indexPath) {
            let optionInfo: KingfisherOptionsInfo = [
                .BackgroundDecode,
                .ScaleFactor(0.25)]
            
            collectionCell.ivBackground.kf_setImageWithURL(photoUrl, placeholderImage: nil, optionsInfo: optionInfo, progressBlock: nil, completionHandler: nil)
        }
        
        //analytics
        let chatRoom = presenter.chatRoomAtIndex(indexPath)
        BlicupAnalytics.sharedInstance.seenChatFromSearch(chatRoom.chatRoomId!)
        
        return collectionCell
    }
    
    
    func startPrefetchImagesThumb(photoUrlList: [String]){
        
        let urlsList = photoUrlList.flatMap { (stringURL) -> NSURL? in
            return NSURL(string: AmazonManager.getThumbUrlFromMainUrl(stringURL))
        }
        
        let prefetcher = ImagePrefetcher(urls: urlsList)
        prefetcher.maxConcurrentDownloads = 20
        prefetcher.start()
        
    }

    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        if let collectionCell =  cell as? ChatRoomListCollectionViewCell {
            collectionCell.ivBackground.stopAnimating()
            collectionCell.ivBackground.kf_cancelDownloadTask()
        }
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        if let collectionCell = cell as? ChatRoomListCollectionViewCell {
            collectionCell.ivBackground.startAnimating()
        }
    }
    
    // MARK: - CollectionView Size\Layout Helper
    
    // Returns total lines and taglist max lines
    private func getNameAndTagListTotalAndTaglLines(indexPath: NSIndexPath) -> (Int, Int){
        let lblNameWidth = GRID_WIDTH - 16
        let lblTagListWidth = GRID_WIDTH - 16
        
        let lblTagListFont = UIFont(name: "SFUIText-Regular", size: 13)
        let lblNameFont = UIFont(name: "SFUIText-Bold", size: 15)
        
        var chatRoomHashTags = ""
        if let hashTags = self.presenter.chatRoomHashtags(forIndex: indexPath) {
            chatRoomHashTags = hashTags
        }
        
        var numberOfLinesName = 0
        if let chatRoomName = self.presenter.chatRoomName(forIndex: indexPath) {
            numberOfLinesName = self.numberOfLinesInLabel(chatRoomName, labelWidth: lblNameWidth, labelHeight: CGFloat.max, font: lblTagListFont!)
        }
        
        let numberOfLinesTagList = self.numberOfLinesInLabel(chatRoomHashTags, labelWidth: lblTagListWidth, labelHeight: CGFloat.max, font: lblNameFont!)
        
        let total = (numberOfLinesName + numberOfLinesTagList)
        if total > 10 {
            return (10, 10 - numberOfLinesName)
        }
        else {
            return (total, numberOfLinesTagList)
        }
    }
    
    private func numberOfLinesInLabel(yourString: String, labelWidth: CGFloat, labelHeight: CGFloat, font: UIFont) -> Int {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = labelHeight
        paragraphStyle.maximumLineHeight = labelHeight
        paragraphStyle.lineBreakMode = .ByTruncatingTail
        
        let attributes: [String: AnyObject] = [NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraphStyle]
        
        let constrain = CGSizeMake(labelWidth, CGFloat(Float.infinity))
        
        let size = yourString.sizeWithAttributes(attributes)
        let stringWidth = size.width
        
        let numberOfLines = ceil(Double(stringWidth/constrain.width))
        
        return Int(numberOfLines)
    }
    

    // MARK: SearchStory
    func searchStory(text: String, shouldChangeTextInRange range: NSRange, replacementText string: String) -> Bool {
        
        let newLength = text.utf16.count + string.utf16.count - range.length
        let searchTerm = (text as NSString).stringByReplacingCharactersInRange(range, withString: string)
        
        
        if searchTerm != "" {
            searchChatRoomWithSearchTerm(searchTerm)
        } else {
            self.presenter.clearChats()
            self.collectionView.reloadData()
        }
        
        return newLength <= TAG_LIMIT_LENGTH
    }
    
    // MARK: SearchChats
    
    func searchChatRoomWithSearchTerm(searchTerm: String) {
        
        if let reachability = try? Reachability.reachabilityForInternetConnection() {
            
            prepareToPerfomSearch()
            
            if reachability.isReachable() {
                
                let searchTermTimestamp = NSDate().timeIntervalSince1970
                
                presenter.searchChatRoomsWithSearchTerm(searchTerm, timestamp: searchTermTimestamp, completionHandler: { (success) in
                    self.stopBlicupActivityIndicator()
                    
                    if success {
                        
                        if self.presenter.chatRoomsCount() > 0 {
                            self.collectionView.reloadData()
                        } else {
                            //                            self.showNoChatsWithSearchTerm(searchTerm)
                        }
                    } else {
                        // TODO: tratar timout servidor
//                        self.showlblNoInternet()
                    }
                    
                })
                
            } else {
//                showlblNoInternet()
            }
            
        } else {
//            showlblNoInternet()
        }
    }
    
    func prepareToPerfomSearch() {
        //        hidelblNoInternet()
        presenter.clearChats()
        self.collectionView.reloadData()
        
        invalidateShowBlicupWhiteTimer()
        showBlicupWhiteActivityIndicatorTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(SearchStoryViewController.startBlicupActivityIndicator), userInfo: nil, repeats: false)
        
    }
    
    func invalidateShowBlicupWhiteTimer() {
        
        if showBlicupWhiteActivityIndicatorTimer != nil {
            showBlicupWhiteActivityIndicatorTimer?.invalidate()
            showBlicupWhiteActivityIndicatorTimer = nil
        }
    }
    
    // MARK: - Show Loading
    
    func startBlicupActivityIndicator() {
        
        UIView.animateWithDuration(0.6) { () -> Void in
            self.ivLoadingBlicupGray.alpha = 1
        }
        
        ivLoadingBlicupGray.startAnimating()
    }
    
    func stopBlicupActivityIndicator() {
        
        invalidateShowBlicupWhiteTimer()
        
        UIView.animateWithDuration(0.6, animations: { () -> Void in
            
            self.ivLoadingBlicupGray.alpha = 0
            
            }, completion: { (finished) -> Void in
                
                self.ivLoadingBlicupGray.stopAnimating()
        })
    }
    
    // MARK: - IndicatorInfoProvider
    
    func indicatorInfoForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }
    
    

}
