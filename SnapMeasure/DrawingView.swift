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
    enum Role : Int {
        case Border = 0, Horizon = 1, Unconformity = 2, Fault = 3
    }
    
    var points = [CGPoint]()
    var name = String()
    var color = UIColor.blackColor().CGColor
    var role : Role = Role.Horizon
    
    mutating func merge(line: Line) {
        var points0 = points
        var points1 = line.points
        
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
    
    mutating func cleanOrientation() {
        // See if first is in opposite direction of the line and remove it (finger tremble)
        if( points.count < 2 ) {
            return
        }
        
        let globalLeftToRight = points.last!.x > points.first!.x
        var filtered = false
        do {
            filtered = false
            let leftToRight = points[1].x > points[0].x
            if( globalLeftToRight != leftToRight ) {
                points.removeAtIndex(0)
                filtered = true
            }
        } while ( filtered )
        
        if( !globalLeftToRight ) {
            points = points.reverse()
        }
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
    
    static func segmentsIntersect(a: CGPoint, b: CGPoint, c: CGPoint, d: CGPoint) -> (exist: Bool, loc: CGPoint) {
        let denom = Double(a.x) * Double( d.y - c.y ) + Double(b.x) * Double( c.y - d.y ) +
                    Double(d.x) * Double( b.y - a.y ) + Double(c.x) * Double( a.y - b.y );
            
        /* If denom is zero, then segments are parallel: no intersection */
        if( abs(denom) < 1e-6 ) {
            return (false, CGPoint())
        }
            
        let nums = Double(a.x) * Double( d.y - c.y ) + Double(c.x) * Double( a.y - d.y ) + Double(d.x) * Double( c.y - a.y )
        var s = nums / denom
        
        let numt = Double(a.x) * Double( c.y - b.y ) + Double(b.x) * Double( a.y - c.y ) + Double(c.x) * Double( b.y - a.y )
        let t = -numt / denom
        
        let eps = 1e-8
        let exist = ( (-eps < s) && (s < 1.0+eps) &&
                      (-eps < t) && (t < 1.0+eps) )
        
        var p : CGPoint = CGPoint()
        if( s < 0 ) { s = 0.0 }
        if( s > 1.0 ) { s = 1.0 }
        
        p.x = a.x + CGFloat(s) * ( b.x - a.x )
        p.y = a.y + CGFloat(s) * ( b.y - a.y )
        return (exist, p)
    }
    
    static func segmentIntersectPoint(a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
        if( b.x != a.x ) {
            return (c.x - a.x)/(b.x - a.x)
        } else if( b.y != a.y ) {
            return (c.y - a.y)/(b.y - a.y)
        } else {
            return 0.0
        }
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
    var polygons : Polygons?
    
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
            CGContextSetStrokeColorWithColor(context, line.color)
            CGContextMoveToPoint (context, line.points[0].x, line.points[0].y);
            for ( var k = 1; k < line.points.count; k++) {
                CGContextAddLineToPoint (context, line.points[k].x, line.points[k].y);
            }
            CGContextStrokePath(context)
        }
        
        // Fill color between two path
        if( polygons == nil ) {
            for var i=0; i < lines.count-1; i++  {
                CGContextSetAlpha(context, 0.3)
                CGContextSetFillColorWithColor(context, lines[i].color)
                CGContextMoveToPoint (context, lines[i].points[0].x, lines[i].points[0].y)
                for ( var k = 1; k < lines[i].points.count; k++) {
                    CGContextAddLineToPoint (context, lines[i].points[k].x, lines[i].points[k].y);
                }
                for ( var k=lines[i+1].points.count-1; k >= 0 ; k--) {
                    CGContextAddLineToPoint (context, lines[i+1].points[k].x, lines[i+1].points[k].y);
                }
                CGContextFillPath(context)
            }
        } else {
            for p in polygons!.polygons  {
                CGContextSetAlpha(context, 0.3)
                CGContextSetFillColorWithColor(context, p.color)
                var first = true
                for l in p.lines  {
                    if( l.reverse ) {
                        for( var k=l.line.points.count-1; k >= 0 ; k-- ) {
                            if( first ) {
                                CGContextMoveToPoint (context, l.line.points[k].x, l.line.points[k].y)
                                first = false
                            }
                            CGContextAddLineToPoint (context, l.line.points[k].x, l.line.points[k].y)
                        }
                    } else {
                        for( var k=0; k < l.line.points.count; k++ ) {
                            if( first ) {
                                CGContextMoveToPoint (context, l.line.points[k].x, l.line.points[k].y)
                                first = false
                            }
                            CGContextAddLineToPoint (context, l.line.points[k].x, l.line.points[k].y)
                        }
                    }
                }
                CGContextFillPath(context)
            }
        }
        
        // Draw line being drawn
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
            // Draw reference line
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
            // Draw measurement line
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
        
        // Draw bounding rectangle
        CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)
        CGContextMoveToPoint (context, 10, 10);
        CGContextAddLineToPoint(context, bounds.width - 10.0, 10.0);
        CGContextAddLineToPoint(context, bounds.width - 10.0, bounds.height - 10.0)
        CGContextAddLineToPoint(context, 10, bounds.height - 10.0)
        CGContextAddLineToPoint(context, 10, 10)
        CGContextStrokePath(context)
    }
    
    // Add or merge a new line 
    // The merge is done when the name of the new line is the same as the name of an existing line
    func add(line: Line) {
        // Find if it needs to be merged with an existing line
        for (index,value) in enumerate(lines) {
            if( value.name == line.name ) {
                var newline = value
                newline.color = line.color // Take latest color
                newline.merge(line)
                lines.removeAtIndex(index)
                lines.insert(newline, atIndex: index)
                return
            }
        }
        // If not an existing line
        // Order the line from top to bottom (y)
        var inserted = false
        for var i=0; i < lines.count; i++  {
            if( line.points[0].y < lines[i].points[0].y ) {
                lines.insert(line, atIndex: i)
                inserted = true
                break
            }
        }
        if( !inserted ) {
           lines.append(line)
        }
    }
    
    func computePolygon() {
        var nlines = lines;
        var border = Line()
        border.role = Line.Role.Border
        border.points.append(CGPoint(x: 10, y: 10))
        border.points.append(CGPoint(x: bounds.width - 10.0, y: 10))
        border.points.append(CGPoint(x: bounds.width - 10.0, y: bounds.height - 10.0))
        border.points.append(CGPoint(x: 10, y: bounds.height - 10.0))
        border.points.append(CGPoint(x: 10, y: 10))
        
        nlines.append(border)
        polygons = Polygons(lines: nlines)
    }
}

