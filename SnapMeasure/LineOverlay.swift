//
//  LineOverlay.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 6/17/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import UIKit
import MapKit

class MapLineOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    var mapLength : Double
    var angle : Double
    var distanceToObject : Double
    var objectCoordinate : MKMapPoint
    
    //length represents the length of the line in meters
    init(length: Double, compassOrientation: CLLocationDirection, coordinate: CLLocationCoordinate2D, object_scale: Double) {
        let orientation : Double
        if (compassOrientation < 0) {
            orientation = 2*Double.pi+compassOrientation * Double.pi/180
        } else {
            orientation = compassOrientation * .pi/180
        }
    
        let scale = MKMetersPerMapPointAtLatitude(coordinate.latitude)
        
        self.coordinate = coordinate
        self.mapLength = length/scale
        self.angle = orientation
        
        // distance to the object 
        // object (mm) = focal length (mm) * real height of the object (mm) * image height (pixels) / (
        // object height (pixels) * sensor height (mm))
        distanceToObject = 3.3 * object_scale * 1000
        let objc = MKMapPointForCoordinate(coordinate)
        let dto = distanceToObject/scale
        let dtx = dto*sin(orientation)
        let dty = -dto*cos(orientation)
        objectCoordinate = MKMapPoint(x: objc.x + dtx, y: objc.y + dty)
        
        // Compute bounding box of annotation (including the section and the line to the section)
        let startMapPoint = MKMapPoint(
            x: objectCoordinate.x+mapLength*cos(angle)/2,
            y: objectCoordinate.y+mapLength*sin(angle)/2
        )
        let endMapPoint = MKMapPoint(
            x: objectCoordinate.x-mapLength*cos(angle)/2,
            y: objectCoordinate.y-mapLength*sin(angle)/2
        )
        let minx = min(objc.x, startMapPoint.x, endMapPoint.x)
        let miny = min(objc.y, startMapPoint.y, endMapPoint.y)
        let maxx = max(objc.x, startMapPoint.x, endMapPoint.x)
        let maxy = max(objc.y, startMapPoint.y, endMapPoint.y)
        self.boundingMapRect = MKMapRect(origin: MKMapPoint(x: minx, y: miny), size: MKMapSize(width: maxx-minx, height: maxy-miny))
     }
}

class MapLineOverlayView: MKOverlayRenderer {
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        if let lineOverlay = overlay as? MapLineOverlay {
            //let overlayMapRect = overlay.boundingMapRect
            //let cgRect = rectForMapRect(overlayMapRect)
            //let cgmapRect = rectForMapRect(mapRect)
            
            let objectMapPoint = lineOverlay.objectCoordinate

            context.setLineWidth(50.0)
        
            //draw line representing length (in Blue)
            //first get map points
            let startMapPoint = MKMapPoint(
                x: objectMapPoint.x+lineOverlay.mapLength*cos(lineOverlay.angle)/2,
                y: objectMapPoint.y+lineOverlay.mapLength*sin(lineOverlay.angle)/2
            )
            let endMapPoint = MKMapPoint(
                x: objectMapPoint.x-lineOverlay.mapLength*cos(lineOverlay.angle)/2,
                y: objectMapPoint.y-lineOverlay.mapLength*sin(lineOverlay.angle)/2
            )
            //let deltaY = lineOverlay.mapLength*sin(lineOverlay.angle)/2
            //get CGpoints for MapPoints
            let startPoint = point(for: startMapPoint)
            var endPoint = point(for: endMapPoint)

            context.setStrokeColor(UIColor.blue.cgColor)

            context.move (to: CGPoint(x: startPoint.x, y: startPoint.y))
            context.addLine (to: CGPoint(x: endPoint.x, y: endPoint.y))
            context.strokePath()
            
            //draw T line (position of the camera)
            //first get map point
            let coordinateMapPoint = MKMapPointForCoordinate(overlay.coordinate)
            
            //get CGpoints for MapPoints
            let coordinatePoint = point(for: coordinateMapPoint)
            endPoint = point(for: objectMapPoint)
            
            context.setStrokeColor(UIColor.red.cgColor)
            context.setLineWidth(2.0)
            
            context.move (to: CGPoint(x: coordinatePoint.x, y: coordinatePoint.y))
            context.addLine (to: CGPoint(x: endPoint.x, y: endPoint.y))
            context.strokePath()

        }
    }
}

