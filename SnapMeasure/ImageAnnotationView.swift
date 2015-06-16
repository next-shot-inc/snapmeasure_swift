//
//  ImageAnnotationView.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 6/9/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import MapKit
import UIKit

class ImageAnnotationView: MKPinAnnotationView {

    var showing : Bool = false
    var lineView : MapLineView?
    var count : Int = 0
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        let ann = self.annotation as! ImageAnnotation
        if (selected) { //add customView
            
            if (ann.length != nil && ann.compassOrientation != nil) {
                lineView = MapLineView(length: ann.length!, orientation: ann.compassOrientation!) //change to due north for testing purposes
                lineView!.center = CGPoint(x: self.frame.width/2-8, y: self.frame.height-4)
                self.addSubview(lineView!)
                self.sendSubviewToBack(lineView!)
            } else {
                //no line
            }
            
            showing = true
            
        } else { //remove customView

            lineView?.removeFromSuperview()
            lineView = nil
            showing = false
        }
        
    }
    
    override func drawRect(rect: CGRect) {
        //super.drawRect(rect)
        let context = UIGraphicsGetCurrentContext()
        CGContextClearRect(context, rect)
        CGContextSetLineWidth(context, 10.0)
        
        CGContextSetStrokeColorWithColor(context, UIColor.greenColor().CGColor)

        CGContextAddRect(context, CGRect(origin: self.frame.origin, size: self.frame.size))
        CGContextStrokePath(context)
        super.drawRect(rect)
        
    }
    
    func setMapLineViewOrientation (newOrientation: CLLocationDirection) {
        
        if (lineView == nil || newOrientation == 0.0) {
            // do nothing orientation already matches or lineView doesn't exist
        } else {
            let radsToRotate = (newOrientation) * M_PI/180
            lineView!.transform = CGAffineTransformMakeRotation(CGFloat(-radsToRotate))

        }
    }
    
    func rotateMapLineViewRads (newOrientation: Double) {
        if (lineView == nil) {
            // do nothing lineView doesn't exist
        } else {
            let transform = lineView!.transform
            lineView!.transform = CGAffineTransformRotate(transform,CGFloat(newOrientation))
            
        }
    }
    
    func isShowingCallout() -> Bool {
        return showing
    }
}

class MapLineView : UIView {
    let length : Double
    let orientation: Double
    
    init (length: Double, orientation: CLLocationDegrees) {
        self.length = length
        if (orientation < 0) {
            self.orientation = 2*M_PI+orientation * M_PI/180;
        } else {
            self.orientation = orientation * M_PI/180;
        }
        
        super.init(frame: CGRect(x: 0.0, y: 0.0, width: abs(length*cos(orientation))+20, height: abs(length*sin(orientation))+20))

        self.backgroundColor = UIColor.clearColor()
    }
    /**
    init (length: Int, orientation: CLLocationDegrees) {
        self.length = length
        self.orientation = orientation
        super.init(frame: CGRect(x: 0, y: 0, width: length, height: 10))
    } **/

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        let context = UIGraphicsGetCurrentContext()
        CGContextClearRect(context, rect)
        CGContextSetLineWidth(context, 5.0)

        
        let origin = CGPoint(x: rect.size.width/2, y: rect.size.height/2)

        //let angle = M_PI_2 - orientation
        //println(origin)
        //println(length)
        
        //draw line representing length
        CGContextSetStrokeColorWithColor(context, UIColor.blueColor().CGColor)
        
        var startPoint = CGPoint(x: Double(origin.x)+length*cos(orientation)/2, y: Double(origin.y)+length*sin(orientation)/2)
        var endPoint = CGPoint(x: Double(origin.x)-length*cos(orientation)/2, y: Double(origin.y)-length*sin(orientation)/2)
        //println(startPoint)
        //println(endPoint)
        CGContextMoveToPoint (context, startPoint.x, startPoint.y)
        CGContextAddLineToPoint (context, endPoint.x, endPoint.y)
        CGContextStrokePath(context)
            
        //draw T line
        CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor)
        
        endPoint = CGPoint(x: Double(origin.x)+length/3*sin(orientation), y: Double(origin.y)-length/3*cos(orientation))
        CGContextMoveToPoint (context, origin.x, origin.y)
        CGContextAddLineToPoint (context, endPoint.x, endPoint.y)

        CGContextStrokePath(context)
        
        //draw point at origin
        
        CGContextSetStrokeColorWithColor(context, UIColor.yellowColor().CGColor)
        
        CGContextAddEllipseInRect(context, CGRect(x: rect.size.width/2-2, y: rect.size.height/2-2,width: 4,height: 4))
        
        
        CGContextStrokePath(context)
        
    
    }
}