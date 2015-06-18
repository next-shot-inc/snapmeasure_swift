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

class MapViewController: UIViewController, MKMapViewDelegate, CustomCalloutViewDelegate {
    
    //@IBOutlet weak var mapView: CustomMapView!
    //@IBOutlet var rotationRecognizer: UIRotationGestureRecognizer!
    
    var mapView: CustomMapView!
    var detailedImages: [DetailedImageObject] = []
    var managedContext: NSManagedObjectContext!
    var calloutView: CustomCalloutView!
    var selectedImage: DetailedImageObject?
    var overlay : MapLineOverlay?
    
    override func viewDidLoad() {
        mapView = CustomMapView(frame: self.view.bounds)
        mapView.delegate = self
        mapView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        //mapView.addGestureRecognizer(rotationRecognizer)
        self.view.addSubview(mapView)
        
        
        self.loadImages()
        //println("count = ", detailedImages.count)
        if (detailedImages.count > 0) {
            
            let initialLocation = CLLocation(latitude: detailedImages[0].latitude!.doubleValue, longitude: detailedImages[0].longitude!.doubleValue)
            //println("latitude: %d\nlongitude: %d",detailedImages[0].latitude!.doubleValue,detailedImages[0].longitude!.doubleValue)
            self.centerMapOnLocation(initialLocation, withRadius: CLLocationDistance(1.0))
            
            mapView.delegate = self
            for detailedImage in detailedImages {
                let annotation = ImageAnnotation(detailedImage: detailedImage)
                mapView.addAnnotation(annotation)
            }
        } else {
            println("No DetailedImageObjects with a location")
        }
        
        //set up rotationRecognizer
        //rotationRecognizer.delegate = self
        
        self.calloutView = CustomCalloutView()
        self.calloutView.delegate = self
        
        self.mapView.calloutView = self.calloutView

    }
    
    func loadImages() {
        // Get the full detailed object from the selected name
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName:"DetailedImageObject")
        
        //sort so most recent is first
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        // only get the detailedImages that have a location
        fetchRequest.predicate = NSPredicate(format: "latitude!=nil AND longitude!=nil")
        
        var error: NSError?
        detailedImages = (managedContext.executeFetchRequest(fetchRequest,
            error: &error) as? [DetailedImageObject])!
    }
    
    func centerMapOnLocation(location: CLLocation, withRadius radius: CLLocationDistance) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
            radius * 2.0, radius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
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
                    //view.setMapLineViewOrientation(self.mapView.camera.heading)
            } else {
                // create a new MKPinAnnotationView
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = false
                //view.setMapLineViewOrientation(self.mapView.camera.heading)
                
                //view.calloutOffset = CGPoint(x: -5, y: 5)
                //view.rightCalloutAccessoryView = UIButton.buttonWithType(.DetailDisclosure) as! UIView
                
                //set up leftCalloutAccessotyView
                //let imgView = UIImageView(image: annotation.image)
                //imgView.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
                //imgView.contentMode = UIViewContentMode.ScaleAspectFill
                //view.leftCalloutAccessoryView = imgView

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
                self.overlay = MapLineOverlay(length: ann.length!, compassOrientation: ann.compassOrientation!, coordinate: ann.coordinate)
                mapView.addOverlay(overlay)
            }
        }
    }
    
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        self.calloutView.dismissCalloutAnimated(true)
        self.calloutView = CustomCalloutView()
        self.calloutView.delegate = self
        self.mapView.calloutView = self.calloutView
        self.selectedImage = nil
        
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
            title: "Edit this Image?", message: nil, preferredStyle: .Alert
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
    /**
    //Mark - UIGestureRecognizer methods
    @IBAction func rotationDetected (gestureRecognizer: UIRotationGestureRecognizer) {
        for ann in mapView.annotations {
            
            if ann.isMemberOfClass(ImageAnnotation) {
                
                let annView = mapView.viewForAnnotation(ann as! ImageAnnotation) as? ImageAnnotationView
                
                annView?.rotateMapLineViewRads(Double(gestureRecognizer.rotation))
                //rotationRecognizer.rotation = 0
            }
        }
        rotationRecognizer.rotation = 0
    } **/

    /**
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.locationInView(mapView)
        let tappedView = self.mapView.hitTest(point, withEvent: nil)
        //println(tappedView)
        if gestureRecognizer.isEqual(rotationRecognizer) {
            //let point = rotationRecognizer.locationInView(mapView)
            //let tappedView = self.mapView.hitTest(point, withEvent: nil)
           // println(tappedView)
            if tappedView!.isKindOfClass(MKMapView) {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    } **/

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
