//
//  CreateChatRoomPresenter.swift
//  Blicup
//
//  Created by Guilherme Braga on 05/04/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import CoreLocation
import AddressBookUI
import ContactsUI

private typealias AddressCompletionHandler = (address: String? ,error: String?) -> Void


class CreateChatRoomPresenter: NSObject {
    
    enum SocialMedia: Int {
        case FACEBOOK, TWITTER
    }
    
    unowned let vcCreateChatRoom: CreateChatRoomViewController
    unowned let cvcCoverPhotos: CoverPhotosCollectionViewController
    
    var coverPhotosEdited: [WebImage] = []
    var coverPhotosOriginal: [WebImage] = []
    
    var imageBGMain: WebImage?
    
    var isImageEditing = false
    var imageEditingIndex: NSIndexPath?
    
    // Publish
    
    private var publishToFacebook = false
    private var publishToTwitter = false
    
    
    //MARK: - Constants
    
    let TITLE_LIMIT_LENGHT = 100
    let TAGS_LIMIT_LENGHT = 140
    let NUMBER_MAX_PHOTOS = 5
    let kLblShareCalloutWidth: CGFloat = 140
    
    required init(vCreateChatRoom: CreateChatRoomViewController, cvcCoverPhotos: CoverPhotosCollectionViewController) {
        self.vcCreateChatRoom = vCreateChatRoom
        self.cvcCoverPhotos = cvcCoverPhotos
    }
    
    
    // MARK: - Datasource
    
    func numberOfCoverPhotos() -> Int {
        return self.coverPhotosEdited.count
    }
    
    func imageAtIndex(index: Int) -> UIImage {
        return self.coverPhotosEdited[index].image!
    }
    
    func originalImageAtIndex(index: Int) -> WebImage {
        return self.coverPhotosOriginal[index]
    }
    
    func replaceImageAtIndex(editedImage: WebImage  , originalImage: WebImage, index: Int) {
        
        let replacedImage = imageAtIndex(index)
        
        coverPhotosEdited[index] = editedImage
        coverPhotosOriginal[index] = originalImage
        
        if replacedImage == imageBGMain?.image {
            imageBGMain = editedImage
        }
    }
    
    func removeImageAtIndex(index: Int) {
        
        let removedImage = imageAtIndex(index)
        
        self.coverPhotosEdited.removeAtIndex(index)
        self.coverPhotosOriginal.removeAtIndex(index)
        
        if removedImage == imageBGMain?.image  {
            
            // troca a imagem de fundo sempre que o usuário remover o indíce 0
            if let firstImage = coverPhotosEdited.first {
                imageBGMain = firstImage
                vcCreateChatRoom.reloadBGImageWithImage(firstImage)
            } else {
                
                // quando o usuário remover a última, passa nil para trocar o fundo da criação
                imageBGMain = nil
                vcCreateChatRoom.reloadBGImageWithImage(nil)
            }
        }
        
        vcCreateChatRoom.showCreateChatBtn()
    }
    
    func insertSelectedImage(editedImage: WebImage, originalImage: WebImage) {
        
        // Adicionando imagem no fim
        coverPhotosEdited.append(editedImage)
        coverPhotosOriginal.append(originalImage)
        
        vcCreateChatRoom.showCreateChatBtn()
    }
    
    func imageFinishedEditing() {
        
        isImageEditing = false
        imageEditingIndex = nil
    }
    
    func beginEditingImageAtIndex(index: Int) {
        
        isImageEditing = true
        imageEditingIndex = NSIndexPath(forRow: index, inSection: 0)
    }
    
    func didFinishPickingImage(editedImage: WebImage, originalImage: WebImage) {
        
        if self.isImageEditing {
            
            if let indexPath = self.imageEditingIndex {
                
                self.replaceImageAtIndex(editedImage, originalImage: originalImage, index: indexPath.row)
                self.cvcCoverPhotos.replaceImageAtIndex(indexPath)
            }
            
            self.imageFinishedEditing()
            
        } else {
            
            self.insertSelectedImage(editedImage, originalImage: originalImage)
            self.cvcCoverPhotos.reloadData()
            self.vcCreateChatRoom.updatePhotosContainer()
        }
    }
    
    func setImageBgMain(image: WebImage?) {
        imageBGMain = image
    }
    
    func imageForCollectionCoverFooter() -> UIImage {
        if numberOfCoverPhotos() == 0 {
            return UIImage(named: "ic_camera_add_chat_photo")!
        } else {
            return UIImage(named: "ic_add_green_large")!
        }
    }
    
    func updatePhotosContainer() {
        vcCreateChatRoom.updatePhotosContainer()
    }
    
    // Publish Methods
    
    func checkFacebookPublishPermissions(completionHandler: CompletionHandlerLoginPublish -> Void) {
        
        LoginController.checkFacebookPublishPermissions(fromController: vcCreateChatRoom) { (publishResult) in
            completionHandler(publishResult)
        }
    }
    
