//
//  CoverPhotosCollectionViewController.swift
//  Blicup
//
//  Created by Moymer on 08/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit

private let reuseIdentifier = "coverPhotosCollectiontViewCell"
private let footerReuseIdentifier = "coverPhotoCollectionReusableViewFooter"


class CoverPhotosCollectionViewController: UICollectionViewController {

    var createChatRoomPresenter: CreateChatRoomPresenter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.createChatRoomPresenter.numberOfCoverPhotos()
    }

    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionFooter {
            
            let reusableView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: footerReuseIdentifier, forIndexPath: indexPath) as! CoverPhotoCollectionReusableView
            reusableView.btnAddCoverPhoto.addTarget(self.createChatRoomPresenter.vcCreateChatRoom, action: #selector(CreateChatRoomViewController.presentActionSheet), forControlEvents: .TouchUpInside)
            
            let image = createChatRoomPresenter.imageForCollectionCoverFooter()
            reusableView.btnAddCoverPhoto.setImage(image, forState: .Normal)
            reusableView.btnAddCoverPhoto.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            
            return reusableView
        }
        
        return UICollectionReusableView()
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CoverPhotoCollectionViewCell
        
        cell.btnCoverPhoto.setImage(self.createChatRoomPresenter.imageAtIndex(indexPath.row), forState: .Normal)
        cell.btnCoverPhoto.addTarget(self.createChatRoomPresenter.vcCreateChatRoom, action: #selector(CreateChatRoomViewController.openRSKImageCropToEditingSelectedImage(_:)), forControlEvents: .TouchUpInside)
        cell.btnCoverPhoto.tag = indexPath.row

        cell.btnRemoveCoverPhoto.hidden = false
        cell.btnRemoveCoverPhoto.addTarget(self, action: #selector(CoverPhotosCollectionViewController.removeCoverPhoto(_:)), forControlEvents: .TouchUpInside)
        cell.btnRemoveCoverPhoto.tag = indexPath.row
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 60, height: 65)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        if createChatRoomPresenter.numberOfCoverPhotos() == createChatRoomPresenter.NUMBER_MAX_PHOTOS {
            return CGSizeZero
        }
        
        return CGSize(width: 60, height: 65)
    }
    
    func removeCoverPhoto(sender: UIButton) {
        
        let index = sender.tag
        self.collectionView?.performBatchUpdates({ [weak self] () -> Void in
            self?.createChatRoomPresenter.removeImageAtIndex(index)
            self?.collectionView?.deleteItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
        }, completion: { [weak self] (finished) -> Void in
            if finished {
                self?.createChatRoomPresenter.updatePhotosContainer()
                self?.reloadData()
            }
        })
    }


    func replaceImageAtIndex(indexPath: NSIndexPath) {
     
        self.collectionView?.performBatchUpdates({ [weak self] () -> Void in
            self?.collectionView?.reloadItemsAtIndexPaths([indexPath])
        }, completion: nil)
    }
    
    func reloadData() {
        self.collectionView?.reloadData()
    }

}
