//
//  ChatRoomMapViewController.swift
//  Blicup
//
//  Created by Moymer on 04/05/16.
//  Copyright © 2016 Moymer. All rights reserved.
//

import UIKit
import MapKit


class ChatRoomMapViewController: UIViewController, MKMapViewDelegate, CCHMapClusterControllerDelegate {
    
    @IBOutlet weak var vSearchShadowContainer: UIView!
    @IBOutlet weak var btnSearchBar: BCButton!
    @IBOutlet weak var btnCreateChat: BCButton!
    @IBOutlet weak var mvChatMap: MKMapView!
    
    @IBOutlet weak var vChatsLoading: UIView!
    @IBOutlet weak var ivBlicLogoLoading: UIImageView!
    @IBOutlet weak var lblNoInternet: UILabel!
    
    private var transitionAnimationOriginPoint = CGPointZero
    
    private var mapCluster: CCHMapClusterController!
    private let locationManager = CLLocationManager()
    private let presenter = ChatMapPresenter()
    
    private var zoomer = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        customizeSearchBar()
        customizeBtnCreateChat()
        
        mapCluster = CCHMapClusterController(mapView: mvChatMap)
        mapCluster.maxZoomLevelForClustering = 14
        mapCluster.delegate = self
        self.mvChatMap.delegate = self
        
        let mapCamera = MKMapCamera(lookingAtCenterCoordinate: mvChatMap.centerCoordinate, fromEyeCoordinate: mvChatMap.centerCoordinate, eyeAltitude: 1000000000)
        mvChatMap.setCamera(mapCamera, animated: false)
        
        self.lblNoInternet.text = NSLocalizedString("No internet", comment: "No internet")
        
