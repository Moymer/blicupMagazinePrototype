//
//  SignupPictureViewController.swift
//  Blicup
//
//  Created by Guilherme Braga on 04/03/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import RSKImageCropper

class SignupPictureViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, RSKImageCropViewControllerDelegate {

    var signupPresenter: SignupPresenter!

    @IBOutlet weak var btnPicture: UIButton!
    @IBOutlet weak var activiyIndicator: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnPicture.layer.cornerRadius = btnPicture.frame.height/2
        btnPicture.clipsToBounds = true
        
        if let photoUrl = self.signupPresenter.getPictureURL() {
            if let url = NSURL(string: photoUrl) {
                btnPicture.kf_setImageWithURL(url, forState: .Normal, placeholderImage: UIImage(named: "nophoto"), optionsInfo: [], completionHandler: { (image, error, cacheType, imageURL) -> () in
                    self.signupPresenter.setChoosenImage(image)
                    self.activiyIndicator.stopAnimating()
                })
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.signupPresenter.validateImage()
    }
    
    func selectedPicture(image: UIImage) {
        self.signupPresenter.setChoosenImage(image)
        btnPicture.setImage(image, forState: .Normal)
    }
    
    // MARK: - Actions
    @IBAction func btnChoosePicturePressed(sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        picker.delegate = self
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    
    // MARK: - UIImagePickerControllerDelegate Methods
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        var newImage: UIImage
        
        if let possibleImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            newImage = possibleImage
        } else if let possibleImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            newImage = possibleImage
        } else {
            return
        }
        
        let vcRSKImagePhotoEditor = RSKImageCropViewController(image: newImage)
        vcRSKImagePhotoEditor.delegate = self
        vcRSKImagePhotoEditor.avoidEmptySpaceAroundImage = true
        picker.pushViewController(vcRSKImagePhotoEditor, animated: true)

    }
    
    func imageCropViewControllerDidCancelCrop(controller: RSKImageCropViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imageCropViewController(controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect) {
        self.selectedPicture(croppedImage)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