    func checkTwitterPublishPermissions(completionHandler: CompletionHandlerLoginPublish -> Void) {
        
        LoginController.checkTwitterPublishPermissions { (publishResult) in
            completionHandler(publishResult)
        }
    }
    
    func publishCreatedChatOnFacebook(chatRoom: ChatRoom, urlFile: String) {
        LoginController.publishCreatedChatOnFacebook(fromController: self.vcCreateChatRoom , delegate: self.vcCreateChatRoom, chatRoom: chatRoom, urlFile: urlFile)
    }
    
    func publishCreatedChatOnTwitter(chatRoom: ChatRoom, urlFile: String) {
        LoginController.publishCreatedChatOnTwitter(chatRoom: chatRoom, urlFile: urlFile)
    }
    
    // Create Chat
    
    func validateAndCreateChat(tags: String, name: String, location: CLLocation, completionHandler:((success:Bool, chatRoom:ChatRoom?)->Void)?) {
        
        guard self.numberOfCoverPhotos() > 0,
            let loggedUser = UserBS.getLoggedUser() else {
                completionHandler?(success: false, chatRoom: nil)
                return
        }
        
        let images = self.coverPhotosEdited
        
        var uploadImages:[UIImage] = []
        for image in images
        {
            uploadImages.append(image.image!)
        }
        AmazonManager.uploadMultipleImagesToAmazonBucket(uploadImages, key: "chatRoomImage") { (urlImages) in
            
            if let unwrappedUrlImages = urlImages {
                self.getAddressForLatLng(location, completionHandler: { (address, error) in
                    guard let unwrappedAddress = address where error == nil else {
                        // TODO: Tratar erro
                        completionHandler?(success: false, chatRoom: nil)
                        print(error)
                        return
                    }
                    
                    let userDic = self.createUserDictionaryFromUser(loggedUser)
                    let imagesDicArray = self.createPhotosListDictionaryArray(uploadImages, imagesUrls: unwrappedUrlImages)
                    let addressDic = self.createAddressDic(unwrappedAddress, location: location)
                    let tagList = self.getFormattedTagsFromTagString(tags)
                    
                    let chatDic = self.createChatRoomDic(name, addressDic: addressDic, userDic: userDic, tagList: tagList, photoList: imagesDicArray)
                    
                    ChatRoomBS.createChatRoom(chatDic, completionHandler: { (success, newChatRoom) in
                        
                        if let unwrappedCreatedChatRoom = newChatRoom where success {
                            
                            self.performedCreateChatTip()
                            
                            //analytics
                            BlicupAnalytics.sharedInstance.mark_CreatedChat(self.publishToFacebook, sharedTwitter: self.publishToTwitter, totalTags: (newChatRoom?.tagList?.count)!, totalPhotos: (newChatRoom?.photoList?.count)!)
                            
                            self.publishChatOnFacebookOrTwitter(unwrappedCreatedChatRoom)
                        }
                        
                        completionHandler?(success: success, chatRoom: newChatRoom)
                    })
                })
            }
            else {
                completionHandler?(success: false, chatRoom: nil)
            }
        }
    }
    
