//
//  DrawingView.swift
//  SnapMeasure
//
//  Created by next-shot on 5/21/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

struct Line {
    enum Role : Int {
        case border = 0, horizon = 1, unconformity = 2, fault = 3
    }
    
    var points = [CGPoint]()
    var name = String()
    var color = UIColor.black.cgColor
    var role : Role = Role.horizon
    
    mutating func merge(_ line: Line) -> Bool {
        var points0 = points
        var points1 = line.points
        
        if( points1.count < 1 ) {
            return false
        }
        if( points0.count < 1 ) {
            return false
        }
        if( points1[0].x > points0[points0.count-1].x ) {
            // If new line is all after the last point -> separate line
            return false
        } else if( points1[points1.count-1].x < points0[0].x ) {
            // If new line is all before the first point -> separate line
            return false
        }
        
        var newPoints = [CGPoint]()
        var inserted = false
        for i in 0 ..< points0.count {
            if( points0[i].x > points1[0].x ) {
                // insert new points
                if( !inserted ) {
                    for j in 0 ..< points1.count {
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
        return true
    }
    
    mutating func cleanOrientation() {
        // See if first is in opposite direction of the line and remove it (finger tremble)
        if( points.count < 2 ) {
            return
        }
        
        let globalLeftToRight = points.last!.x > points.first!.x
        var filtered = false
        repeat {
            filtered = false
            let leftToRight = points[1].x > points[0].x
            if( globalLeftToRight != leftToRight ) {
                points.remove(at: 0)
                filtered = true
            }
        } while ( filtered )
        
        if( !globalLeftToRight ) {
            points = points.reversed()
        }
    }
    
    func intersectBox(_ rect: CGRect) -> Bool {
        for i in 0 ..< points.count-1 {
            if( segmentIntersectRectangle(rect, p1: points[i], p2: points[i+1])) {
                return true
            }
        }
        return false
    }
    
    func segmentIntersectRectangle(_ rect: CGRect, p1: CGPoint, p2: CGPoint) -> Bool {
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
        let dx = p2.x - p1.x;
        
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
    
    static func segmentsIntersect(_ a: CGPoint, b: CGPoint, c: CGPoint, d: CGPoint) -> (exist: Bool, loc: CGPoint) {
        var denom = Double(a.x) * Double( d.y - c.y ) + Double(b.x) * Double( c.y - d.y ) ;
        denom += Double(d.x) * Double( b.y - a.y ) + Double(c.x) * Double( a.y - b.y );
            
        /* If denom is zero, then segments are parallel: no intersection */
        if( abs(denom) < 1e-6 ) {
            return (false, CGPoint())
        }
            
        var nums = Double(a.x) * Double( d.y - c.y ) + Double(c.x) * Double( a.y - d.y ) ;
        nums += Double(d.x) * Double( c.y - a.y )
        var s = nums / denom
        
        var numt = Double(a.x) * Double( c.y - b.y ) + Double(b.x) * Double( a.y - c.y )
        numt += Double(c.x) * Double( b.y - a.y )
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
    
    static func distance(_ p0: CGPoint, _ p1: CGPoint, _ p: CGPoint) -> Double {
        let dx = Double(p1.x-p0.x)
        let dy = Double(p1.y-p0.y)
        let dpx = Double(p.x-p0.x)
        let dpy = Double(p.y-p0.y)
        let ldir = sqrt(dx*dx + dy*dy)
        let det = dpy*dx - dpx*dy
        return abs(det)/ldir
    }
    
    static func segmentIntersectPoint(_ a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
        if( b.x != a.x ) {
            return (c.x - a.x)/(b.x - a.x)
        } else if( b.y != a.y ) {
            return (c.y - a.y)/(b.y - a.y)
        } else {
            return 0.0
        }
    }
    
    mutating func filterKinks() {
        var newPoints = [CGPoint]()
        let vertices = self.points
        newPoints.append(vertices[0])
        let n = vertices.count
        var i = 0
        while ( i < n-2 ) {
            var di = 0
            repeat {
                let p0x = vertices[i].x
                let p0y = vertices[i].y
                let p1x = vertices[i+di+1].x
                let p1y = vertices[i+di+1].y
                let p2x = vertices[i+di+2].x
                let p2y = vertices[i+di+2].y
                var dx0 = p1x - p0x
                var dy0 = p1y - p0y
                let d0 = sqrt(dx0*dx0 + dy0*dy0)
                dx0 /= d0
                dy0 /= d0
                var dx1 = p2x - p1x
                var dy1 = p2y - p1y
                let d1 = sqrt(dx1*dx1 + dy1*dy1)
                dx1 /= d1
                dy1 /= d1
                let dot = dx0*dx1 + dy0*dy1
                if( dot < 0 || dot < 0.7 ) {
                    di += 1
                } else {
                    newPoints.append(vertices[i+di+1])
                    i += di
                    di = 0
                }
            } while( di > 0 && di+i < n-2 )
            i += 1
        }
        newPoints.append(vertices[n-1])
        points = newPoints
    }
    
    mutating func filter(tol: Float) {
        var vertices = self.points
        if( vertices.count == 0 ) {
            return
        }
        
        var found = false
        var newPoints = [(p: CGPoint, i: Int)]()
        newPoints.append((p: vertices.first!, i: 0))
        newPoints.append((p: vertices.last!, i: vertices.count-1))
        
        repeat {
            found = false
            // In each interval of newPoints find if there is a new point to insert
            for i in 0 ..< newPoints.count - 1 {
                let p0 = newPoints[i]
                let p2 = newPoints[i+1]
                var maxDist : Double = Double(tol)
                var maxDistIndex = -1
                for j in p0.i+1 ..< p2.i {
                    let p1 = vertices[j]
                    let d = Line.distance(p0.p, p2.p, p1)
                    if( d > maxDist ) {
                        maxDist = d
                        maxDistIndex = j
                    }
                }
                if( maxDistIndex != -1 ) {
                    newPoints.insert((p: vertices[maxDistIndex], i: maxDistIndex), at: i+1)
                    found = true
                }
            }
        } while( found )
        
        vertices.removeAll()
        for p in newPoints {
            vertices.append(p.p)
        }
        
        points = vertices
    }
}


class LineViewTool {
    var lineName = String()
    var lineType = String()
    
    static func role(_ lineType: String) -> Line.Role {
        if( lineType == horizonTypes[0] ) {
            return Line.Role.horizon
        } else if( lineType == horizonTypes[1] ) {
            return Line.Role.unconformity
        } else if( lineType == horizonTypes[2] ) {
            return Line.Role.fault
        } else {
            return Line.Role.border
        }
    }
    
    static func typeName(_ role: Line.Role) -> String {
        if( role == Line.Role.horizon ) {
            return horizonTypes[0]
        } else if( role == Line.Role.unconformity ) {
            return horizonTypes[1]
        } else if( role == Line.Role.fault ) {
            return horizonTypes[2]
        } else {
            return horizonTypes[0]
        }
    }
}

class LineView : UIView {
    var lines = [Line]()
    var measure = [CGPoint]()
    var refMeasurePoints = [CGPoint]()
    var currentMeasure : Float = 0.0
    var refMeasureValue : Float = 0.0
    var tool = LineViewTool()
    var polygons : Polygons?
    var drawPolygon = false
    var zoomScale : CGFloat = 1.0
    var boundsCopy = CGRect()
    weak var scrollView: UIScrollView?
    var visibleRect = CGRect()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class var layerClass : AnyClass {
        return CATiledLayer.self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        boundsCopy = self.bounds // to use in drawRect method to avoid multi-threaded warnings
        if( scrollView != nil ) {
            visibleRect = scrollView!.convert(scrollView!.bounds, to: self)
        }
    }

    // Handle thread safety for currentLine
    fileprivate var _currentLine = Line()
    fileprivate let queue = DispatchQueue(label: "...", attributes: [])
    func with(_ queue: DispatchQueue, f: ()->Void) {
        queue.sync(execute: f)
    }
    
    var currentLine : Line {
        get {
            var result : Line?
            with(queue) {
                result = self._currentLine
            }
            return result!
        }
        set {
            with(queue) {
                self._currentLine = newValue
            }
        }
    }
    //var currentLine = Line()
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        let line_width = 2.0/zoomScale
        let font_size = 16.0/zoomScale
        context?.setLineWidth(line_width)
        
        // Draw digitized lines
        for line in lines {
            context?.setStrokeColor(line.color)
            context?.move (to: CGPoint(x: line.points[0].x, y: line.points[0].y))
            for k in 1 ..< line.points.count {
                context?.addLine (to: CGPoint(x: line.points[k].x, y: line.points[k].y));
            }
            context?.strokePath()
            
            var textPoint = CGPoint(x: line.points[0].x, y: line.points[0].y)
            if( !visibleRect.isEmpty ) {
                // Compute the intersection of the line with the visibleRect (reduced by a margin).
                let margin : CGFloat = 5
                let left_edge_p0 = CGPoint(x: visibleRect.origin.x + margin, y: visibleRect.origin.y + margin)
                let left_edge_p1 = CGPoint(x: visibleRect.origin.x + margin, y: visibleRect.origin.y + visibleRect.height - margin)
                for j in 0 ..< line.points.count-1 {
                    let ipoint = Line.segmentsIntersect(
                        left_edge_p0, b: left_edge_p1, c: line.points[j], d: line.points[j+1]
                    )
                    if( ipoint.exist ) {
                        textPoint = ipoint.loc
                        break
                    }
                }
            }
            
            NSString(string: line.name).draw(
                at: textPoint,
                withAttributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: font_size)]
            )
        }
        
        // Fill color
        if( polygons != nil ) {
            for p in polygons!.polygons  {
                if( p.color == nil ) {
                    continue
                }
                context?.setAlpha(0.2)
                context?.setFillColor(p.color!)
                var first = true
                for l in p.lines  {
                    if( l.reverse ) {
                        for p in l.line.points.reversed() {
                            if( first ) {
                                context?.move (to: CGPoint(x: p.x, y: p.y))
                                first = false
                            }
                            context?.addLine (to: CGPoint(x: p.x, y: p.y))
                        }
                    } else {
                        for p in l.line.points {
                            if( first ) {
                                context?.move (to: CGPoint(x: p.x, y: p.y))
                                first = false
                            }
                            context?.addLine (to: CGPoint(x: p.x, y: p.y))
                        }
                    }
                }
                context?.fillPath()
            }
        }
        
        // Draw line being drawn
        let curLine = currentLine // Copy for multi-threaded
        if( curLine.points.count > 2 ) {
            context?.setStrokeColor(UIColor.black.cgColor)
            // Draw as dash line
            let dashes:[CGFloat] = [6, 2]
            context?.setLineDash(phase: 0, lengths: dashes)
            context?.move (to: CGPoint(x: curLine.points[0].x, y: curLine.points[0].y));
            for k in 1 ..< curLine.points.count {
                context?.addLine (to: CGPoint(x: curLine.points[k].x, y: curLine.points[k].y));
            }
            context?.strokePath()
            
            // return to normal line
            let normal : [CGFloat]=[1]
            context?.setLineDash(phase: 0,lengths: normal)
        }
        
        var scale = 1.0
        if( refMeasurePoints.count == 2 ) {
            // Draw reference line
            context?.setStrokeColor(UIColor.blue.cgColor)
            
            // Add Label
            let loc = CGPoint(
                x: (refMeasurePoints[1].x+refMeasurePoints[0].x)/2.0,
                y: (refMeasurePoints[1].y+refMeasurePoints[0].y)/2.0
            )
            NSString(format: "%g", refMeasureValue).draw(
                at: loc,
                withAttributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: font_size)]
            )
            
            context?.move (to: CGPoint(x: refMeasurePoints[0].x, y: refMeasurePoints[0].y));
            context?.addLine (to: CGPoint(x: refMeasurePoints[1].x, y: refMeasurePoints[1].y));
            context?.strokePath()
            
            // Draw scale bar
            if( refMeasurePoints[0].y == refMeasurePoints[1].y ) {
               let minp = CGPoint(x: min(refMeasurePoints[0].x, refMeasurePoints[1].x), y: refMeasurePoints[0].y)
               let width = abs(refMeasurePoints[0].x-refMeasurePoints[1].x)
               let height : CGFloat = 5/zoomScale
               context?.setFillColor(UIColor.black.cgColor)
               context?.fill(CGRect(x: minp.x, y: refMeasurePoints[0].y-height, width: width/2, height: height))
               context?.setFillColor(UIColor.white.cgColor)
               context?.fill(CGRect(x: minp.x+width/2, y: refMeasurePoints[0].y-height, width: width/2, height: height))
            }
            
            let dx = refMeasurePoints[1].x - refMeasurePoints[0].x
            let dy = refMeasurePoints[1].y - refMeasurePoints[0].y
            let dist = sqrt(dx*dx + dy*dy)
            scale = Double(refMeasureValue)/Double(dist)
        }
        
        let measure = self.measure // Copy for multi-threaded
        if( measure.count == 2 ) {
            // Draw measurement line
            context?.setStrokeColor(UIColor.red.cgColor)
            let dx = measure[1].x - measure[0].x
            let dy = measure[1].y - measure[0].y
            let dist = sqrt(dx*dx + dy*dy)
            
            // Add label
            currentMeasure = Float(dist) * Float(scale)
            let loc = CGPoint(x: (measure[1].x+measure[0].x)/2.0, y: (measure[1].y+measure[0].y)/2.0)
            NSString(format: "%g", currentMeasure).draw(
                at: loc,
                withAttributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: font_size)]
            )
            
            context?.move (to: CGPoint(x: measure[0].x, y: measure[0].y));
            context?.addLine (to: CGPoint(x: measure[1].x, y: measure[1].y));
            context?.strokePath()
        }
        
