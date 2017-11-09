//
//  MapViewController.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 6/8/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, CustomCalloutViewDelegate, UITextFieldDelegate {
    
    //@IBOutlet weak var mapView: CustomMapView!
    @IBOutlet weak var mapView: CustomMapView!
    //@IBOutlet var rotationRecognizer: UIRotationGestureRecognizer!
    @IBOutlet weak var filterByDateButton: UIBarButtonItem!
    
    //var mapView: CustomMapView!
    var detailedImages: [DetailedImageObject] = []
    var managedContext: NSManagedObjectContext!
    var calloutView: CustomCalloutView!
    var selectedImage: DetailedImageObject?
    var overlay : MapLineOverlay?
    
    var menuController: PopupMenuController?
    
    var testImages : [DetailedImageObject] = []
    
    override func viewDidLoad() {
        mapView.delegate = self

        // get all images for project
        self.loadImages()

        if (detailedImages.count > 0) {
            // Compute the
            self.centerMapOnLocation()
        
            self.showAll()
        } else {
            print("No DetailedImageObjects with a location")
        }
        
        //self.seeAllAnnotations(mapView.annotations as! [MKAnnotation])
        
        self.calloutView = CustomCalloutView()
        self.calloutView.delegate = self
        
        self.mapView.calloutView = self.calloutView

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if( menuController == nil ) {
           super.viewDidDisappear(animated)
           mapView.removeFromSuperview()
        }
    }
    
    func initTestImages() {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "MM/dd/yyyy hh:mm a"
        dateFormater.locale = Locale.current
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!

        
        let t1 = NSEntityDescription.insertNewObject(forEntityName: "DetailedImageObject",
            into: managedContext) as! DetailedImageObject
        t1.setCoordinate(30.0, longitude: -100.0)
        t1.date = dateFormater.date(from: "6/19/2015 09:00 AM")!
        //t1.imageData = UIImageJPEGRepresentation(UIImage(named: "sand")!,1.0)!
        t1.scale = 0.005
        t1.compassOrientation = 0
        t1.name = "Day"
        self.testImages.append(t1)
        
        let t2 = NSEntityDescription.insertNewObject(forEntityName: "DetailedImageObject",
            into: managedContext) as! DetailedImageObject
        t2.setCoordinate(35.0, longitude: -120.0)
        t2.date = dateFormater.date(from: "6/13/2015 09:00 AM")!
        //t2.imageData = UIImageJPEGRepresentation(UIImage(named: "sand")!,1.0)!
        t2.scale = 0.005
        t2.compassOrientation = 0
        t2.name = "Week"
        self.testImages.append(t2)
        
        let t3 = NSEntityDescription.insertNewObject(forEntityName: "DetailedImageObject",
            into: managedContext) as! DetailedImageObject
        t3.setCoordinate(45.0, longitude: -70.0)
        t3.date = dateFormater.date(from: "5/25/2015 09:00 AM")!
        //t3.imageData = UIImageJPEGRepresentation(UIImage(named: "sand")!,1.0)!
        t3.scale = 0.005
        t3.compassOrientation = 0
        t3.name = "Month"
        self.testImages.append(t3)
        
        let t4 = NSEntityDescription.insertNewObject(forEntityName: "DetailedImageObject",
            into: managedContext) as! DetailedImageObject
        t4.setCoordinate(40.0, longitude: -100.0)
        t4.date = dateFormater.date(from: "9/8/2014 09:00 AM")!
        //t4.imageData = UIImageJPEGRepresentation(UIImage(named: "sand")!,1.0)!
        t4.scale = 0.005
        t4.compassOrientation = 0
        t4.name = "Year"
        self.testImages.append(t4)
    }
    
    func loadImages() {
        // Get the full detailed object from the selected name
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"DetailedImageObject")
        
        //sort so most recent is first
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        // only get the detailedImages that have a location
        fetchRequest.predicate = NSPredicate(format: "latitude!=nil AND longitude!=nil AND project.name==%@", currentProject.name)
        
        do {
            try detailedImages = (managedContext.fetch(fetchRequest) as? [DetailedImageObject])!
        } catch {
            
        }
        
    }
    
    func centerMapOnLocation() {
        var loc : MKMapPoint?
        for image in detailedImages {
            if( image.coordinate != nil ) {
                loc = MKMapPointForCoordinate(image.coordinate!)
                break
            }
        }
        if( loc == nil ) {
            return
        }
        
        var minX = loc!.x
        var minY = loc!.y
        var maxX = loc!.x
        var maxY = loc!.y
        for image in detailedImages {
            if( image.coordinate != nil ) {
               loc = MKMapPointForCoordinate(image.coordinate!)
               minX = min(loc!.x, minX)
               minY = min(loc!.y, minY)
               maxX = max(loc!.x, maxX)
               maxY = max(loc!.y, maxY)
            }
        }
        let size = MKMapSize(width: maxX-minX, height: maxY-minY)
        let rect = MKMapRect(origin: MKMapPoint(x: minX-size.width*0.1, y: minY-size.height*0.1), size: MKMapSize(width: size.width*1.2, height: size.height*1.2))
        let loc_rect = MKCoordinateRegionForMapRect(rect)
        
        mapView.setRegion(loc_rect, animated: true)
    }
    
    func seeAllAnnotations(_ annotations: [MKAnnotation]) {
        if (annotations.count > 1) {
            var upper = annotations[0].coordinate
            var lower = annotations[0].coordinate
            
            for ann in annotations {
                if ann.coordinate.latitude > upper.latitude {
                    upper.latitude = ann.coordinate.latitude
                }
                if ann.coordinate.latitude < lower.latitude {
                    lower.latitude = ann.coordinate.latitude
                }
                if ann.coordinate.longitude > upper.longitude {
                    upper.longitude = ann.coordinate.longitude
                }
                if ann.coordinate.longitude < lower.longitude {
                    lower.longitude = ann.coordinate.longitude
                }
            }
            var locationSpan = MKCoordinateSpan()
            locationSpan.latitudeDelta = upper.latitude - lower.latitude
            locationSpan.longitudeDelta = upper.longitude - lower.longitude
            
            var locationCenter = CLLocationCoordinate2D()
            locationCenter.latitude = (upper.latitude + lower.latitude)/2
            locationCenter.longitude = (upper.longitude + lower.longitude)/2
            let region = MKCoordinateRegionMake(locationCenter, locationSpan)
            
            mapView.setRegion(region, animated: true)
        } else if annotations.count == 1 {
            let region = MKCoordinateRegionMake(annotations[0].coordinate, MKCoordinateSpanMake(2.0, 2.0))
            mapView.setRegion(region, animated: true)
        } else {
            // no annotations set to default
            mapView.setRegion(MKMapView().region, animated: true)
        }
    }
    
    func removeAll() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
    }
    
    @objc func showAll() {
        self.removeAll()
        for detailedImage in detailedImages {
            let annotation = ImageAnnotation(detailedImage: detailedImage)
            mapView.addAnnotation(annotation)
        }
        
        menuController?.dismiss(animated: true, completion: nil)
        menuController = nil
        self.filterByDateButton.title = "Filter by Date:"
    }
    
    //Mark: - Actions: Filtering by Date
    @IBAction func tappedFilterByDate(_ sender: UIBarButtonItem) {
        let width = 150
        let height = 45
        menuController = PopupMenuController()
        menuController!.initCellContents(6, cols: 1)
        
        //Add Filter Options
        let mostRecentButton = UIButton(type: UIButtonType.system)
        mostRecentButton.setTitle("Last Day", for: UIControlState())
        mostRecentButton.frame = CGRect(x: 0, y: 0, width: width, height: height)
        mostRecentButton.addTarget(self, action: #selector(MapViewController.showAnnotationsForLatestDay(_:)), for: UIControlEvents.touchUpInside)
        menuController!.cellContents[0][0] = mostRecentButton
        
        let lastWeekButton = UIButton(type: UIButtonType.system)
        lastWeekButton.setTitle("Last Week", for: UIControlState())
        lastWeekButton.frame = CGRect(x: 0, y: 0, width: width, height: height)
        lastWeekButton.addTarget(self, action: #selector(MapViewController.showAnnotationsForLatestWeek), for: UIControlEvents.touchUpInside)
        menuController!.cellContents[1][0] = lastWeekButton
        
        let lastMonthButton = UIButton(type: UIButtonType.system)
        lastMonthButton.setTitle("Last Month", for: UIControlState())
        lastMonthButton.frame = CGRect(x: 0, y: 0, width: width, height: height)
        lastMonthButton.addTarget(self, action: #selector(MapViewController.showAnnotationsForLatestMonth), for: UIControlEvents.touchUpInside)
        menuController!.cellContents[2][0] = lastMonthButton
        
        let lastYearButton = UIButton(type: UIButtonType.system)
        lastYearButton.setTitle("Last Year", for: UIControlState())
        lastYearButton.frame = CGRect(x: 0, y: 0, width: width, height: height)
        lastYearButton.addTarget(self, action: #selector(MapViewController.showAnnotationsForLatestYear), for: UIControlEvents.touchUpInside)
        menuController!.cellContents[3][0] = lastYearButton

        let AllButton = UIButton(type: UIButtonType.system)
        AllButton.setTitle("All", for: UIControlState())
        AllButton.frame = CGRect(x: 0, y: 0, width: width, height: height)
        AllButton.addTarget(self, action: #selector(MapViewController.showAll), for: UIControlEvents.touchUpInside)
        menuController!.cellContents[4][0] = AllButton
        
        let textFeild = UITextField(frame: CGRect(x: 0, y: 0, width: width-10, height: height-10))
        textFeild.placeholder = "MM/DD/YYYY"
        textFeild.keyboardType = UIKeyboardType.numbersAndPunctuation
        textFeild.delegate = self
        menuController!.cellContents[5][0] = textFeild


        //set up menu Controller
        menuController!.modalPresentationStyle = UIModalPresentationStyle.popover
        menuController!.preferredContentSize.width = 150
        menuController!.tableView.rowHeight = 45
        menuController!.preferredContentSize.height = menuController!.preferredHeight()
        menuController!.popoverPresentationController?.barButtonItem = sender
        menuController!.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.any
        
        self.present(menuController!, animated: true, completion: nil)
    }
    
    func showAnnotationsForTimeIntervalFromCurrentDate(_ interval: TimeInterval) {
        self.removeAll()
        let currentDate = Date()
        for detailedImage in detailedImages {
            //if the date is later in time than the earliestAllowedDate
            if currentDate.timeIntervalSince(detailedImage.date as Date) < interval {
                let annotation = ImageAnnotation(detailedImage: detailedImage)
                mapView.addAnnotation(annotation)
            }
        }
        menuController?.dismiss(animated: true, completion: nil)
        menuController = nil
    }
    
    @objc func showAnnotationsForLatestDay(_ sender: UIButton) {
        //24hours/day * 60min/hour * 60sec/min
        let dayInterval : TimeInterval = 86400 //secs
        showAnnotationsForTimeIntervalFromCurrentDate(dayInterval)
        filterByDateButton.title = "Filter by Date: Latest Day"
    }
    
    @objc func showAnnotationsForLatestWeek() {
        //7days/week * 24hours/day * 60min/hour * 60sec/min
        let weekInterval : TimeInterval = 604800 //secs
        showAnnotationsForTimeIntervalFromCurrentDate(weekInterval)
        filterByDateButton.title = "Filter by Date: Latest Week"
    }
    
    @objc func showAnnotationsForLatestMonth() {
        //30.5 days/month * 24hours/day * 60min/hour * 60sec/min
        let monthInterval : TimeInterval = 2635200 //secs
        showAnnotationsForTimeIntervalFromCurrentDate(monthInterval)
        filterByDateButton.title = "Filter by Date: Latest Month"
    }
    
    @objc func showAnnotationsForLatestYear() {
        //24hours/day * 60min/hour * 60sec/min
        let yearInterval : TimeInterval = 31536000 //secs
        showAnnotationsForTimeIntervalFromCurrentDate(yearInterval)
        filterByDateButton.title = "Filter by Date: Latest Year"
    }
    
    func showAnnotationsForTimeSpan (_ interval: TimeInterval, fromDate: Date) {
        self.removeAll()
        for detailedImage in detailedImages {
            //if the date is later in time than the earliestAllowedDate
            print(detailedImage.date)
            let intervalSinceDate = detailedImage.date.timeIntervalSince(fromDate)
            print(intervalSinceDate)
            if intervalSinceDate < interval && intervalSinceDate >= 0 {
                let annotation = ImageAnnotation(detailedImage: detailedImage)
                mapView.addAnnotation(annotation)
            }
        }
        menuController?.dismiss(animated: true, completion: nil)
        menuController = nil
    }
    
    //Mark: - Actions: Filtering by Date
    @IBAction func tappedSettings(_ sender: UIBarButtonItem) {
        let width = 150
        let height = 45
        menuController = PopupMenuController()
        menuController!.initCellContents(3, cols: 1)
        
        //Add Map display Options
        let standardButton = UIButton(type: UIButtonType.system)
        standardButton.setTitle("Standard", for: UIControlState())
        standardButton.frame = CGRect(x: 0, y: 0, width: width, height: height)
        standardButton.addTarget(self, action: #selector(MapViewController.showStandardMap), for: UIControlEvents.touchUpInside)
        menuController!.cellContents[0][0] = standardButton
        
        let satelliteButton = UIButton(type: UIButtonType.system)
        satelliteButton.setTitle("Satellite", for: UIControlState())
        satelliteButton.frame = CGRect(x: 0, y: 0, width: width, height: height)
        satelliteButton.addTarget(self, action: #selector(MapViewController.showSatelliteMap), for: UIControlEvents.touchUpInside)
        menuController!.cellContents[1][0] = satelliteButton
        
        let hybridButton = UIButton(type: UIButtonType.system)
        hybridButton.setTitle("Hybrid", for: UIControlState())
        hybridButton.frame = CGRect(x: 0, y: 0, width: width, height: height)
        hybridButton.addTarget(self, action: #selector(MapViewController.showHybridMap), for: UIControlEvents.touchUpInside)
        menuController!.cellContents[2][0] = hybridButton

        //set up menu Controller
        menuController!.modalPresentationStyle = UIModalPresentationStyle.popover
        //menuController!.preferredContentSize.width = width
        menuController!.tableView.rowHeight = 45
        menuController!.preferredContentSize.height = menuController!.preferredHeight()
        menuController!.popoverPresentationController?.barButtonItem = sender
        menuController!.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.any
        
        self.present(menuController!, animated: true, completion: nil)
    }
    
    @objc func showStandardMap() {
        self.mapView.mapType = MKMapType.standard
        menuController?.dismiss(animated: true, completion: nil)
        menuController = nil
    }
    @objc func showSatelliteMap() {
        self.mapView.mapType = MKMapType.satellite
        menuController?.dismiss(animated: true, completion: nil)
        menuController = nil
    }
    @objc func showHybridMap() {
        self.mapView.mapType = MKMapType.hybrid
        menuController?.dismiss(animated: true, completion: nil)
        menuController = nil
    }

    
    //Mark: - UITextFieldDelegateMethods
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.timeStyle = DateFormatter.Style.none
        dateFormatter.locale = Locale.current

        if let date = dateFormatter.date(from: textField.text!) { //date is in GMT
            self.showAnnotationsForTimeSpan(86400, fromDate: date)
            self.filterByDateButton.title = "Filter by Date: " + textField.text!
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    //Mark: - MKMapViewDelegate methods
    
    //gets called for each annotation added to the map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? ImageAnnotation {
            let identifier = "ImageAnnotationView"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKPinAnnotationView { // checks to see if an unseen annotation view can be reused
                    dequeuedView.annotation = annotation
                    view = dequeuedView
            } else {
                // create a new MKPinAnnotationView
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = false
            }
            return view
        }
        return nil
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let ann = view.annotation as? ImageAnnotation {
            //annView.setMapLineViewOrientation(self.mapView.camera.heading)
            
            // apply the MKAnnotationView's basic properties
            self.calloutView = CustomCalloutView()
            self.calloutView.delegate = self
            self.mapView.calloutView = self.calloutView
            self.selectedImage = nil
            self.calloutView.title = ann.title as NSString?;
            self.calloutView.subtitle = ann.subtitle as NSString?;
            
            
            let imageView = UIImageView(image: ann.image)
            let aspectRatio = imageView.image!.size.height/imageView.image!.size.width
            imageView.setFrameSize(CGSize(width: 133, height: 133 * aspectRatio))
            imageView.contentMode = UIViewContentMode.scaleToFill
            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MapViewController.calloutImageTapped)))
            self.calloutView.contentView = imageView
            
            // Apply the MKAnnotationView's desired calloutOffset (from the top-middle of the view)
            self.calloutView.calloutOffset = view.calloutOffset;
            
            //set selectedImage
            self.selectedImage = ann.detailedImage
            
            // This does all the magic.
            self.calloutView.presentCalloutFromRect(view.bounds, inView:view, constrainedToView:self.view, animated:true)
            
            if (ann.length != nil && ann.compassOrientation != nil) {
                self.overlay = MapLineOverlay(
                    length: ann.length!, compassOrientation: ann.compassOrientation!,
                    coordinate: ann.coordinate, object_scale: ann.detailedImage.scale != nil ? ann.detailedImage.scale!.doubleValue : 1.0
                )
                mapView.add(overlay!)
            }
        }
    }
    
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        self.calloutView.dismissCalloutAnimated(true)
        
        
        if (overlay != nil) {
            mapView.remove(overlay!)
        }
    }
    
    func mapView(_ mapView: MKMapView,rendererFor overlay: MKOverlay)-> MKOverlayRenderer {
        let overlayView = MapLineOverlayView(overlay: overlay)
        return overlayView
    }
    
    @objc func calloutImageTapped() {
        let alert = UIAlertController(
            title: "Interpret this Outcrop?", message: nil, preferredStyle: .alert
        )
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //do stuff
        }
        alert.addAction(cancelAction)
        
        let yesAction: UIAlertAction = UIAlertAction(title: "Yes", style: .default) { action -> Void in
            self.performSegue(withIdentifier: "mapToDrawing", sender: self.mapView)
        }
        alert.addAction(yesAction)
        self.present(alert, animated: true, completion: nil)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mapToDrawing" {
            var drawingVC = segue.destination as? DrawingViewController
            if( drawingVC == nil ) {
                let navigationVC = segue.destination as? UINavigationController
                if( navigationVC != nil ) {
                    for vc in navigationVC!.viewControllers {
                        drawingVC = vc as? DrawingViewController
                        if( drawingVC != nil ) {
                            break
                        }
                    }
                }
            }

            if( drawingVC != nil ) {
                drawingVC!.detailedImage = self.selectedImage!
                drawingVC!.image = selectedImage!.image()!
                
                //get ImageInfo
                var imageInfo = ImageInfo()
                imageInfo.xDimension = Int(drawingVC!.image!.size.width)
                imageInfo.yDimension = Int(drawingVC!.image!.size.height)
                imageInfo.latitude = self.selectedImage!.latitude?.doubleValue
                imageInfo.longitude = self.selectedImage!.longitude?.doubleValue
                imageInfo.compassOrienation = self.selectedImage!.compassOrientation?.doubleValue
                imageInfo.date = self.selectedImage!.date
                imageInfo.scale = self.selectedImage!.scale?.doubleValue
                
                drawingVC!.imageInfo = imageInfo
            }
        }
    }
    
    //Mark - CustomCalloutDelegate Methods
    func calloutView(_ calloutView: CustomCalloutView, delayForRepositionWithSize offset: CGSize) -> TimeInterval {
        // When the callout is being asked to present in a way where it or its target will be partially offscreen, it asks us
        // if we'd like to reposition our surface first so the callout is completely visible. Here we scroll the map into view,
        // but it takes some math because we have to deal in lon/lat instead of the given offset in pixels.
        
        var coordinate = self.mapView.centerCoordinate;
        
        // where's the center coordinate in terms of our view?
        var center : CGPoint = self.mapView.convert(coordinate, toPointTo:self.view)
        
        // move it by the requested offset
        center.x -= offset.width;
        center.y -= offset.height;
        
        // and translate it back into map coordinates
        coordinate = self.mapView.convert(center, toCoordinateFrom:self.view)
        
        // move the map!
        self.mapView.setCenter(coordinate, animated:true)
        
        // tell the callout to wait for a while while we scroll (we assume the scroll delay for MKMapView matches UIScrollView)
        return (1.0/3.0)
    }
}

class CustomMapView: MKMapView , UIGestureRecognizerDelegate{
    var calloutView : CustomCalloutView?

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if (touch.view!.isKind(of: UIControl.self)) {
            return false
        } else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        let calloutMaybe = self.calloutView!.hitTest(self.calloutView!.convert(point, from: self), with: event)
        if (calloutMaybe != nil) {
            return calloutMaybe
        } else {
            return super.hitTest(point, with: event)
        }
    }

}