    private func performedCreateChatTip() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.objectForKey(kCreateChatTipKey) == nil {
            let tipObject: [String : AnyObject] = ["count" : 1, "hasPerformedTip" : true]
            userDefaults.setObject(tipObject, forKey: kCreateChatTipKey)
        } else {
            let tipObject = userDefaults.objectForKey(kCreateChatTipKey) as? [String : AnyObject]
            let countPCTip = tipObject!["count"] as? NSNumber
            let updatedObject : [String : AnyObject] = ["count" : (countPCTip?.integerValue)!, "hasPerformedTip" : true]
            userDefaults.setObject(updatedObject, forKey: kCreateChatTipKey)
        }
    }
    
    private func createUserDictionaryFromUser(user:User)->[String:AnyObject] {
        let userDic = ["photoUrl"   : user.photoUrl!,
                       "userId"     : user.userId!,
                       "username"   : user.username!]
        return userDic
    }
    
    private func createPhotosListDictionaryArray(images:[UIImage], imagesUrls:[String])-> [AnyObject] {
        var photoList: [AnyObject] = []
        
        for (index, image) in images.enumerate() {
            
            let averageColor = image.averageColor()
            if let mainColor = averageColor.rgbToInt() {
                
                let photoDic = ["mainColor" : mainColor,
                                "height"    : image.size.height,
                                "width"     : image.size.width,
                                "photoUrl"  : imagesUrls[index]]
                
                photoList.append(photoDic)
            }
        }
        
        return photoList
    }
    
    private func createAddressDic(formatedAddress:String, location:CLLocation)->NSDictionary {
        let addressDic = ["formattedAddress" : formatedAddress,
                          "lat"              : location.coordinate.latitude,
                          "lng"              : location.coordinate.longitude]
        
        return addressDic
    }
    
    private func getFormattedTagsFromTagString(tagString:String)->[String] {
        let replacedTags = tagString.stringByReplacingOccurrencesOfString(" ", withString: "").lowercaseString
        let tagList = replacedTags.characters.split{$0 == "#"}.map(String.init)
        
        return tagList
    }
    
    private func createChatRoomDic(chatName:String, addressDic:NSDictionary, userDic:NSDictionary, tagList:[String], photoList:[AnyObject])-> [String:AnyObject] {
        let chatRoomDic = ["name"       : chatName,
                           "address"    : addressDic,
                           "whoCreated" : userDic,
                           "tagList"    : tagList,
                           "photoList"  : photoList]
        return chatRoomDic
    }
    
    private func publishChatOnFacebookOrTwitter(chatRoom:ChatRoom) {
        NSUserDefaults.standardUserDefaults().removeObjectForKey("lastSearch")
        
        let htmlDic = ChatRoomBS.createPublishHTMLDic(chatRoom)
        
        AmazonManager.uploadHTMLToAmazonBucket(htmlDic, key: chatRoom.chatRoomId!) { (urlFile) in
            
            if let unwrappedURLFile = urlFile {
                dispatch_async(dispatch_get_main_queue(), {
                    if self.publishToFacebook {
                        self.publishCreatedChatOnFacebook(chatRoom, urlFile: unwrappedURLFile)
                    }
                    if self.publishToTwitter {
                        self.publishCreatedChatOnTwitter(chatRoom, urlFile: unwrappedURLFile)
                    }
                })
            }
        }
    }
    
    private func getAddressForLatLng(location : CLLocation, completionHandler: AddressCompletionHandler) {
        
        var address: String?
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
            
            if error != nil {
                print(error)
                completionHandler(address: nil, error: error?.localizedDescription)
            }
            else {
                
                if let pm = placemarks?.first {
                    if let addressDic = pm.addressDictionary {
                        if let city = addressDic["City"], let state = addressDic["State"], let countryCode = addressDic["Country"] {
                            address = "\(city),\(state),\(countryCode)"
                            
                            completionHandler(address: address, error: nil)
                        } else {
                            completionHandler(address: nil, error: "Error to parse address elements!")
                        }
                    } else {
                        completionHandler(address: nil, error: "No address dictionary found!")
                    }
                    
                } else {
                    completionHandler(address: nil, error: "No Placemarks Found!")
                }
            }
        })
    }
    
    func textForShareCallout(on: Bool, socialMedia: Int) -> (text: NSAttributedString, size: CGSize) {
        
        let socialPost = socialMedia == SocialMedia.FACEBOOK.rawValue ? NSLocalizedString("Facebook_post", comment: "Facebook Post") : NSLocalizedString("Twitter_post", comment: "Twitter Post")
        let stateON = NSLocalizedString("ON", comment: "ON")
        let stateOFF = NSLocalizedString("OFF", comment: "OFF")
        let text = (on == true) ? "\(socialPost) \(stateON)" : "\(socialPost) \(stateOFF)"
        let string = (on == true) ?  stateON : stateOFF
        
        
        guard let firstDataRange = text.rangeOfString(string) else {
            let font = UIFont(name: "SFUIText-Regular", size: 12)!
            let attr = NSAttributedString(string: text, attributes: [NSFontAttributeName:font])
            let size = sizeForShareCallout(attr, font: font)
            return (attr, size)
        }
        
        let length = text.startIndex.distanceTo(firstDataRange.startIndex)
        
        let attrString = NSMutableAttributedString(string: text, attributes:[NSFontAttributeName:UIFont(name: "SFUIText-Bold", size: 12)!])
        attrString.addAttributes([NSFontAttributeName:UIFont(name: "SFUIText-Regular", size: 12)!], range: NSMakeRange(0, length))
        
        let font = UIFont(name: "SFUIText-Bold", size: 12)!
        let size = sizeForShareCallout(attrString, font: font)
        
        return (attrString, size)
    }
    
    private func sizeForShareCallout(text: NSAttributedString, font: UIFont) -> CGSize {
        
        let padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        let label: UILabel = UILabel(frame: CGRectMake(0, 0, kLblShareCalloutWidth, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font = font
        label.attributedText = text
        label.sizeToFit()
        
        let width = label.frame.width + padding.left + padding.right
        let heigth = label.frame.height + padding.top + padding.bottom
        
        return CGSize(width: width, height: heigth)
    }
    
    func publishToFacebook(publish: Bool) {
        publishToFacebook = publish
    }
    
    func publishToTwitter(publish: Bool) {
        publishToTwitter = publish
    }
 
    
    func hasLocationBtnTag()->Bool {
        guard let tagList = UserBS.getLoggedUser()?.tagList else {
            return false
        }
        
        return tagList.contains("showlocationbutton2016")
    }
}