class FaciesVignette {
    var rect: CGRect = CGRect()
    var imageId : Int = -1
    
    init(rect: CGRect, image: Int) {
        self.rect = rect
        self.imageId = image
    }
}

class FaciesColumn {
    var faciesVignettes = [FaciesVignette]()
    
    func inside(point: CGPoint) -> Bool {
        if( faciesVignettes.count == 0 ) {
            return false
        }
        let rect = faciesVignettes[0].rect
        return point.x > rect.minX-5 && point.x < rect.maxX+5;
    }
    
    func snap(point: CGPoint) -> (point: CGPoint, below: Bool) {
        if( faciesVignettes.count == 0 ) {
            return (point, true)
        }
        
        var snapped = CGPoint()
        let dxmin = abs(faciesVignettes[0].rect.minX-point.x)
        let dxmax = abs(faciesVignettes[0].rect.maxX-point.x)
        if( dxmin < dxmax ) {
            snapped.x = faciesVignettes[0].rect.minX
        } else {
            snapped.x = faciesVignettes[0].rect.maxX
        }
        let dymin = abs(faciesVignettes[0].rect.minY-point.y)
        let dymax = abs(faciesVignettes.last!.rect.maxY-point.y)
        var below : Bool
        if( dymin < dymax ) {
            snapped.y = faciesVignettes[0].rect.minY
            below = false
        } else {
            snapped.y = faciesVignettes.last!.rect.maxY
            below = true
        }
        return (snapped, below)
    }
    