        // Draw bounding rectangle
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.move (to: CGPoint(x: 10, y: 10));
        context?.addLine(to: CGPoint(x: boundsCopy.width - 10.0, y: 10.0));
        context?.addLine(to: CGPoint(x: boundsCopy.width - 10.0, y: boundsCopy.height - 10.0))
        context?.addLine(to: CGPoint(x: 10, y: boundsCopy.height - 10.0))
        context?.addLine(to: CGPoint(x: 10, y: 10))
        context?.strokePath()
    }
    
    // Add or merge a new line
    // The merge is done when the name of the new line is the same as the name of an existing line
    // And when the new portion and the old portion overlaps. 
    func add(_ iline: Line) {
        if( iline.points.count < 2 ) {
            return
        }
        var line = iline
        line.filter(tol: Float(boundsCopy.maxY*0.002/zoomScale))
        line.filterKinks()
        
        // Find if it needs to be merged with an existing line
        for (index,value) in lines.enumerated() {
            if( value.name == line.name ) {
                var newline = value
                newline.color = line.color // Take latest color
                newline.role = line.role // Take latest role
                if( newline.merge(line) ) {
                    newline.filterKinks()
                   lines.remove(at: index)
                   lines.insert(newline, at: index)
                   return
                }
            }
        }
        // If not an existing line
        // Order the line from top to bottom (y)
        var inserted = false
        for i in 0 ..< lines.count  {
            if( line.points[0].y < lines[i].points[0].y ) {
                lines.insert(line, at: i)
                inserted = true
                break
            }
        }
        if( !inserted ) {
           lines.append(line)
        }
    }
    
    func computePolygon() {
        if( drawPolygon == false ) {
            polygons = nil
        } else {
            var nlines = lines;
            var border = Line()
            border.role = Line.Role.border
            border.points.append(CGPoint(x: 10, y: 10))
            border.points.append(CGPoint(x: bounds.width - 10.0, y: 10))
            border.points.append(CGPoint(x: bounds.width - 10.0, y: bounds.height - 10.0))
            border.points.append(CGPoint(x: 10, y: bounds.height - 10.0))
            border.points.append(CGPoint(x: 10, y: 10))
            
            nlines.append(border)
            polygons = Polygons(lines: nlines)
        }
    }
}

