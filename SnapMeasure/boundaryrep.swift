//
//  boundaryrep.swift
//  SnapMeasure
//
//  Created by next-shot on 6/1/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit

class RadialNode {
    // Contains the sorted list all all the lines intersecting at that location
    
    var loc : CGPoint = CGPoint() // The location of the radial node
    var lines = [OrientedLine]() // The sorted array of lines beginning by at this radial node
    
    init(loc: CGPoint) {
        self.loc = loc
    }
    
    func add(_ line: OrientedLine) {
        let c = line.endSegment()
        
        if( lines.count < 2 ) {
            // The first line is always first (angle = 0)
            // The second line is always second (angle > 0 && angle < 360)
           lines.append(line)
        } else {
            // Sort by computing the angle of the given line with the segment 0.
            let b = lines[0].endSegment()
            let nangle = angle(loc, b: b, c: c)
            for i in 1 ..< lines.count {
                let ci = lines[i].endSegment()
                // compute angle of segment i with segment 0,
                let iangle = angle(loc, b: b, c: ci)
                if( nangle < iangle ) {
                    lines.insert(line, at: i)
                    return
                }
            }
            lines.append(line)
        }
    }
    
    func next(_ line: OrientedLine) -> OrientedLine? {
        // Return the next line in the array of lines
        for (index, iline) in lines.enumerated() {
            if( iline == line ) {
                if( index == lines.count-1 ) {
                    // Circular list
                    return lines[0]
                } else {
                    return lines[index+1]
                }
            }
        }
        return nil
    }
    
    func cross(_ a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
        return (b.x - a.x)*(c.y - a.y) - (b.y - a.y)*(c.x - a.x)
    }
    
    func dot(_ a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
        return (b.x - a.x)*(c.x - a.x) + (b.y - a.y)*(c.y - a.y)
    }
   
    func angle(_ a: CGPoint, b: CGPoint, c: CGPoint) ->  Double {
        var a = atan2(Double(cross(a, b: b, c: c)), Double(dot(a,b: b,c: c)))
        if( a < 0.0 ) {
            // All angles need to be measured along the same direction.
            a += 2 * Double.pi
        }
        // Return angle between 0 and 360.
        return a * 180/Double.pi
    }
}

class OrientedLine : Hashable {
    // Represents a Macro Half Segment
    static var globalIndex = 0
    
    var line: Line  // The real line geometry
    var reverse : Bool // In which direction should the array of points be interpreted.
    var index: Int // An hash index
    var mate : OrientedLine? // The half macro-segment in the opposite direction
    var rn : RadialNode? // The radial node at the beginning of the macro-segment
    
    init(line: Line, reverse: Bool) {
        self.line = line
        self.reverse = reverse
        self.index = OrientedLine.globalIndex
        OrientedLine.globalIndex += 1
    }
    
    func endSegment() -> CGPoint {
        if( line.points.count < 2 ) {
            return line.points[0]
        }
        if( reverse ) {
            return line.points[line.points.count-2]
        } else {
            return line.points[1]
        }
    }

    var hashValue : Int {
        return index
    }
}

func ==(left: OrientedLine, right: OrientedLine) -> Bool {
    return left.index == right.index
}

class OrientedPolygon {
    var lines = [OrientedLine]()
    var color : CGColor?
    
    func computeColor() {
        var ymin : CGFloat = 1e+30
        var lmin : Line?
        for l in lines {
            if( l.line.role == Line.Role.horizon || l.line.role == Line.Role.border ) {
                for i in 0 ..< l.line.points.count-1 {
                    let y = (l.line.points[i].y + l.line.points[i+1].y)*0.5
                    if( y < ymin  ) {
                        ymin = y
                        lmin = l.line
                    }
                }
            }
        }
        if( lmin != nil && lmin!.role == Line.Role.horizon ) {
            color = lmin!.color
        }
    }
}

class SplitSegment {
    var index : Int
    var loc : CGPoint
    init(index: Int, loc: CGPoint) {
        self.index = index
        self.loc = loc
    }
}

class SplitLine {
    var line : Line
    var splits = [SplitSegment]()
    
    init(line: Line) {
        self.line = line
    }
    
    func add(_ seg: SplitSegment) {
        // Add the split of the line in order along the line
        for i in 0 ..< splits.count {
            if( seg.index < splits[i].index ) {
                splits.insert(seg, at: i)
                return
            } else if( seg.index == splits[i].index ) {
                // Same segment is splitted. Find the order.
                let s = Line.segmentIntersectPoint(
                    line.points[seg.index], b: line.points[seg.index+1], c: seg.loc
                )
                let si = Line.segmentIntersectPoint(
                    line.points[seg.index], b: line.points[seg.index+1], c: splits[i].loc
                )
                if( s < si ) {
                    splits.insert(seg, at: i)
                    return
                } else if( s == si ) {
                    return
                }
            }
        }
        splits.append(seg)
    }
    