    func snap(origin: CGPoint, point: CGPoint) -> CGRect {
        if( faciesVignettes.count == 0 ) {
            var xmin = min(origin.x, point.x)
            var xmax = max(origin.x, point.x)
            var ymin = min(origin.y, point.y)
            var ymax = max(origin.y, point.y)
            return CGRectMake(xmin, ymin, xmax-xmin, ymax-ymin)
        } else {
            var snapped = CGPoint()
            if( origin.x == faciesVignettes[0].rect.minX ) {
                snapped.x = faciesVignettes[0].rect.maxX
            } else {
                snapped.x = faciesVignettes[0].rect.minX
            }
            var xmin = min(origin.x, snapped.x)
            var xmax = max(origin.x, snapped.x)
            if( origin.y == faciesVignettes[0].rect.minY ) {
                // Drawing rectangle above the first one
                if( point.y < origin.y ) {
                   return CGRectMake(xmin, point.y, xmax-xmin, origin.y - point.y)
                } else {
                   return CGRectMake(xmin, origin.y, xmax-xmin, 0)
                }
            } else {
                // Drawing rectangle below the last one
                if( point.y > origin.y ) {
                    return CGRectMake(xmin, origin.y, xmax-xmin, point.y - origin.y)
                } else {
                    return CGRectMake(xmin, origin.y, xmax-xmin, 0)
                }
            }
        }
    }
    
    
    // Remove one element (if the thing is in the middle, remove all elements before or after)
    func remove(index: Int) {
        if( index == 0 ) {
            faciesVignettes.removeAtIndex(0)
        } else if( index == faciesVignettes.count-1 ) {
            faciesVignettes.removeAtIndex(index)
        } else if( index < faciesVignettes.count/2 ) {
            faciesVignettes.removeRange(Range(start: 0, end: index+1))
        } else {
            faciesVignettes.removeRange(Range(start: index, end: faciesVignettes.count))
        }
    }
}

class FaciesDrawTool {
    var origin = CGPoint()
    var curColumn : FaciesColumn?
    var append = false
    var curRect = CGRect()
    
    init(curColumn: FaciesColumn, point: CGPoint) {
        self.curColumn = curColumn
        (origin, append) = curColumn.snap(point)
    }
    
    func move(point: CGPoint) {
        curRect = curColumn!.snap(origin, point: point)
    }
    
    func end(#imageId: Int) {
        if( append ) {
            curColumn!.faciesVignettes.append(
                FaciesVignette(rect: curRect, image: imageId)
            )
        } else {
            curColumn!.faciesVignettes.insert(
                FaciesVignette(rect: curRect, image: imageId), atIndex: 0
            )
        }
    }
}

class FaciesView : UIView {
    var faciesColumns = [FaciesColumn]()
    var drawTool : FaciesDrawTool?
    var images = ["sand", "mud", "grading", "lamination" ]
    var curImageName = String()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextSetLineWidth(context, 2.0)
        
        for fc in faciesColumns {
            for v in fc.faciesVignettes{
                let uiimage = UIImage(named: images[v.imageId])
                if( uiimage != nil ) {
                    let cgimage = uiimage!.CGImage
                    CGContextSaveGState(context)
                    CGContextClipToRect(context, v.rect)
                    CGContextDrawTiledImage(context,
                        CGRect(x:0, y:0, width: uiimage!.size.width, height: uiimage!.size.height),
                        cgimage
                    )
                    CGContextRestoreGState(context)
                }
                CGContextAddRect(context, v.rect)
                CGContextStrokePath(context)
            }
        }
        
        if( drawTool != nil && drawTool!.curRect.width > 0 && drawTool!.curRect.height > 0 ) {
            CGContextAddRect(context, drawTool!.curRect)
            CGContextStrokePath(context)
        }
        
        // Draw bounding rectangle
        CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor)
        CGContextMoveToPoint (context, 10, 10);
        CGContextAddLineToPoint(context, bounds.width - 10.0, 10.0);
        CGContextAddLineToPoint(context, bounds.width - 10.0, bounds.height - 10.0)
        CGContextAddLineToPoint(context, 10, bounds.height - 10.0)
        CGContextAddLineToPoint(context, 10, 10)
        CGContextStrokePath(context)

    }
    
    func imageId() -> Int {
        for( var i=0; i < images.count; i++ ) {
            if( images[i] == curImageName ) {
                return i;
            }
        }
        return 0
    }
}

