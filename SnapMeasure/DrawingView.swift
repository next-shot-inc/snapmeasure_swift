//
//  DrawingView.swift
//  SnapMeasure
//
//  Created by next-shot on 5/21/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit

struct Line {
    var points = [CGPoint]()
}

class LineView : UIView {
    var lines = [Line]()
    var measure = [CGPoint]()
    var refMeasurePoints = [CGPoint]()
    var label = UILabel()
    var refLabel = UILabel()
    var refMeasureValue : Float = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(label)
        self.addSubview(refLabel)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextSetLineWidth(context, 2.0)
        
        // Draw digitized lines
        for line in lines {
            CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)
            CGContextMoveToPoint (context, line.points[0].x, line.points[0].y);
            for ( var k = 1; k < line.points.count; k++) {
                CGContextAddLineToPoint (context, line.points[k].x, line.points[k].y);
            }
            CGContextStrokePath(context)
        }
        
        var scale = 1.0
        if( refMeasurePoints.count == 2 ) {
            CGContextSetStrokeColorWithColor(context, UIColor.blueColor().CGColor)
            let loc = CGPoint(
                x: (refMeasurePoints[1].x+refMeasurePoints[0].x)/2.0,
                y: (refMeasurePoints[1].y+refMeasurePoints[0].y)/2.0
            )
            refLabel.text = String(format: "%g", refMeasureValue)
            refLabel.frame = CGRectMake(loc.x, loc.y, 100, 20)
            
            CGContextMoveToPoint (context, refMeasurePoints[0].x, refMeasurePoints[0].y);
            CGContextAddLineToPoint (context, refMeasurePoints[1].x, refMeasurePoints[1].y);
            CGContextStrokePath(context)
            
            let dx = refMeasurePoints[1].x - refMeasurePoints[0].x
            let dy = refMeasurePoints[1].y - refMeasurePoints[0].y
            let dist = sqrt(dx*dx + dy*dy)
            scale = Double(refMeasureValue)/Double(dist)
        }
        
        if( measure.count == 2 ) {
            CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor)
            let dx = measure[1].x - measure[0].x
            let dy = measure[1].y - measure[0].y
            let dist = sqrt(dx*dx + dy*dy)
            
            let loc = CGPoint(x: (measure[1].x+measure[0].x)/2.0, y: (measure[1].y+measure[0].y)/2.0)
            label.text = String(format: "%g", Float(dist) * Float(scale))
            label.frame = CGRectMake(loc.x, loc.y, 100, 20)
            
            CGContextMoveToPoint (context, measure[0].x, measure[0].y);
            CGContextAddLineToPoint (context, measure[1].x, measure[1].y);
            CGContextStrokePath(context)
        }
        
        
    }
}

class DrawingView : UIImageView {
    enum ToolMode : Int {
        case Draw = 0, Erase = 1, Measure = 2, Reference = 3
    }
    
    var currentLine = Line()
    var lineView = LineView()
    var drawMode : ToolMode = ToolMode.Draw
    var imageInfo = ImageInfo()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        lineView = LineView(frame: frame)
        lineView.opaque = false
        lineView.backgroundColor = nil
        self.addSubview(lineView)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        lineView = LineView(frame: self.frame)
        lineView.opaque = false
        lineView.backgroundColor = nil
        self.addSubview(lineView)
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
       let touch = touches.first as! UITouch
       let point = touch.locationInView(self)
       currentLine = Line()
       currentLine.points.append(point)
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch = touches.first as! UITouch
        let point = touch.locationInView(self)
        currentLine.points.append(point)
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch = touches.first as! UITouch
        let point = touch.locationInView(self)
        currentLine.points.append(point)
        
        if( drawMode == ToolMode.Measure ) {
            lineView.measure.removeAll(keepCapacity: true)
            if( currentLine.points.count >= 2 ) {
                lineView.measure.append(currentLine.points[0])
                lineView.measure.append(currentLine.points[currentLine.points.count-1])
                lineView.setNeedsDisplay()
            }
        } else if( drawMode == ToolMode.Draw) {
           lineView.lines.append(currentLine)
           lineView.setNeedsDisplay()
        } else if( drawMode == ToolMode.Reference ) {
            lineView.refMeasurePoints.removeAll(keepCapacity: true)
            if( currentLine.points.count >= 2 ) {
                lineView.refMeasurePoints.append(currentLine.points[0])
                lineView.refMeasurePoints.append(currentLine.points[currentLine.points.count-1])
                lineView.setNeedsDisplay()
            }
        }
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
    }
}