    func split() -> [Line] {
        // Take the splits and create n+1 lines.
        var lines = [Line]()
        
        // Start first line
        var prev = 0
        var curLine = Line()
        curLine.name = line.name
        curLine.color = line.color
        curLine.role = line.role
        for split in splits {
            // Append from prev to split location the points
            if( prev < split.index ) {
               for i in prev ... split.index {
                   curLine.points.append(line.points[i])
               }
            }
            curLine.points.append(split.loc)
            lines.append(curLine)
            
            // Start new line
            prev = split.index+1
            curLine = Line()
            curLine.name = line.name
            curLine.color = line.color
            curLine.role = line.role
            curLine.points.append(split.loc)
        }
        
        // Fill last line
        for i in prev ..< line.points.count {
            curLine.points.append(line.points[i])
        }
        lines.append(curLine)
        return lines
    }
}

class Extremity : Comparable {
    // Store the extremity of the oriented line (Remark: Loc is redundant and can be computed)
    var line: OrientedLine
    var loc : CGPoint
    init(line: OrientedLine, loc: CGPoint) {
        self.line = line
        self.loc = loc
    }
}

func <(left: Extremity, right: Extremity) -> Bool {
    if( left.loc.x == right.loc.x ) {
        return left.loc.y < right.loc.y
    }
    return left.loc.x < right.loc.x
}

func ==(left: Extremity, right: Extremity) -> Bool {
    return left.loc == right.loc
}

class Polygons {
    var splitLines = [Int: SplitLine]()
    var polygons = [OrientedPolygon]()
    
    init(lines: [Line]) {
        // Compute all intersections and store then in splitLines
        for  i in 0 ..< lines.count {
            for j in i+1 ..< lines.count {
                intersect(lines, iline0: i, iline1: j)
            }
        }
        
        // Split the lines
        var olines = Set<OrientedLine>()
        var extremities = [Extremity]()
        for line in splitLines.values {
            let splitted = line.split()
            for nline in splitted {
                if( nline.points.count <= 1 ) {
                    continue
                }
                // For every piece of geomtric line,create two oppositely oriented lines
                let o1 = OrientedLine(line: nline, reverse: false)
                let o2 = OrientedLine(line: nline, reverse: true)
                o1.mate = o2
                o2.mate = o1
                extremities.append(Extremity(line: o1, loc: nline.points[0]))
                extremities.append(Extremity(line: o2, loc: nline.points[nline.points.count-1]))
                olines.insert(o1)
                olines.insert(o2)
            }
        }
        
        extremities.sort()
        
        // Construct the radial nodes 
        // after the sorting the extremities at the same location are next to each others
        if( extremities.count > 0 ) {
            var curExtremity = extremities[0].loc
            var rn = RadialNode(loc: curExtremity)
            for e in extremities {
                if( e.loc != curExtremity ) {
                    curExtremity = e.loc
                    rn = RadialNode(loc: curExtremity)
                }
                e.line.rn = rn
                rn.add(e.line)
            }
        }
        
        // Construct oriented polygons
        while( olines.count > 0 ) {
            var nline = olines.first
            let oPolygon = OrientedPolygon()
            while( nline != nil && olines.contains(nline!) ) {
                olines.remove(nline!)
                let mate = nline!.mate!
                
                if( nline!.rn != nil && nline!.rn!.lines.count > 1 &&
                    mate.rn != nil && mate.rn!.lines.count > 1
                ) {
                    // Not a free extremity line
                    oPolygon.lines.append(nline!)
                }
                
                // Next element of the polygon is found around the "mate" radial node
                // As the next line starting from this radial node
                nline = mate.rn?.next(mate)
            }
            oPolygon.computeColor()
            polygons.append(oPolygon)
        }
        
    }
    
    func intersect(_ lines: [Line], iline0: Int, iline1: Int) {
        let line0 = lines[iline0]
        let line1 = lines[iline1]
        for i in 0 ..< line0.points.count-1 {
            for j in 0 ..< line1.points.count-1 {
                let ipoint = Line.segmentsIntersect(
                    line0.points[i], b: line0.points[i+1], c: line1.points[j], d: line1.points[j+1]
                )
                if( ipoint.exist ) {
                    var spliti = splitLines[iline0]
                    if( spliti == nil ) {
                        spliti = SplitLine(line: line0)
                        splitLines[iline0] = spliti
                    }
                    spliti!.add(SplitSegment(index: i, loc: ipoint.loc))
                    
                    var splitj = splitLines[iline1]
                    if( splitj == nil ) {
                        splitj = SplitLine(line: line1)
                        splitLines[iline1] =  splitj
                    }
                    splitj!.add(SplitSegment(index: j, loc: ipoint.loc))
                }
            }
        }
    }
}
