//
//  export.swift
//  SnapMeasure
//
//  Created by next-shot on 6/19/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class ExportAsShapeFile {
    let object : DetailedImageObject
    let mapview : MKMapView
    init(object: DetailedImageObject, view: MKMapView) {
        self.object = object
        self.mapview = view
    }
    
    func export(url: NSURL) {
        var filePath = url.path?.fileSystemRepresentation()
        var fd = open(filePath!, O_CREAT | O_TRUNC | O_WRONLY);
        // Byte 0 File Code 9994 Integer Big
        var file_code : UInt32 = CFSwapInt32HostToBig(9994)
        write(fd, &file_code, sizeof(CInt))
        // Byte 4 Unused 0 Integer Big
        var zero : CInt = 0 ;
        // Byte 8 Unused 0 Integer Big
        write(fd, &zero, sizeof(CInt))
        // Byte 12 Unused 0 Integer Big
        write(fd, &zero, sizeof(CInt))
        // Byte 16 Unused 0 Integer Big
        write(fd, &zero, sizeof(CInt))
        // Byte 20 Unused 0 Integer Big
        write(fd, &zero, sizeof(CInt))
        
        // Byte 24 File Length File Length Integer Big
        var file_length = computeFileLength()
        var file_length_s = CFSwapInt32HostToBig(file_length)
        write(fd, &file_length_s, sizeof(CInt))
        
        // Byte 28 Version 1000 Integer Little
        var file_version : UInt32 = CFSwapInt32HostToLittle(1000)
        write(fd, &file_version, sizeof(CInt))
        
        // Byte 32 Shape Type Shape Type Integer Little (PolylineZ=13)
        var shape_type : UInt32 = CFSwapInt32HostToLittle(13)
        write(fd, &shape_type, sizeof(CInt))
        
        // Byte 36 Bounding Box Xmin Double Little
        // Byte 44 Bounding Box Ymin Double Little
        // Byte 52 Bounding Box Xmax Double Little
        // Byte 60 Bounding Box Ymax Double Little
        // Byte 68* Bounding Box Zmin Double Little
        // Byte 76* Bounding Box Zmax Double Little
        // Byte 84* Bounding Box Mmin Double Little
        // Byte 92* Bounding Box Mmax Double Little
        
        
        close(fd)
    }
    
    func computeFileLength() -> UInt32 {
        var length = 100 ; // Bit size of the header
        
        // PolylineZ shape
        for alo in object.lines {
            length += sizeof(Int32)*2 // Record header
            length += sizeof(Int32) // Shape Type
            length += sizeof(Double)*4 // BBox
            length += sizeof(Int32) // Number of parts (1)
            length += sizeof(Int32) // Total Number of points
            length += sizeof(Int32) * 1 // Index to First Point in Part
            
            let lo = alo as? LineObject
            let arrayData = lo!.pointData
            let len = arrayData.length/sizeof(CGPoint)
            length += sizeof(Double)*2*len // Points
            
            length += sizeof(Double)*2 // Bounding Z Range
            length += sizeof(Double)*len // Z Values for All Points
        }
        
        // Return the length in word-16 byte size
        return UInt32(length*8/16) ;
    }
    
    func computeBBox(lo: LineObject) -> CGRect {
        let arrayData = lo.pointData
        let array = Array(
            UnsafeBufferPointer(
                start: UnsafePointer<CGPoint>(arrayData.bytes),
                count: arrayData.length/sizeof(CGPoint)
            )
        )
        var minx : CGFloat = 1000000
        var miny : CGFloat = 1000000
        var maxx : CGFloat = -1000000
        var maxy : CGFloat = -1000000
        for( var i=0; i < array.count; i++ ) {
            minx = min(array[i].x, minx)
            miny = min(array[i].y, miny)
            maxx = max(array[i].x, maxx)
            maxy = max(array[i].y, maxy)
        }

        return CGRect(origin: CGPoint(x: minx,y: miny), width: (maxx-minx), height: (maxy-miny))
    }
    
    func computeBBox() -> CGRect {
        var rect = CGRect()
        for alo in object.lines {
            rect = rect.rectByUnion(computeBBox(alo as! LineObject))
        }
        return rect
    }
    
    //PolyLineZ
    //{
    //  Double[4] Box // Bounding Box
    //  Integer NumParts // Number of Parts
    //  Integer NumPoints // Total Number of Points
    //  Integer[NumParts] Parts // Index to First Point in Part
    //  Point[NumPoints] Points // Points for All Parts
    //   Double[2] Z Range // Bounding Z Range
    //   Double[NumPoints] Z Array // Z Values for All Points
    //}
    func writePolylineZ() {
        
    }
}