class DrawingView : UIImageView {
    enum ToolMode : Int {
        case Draw = 0, Erase = 1, Measure = 2, Reference = 3, Facies = 4
    }
    
    var lineView = LineView()
    var faciesView = FaciesView()
    var drawMode : ToolMode = ToolMode.Draw
    var imageInfo = ImageInfo()
    var curColor = UIColor.blackColor().CGColor
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        lineView = LineView(frame: frame)
        lineView.opaque = false
        lineView.backgroundColor = nil
        self.addSubview(lineView)
        
        faciesView = FaciesView(frame: frame)
        faciesView.opaque = false
        faciesView.backgroundColor = nil
        self.addSubview(faciesView)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        lineView = LineView(frame: self.bounds)
        lineView.opaque = false
        lineView.backgroundColor = nil
        lineView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        self.addSubview(lineView)

        
        faciesView = FaciesView(frame: self.bounds)
        faciesView.opaque = false
        faciesView.backgroundColor = nil
        faciesView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        self.addSubview(faciesView)
    }
    
    func initFrame() {
        self.sizeToFit()
        //lineView.frame = CGRect(origin: CGPoint(x: 0,y: 0), size: self.bounds.size)
    }
    
    func select(point: CGPoint)  -> Line? {
        // Fingers are roughly 40 pixels wide
        let rect = CGRectMake(point.x-20.0, point.y-20.0, 40.0, 40.0)
        for line in lineView.lines {
            if( line.intersectBox(rect) ) {
                return line
            }
        }
        return nil
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
       let touch = touches.first as! UITouch
       let point = touch.locationInView(self)
    
        if( drawMode != ToolMode.Facies ) {
            lineView.currentLine = Line()
            lineView.currentLine.points.append(point)
        } else {
            // See if we are adding a new column or appending to an existing column
            var cc : FaciesColumn?
            for fc in faciesView.faciesColumns {
                if( fc.inside(point) ) {
                    cc = fc
                    break
                }
            }
            if( cc == nil ) {
                cc = FaciesColumn()
                faciesView.faciesColumns.append(cc!)
            }
            faciesView.drawTool = FaciesDrawTool(curColumn: cc!, point: point)
        }
        
        if( drawMode == ToolMode.Erase ) {
            let rect = CGRectMake(point.x-10.0, point.y-10.0, 20.0, 20.0)
            // Find if there is a line below
            for (index,value) in enumerate(lineView.lines) {
                if( value.intersectBox(rect) ) {
                    lineView.lines.removeAtIndex(index)
                    lineView.setNeedsDisplay()
                    break
                }
            }
            // Find if there is a facies vignette
            for (fcindex, fc) in enumerate(faciesView.faciesColumns) {
                for (index,value) in enumerate(fc.faciesVignettes) {
                    if( value.rect.intersects(rect) ) {
                        fc.remove(index)
                        if( fc.faciesVignettes.count == 0 ) {
                            faciesView.faciesColumns.removeAtIndex(fcindex)
                        }
                        faciesView.setNeedsDisplay()
                        break
                    }
                }
            }
        }
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch = touches.first as! UITouch
        let point = touch.locationInView(self)
        
        if( drawMode != ToolMode.Facies ) {
           lineView.currentLine.points.append(point)
           if( drawMode != ToolMode.Erase ) {
                lineView.setNeedsDisplay()
           }
        } else {
           faciesView.drawTool!.move(point)
           faciesView.setNeedsDisplay()
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
            lineView.currentLine.color = curColor
            lineView.currentLine.name = lineView.currentLineName
            lineView.currentLine.cleanOrientation()
            lineView.add(lineView.currentLine)
            lineView.computePolygon()
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
                        lineView.computePolygon()
                        break
                    }
                }
            }
        } else if( drawMode == ToolMode.Facies ) {
            if( faciesView.drawTool != nil ) {
                faciesView.drawTool!.end(imageId: faciesView.imageId())
            }
            faciesView.drawTool = nil
            faciesView.setNeedsDisplay()
        }
        lineView.currentLine = Line()
        lineView.setNeedsDisplay()
    }
    
    /**
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
    }
**/
}
