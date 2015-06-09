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

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var detailedImages: [DetailedImageObject] = []
    var managedContext: NSManagedObjectContext!
    
    override func viewDidLoad() {
        self.loadImages()
        println("count = ", detailedImages.count)
        if (detailedImages.count > 0) {
            let initialLocation = CLLocation(latitude: detailedImages[0].latitude!.doubleValue, longitude: detailedImages[0].longitude!.doubleValue)
            println("latitude: %d\nlongitude: %d",detailedImages[0].latitude!.doubleValue,detailedImages[0].longitude!.doubleValue)
            //let initialLocation = CLLocation(latitude: 21.282778, longitude: -157.829444)
            self.centerMapOnLocation(initialLocation, withRadius: CLLocationDistance(1.0))
            for detailedImage in detailedImages {
                let image = UIImage(data:detailedImage.imageData)
                let coordinate = CLLocationCoordinate2D(latitude: detailedImage.latitude!.doubleValue, longitude: detailedImage.longitude!.doubleValue)
                //let annotation = ImageAnnotation(name: detailedImage.name, image: UIImage(data:detailedImage.imageData), coordinate: coordinate, compassOrientation: detailedImage.compassOrientation!.doubleValue)
            }
        } else {
            println("No DetailedImageObjects with a location")
        }
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

}