class FaciesVignette {
    var rect: CGRect = CGRect()
    var imageName = String()
    
    init(rect: CGRect, image: String) {
        self.rect = rect
        self.imageName = image
    }
}

class FaciesColumn {
    var faciesVignettes = [FaciesVignette]()
    
    func inside(_ point: CGPoint) -> Bool {
        if( faciesVignettes.count == 0 ) {
            return false
        }
        let rect = faciesVignettes[0].rect
        return point.x > rect.minX-5 && point.x < rect.maxX+5;
    }
    
    func snap(_ point: CGPoint) -> (point: CGPoint, below: Bool) {
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
    
    func snap(_ origin: CGPoint, point: CGPoint) -> CGRect {
        if( faciesVignettes.count == 0 ) {
            let xmin = min(origin.x, point.x)
            let xmax = max(origin.x, point.x)
            let ymin = min(origin.y, point.y)
            let ymax = max(origin.y, point.y)
            return CGRect(x: xmin, y: ymin, width: xmax-xmin, height: ymax-ymin)
        } else {
            var snapped = CGPoint()
            if( origin.x == faciesVignettes[0].rect.minX ) {
                snapped.x = faciesVignettes[0].rect.maxX
            } else {
                snapped.x = faciesVignettes[0].rect.minX
            }
            let xmin = min(origin.x, snapped.x)
            let xmax = max(origin.x, snapped.x)
            if( origin.y == faciesVignettes[0].rect.minY ) {
                // Drawing rectangle above the first one
                if( point.y < origin.y ) {
                   return CGRect(x: xmin, y: point.y, width: xmax-xmin, height: origin.y - point.y)
                } else {
                   return CGRect(x: xmin, y: origin.y, width: xmax-xmin, height: 0)
                }
            } else {
                // Drawing rectangle below the last one
                if( point.y > origin.y ) {
                    return CGRect(x: xmin, y: origin.y, width: xmax-xmin, height: point.y - origin.y)
                } else {
                    return CGRect(x: xmin, y: origin.y, width: xmax-xmin, height: 0)
                }
            }
        }
    }
    
    
    // Remove one element (if the thing is in the middle, remove all elements before or after)
    func remove(_ index: Int) {
        if( index == 0 ) {
            faciesVignettes.remove(at: 0)
        } else if( index == faciesVignettes.count-1 ) {
            faciesVignettes.remove(at: index)
        } else if( index < faciesVignettes.count/2 ) {
            faciesVignettes.removeSubrange(0 ... index+1)
        } else {
            faciesVignettes.removeSubrange(index ..< faciesVignettes.count)
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
    
    func move(_ point: CGPoint) {
        curRect = curColumn!.snap(origin, point: point)
    }
    
    func end(imageName: String) {
        if( curRect.width < 5 || curRect.height < 0.01 ) {
            return
        }
        if( append ) {
            curColumn!.faciesVignettes.append(
                FaciesVignette(rect: curRect, image: imageName)
            )
        } else {
            curColumn!.faciesVignettes.insert(
                FaciesVignette(rect: curRect, image: imageName), at: 0
            )
        }
    }
}

class FaciesView : UIView {
    var faciesColumns = [FaciesColumn]()
    var drawTool : FaciesDrawTool?
    var faciesCatalog : FaciesCatalog?
    var curImageName = String()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class var layerClass : AnyClass {
        return CATiledLayer.self
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(2.0)
        
        for fc in faciesColumns {
            for v in fc.faciesVignettes{
                let imageinfo = faciesCatalog?.image(v.imageName)
                if( imageinfo != nil && imageinfo!.image != nil ) {
                    let uiimage = imageinfo!.image!
                    let cgimage = uiimage.cgImage
                    context?.saveGState()
                    context?.setAlpha(0.4)
                    if( imageinfo!.tile ) {
                        context?.clip(to: v.rect)
                        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: v.rect.size.height)
                        context?.concatenate(flipVertical)
                        context?.draw(
                            cgimage!,
                            in: CGRect(x:0, y:0, width: uiimage.size.width, height: uiimage.size.height), byTiling: true
                        )
                    } else {
                        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: v.rect.size.height+2.0*v.rect.origin.y)
                        context?.concatenate(flipVertical)
                        context?.draw(cgimage!, in: v.rect, byTiling: false)
                    }
                    context?.restoreGState()
                }
                context?.addRect(v.rect)
                context?.strokePath()
            }
        }
        
        if( drawTool != nil && drawTool!.curRect.width > 0 && drawTool!.curRect.height > 0 ) {
            context?.addRect(drawTool!.curRect)
            context?.strokePath()
        }
    }
    
}

class TextDrawTool {
    var curRect = CGRect()
    var origin = CGPoint()
    init(point: CGPoint) {
        curRect = CGRect(x: point.x, y: point.y, width: 0, height: 0)
        origin = point
    }
    
