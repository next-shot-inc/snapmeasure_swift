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
    
    let calloutView : UIImageView = UIImageView()
    var showing : Bool = false
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        let ann = self.annotation as! ImageAnnotation
        if (selected) { //add customView
            calloutView.image = ann.image
            calloutView.frame = CGRect(x: -75, y: 75, width: 150, height: 150)
            calloutView.contentMode = UIViewContentMode.ScaleAspectFill
            calloutView.center = CGPoint(x: self.frame.width/2 - 7, y: 125)
            
            if (ann.length != nil) {
                let lineView = MapLineView(length: ann.length!, orientation: ann.compassOrientation)
                lineView.center = CGPoint(x: calloutView.frame.width/2, y: -10)
                calloutView.addSubview(lineView)
            } else {
                //no line
            }
            
            //TODO: animate apearance
            
            self.addSubview(calloutView)
            showing = true
            
        } else { //remove customView
            calloutView.removeFromSuperview()
            showing = false
        }
    }
    
    func isShowingCallout() -> Bool {
        return showing
    }
}

class MapLineView : UIView {
    let length : Double
    let orientation: CLLocationDegrees
    
    init (length: Double, orientation: CLLocationDegrees) {
        self.length = length
        self.orientation = orientation
        
        if (orientation == 0.0 || orientation == 180.0) { //picture was taken facing North or South
            super.init(frame: CGRect(x: 0.0, y: 0.0, width: length, height: 20))
        } else if (orientation == 90.0 || orientation == 270.0) {//picture was taken facing East or West
            super.init(frame: CGRect(x: 0.0, y: 0.0, width: 20, height: length))
        } else {
            super.init(frame: CGRect(x: 0.0, y: 0.0, width: length*cos(orientation), height: length*sin(orientation)))
        }
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
        let context = UIGraphicsGetCurrentContext()
        CGContextClearRect(context, rect)
        CGContextSetLineWidth(context, 5.0)
        
        //draw line representing length
        CGContextSetStrokeColorWithColor(context, UIColor.blueColor().CGColor)

        CGContextMoveToPoint (context, 0, 9);
        CGContextAddLineToPoint (context, CGFloat(length), CGFloat(9.0));
        CGContextStrokePath(context)
        
        //draw north facing line
        CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor)
        
        CGContextMoveToPoint (context, CGFloat(length/2), 0);
        CGContextAddLineToPoint (context, CGFloat(length/2), CGFloat(9));
        CGContextStrokePath(context)
    }
}