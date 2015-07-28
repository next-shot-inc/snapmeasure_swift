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

        self.loadImages()

        if (detailedImages.count > 0) {
            
            self.centerMapOnLocation(detailedImages[0].coordinate!, withRadius: CLLocationDistance(1.0))
        
            self.showAll()
        } else {
            println("No DetailedImageObjects with a location")
        }
        
        //self.seeAllAnnotations(mapView.annotations as! [MKAnnotation])
        
        self.calloutView = CustomCalloutView()
        self.calloutView.delegate = self
        
        self.mapView.calloutView = self.calloutView

    }
    
    func initTestImages() {
        let dateFormater = NSDateFormatter()
        dateFormater.dateFormat = "MM/dd/yyyy hh:mm a"
        dateFormater.locale = NSLocale.currentLocale()
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!

        
        let t1 = NSEntityDescription.insertNewObjectForEntityForName("DetailedImageObject",
            inManagedObjectContext: managedContext) as! DetailedImageObject
        t1.setCoordinate(30.0, longitude: -100.0)
        t1.date = dateFormater.dateFromString("6/19/2015 09:00 AM")!
        t1.imageData = UIImageJPEGRepresentation(UIImage(named: "sand")!,1.0)
        t1.scale = 0.005
        t1.compassOrientation = 0
        t1.name = "Day"
        self.testImages.append(t1)
        
        let t2 = NSEntityDescription.insertNewObjectForEntityForName("DetailedImageObject",
            inManagedObjectContext: managedContext) as! DetailedImageObject
        t2.setCoordinate(35.0, longitude: -120.0)
        t2.date = dateFormater.dateFromString("6/13/2015 09:00 AM")!
        t2.imageData = UIImageJPEGRepresentation(UIImage(named: "sand")!,1.0)
        t2.scale = 0.005
        t2.compassOrientation = 0
        t2.name = "Week"
        self.testImages.append(t2)
        
        let t3 = NSEntityDescription.insertNewObjectForEntityForName("DetailedImageObject",
            inManagedObjectContext: managedContext) as! DetailedImageObject
        t3.setCoordinate(45.0, longitude: -70.0)
        t3.date = dateFormater.dateFromString("5/25/2015 09:00 AM")!
        t3.imageData = UIImageJPEGRepresentation(UIImage(named: "sand")!,1.0)
        t3.scale = 0.005
        t3.compassOrientation = 0
        t3.name = "Month"
        self.testImages.append(t3)
        
        let t4 = NSEntityDescription.insertNewObjectForEntityForName("DetailedImageObject",
            inManagedObjectContext: managedContext) as! DetailedImageObject
        t4.setCoordinate(40.0, longitude: -100.0)
        t4.date = dateFormater.dateFromString("9/8/2014 09:00 AM")!
        t4.imageData = UIImageJPEGRepresentation(UIImage(named: "sand")!,1.0)
        t4.scale = 0.005
        t4.compassOrientation = 0
        t4.name = "Year"
        self.testImages.append(t4)
    }
    
    func loadImages() {
        // Get the full detailed object from the selected name
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName:"DetailedImageObject")
        
        //sort so most recent is first
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        // only get the detailedImages that have a location
        fetchRequest.predicate = NSPredicate(format: "latitude!=nil AND longitude!=nil AND project.name==%@", currentProject.name)
        
        var error: NSError?
        detailedImages = (managedContext.executeFetchRequest(fetchRequest,
            error: &error) as? [DetailedImageObject])!
    }
    
    func centerMapOnLocation(coordinate: CLLocationCoordinate2D, withRadius radius: CLLocationDistance) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate,
            radius * 2.0, radius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func seeAllAnnotations(annotations: [MKAnnotation]) {
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
    
    func showAll() {
        self.removeAll()
        for detailedImage in detailedImages {
            let annotation = ImageAnnotation(detailedImage: detailedImage)
            mapView.addAnnotation(annotation)
        }
        
        menuController?.dismissViewControllerAnimated(true, completion: nil)
        self.filterByDateButton.title = "Filter by Date:"
    }
    
    //Mark: - Actions: Filtering by Date
    @IBAction func tappedFilterByDate(sender: UIBarButtonItem) {
        let width = 150
        let height = 45
        menuController = PopupMenuController()
        menuController!.initCellContents(6, cols: 1)
        
        //Add Filter Options
        let mostRecentButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        mostRecentButton.setTitle("Last Day", forState: UIControlState.Normal)
        mostRecentButton.frame = CGRect(x: 0, y: 0, width: width, height: height)
        mostRecentButton.addTarget(self, action: "showAnnotationsForLatestDay:", forControlEvents: UIControlEvents.TouchUpInside)
        menuController!.cellContents[0][0] = mostRecentButton
        
        let lastWeekButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        lastWeekButton.setTitle("Last Week", forState: UIControlState.Normal)
        lastWeekButton.frame = CGRect(x: 0, y: 0, width: width, height: height)
        lastWeekButton.addTarget(self, action: "showAnnotationsForLatestWeek", forControlEvents: UIControlEvents.TouchUpInside)
        menuController!.cellContents[1][0] = lastWeekButton
        
        let lastMonthButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        lastMonthButton.setTitle("Last Month", forState: UIControlState.Normal)
        lastMonthButton.frame = CGRect(x: 0, y: 0, width: width, height: height)
        lastMonthButton.addTarget(self, action: "showAnnotationsForLatestMonth", forControlEvents: UIControlEvents.TouchUpInside)
        menuController!.cellContents[2][0] = lastMonthButton
        
        let lastYearButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        lastYearButton.setTitle("Last Year", forState: UIControlState.Normal)
        lastYearButton.frame = CGRect(x: 0, y: 0, width: width, height: height)
        lastYearButton.addTarget(self, action: "showAnnotationsForLatestYear", forControlEvents: UIControlEvents.TouchUpInside)
        menuController!.cellContents[3][0] = lastYearButton

        let AllButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        AllButton.setTitle("All", forState: UIControlState.Normal)
        AllButton.frame = CGRect(x: 0, y: 0, width: width, height: height)
        AllButton.addTarget(self, action: "showAll", forControlEvents: UIControlEvents.TouchUpInside)
        menuController!.cellContents[4][0] = AllButton
        
        let textFeild = UITextField(frame: CGRect(x: 0, y: 0, width: width-10, height: height-10))
        textFeild.placeholder = "MM/DD/YYYY"
        textFeild.keyboardType = UIKeyboardType.NumbersAndPunctuation
        textFeild.delegate = self
        menuController!.cellContents[5][0] = textFeild


        //set up menu Controller
        menuController!.modalPresentationStyle = UIModalPresentationStyle.Popover
        menuController!.preferredContentSize.width = 150
        menuController!.tableView.rowHeight = 45
        menuController!.preferredContentSize.height = menuController!.preferredHeight()
        menuController!.popoverPresentationController?.barButtonItem = sender
        menuController!.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Any
        
        self.presentViewController(menuController!, animated: true, completion: nil)
    }
    
    func showAnnotationsForTimeIntervalFromCurrentDate(interval: NSTimeInterval) {
        self.removeAll()
        let currentDate = NSDate()
        for detailedImage in detailedImages {
            //if the date is later in time than the earliestAllowedDate
            if currentDate.timeIntervalSinceDate(detailedImage.date) < interval {
                let annotation = ImageAnnotation(detailedImage: detailedImage)
                mapView.addAnnotation(annotation)
            }
        }
        menuController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showAnnotationsForLatestDay(sender: UIButton) {
        //24hours/day * 60min/hour * 60sec/min
        let dayInterval : NSTimeInterval = 86400 //secs
        self.showAnnotationsForTimeIntervalFromCurrentDate(dayInterval)
        self.filterByDateButton.title = "Filter by Date: Latest Day"
    }
    
    func showAnnotationsForLatestWeek() {
        //7days/week * 24hours/day * 60min/hour * 60sec/min
        let weekInterval : NSTimeInterval = 604800 //secs
        self.showAnnotationsForTimeIntervalFromCurrentDate(weekInterval)
        self.filterByDateButton.title = "Filter by Date: Latest Week"
    }
    
    func showAnnotationsForLatestMonth() {
        //30.5 days/month * 24hours/day * 60min/hour * 60sec/min
        let monthInterval : NSTimeInterval = 2635200 //secs
        self.showAnnotationsForTimeIntervalFromCurrentDate(monthInterval)
        self.filterByDateButton.title = "Filter by Date: Latest Month"
    }
    
    func showAnnotationsForLatestYear() {
        //24hours/day * 60min/hour * 60sec/min
        let yearInterval : NSTimeInterval = 31536000 //secs
        self.showAnnotationsForTimeIntervalFromCurrentDate(yearInterval)
        self.filterByDateButton.title = "Filter by Date: Latest Year"
    }
    
    func showAnnotationsForTimeSpan (interval: NSTimeInterval, fromDate: NSDate) {
        self.removeAll()
        for detailedImage in detailedImages {
            //if the date is later in time than the earliestAllowedDate
            println(detailedImage.date)
            let intervalSinceDate = detailedImage.date.timeIntervalSinceDate(fromDate)
            println(intervalSinceDate)
            if intervalSinceDate < interval && intervalSinceDate >= 0 {
                let annotation = ImageAnnotation(detailedImage: detailedImage)
                mapView.addAnnotation(annotation)
            }
        }
        menuController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //Mark: - UITextFeildDelegateMethods
    
    func textFieldDidEndEditing(textField: UITextField) {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        dateFormatter.locale = NSLocale.currentLocale()

        if let date = dateFormatter.dateFromString(textField.text) { //date is in GMT
            self.showAnnotationsForTimeSpan(86400, fromDate: date)
            self.filterByDateButton.title = "Filter by Date: " + textField.text
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    //Mark: - MKMapViewDelegate methods
    
    //gets called for each annotation added to the map
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if let annotation = annotation as? ImageAnnotation {
            let identifier = "ImageAnnotationView"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
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

    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        if let ann = view.annotation as? ImageAnnotation {
            //annView.setMapLineViewOrientation(self.mapView.camera.heading)
            
            // apply the MKAnnotationView's basic properties
            self.calloutView.title = ann.title;
            self.calloutView.subtitle = ann.subtitle;
            
            
            let imageView = UIImageView(image: ann.image)
            let aspectRatio = imageView.image!.size.height/imageView.image!.size.width
            imageView.setFrameSize(CGSize(width: 133, height: 133 * aspectRatio))
            imageView.contentMode = UIViewContentMode.ScaleToFill
            imageView.userInteractionEnabled = true
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "calloutImageTapped"))
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
                mapView.addOverlay(overlay)
            }
        }
    }
    
    
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        self.calloutView.dismissCalloutAnimated(true)
        //self.calloutView = CustomCalloutView()
        //self.calloutView.delegate = self
        //self.mapView.calloutView = self.calloutView
        //self.selectedImage = nil
        
        if (overlay != nil) {
            mapView.removeOverlay(overlay!)
        }
    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if overlay is MapLineOverlay {
            let overlayView = MapLineOverlayView(overlay: overlay)
            return overlayView
        } else {
            return nil
        }
    }
    
    func calloutImageTapped() {
        var goToDrawing = false
        let alert = UIAlertController(
            title: "Interpret this Outcrop?", message: nil, preferredStyle: .Alert
        )
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            //do stuff
        }
        alert.addAction(cancelAction)
        
        let yesAction: UIAlertAction = UIAlertAction(title: "Yes", style: .Default) { action -> Void in
            self.performSegueWithIdentifier("mapToDrawing", sender: self.mapView)
        }
        alert.addAction(yesAction)
        self.presentViewController(alert, animated: true, completion: nil)

    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "mapToDrawing" {
            let drawingVC = segue.destinationViewController as! DrawingViewController
            
            drawingVC.detailedImage = self.selectedImage!
            drawingVC.image = UIImage(data: self.selectedImage!.imageData)
            
            //get ImageInfo
            var imageInfo = ImageInfo()
            imageInfo.xDimension = Int(drawingVC.image!.size.width)
            imageInfo.yDimension = Int(drawingVC.image!.size.height)
            imageInfo.latitude = self.selectedImage!.latitude?.doubleValue
            imageInfo.longitude = self.selectedImage!.longitude?.doubleValue
            imageInfo.compassOrienation = self.selectedImage!.compassOrientation?.doubleValue
            imageInfo.date = self.selectedImage!.date
            imageInfo.scale = self.selectedImage!.scale?.doubleValue
            
            
            drawingVC.imageInfo = imageInfo
        }
    }
    
    //Mark - CustomCalloutDelegate Methods
    func calloutView(calloutView: CustomCalloutView, delayForRepositionWithSize offset: CGSize) -> NSTimeInterval {
        // When the callout is being asked to present in a way where it or its target will be partially offscreen, it asks us
        // if we'd like to reposition our surface first so the callout is completely visible. Here we scroll the map into view,
        // but it takes some math because we have to deal in lon/lat instead of the given offset in pixels.
        
        var coordinate = self.mapView.centerCoordinate;
        
        // where's the center coordinate in terms of our view?
        var center : CGPoint = self.mapView.convertCoordinate(coordinate, toPointToView:self.view)
        
        // move it by the requested offset
        center.x -= offset.width;
        center.y -= offset.height;
        
        // and translate it back into map coordinates
        coordinate = self.mapView.convertPoint(center, toCoordinateFromView:self.view)
        
        // move the map!
        self.mapView.setCenterCoordinate(coordinate, animated:true)
        
        // tell the callout to wait for a while while we scroll (we assume the scroll delay for MKMapView matches UIScrollView)
        return (1.0/3.0)
    }
}

class CustomMapView: MKMapView , UIGestureRecognizerDelegate{
    var calloutView : CustomCalloutView?

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        
        if (touch.view.isKindOfClass(UIControl)) {
            return false
        } else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
    }
    
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        
        let calloutMaybe = self.calloutView!.hitTest(self.calloutView!.convertPoint(point, fromView: self), withEvent: event)
        if (calloutMaybe != nil) {
            return calloutMaybe
        } else {
            return super.hitTest(point, withEvent: event)
        }
    }

}
