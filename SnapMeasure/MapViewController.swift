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

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var rotationRecognizer: UIRotationGestureRecognizer!
    
    var detailedImages: [DetailedImageObject] = []
    var managedContext: NSManagedObjectContext!
    
    override func viewDidLoad() {
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
        rotationRecognizer.delegate = self

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
            var view: ImageAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
                as? ImageAnnotationView { // checks to see if an unseen annotation view can be reused
                    dequeuedView.annotation = annotation
                    view = dequeuedView
                    view.setMapLineViewOrientation(self.mapView.camera.heading)
            } else {
                // create a new MKPinAnnotationView
                view = ImageAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.setMapLineViewOrientation(self.mapView.camera.heading)
                
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
        if view.isMemberOfClass(ImageAnnotationView) {
            (view as! ImageAnnotationView).setMapLineViewOrientation(self.mapView.camera.heading)
        }
    } 
    /**
    func mapView(mapView: MKMapView!, regionWillChangeAnimated animated: Bool) {
        
        for ann in mapView.annotations {
            
            if ann.isMemberOfClass(ImageAnnotation) {
                
                let annView = mapView.viewForAnnotation(ann as! ImageAnnotation) as? ImageAnnotationView
                
                annView?.rotateMapLineView(self.mapView.camera.heading)
            }
        }
    }
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        for ann in mapView.annotations {
            
            if ann.isMemberOfClass(ImageAnnotation) {
                
                let annView = mapView.viewForAnnotation(ann as! ImageAnnotation) as? ImageAnnotationView
                
                annView?.rotateMapLineView(self.mapView.camera.heading)
            }
        }
    } **/
    
    //Mark - UIGestureRecognizer methods
    @IBAction func rotationDetected (gestureRecognizer: UIRotationGestureRecognizer) {
        for ann in mapView.annotations {
            
            if ann.isMemberOfClass(ImageAnnotation) {
                
                let annView = mapView.viewForAnnotation(ann as! ImageAnnotation) as? ImageAnnotationView
                
                annView?.rotateMapLineViewRads(Double(gestureRecognizer.rotation))
                rotationRecognizer.rotation = 0
            }
        }
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.locationInView(mapView)
        let tappedView = self.mapView.hitTest(point, withEvent: nil)
        println(tappedView)
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
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true;
    }

}