    func move(_ point: CGPoint) {
        let xmin = min(origin.x, point.x)
        let xmax = max(origin.x, point.x)
        let ymin = min(origin.y, point.y)
        let ymax = max(origin.y, point.y)
        curRect = CGRect(x: xmin, y: ymin, width: xmax-xmin, height: ymax-ymin)
    }

}

class TextView : UIView {
    var drawTool : TextDrawTool?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class var layerClass : AnyClass {
        return CATiledLayer.self
    }
    
    func addText(_ label: String, rect: CGRect) -> UILabel {
        let uilabel = UILabel(frame: rect)
        uilabel.adjustsFontSizeToFitWidth = true
        uilabel.numberOfLines = 0
        uilabel.text = label
        self.addSubview(uilabel)
        return uilabel
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(2.0)
        if( drawTool != nil && drawTool!.curRect.width > 0 && drawTool!.curRect.height > 0 ) {
            context?.addRect(drawTool!.curRect)
            context?.strokePath()
        }
    }
}

struct DipMarkerPoint {
    var loc: CGPoint
    var normal : Vector3
    var realLocation : CLLocation
    var snappedLine : Line?
}

class DipMarkerPickTool {
    var normal : Vector3
    var previousToolMode : Int
    var previousButton : UIButton?
    var curPoint = CGPoint()
    var realLocation : CLLocation?
    
    init( normal: Vector3, realLocation: CLLocation?, toolMode: Int, prevButton: UIButton?){
        self.normal = normal
        self.previousToolMode = toolMode
        self.realLocation = realLocation
        self.previousButton = prevButton
    }
    
