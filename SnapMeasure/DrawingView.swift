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
    var name = String()
    
    mutating func merge(line: Line) {
        let leftToRight0 = points[1].x > points[0].x
        let leftToRight1 = line.points[1].x > line.points[0].x
        var points0 = points
        if( !leftToRight0 ) { points0 = points0.reverse() }
        var points1 = line.points
        if( !leftToRight1 ) { points1 = points1.reverse() }
        
        var newPoints = [CGPoint]()
        var inserted = false
        for var i=0; i < points0.count; i++ {
            if( points0[i].x > points1[0].x ) {
                // insert new points
                if( !inserted ) {
                    for( var j=0 ; j < points1.count; j++ ) {
                        newPoints.append(points1[j])
                    }
                    inserted = true
                }
            }
            if( points0[i].x > points1[points1.count-1].x || points0[i].x < points1[0].x ) {
                // insert old points
                newPoints.append(points0[i])
            }
        }
        points = newPoints
    }
    
    func intersectBox(rect: CGRect) -> Bool {
        for var i=0; i < points.count-1; ++i {
            if( segmentIntersectRectangle(rect, p1: points[i], p2: points[i+1])) {
                return true
            }
        }
        return false
    }
    
    func segmentIntersectRectangle(rect: CGRect, p1: CGPoint, p2: CGPoint) -> Bool {
        // Find min and max X for the segment
        var minX = p1.x;
        var maxX = p2.x;
        if( minX > maxX ) {
            swap(&minX, &maxX)
        }
        
        // Find the intersection of the segment's and rectangle's x-projections
        
        if(maxX > rect.maxX) {
            maxX = rect.maxX;
        }
        if(minX < rect.minX) {
            minX = rect.minX;
        }
        if(minX > maxX) {// If their projections do not intersect return false
            return false;
        }
        
        // Find corresponding min and max Y for minX and maxX we found before
        var minY = p1.y;
        var maxY = p2.y;
        var dx = p2.x - p1.x;
        
        if( abs(dx) > 0.0000001 ) {
            let a = (p2.y - p1.y) / dx;
            let b = p1.y - a * p1.x;
            minY = a * minX + b;
            maxY = a * maxX + b;
        }
        
        if(minY > maxY) {
            swap(&minY, &maxY)
        }
        
        // Find the intersection of the segment's and rectangle's y-projections
        
        if(maxY > rect.maxY){
            maxY = rect.maxY;
        }
        if(minY < rect.minY){
            minY = rect.minY;
        }
        if(minY > maxY) { // If Y-projections do not intersect return false
            return false;
        }
        return true;
    }
}

class LineView : UIView {
    var lines = [Line]()
    var measure = [CGPoint]()
    var refMeasurePoints = [CGPoint]()
    var currentLine = Line()
    var label = UILabel()
    var refLabel = UILabel()
    var refMeasureValue : Float = 0.0
    var currentLineName = String()
    
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
        
        if( currentLine.points.count > 2 ) {
            CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)
            // Draw as dash line
            let dashes:[CGFloat] = [6, 2]
            CGContextSetLineDash(context, 0, dashes, 2)
            CGContextMoveToPoint (context, currentLine.points[0].x, currentLine.points[0].y);
            for ( var k = 1; k < currentLine.points.count; k++) {
                CGContextAddLineToPoint (context, currentLine.points[k].x, currentLine.points[k].y);
            }
            CGContextStrokePath(context)
            
            // return to normal line
            let normal : [CGFloat]=[1]
            CGContextSetLineDash(context,0,normal,0);
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
        
        CGContextMoveToPoint (context, 10, 10);
        CGContextAddLineToPoint(context, bounds.width - 10.0, 10.0);
        CGContextAddLineToPoint(context, bounds.width - 10.0, bounds.height - 10.0)
        CGContextAddLineToPoint(context, 10, bounds.height - 10.0)
        CGContextAddLineToPoint(context, 10, 10)
        CGContextStrokePath(context)
    }
    
    func add(line: Line) {
        for (index,value) in enumerate(lines) {
            if( value.name == line.name ) {
                var newline = value
                newline.merge(line)
                lines.removeAtIndex(index)
                lines.append(newline)
                return
            }
        }
        lines.append(line)
    }
}

class DrawingView : UIImageView {
    enum ToolMode : Int {
        case Draw = 0, Erase = 1, Measure = 2, Reference = 3
    }
    
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
        
        lineView = LineView(frame: self.bounds)
        lineView.opaque = false
        lineView.backgroundColor = nil
        lineView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        self.addSubview(lineView)
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
       let touch = touches.first as! UITouch
       let point = touch.locationInView(self)
        
       lineView.currentLine = Line()
       lineView.currentLine.points.append(point)
        
       if( drawMode == ToolMode.Erase ) {
            let rect = CGRectMake(point.x-10.0, point.y-10.0, 20.0, 20.0)
            for (index,value) in enumerate(lineView.lines) {
                if( value.intersectBox(rect) ) {
                    lineView.lines.removeAtIndex(index)
                    lineView.setNeedsDisplay()
                    break
                }
            }
       }
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch = touches.first as! UITouch
        let point = touch.locationInView(self)
        lineView.currentLine.points.append(point)
        if( drawMode != ToolMode.Erase ) {
           lineView.setNeedsDisplay()
        }
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch = touches.first as! UITouch
        let point = touch.locationInView(self)
        lineView.currentLine.points.append(point)
        
        if( drawMode == ToolMode.Measure ) {
            lineView.measure.removeAll(keepCapacity: true)
            if( lineView.currentLine.points.count >= 2 ) {
                lineView.measure.append(lineView.currentLine.points[0])
                lineView.measure.append(lineView.currentLine.points[lineView.currentLine.points.count-1])
            }
        } else if( drawMode == ToolMode.Draw) {
            lineView.currentLine.name = lineView.currentLineName
            lineView.add(lineView.currentLine)
        } else if( drawMode == ToolMode.Reference ) {
            lineView.refMeasurePoints.removeAll(keepCapacity: true)
            if( lineView.currentLine.points.count >= 2 ) {
                lineView.refMeasurePoints.append(lineView.currentLine.points[0])
                lineView.refMeasurePoints.append(lineView.currentLine.points[lineView.currentLine.points.count-1])
            }
        } else if( drawMode == ToolMode.Erase ) {
            if( lineView.currentLine.points.count >= 2 ) {
                let p0 = lineView.currentLine.points[0]
                let p1 = lineView.currentLine.points[lineView.currentLine.points.count-1]
                let minX = min(p1.x, p0.x)
                let minY = min(p1.y, p0.y)
                let maxX = max(p1.x, p0.x)
                let maxY = max(p1.y, p0.y)
                
                let rect = CGRectMake(minX, minY, maxX-minX, maxY-minY)
                for (index,value) in enumerate(lineView.lines) {
                    if( value.intersectBox(rect) ) {
                        lineView.lines.removeAtIndex(index)
                        
                        break
                    }
                }
            }
        }
        lineView.currentLine = Line()
        lineView.setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
    }
}