        customizeChatsLoading()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().statusBarStyle = .Default
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatRoomMapViewController.moveToForeground(_:)), name: LDTPWebSocketManagerNotification.SocketOpened.rawValue, object: nil)
        self.loadChatMaps(self.mvChatMap.region.span, mapView: self.mvChatMap)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBarController?.tabBar.hidden = (self.presentedViewController != nil) // esconde tabbar caso esteja exibindo alguma outra tela
        BlicupAnalytics.sharedInstance.mark_EnteredScreenChatMap()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: LDTPWebSocketManagerNotification.SocketOpened.rawValue, object: nil)
    }
    
    func moveToForeground(notification: NSNotification){
        self.loadChatMaps(self.mvChatMap.region.span, mapView: self.mvChatMap)
    }
    
    private func updateMap() {
        var mapAnnotations = [MKPointAnnotation]()
        
        for index in 0...presenter.numberOfAnnotationsToShow() {
            let annotation = MKPointAnnotation()
            guard let coordinate = presenter.coordinateForChatRoomIndex(index) else {
                continue
            }
            
            annotation.coordinate = coordinate
            annotation.title = presenter.chatRoomIdForIndex(index)
            mapAnnotations.append(annotation)
            
        }
        
        mapCluster.addAnnotations(mapAnnotations, withCompletionHandler: nil)
    }
    
    private func customizeSearchBar() {
        vSearchShadowContainer.layer.shadowOpacity = 0.1
        vSearchShadowContainer.layer.shadowOffset = CGSize(width: 0, height: 0)
        vSearchShadowContainer.layer.shadowRadius = 2.0
        vSearchShadowContainer.layer.shadowColor = UIColor.blackColor().CGColor
        vSearchShadowContainer.layer.masksToBounds = false
        
        btnSearchBar.layer.borderWidth = 1.5
        btnSearchBar.layer.borderColor = UIColor.whiteColor().colorWithAlphaComponent(0.8).CGColor
        btnSearchBar.layer.cornerRadius = 4
        btnSearchBar.clipsToBounds = true
    }
    
    func customizeBtnCreateChat() {
        
        btnCreateChat.layer.shadowOpacity = 0.2
        btnCreateChat.layer.shadowOffset = CGSize(width: 0, height: 0)
        btnCreateChat.layer.shadowRadius = 1.0
        btnCreateChat.layer.shadowColor = UIColor.blackColor().CGColor
        btnCreateChat.layer.masksToBounds = false
        
    }
    
    
    // MARK: Loading Chats
    private func customizeChatsLoading() {
        var imagesArray = [UIImage]()
        for number in 0...30 {
            let name = "BlicLoading_\(number)"
            guard let image = UIImage(named: name) else {
                continue
            }
            
            imagesArray.append(image)
        }
        
        ivBlicLogoLoading.animationImages = imagesArray
    }
    
    private func showChatsLoading() {
        ivBlicLogoLoading.startAnimating()
        self.lblNoInternet.alpha = 0.0
        
        UIView.animateWithDuration(0.5, animations: {
            self.ivBlicLogoLoading.alpha = 1.0
            self.vChatsLoading.alpha = 1
        })
    }
    
    private func hideChatsLoading(withNoInternet: Bool) {
        let alpha:CGFloat = withNoInternet ? 1.0 : 0.0
        
        UIView.animateWithDuration(0.5, animations: {
            self.vChatsLoading.alpha = alpha
            self.lblNoInternet.alpha = alpha
            self.ivBlicLogoLoading.alpha = 0.0
        }) { (finished) in
            self.ivBlicLogoLoading.stopAnimating()
        }
    }
    
    
    // MARK: MapView Delegate
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let clusterAnnotation = annotation as? CCHMapClusterAnnotation else {
            return nil
        }
        var chatAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("clusterAnnotation") as? ChatRoomAnnotationView
        
        if chatAnnotationView != nil {
            chatAnnotationView!.annotation = annotation
        }
        else {
            chatAnnotationView = ChatRoomAnnotationView(annotation: annotation, reuseIdentifier: "clusterAnnotation")
        }
        
        chatAnnotationView!.chatsNumber = clusterAnnotation.annotations.count
        
        
        if clusterAnnotation.annotations.count == 1  || isAllAnnotationsInSameLocation(clusterAnnotation.annotations) || isAnnotationsNear(clusterAnnotation.annotations) {
            loadOverlayForRegionWithLatitude(clusterAnnotation.coordinate.latitude, andLongitude: clusterAnnotation.coordinate.longitude)
        }
        
        return chatAnnotationView
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.fillColor = UIColor(hexString: "#ecf9ffff")
        circleRenderer.strokeColor = UIColor.whiteColor()
        circleRenderer.lineWidth = 1
        
        return circleRenderer
        
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let span = mapView.region.span
        
        if span.latitudeDelta < 0.3 || span.longitudeDelta < 0.3 {
            var newRegion = mapView.region
            newRegion.span = MKCoordinateSpanMake(0.3, 0.3)
            mapView.setRegion(newRegion, animated: true)
        }
        
        let zoomMKMapView = self.getZoomLevel()
        
        if !compare2Double(zoomer, second: zoomMKMapView) && zoomer < zoomMKMapView{
            zoomer = zoomMKMapView
        }
        else if UIApplication.sharedApplication().applicationState == UIApplicationState.Active {
            self.loadChatMaps(span, mapView: mapView)
        }
        
    }
    
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        guard let clusterAnnotation = view.annotation as? CCHMapClusterAnnotation else {
            return
        }
        
        var chatIds = [String]()
        for item in clusterAnnotation.annotations {
            guard let annotation = item as? MKPointAnnotation else {
                continue
            }
            
            if annotation.title != nil && !annotation.title!.isEmpty {
                chatIds.append(annotation.title!)
            }
        }
        
        if !chatIds.isEmpty {
            self.view.userInteractionEnabled = false
            UIView.animateWithDuration(0.2, delay: 0.0, usingSpringWithDamping: 0.2, initialSpringVelocity: 5, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                
                view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1)
            }) { (finished) in
                UIView.animateWithDuration(0.2, delay: 0.0, usingSpringWithDamping: 0.2, initialSpringVelocity: 5, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                    
                    view.transform = CGAffineTransformIdentity
                    
                }) { (finished) in
                    mapView.deselectAnnotation(view.annotation, animated: false)
                    let presenter = MapChatRoomListPresenter(withLocalChats: chatIds)
                    self.tabBarController?.tabBar.hidden = true
                    
                    if presenter.chatRoomsCount() == 1{
                        self.transitionAnimationOriginPoint = view.center
                        self.performSegueWithIdentifier("showSingleChatSegue", sender: presenter)
                    }
                    else{
                        self.performSegueWithIdentifier("showChatListSegue", sender: presenter)
                    }
                    
                    self.view.userInteractionEnabled = true
                }
            }
        }
        
    }
    
    // MARK: CCHMapCluster Delegate
    func mapClusterController(mapClusterController: CCHMapClusterController!, willReuseMapClusterAnnotation mapClusterAnnotation: CCHMapClusterAnnotation!) {
        let annotationView = mvChatMap.viewForAnnotation(mapClusterAnnotation) as? ChatRoomAnnotationView
        
        annotationView?.chatsNumber = mapClusterAnnotation.annotations.count
        
    }
    
    func mapClusterController(mapClusterController: CCHMapClusterController!, willUpdateOverlayMapClusterAnnotation mapClusterAnnotation: CCHMapClusterAnnotation!) {
        if mapClusterAnnotation.annotations.count == 1  || isAllAnnotationsInSameLocation(mapClusterAnnotation.annotations) || isAnnotationsNear(mapClusterAnnotation.annotations) {
            loadOverlayForRegionWithLatitude(mapClusterAnnotation.coordinate.latitude, andLongitude: mapClusterAnnotation.coordinate.longitude)
        }
        
    }
    
    //MARK: Update Map Pins
    
    func loadChatMaps(span: MKCoordinateSpan, mapView: MKMapView){
        showChatsLoading()
        
        presenter.reloadChatRoomsListInArea(mapCenter: mapView.region.center, latDelta: span.latitudeDelta, lngDelta: span.longitudeDelta) { (success) in
            
            let oldAnnotations = self.mapCluster.annotations as NSSet
            self.mapCluster.removeAnnotations(oldAnnotations.allObjects, withCompletionHandler: {
                if success {
                    self.updateMap()
                }
                
                self.hideChatsLoading(!success)
            })
            
        }
    }
    
    
    // MARK: Map Helper Func
    private func isAllAnnotationsInSameLocation(annotationsSet: NSSet) -> Bool {
        let uniqueLocationAnnotations = annotationsSet.valueForKey("coordinate")
        return uniqueLocationAnnotations.count == 1
    }
    
    private func isAnnotationsNear(annotationsSet: NSSet) -> Bool{
        
        guard let annotation = annotationsSet.allObjects as? [MKPointAnnotation] else {
            return false
        }
        
        for item in annotation {
            for itemCompare in annotation{
                if (CLLocation(latitude: itemCompare.coordinate.latitude, longitude: itemCompare.coordinate.longitude).distanceFromLocation(CLLocation(latitude: item.coordinate.latitude, longitude: item.coordinate.longitude)) > 500) {
                    return false
                }
            }
        }
        return true
    }
    
    private func removeOverlayForRegionWithCoordinates(annotationsSet: NSSet) {
        if annotationsSet.count > 1{
            for annotationPoints in annotationsSet{
                if let annotationAux = annotationPoints as? MKPointAnnotation{
                    for ovly in self.mvChatMap.overlays{
                        if ovly.coordinate.latitude == annotationAux.coordinate.latitude && ovly.coordinate.longitude == annotationAux.coordinate.longitude{
                            self.mvChatMap.removeOverlay(ovly)
                        }
                    }
                }
            }
        }
    }
    
    private func loadOverlayForRegionWithLatitude(latitude: Double, andLongitude longitude: Double) {
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let circle = MKCircle(centerCoordinate: coordinates, radius: 4000)
        self.mvChatMap.addOverlay(circle)
    }
    
    let MERCATOR_RADIUS = 85445659.44705395
    let kVerySmallValue = 0.000001
    
    private func compare2Double(first: Double, second: Double) -> Bool{
        if (fabs(first - second) < kVerySmallValue){
            return true
        }
        return false
    }
    
    private func getZoomLevel() -> Double{
        
        var maxGoogleLevels = -1.0
        
        if(maxGoogleLevels < 0.0){
            maxGoogleLevels = log2(MKMapSizeWorld.width / 256.0)
        }
        
        let longitudeDelta = self.mvChatMap.region.span.longitudeDelta
        let mapWidthInPixels = self.mvChatMap.bounds.size.width
        let zoomScale = (longitudeDelta * MERCATOR_RADIUS * M_PI / (180.0 * Double(mapWidthInPixels)))
        var zoomer = maxGoogleLevels - log2(zoomScale)
        if (zoomer < 0){
            zoomer = 0
        }
        
        return zoomer
    }
    
    // MARK: Actions
    
    @IBAction func searchBarPressed(sender: AnyObject) {
        
        self.view.userInteractionEnabled = false
        btnSearchBar.transform = CGAffineTransformMakeScale(0.95, 0.95)
        UIView.animateWithDuration(0.3, animations: {
            self.btnSearchBar.transform = CGAffineTransformMakeScale(1, 1)
        }) { (_) in
            self.performSegueWithIdentifier("ncShowChatRoomAndUserSearchSegue", sender: nil)
            self.view.userInteractionEnabled = true
        }
        
    }
    
    
    // MARK: Create Chat
    @IBAction func createChatPressed(sender: UIButton) {
        self.view.userInteractionEnabled = false
        UIView.animateWithDuration(0.05, animations: {
            self.btnCreateChat.transform = CGAffineTransformMakeScale(1, 1)
        }) { (_) in
            self.performSegueWithIdentifier("createChatSegue", sender: sender)
            self.view.userInteractionEnabled = true
        }
    }
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "createChatSegue"{
            let touch = sender as! UIButton
            (segue as! OHCircleSegue).circleOrigin = CGPoint(x: touch.frame.midX, y: touch.frame.midY)
            
            let seguePoint = CGPoint(x: touch.frame.midX, y: touch.frame.midY + 20)
            
            if let destVC = segue.destinationViewController as? CreateChatRoomViewController{
                destVC.parentView = self
                destVC.cgPointBtnCreate = seguePoint
            }
            
        }
        else if segue.identifier == "showSingleChatSegue" || segue.identifier == "showChatListSegue" {
            // Get the destionation NavController and add the correspondent new controller to be presented
            guard let navController = segue.destinationViewController as? UINavigationController,
                let presenter = sender as? MapChatRoomListPresenter else {
                    return
            }
            
            var viewControllers = [UIViewController]()
            if segue.identifier == "showChatListSegue" {
                let listController = self.storyboard!.instantiateViewControllerWithIdentifier("MapChatListViewController") as! MapChatListViewController
                listController.presenter = presenter
                viewControllers.append(listController)
            }
            else  if segue.identifier == "showSingleChatSegue"{
                (segue as! OHCircleSegue).circleOrigin = self.transitionAnimationOriginPoint
                
                let coverController = self.storyboard!.instantiateViewControllerWithIdentifier("CoverController") as! ChatRoomsListHorizontalPageViewController
                coverController.showOnlyOneChat = true
                coverController.hidesBottomBarWhenPushed = true
                let currentIndex = NSIndexPath(forItem: 0, inSection: 0)
                let presenter = CoverChatRoomsListPresenter(withLocalChats: presenter.currentChatIds())
                presenter.currentIndex = currentIndex
                coverController.initCover(coverPresenter: presenter)
                coverController.parentView = self
                coverController.cgPointBtnCreate = self.transitionAnimationOriginPoint
                viewControllers.append(coverController)
            }
            
            navController.setViewControllers(viewControllers, animated: false)
        }
        
    }
    
    @IBAction func unwindFromSecondary(segue: UIStoryboardSegue) {
        
    }
}