    func move(_ point: CGPoint) {
        curPoint = point
    }
}

class DipMarkerView : UIView {
    var points = [DipMarkerPoint]()
    var normal = Vector3(x: 0, y: 0, z: 0)
    var pickTool : DipMarkerPickTool?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class var layerClass : AnyClass {
        return CATiledLayer.self
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(2.0)

        for p in points {
            if( p.loc.x == 0 && p.loc.y == 0 ) {
                continue
            }
            if( p.snappedLine != nil ) {
                 context?.setStrokeColor(p.snappedLine!.color)
            } else {
                 context?.setStrokeColor(UIColor.red.cgColor)
            }
            let hl : CGFloat = 4
            context?.move (to: CGPoint(x: p.loc.x - hl, y: p.loc.y - hl));
            context?.addLine(to: CGPoint(x: p.loc.x - hl, y: p.loc.y + hl));
            context?.addLine(to: CGPoint(x: p.loc.x + hl, y: p.loc.y + hl))
            context?.addLine(to: CGPoint(x: p.loc.x + hl, y: p.loc.y - hl))
            context?.addLine(to: CGPoint(x: p.loc.x - hl, y: p.loc.y - hl))
            context?.strokePath()
            
            //Project normal vector onto plane
            //B = A - (A.dot.N)N
            let dot = normal.x*p.normal.x + normal.y*p.normal.y + normal.z*p.normal.z
            let b = Vector3(x: p.normal.x - dot * normal.x, y: p.normal.y - dot * normal.y, z: p.normal.z - dot * normal.z)
            let adip = asin(sqrt(b.x*b.x+b.y*b.y)/sqrt(b.x*b.x+b.y*b.y+b.z*b.z))
            let dmhl : Double = 20
            context?.move (to: CGPoint(x: p.loc.x - CGFloat(dmhl * cos(adip)), y: p.loc.y - CGFloat(dmhl * sin(adip))))
            context?.addLine(to: CGPoint(x: p.loc.x + CGFloat(dmhl * cos(adip)), y: p.loc.y + CGFloat(dmhl * sin(adip))))
            context?.strokePath()
        }

        if( pickTool != nil ) {
            context?.setStrokeColor(UIColor.red.cgColor)
            context?.move (to: CGPoint(x: pickTool!.curPoint.x - 50, y: pickTool!.curPoint.y));
            context?.addLine(to: CGPoint(x: pickTool!.curPoint.x + 50, y: pickTool!.curPoint.y))
            context?.strokePath()
            context?.move (to: CGPoint(x: pickTool!.curPoint.x, y: pickTool!.curPoint.y - 50));
            context?.addLine(to: CGPoint(x: pickTool!.curPoint.x, y: pickTool!.curPoint.y + 50))
            context?.strokePath()
        }
    }
    
    func initializeNormal(_ orientation: Float?) {
        if( orientation != nil ) {
            normal.x = Double(cos(orientation!)) // x is along North
            normal.y = Double(sin(orientation!))
        }
    }
    
    // Add a point located in the current picture
    func addPoint(_ loc: CGPoint, line: Line?) {
        if( pickTool != nil ) {
            let dm = DipMarkerPoint(
                loc: loc, normal: pickTool!.normal,
                realLocation: pickTool!.realLocation == nil ? CLLocation() : pickTool!.realLocation!,
                snappedLine: line
            )
           points.append(dm)
        }
    }
    
    // Add a point related to the current picture but not localized in the picture
    func addPoint(realLocation: CLLocation, normal: Vector3) {
        let dm = DipMarkerPoint(
            loc: CGPoint(), normal: normal,
            realLocation: realLocation,
            snappedLine: nil
        )
        points.append(dm)
    }
    
}

class DrawingView : UIImageView {
    enum ToolMode : Int {
        case draw = 0, erase = 1, measure = 2, reference = 3, facies = 4, text = 5,
        dipMarker = 6, select = 7, measure_H = 8, measure_L = 9
    }
    
    var lineView = LineView()
    var faciesView = FaciesView()
    var textView = TextView()
    var dipMarkerView = DipMarkerView()
    var imageSize = CGSize()
    
    var drawMode : ToolMode = ToolMode.draw
    var imageInfo = ImageInfo()
    var curColor = UIColor.black.cgColor
    var affineTransform = CGAffineTransform.identity
    var controller : DrawingViewController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        lineView = LineView(frame: frame)
        lineView.isOpaque = false
        lineView.backgroundColor = nil
        lineView.autoresizingMask = [UIViewAutoresizing.flexibleWidth,UIViewAutoresizing.flexibleHeight]
        self.addSubview(lineView)
        
        faciesView = FaciesView(frame: frame)
        faciesView.isOpaque = false
        faciesView.backgroundColor = nil
        faciesView.autoresizingMask = [UIViewAutoresizing.flexibleWidth,UIViewAutoresizing.flexibleHeight]
        self.addSubview(faciesView)
        
        textView = TextView(frame: frame)
        textView.isOpaque = false
        textView.backgroundColor = nil
        textView.autoresizingMask = [UIViewAutoresizing.flexibleWidth,UIViewAutoresizing.flexibleHeight]
        self.addSubview(textView)
        
        dipMarkerView = DipMarkerView(frame: frame)
        dipMarkerView.isOpaque = false
        dipMarkerView.backgroundColor = nil
        dipMarkerView.autoresizingMask = [UIViewAutoresizing.flexibleWidth,UIViewAutoresizing.flexibleHeight]
        self.addSubview(dipMarkerView)

    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        
        lineView = LineView(frame: self.bounds)
        lineView.isOpaque = false
        lineView.backgroundColor = nil
        lineView.autoresizingMask = [UIViewAutoresizing.flexibleWidth,UIViewAutoresizing.flexibleHeight]
        self.addSubview(lineView)

        
        faciesView = FaciesView(frame: self.bounds)
        faciesView.isOpaque = false
        faciesView.backgroundColor = nil
        faciesView.autoresizingMask = [UIViewAutoresizing.flexibleWidth,UIViewAutoresizing.flexibleHeight]
        self.addSubview(faciesView)
        
        textView = TextView(frame: self.bounds)
        textView.isOpaque = false
        textView.backgroundColor = nil
        textView.autoresizingMask = [UIViewAutoresizing.flexibleWidth,UIViewAutoresizing.flexibleHeight]
        self.addSubview(textView)
        
        dipMarkerView = DipMarkerView(frame: self.bounds)
        dipMarkerView.isOpaque = false
        dipMarkerView.backgroundColor = nil
        dipMarkerView.autoresizingMask = [UIViewAutoresizing.flexibleWidth,UIViewAutoresizing.flexibleHeight]
        self.addSubview(dipMarkerView)
    }
    
    func initFrame() {
        // self.sizeToFit()
        //lineView.frame = CGRect(origin: CGPoint(x: 0,y: 0), size: self.bounds.size)
    }
    
