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
    
    //length represents the length of the line in meters
    init(length: Double, compassOrientation: CLLocationDirection, coordinate: CLLocationCoordinate2D) {
        let orientation : Double
        if (compassOrientation < 0) {
            orientation = 2*M_PI+compassOrientation * M_PI/180;
        } else {
            orientation = compassOrientation * M_PI/180;
        }
        let meteredWidth = abs(length*cos(orientation))
        let meteredHeight = abs(length*sin(orientation))
        let scale = MKMetersPerMapPointAtLatitude(coordinate.latitude)
        
        let size = MKMapSize(width: meteredWidth/scale, height: meteredHeight/scale)
        let centerMapPoint = MKMapPointForCoordinate(coordinate)
        let origin = MKMapPoint(x: centerMapPoint.x-size.width/2, y: centerMapPoint.y-size.height/2)
        
        self.boundingMapRect = MKMapRect(origin: origin, size: size)
        self.coordinate = coordinate
        self.mapLength = length/scale
        self.angle = orientation
    }
}

class MapLineOverlayView: MKOverlayRenderer {
    
    
    override func drawMapRect(mapRect: MKMapRect, zoomScale: MKZoomScale, inContext context: CGContext!) {
        if let lineOverlay = overlay as? MapLineOverlay {
            let overlayMapRect = overlay.boundingMapRect
            let cgRect = rectForMapRect(overlayMapRect)
        
            let cgmapRect = rectForMapRect(mapRect)
            
            let coordinateMapPoint = MKMapPointForCoordinate(overlay.coordinate)
            let coordinatePoint = pointForMapPoint(coordinateMapPoint)
        
            CGContextSetLineWidth(context, 50.0)
        
            //draw line representing length
            //first get map points
            var startMapPoint = MKMapPoint(x: coordinateMapPoint.x+lineOverlay.mapLength*cos(lineOverlay.angle)/2, y: coordinateMapPoint.y+lineOverlay.mapLength*sin(lineOverlay.angle)/2)
            var endMapPoint = MKMapPoint(x: coordinateMapPoint.x-lineOverlay.mapLength*cos(lineOverlay.angle)/2, y: coordinateMapPoint.y-lineOverlay.mapLength*sin(lineOverlay.angle)/2)
            let deltaY = lineOverlay.mapLength*sin(lineOverlay.angle)/2
            //get CGpoints for MapPoints
            var startPoint = pointForMapPoint(startMapPoint)
            var endPoint = pointForMapPoint(endMapPoint)

            
            CGContextSetStrokeColorWithColor(context, UIColor.blueColor().CGColor)

            CGContextMoveToPoint (context, startPoint.x, startPoint.y)
            CGContextAddLineToPoint (context, endPoint.x, endPoint.y)
            CGContextStrokePath(context)
            
            //draw T line
            //first get map point
            endMapPoint = MKMapPoint(x: coordinateMapPoint.x+lineOverlay.mapLength/4*sin(lineOverlay.angle), y: coordinateMapPoint.y - lineOverlay.mapLength*cos(lineOverlay.angle)/4)
            
            //get CGpoints for MapPoints
            endPoint = pointForMapPoint(endMapPoint)
            
            CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor)
            
            CGContextMoveToPoint (context, coordinatePoint.x, coordinatePoint.y)
            CGContextAddLineToPoint (context, endPoint.x, endPoint.y)
            CGContextStrokePath(context)

        }
    }
}