    func initFromObject(_ detailedImage: DetailedImageObject, catalog: FaciesCatalog) {
        faciesView.faciesCatalog = catalog
        if( detailedImage.scale != nil && detailedImage.scale!.floatValue != 0 ) {
            // Draw scale at approximatevely 10% of image width
            let refValue = Float(self.imageSize.width)*0.1*detailedImage.scale!.floatValue
            // Compute a nice reference number to draw
            let niceRefValue = getNiceNumber(refValue)
            // Recompute image pixel distance from this reference number and scale
            let dist = niceRefValue / detailedImage.scale!.floatValue
            lineView.refMeasureValue = niceRefValue
            let p1 = CGPoint(x: self.imageSize.width-100.0, y: self.imageSize.height-100.0)
            var p0 = p1
            p0.x -= CGFloat(dist)
            lineView.refMeasurePoints.append(p0)
            lineView.refMeasurePoints.append(p1)
        }
        
        // Get the lines via the DetailedView NSSet.
        let scalex = self.bounds.width/self.imageSize.width
        let scaley = self.bounds.height/self.imageSize.height
        
        if( self.contentMode == UIViewContentMode.scaleToFill ) {
            affineTransform = CGAffineTransform(scaleX: scalex, y: scaley)
        } else if( self.contentMode == UIViewContentMode.scaleAspectFill ) {
            // scale to maximum while keeping aspect ratio
            let scale = max(scalex, scaley)
            affineTransform = CGAffineTransform(scaleX: scale, y: scale)
            
            // Center.
            let tx = (self.bounds.width - self.imageSize.width * scale)/2.0
            let ty = (self.bounds.height - self.imageSize.height * scale)/2.0
            affineTransform = affineTransform.concatenating(CGAffineTransform(translationX: tx, y: ty))
        } else if( self.contentMode == UIViewContentMode.scaleAspectFit ) {
            // scale to minimum
            let scale = min(scalex, scaley)
            affineTransform = CGAffineTransform(scaleX: scale, y: scale)
            // Center
            let tx = (self.bounds.width - self.imageSize.width * scale)/2.0
            let ty = (self.bounds.height - self.imageSize.height * scale)/2.0
            affineTransform = affineTransform.concatenating(CGAffineTransform(translationX: tx, y: ty))
        }
        
        for alo in detailedImage.lines {
            let lo = alo as? LineObject
            var line = Line()
            line.name = lo!.name
            let color = NSKeyedUnarchiver.unarchiveObject(with: lo!.colorData as Data) as? UIColor
            line.color = (color?.cgColor)!
            line.role = LineViewTool.role(lo!.type)
            let arrayData = lo!.pointData
            let array = Array(
                UnsafeBufferPointer(
                    start: (arrayData as NSData).bytes.bindMemory(to: CGPoint.self, capacity: arrayData.count),
                    count: arrayData.count/MemoryLayout<CGPoint>.size
                )
            )
            for i in 0 ..< array.count {
                line.points.append(array[i].applying(affineTransform))
            }
            lineView.lines.append(line)
            lineView.setNeedsDisplay()
        }
        
        // Get the facies vignettes
        for afvo in detailedImage.faciesVignettes {
            let fvo = afvo as? FaciesVignetteObject
            let orect = fvo!.rect.cgRectValue!
            let rect = orect.applying(affineTransform)
            let fv = FaciesVignette(rect: rect, image: fvo!.imageName)
            let center = CGPoint(x: (rect.minX+rect.maxX)/2.0, y: (rect.minY+rect.maxY)/2.0)
            
            var inserted_in_column = false
            for fvc in faciesView.faciesColumns {
                if( fvc.inside(center) ) {
                    for (index,cfv) in fvc.faciesVignettes.enumerated() {
                        if( center.y < cfv.rect.minY ) {
                            fvc.faciesVignettes.insert(fv, at: index)
                            inserted_in_column = true
                            break
                        }
                    }
                    if( !inserted_in_column ) {
                        fvc.faciesVignettes.append(fv)
                        inserted_in_column = true
                        break
                    }
                }
            }
            if( !inserted_in_column ) {
                let nfc = FaciesColumn()
                nfc.faciesVignettes.append(fv)
                faciesView.faciesColumns.append(nfc)
            }
            faciesView.setNeedsDisplay()
        }
        
        // Get the annotations
        for ato in detailedImage.texts {
            let to = ato as? TextObject
            let orect = to!.rect.cgRectValue!
            let rect = orect.applying(affineTransform)
            _ = textView.addText(to!.string, rect: rect)
            textView.setNeedsDisplay()
        }
        
        // Initialize the dip markers
        for admpo in detailedImage.dipMeterPoints {
            let dmpo = admpo as? DipMeterPointObject
            var loc = dmpo!.locationInImage.cgPointValue!
            if( loc.x != 0 && loc.y != 0 ) {
                loc = loc.applying(affineTransform)
            }
            let strike = dmpo!.strike.doubleValue * .pi/180
            let dip = dmpo!.dip.doubleValue * .pi / 180
            var line : Line?
            if( dmpo?.feature != "unassigned" ) {
                for l in lineView.lines {
                    if( l.name == dmpo?.feature ) {
                        line = l
                        break
                    }
                }
            }
            dipMarkerView.points.append(DipMarkerPoint(
                loc: loc,
                normal: Vector3(x: cos(strike)*sin(dip), y: sin(strike)*sin(dip), z: cos(dip)),
                realLocation: dmpo!.realLocation as! CLLocation,
                snappedLine: line
            ))
            dipMarkerView.setNeedsDisplay()
        }
        
        dipMarkerView.initializeNormal(detailedImage.compassOrientation?.floatValue)
    }
    
    override var bounds : CGRect {
        // Function to transform the coordinates to fit the new bounds
        // in the same way as the ImageView transform the image.
        willSet(newBounds) {
            // First take the inverse of the previous transform
            var caffineTransform = self.affineTransform.inverted()
            
            // Compute scaling factors
            let scalex = newBounds.width/self.imageSize.width
            let scaley = newBounds.height/self.imageSize.height
            
            affineTransform = CGAffineTransform.identity
            
            if( self.contentMode == UIViewContentMode.scaleToFill) {
                affineTransform = CGAffineTransform(scaleX: scalex, y: scaley)
            } else if( self.contentMode == UIViewContentMode.scaleAspectFill ) {
                // scale to maximum while keeping aspect ratio
                let scale = max(scalex, scaley)
                affineTransform = CGAffineTransform(scaleX: scale, y: scale)
        
                // Center.
                let tx = (newBounds.width - self.imageSize.width * scale)/2.0
                let ty = (newBounds.height - self.imageSize.height * scale)/2.0
                affineTransform = affineTransform.concatenating(CGAffineTransform(translationX: tx, y: ty))
            } else if( self.contentMode == UIViewContentMode.scaleAspectFit ) {
                // scale to minimum
                let scale = min(scalex, scaley)
                affineTransform = CGAffineTransform(scaleX: scale, y: scale)
                // Center
                let tx = (newBounds.width - self.imageSize.width * scale)/2.0
                let ty = (newBounds.height - self.imageSize.height * scale)/2.0
                affineTransform = affineTransform.concatenating(CGAffineTransform(translationX: tx, y: ty))
            }
            
            // Concatenate the inverse of the previous transform with the new transform
            caffineTransform = caffineTransform.concatenating(affineTransform)
            
            for j in 0 ..< lineView.lines.count {
                for i in 0 ..< lineView.lines[j].points.count {
                    lineView.lines[j].points[i] = lineView.lines[j].points[i].applying(caffineTransform)
                }
            }
            for fvc in faciesView.faciesColumns {
                for (index,cfv) in fvc.faciesVignettes.enumerated() {
                    fvc.faciesVignettes[index].rect = cfv.rect.applying(caffineTransform)
                }
            }
            for i in 0 ..< textView.subviews.count {
                let rect = textView.subviews[i].frame.applying(caffineTransform)
                let fv = textView.subviews[i] 
                fv.frame = rect
                textView.setNeedsDisplay()
            }
            for i in 0 ..< dipMarkerView.points.count {
                if( dipMarkerView.points[i].loc.x != 0 && dipMarkerView.points[i].loc.y != 0 ) {
                    dipMarkerView.points[i].loc = dipMarkerView.points[i].loc.applying(caffineTransform)
                }
                dipMarkerView.setNeedsDisplay()
            }
            
            for i in 0 ..< lineView.refMeasurePoints.count {
                lineView.refMeasurePoints[i] = lineView.refMeasurePoints[i].applying(caffineTransform)
            }
            
            faciesView.setNeedsDisplay()
        }
        didSet(bounds) {
            lineView.computePolygon()
            lineView.setNeedsDisplay()
        }
    }
    
    override var center : CGPoint {
        willSet(newCenter) {
            //print(newCenter, center, transform)
        }
    }
    
    func select(_ point: CGPoint)  -> Line? {
        // Fingers are roughly 40 pixels wide
        let rect = CGRect(x: point.x-20.0, y: point.y-20.0, width: 40.0, height: 40.0)
        for line in lineView.lines {
            if( line.intersectBox(rect) ) {
                return line
            }
        }
        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       let touch = touches.first
       let point = touch!.location(in: self)
        
       if( drawMode != ToolMode.facies && drawMode != ToolMode.text &&
            drawMode != ToolMode.dipMarker
        ) {
            lineView.currentLine = Line()
            lineView.currentLine.points.append(point)
        } else if( drawMode == ToolMode.facies ){
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
        } else if( drawMode == ToolMode.text ) {
            textView.drawTool = TextDrawTool(point: point)
        } else if( drawMode == ToolMode.dipMarker && dipMarkerView.pickTool != nil ) {
            dipMarkerView.pickTool!.move(point)
            dipMarkerView.setNeedsDisplay()
        }
        
        if( drawMode == ToolMode.erase ) {
            let rect = CGRect(x: point.x-10.0, y: point.y-10.0, width: 20.0, height: 20.0)
            // Find if there is a line below
            for (index,value) in lineView.lines.enumerated() {
                if( value.intersectBox(rect) ) {
                    lineView.lines.remove(at: index)
                    lineView.setNeedsDisplay()
                    controller!.hasChanges = true
                    break
                }
            }
            // Find if there is a facies vignette
            for (fcindex, fc) in faciesView.faciesColumns.enumerated() {
                for (index,value) in fc.faciesVignettes.enumerated() {
                    if( value.rect.intersects(rect) ) {
                        fc.remove(index)
                        if( fc.faciesVignettes.count == 0 ) {
                            faciesView.faciesColumns.remove(at: fcindex)
                        }
                        faciesView.setNeedsDisplay()
                        controller!.hasChanges = true
                        break
                    }
                }
            }
            // Find if there is any text label to remove as well.
            for lv in textView.subviews {
                if( lv.frame.intersects(rect) ) {
                    lv.removeFromSuperview()
                    controller!.hasChanges = true
                    break
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let point = touch.location(in: self)
        
        if( drawMode == ToolMode.measure || drawMode == ToolMode.measure_H || drawMode == ToolMode.measure_L ) {
            lineView.measure.removeAll(keepingCapacity: true)
            var curLine = lineView.currentLine
            if( curLine.points.count >= 2 ) {
                lineView.measure.append(curLine.points[0])
                if( drawMode == ToolMode.measure ) {
                    lineView.measure.append(curLine.points[curLine.points.count-1])
                } else if( drawMode == ToolMode.measure_L ) {
                    lineView.measure.append(CGPoint(x: curLine.points.last!.x, y: curLine.points.first!.y))
                } else if( drawMode == ToolMode.measure_H ){
                    lineView.measure.append(CGPoint(x: curLine.points.first!.x, y: curLine.points.last!.y))
                }
                lineView.currentLine.points = lineView.measure
            } else {
                lineView.currentLine.points.append(point)
            }
            lineView.setNeedsDisplay()
            
        } else if( drawMode != ToolMode.facies && drawMode != ToolMode.text &&
            drawMode != ToolMode.dipMarker && drawMode != DrawingView.ToolMode.select
        ) {
           lineView.currentLine.points.append(point)
           if( drawMode != ToolMode.erase ) {
                lineView.setNeedsDisplay()
           }
        } else if( drawMode == ToolMode.facies && faciesView.drawTool != nil ) {
           faciesView.drawTool!.move(point)
           faciesView.setNeedsDisplay()
        } else if( drawMode == ToolMode.text && textView.drawTool != nil ) {
            textView.drawTool!.move(point)
            textView.setNeedsDisplay()
        } else if( drawMode == ToolMode.dipMarker && dipMarkerView.pickTool != nil ) {
            dipMarkerView.pickTool!.move(point)
            dipMarkerView.setNeedsDisplay()
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let point = touch.location(in: self)
        lineView.currentLine.points.append(point)
        
        var curLine = lineView.currentLine // Copy for multi-threaded
        if( drawMode == ToolMode.measure || drawMode == ToolMode.measure_H || drawMode == ToolMode.measure_L ) {
            lineView.measure.removeAll(keepingCapacity: true)
            if( curLine.points.count >= 2 ) {
                lineView.measure.append(curLine.points[0])
                if( drawMode == ToolMode.measure ) {
                    lineView.measure.append(curLine.points[curLine.points.count-1])
                } else if( drawMode == ToolMode.measure_L ) {
                    lineView.measure.append(CGPoint(x: curLine.points.last!.x, y: curLine.points.first!.y))
                } else if( drawMode == ToolMode.measure_H ){
                    lineView.measure.append(CGPoint(x: curLine.points.first!.x, y: curLine.points.last!.y))
                }
            }
        } else if( drawMode == ToolMode.draw) {
            // Avoid wrong digitizing with doubleTap event
            if( curLine.points.count > 2 ) {
                curLine.color = curColor
                curLine.name = lineView.tool.lineName
                curLine.role = LineViewTool.role(lineView.tool.lineType)
                curLine.cleanOrientation()
                lineView.add(curLine)
                lineView.computePolygon()
                controller!.hasChanges = true
            }
        } else if( drawMode == ToolMode.reference ) {
            lineView.refMeasurePoints.removeAll(keepingCapacity: true)
            if( curLine.points.count >= 2 ) {
                let p0 = curLine.points[0]
                let p1 = curLine.points[curLine.points.count-1]
                let dx = p1.x - p0.x
                let dy = p1.y - p0.y
                let dist = sqrt(dx*dx + dy*dy)
                if( dist > 0.01 ) {
                    lineView.refMeasurePoints.append(p0)
                    lineView.refMeasurePoints.append(p1)
                    controller!.hasChanges = true
                }
            }
        } else if( drawMode == ToolMode.erase ) {
            if( curLine.points.count >= 2 ) {
                let p0 = curLine.points[0]
                let p1 = curLine.points[curLine.points.count-1]
                let minX = min(p1.x, p0.x)
                let minY = min(p1.y, p0.y)
                let maxX = max(p1.x, p0.x)
                let maxY = max(p1.y, p0.y)
                
                let rect = CGRect(x: minX, y: minY, width: maxX-minX, height: maxY-minY)
                for (index,value) in lineView.lines.enumerated() {
                    if( value.intersectBox(rect) ) {
                        lineView.lines.remove(at: index)
                        lineView.computePolygon()
                        lineView.setNeedsDisplay()
                        controller!.hasChanges = true
                        break
                    }
                }
                for i in 0 ..< dipMarkerView.points.count {
                    if( rect.contains(dipMarkerView.points[i].loc) ) {
                        dipMarkerView.points.remove(at: i)
                        dipMarkerView.setNeedsDisplay()
                        controller!.hasChanges = true
                        break
                    }
                }
            }
        } else if( drawMode == ToolMode.facies ) {
            if( faciesView.drawTool != nil ) {
                faciesView.drawTool!.end(imageName: faciesView.curImageName)
                if( faciesView.drawTool!.curColumn!.faciesVignettes.isEmpty ) {
                    faciesView.faciesColumns.removeLast()
                }
                controller!.hasChanges = true
            }
            faciesView.drawTool = nil
            faciesView.setNeedsDisplay()
        } else if( drawMode == ToolMode.text && textView.drawTool != nil ) {
            let label = textView.addText("", rect: textView.drawTool!.curRect)
            controller!.hasChanges = true
            textView.drawTool = nil
            controller?.askText(label)
        } else if( drawMode == ToolMode.dipMarker && dipMarkerView.pickTool != nil ) {
            drawMode = ToolMode(rawValue: dipMarkerView.pickTool!.previousToolMode)!
            controller!.highlightButton(dipMarkerView.pickTool!.previousButton!)
            let rect = CGRect(x: point.x-10.0, y: point.y-10, width: 20.0, height: 20.0)
            var snappedLine : Line?
            for l in lineView.lines {
                if( l.intersectBox(rect) ) {
                    snappedLine = l
                }
            }
            dipMarkerView.addPoint(point, line: snappedLine)
            dipMarkerView.pickTool = nil
            dipMarkerView.setNeedsDisplay()
            controller!.hasChanges = true
        }
        lineView.currentLine = Line()
        lineView.setNeedsDisplay()
    }
    
    func getScale() -> (defined: Bool, scale: Double) {
        if( lineView.refMeasurePoints.count > 1 && lineView.refMeasureValue > 0.0 ) {
            let aft = affineTransform.inverted()
            let p0 = lineView.refMeasurePoints[0].applying(aft)
            let p1 = lineView.refMeasurePoints[1].applying(aft)
            let dx = p1.x - p0.x
            let dy = p1.y - p0.y
            let dist = sqrt(dx*dx + dy*dy)
            let scale = Double(lineView.refMeasureValue)/Double(dist)
            return (true, scale)
        } else {
            return (false, 0.0)
        }
    }
    
    func getNiceNumber(_ v: Float) -> Float {
       let expt = floor(log10(v))
       let frac = v/pow(10, expt)
       let nice : Float = {
            if( frac <= 1.0 ) {
            return 1.0
            } else if( frac <= 2.0 ) {
                return 2.0
            } else if( frac <= 5.0 ) {
                return 5.0
            } else {
                return 10.0
            }
        }()
        return nice*pow(10, expt)
    }
    
    /**
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
    }
**/
}
