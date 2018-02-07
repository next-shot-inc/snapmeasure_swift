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

struct DPoint3 {
    var x : Double
    var y : Double
    var z : Double
}

class Exporter {
    let object : DetailedImageObject
    let faciesCatalog : FaciesCatalog?
    let startMapPoint : MKMapPoint
    let endMapPoint : MKMapPoint
    let elevation : Double
    let pixelToMeterForZ : Double
    let xLength : Double
    let yHeight : Double
    
    // Need detailedImage.scale != nil
    // Need detailedImage.longitude != nil
    
    init(detailedImage: DetailedImageObject, faciesCatalog: FaciesCatalog?) {
        self.object = detailedImage
        self.faciesCatalog = faciesCatalog
        
        let image = detailedImage.image()!
        let length = detailedImage.scale!.doubleValue * Double(image.size.width)
        
        xLength = Double(image.size.width)
        yHeight = Double(image.size.height)
        
        // Compute map points extremities
        if( detailedImage.latitude != nil ) {
            let coordinate = CLLocationCoordinate2D(latitude: detailedImage.latitude!.doubleValue, longitude: detailedImage.longitude!.doubleValue)
            
            let compassOrientation = detailedImage.compassOrientation?.doubleValue
            
            let orientation = compassOrientation! < 0 ?
                2*Double.pi+compassOrientation! * Double.pi/180 : compassOrientation! * Double.pi/180
            
            let scale = MKMetersPerMapPointAtLatitude(coordinate.latitude)
            print(scale)
            
            var centerMapPoint = MKMapPointForCoordinate(coordinate)
            
            // Look at dip meter points to better locate the image
            var minLoc : CGFloat = CGFloat(xLength)
            var maxLoc : CGFloat = 0.0
            var minPoint = MKMapPoint()
            var maxPoint = MKMapPoint()
            for adpo in object.dipMeterPoints  {
                let dpo = adpo as! DipMeterPointObject
                let loc = dpo.locationInImage.cgPointValue
                if( loc?.x != 0 && loc?.y != 0 ) {
                    let rloc = dpo.realLocation as! CLLocation
                    if( rloc.horizontalAccuracy > 0 ) {
                       let mapPoint = MKMapPointForCoordinate(rloc.coordinate)
                        if( (loc?.x)! < minLoc ) {
                            minLoc = (loc?.x)!
                            minPoint = mapPoint
                        }
                        if( (loc?.x)! > maxLoc ) {
                            maxLoc = (loc?.x)!
                            maxPoint = mapPoint
                        }
                    }
                }
            }
            
            if( maxLoc != CGFloat(0.0) ) {
                if( maxLoc != minLoc ) {
                    // If we have two located points on the image
                    // Compute the location of the center of the image
                    let s = Double(CGFloat(xLength)/2 - minLoc)/Double(maxLoc - minLoc)
                    centerMapPoint.x = minPoint.x + s*(maxPoint.x - minPoint.x)
                    centerMapPoint.y = minPoint.y + s*(maxPoint.y - minPoint.y)
                } else {
                    // Compute the distance of the point to the camera position
                    let dx = centerMapPoint.x-minPoint.x
                    let dy = centerMapPoint.y-minPoint.y
                    let d = sqrt(dx*dx + dy*dy)
                    // Move the center by the distance perpendicular to the orientation
                    centerMapPoint.x += d*sin(orientation)
                    centerMapPoint.y -= d*cos(orientation)
                }
            } else {
                // distance to the object
                // object (mm) = focal length (mm) * real height of the object (mm) * image height (pixels) / (
                // object height (pixels) * sensor height (mm))
                let distanceToObject = 3.3 * detailedImage.scale!.doubleValue * 1000
                centerMapPoint.x += distanceToObject*sin(orientation)/scale
                centerMapPoint.y -= distanceToObject*cos(orientation)/scale
            }
            
            let mapLength = length/scale
            
            startMapPoint = MKMapPoint(x: centerMapPoint.x*scale+mapLength*cos(orientation)/2, y: centerMapPoint.y*scale+mapLength*sin(orientation)/2)
            
            endMapPoint = MKMapPoint(x: centerMapPoint.x*scale-mapLength*cos(orientation)/2, y: centerMapPoint.y*scale-mapLength*sin(orientation)/2)
            
        } else {
            startMapPoint = MKMapPoint(x: 0.0, y:0.0)
            endMapPoint = MKMapPoint(x: xLength*detailedImage.scale!.doubleValue, y: 0.0)
        }
        
        // Get elevation and scale to compute Z
        elevation = detailedImage.altitude != nil ? detailedImage.altitude!.doubleValue : 0.0
        
        pixelToMeterForZ = detailedImage.scale!.doubleValue
    }
    
    func zpoint(_ point: CGPoint) -> DPoint3 {
        // Compute (x,y) via its absicca in the picture space mapped into Map-Space
        let x = Double(point.x)/xLength * (endMapPoint.x - startMapPoint.x) + startMapPoint.x
        let y = Double(point.x)/xLength * (endMapPoint.y - startMapPoint.y) + startMapPoint.y
        
        // Need to add camera tilt and distance of camera to outcrop to compute z more accurately.
        let z = (Double(-point.y) + yHeight/2.0) * pixelToMeterForZ + elevation
        return DPoint3(x: x,y: y,z: z)
    }

}

class ExportAsShapeFile : Exporter {
    func export() -> URL {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let url_shp = appDelegate.applicationDocumentsDirectory.appendingPathComponent("export.shp")
        let url_shx = appDelegate.applicationDocumentsDirectory.appendingPathComponent("export.shx")
        export(url_shp, url_shx: url_shx)
        return url_shp
    }
    
    func export(_ url_shp: URL, url_shx: URL) {
        let df = FileManager.default
        if( df.fileExists(atPath: url_shp.path) ) {
            do {
               try df.removeItem(atPath: url_shp.path)
            } catch {
                
            }
        }
        df.createFile(atPath: url_shp.path, contents: nil, attributes: nil)
        
        if( df.fileExists(atPath: url_shx.path) ) {
            do {
               try df.removeItem(atPath: url_shx.path)
            } catch {
                
            }
        }
        df.createFile(atPath: url_shx.path, contents: nil, attributes: nil)

        let filePath = (url_shp as NSURL).fileSystemRepresentation
        let fd = open(filePath, O_WRONLY)
        if( fd < 0 ) {
            _ = errno
            return
        }
        
        let filePathx = (url_shx as NSURL).fileSystemRepresentation
        let fdx = open(filePathx, O_WRONLY)
        if( fdx < 0 ) {
            _ = errno
            return
        }
        
        // Byte 0 File Code 9994 Integer Big
        var file_code : UInt32 = CFSwapInt32HostToBig(9994)
        write(fd, &file_code, MemoryLayout<CInt>.size)
        write(fdx, &file_code, MemoryLayout<CInt>.size)
        // Byte 4 Unused 0 Integer Big
        var zero : CInt = 0 ;
        // Byte 8 Unused 0 Integer Big
        write(fd, &zero, MemoryLayout<CInt>.size)
        write(fdx, &zero, MemoryLayout<CInt>.size)
        // Byte 12 Unused 0 Integer Big
        write(fd, &zero, MemoryLayout<CInt>.size)
        write(fdx, &zero, MemoryLayout<CInt>.size)
        // Byte 16 Unused 0 Integer Big
        write(fd, &zero, MemoryLayout<CInt>.size)
        write(fdx, &zero, MemoryLayout<CInt>.size)
        // Byte 20 Unused 0 Integer Big
        write(fd, &zero, MemoryLayout<CInt>.size)
        write(fdx, &zero, MemoryLayout<CInt>.size)
        
        // Byte 24 File Length File Length Integer Big
        let file_length = computeFileLength()
        var file_length_s = CFSwapInt32HostToBig(file_length)
        write(fd, &file_length_s, MemoryLayout<CInt>.size)
        write(fdx, &file_length_s, MemoryLayout<CInt>.size)
        
        // Byte 28 Version 1000 Integer Little
        var file_version : UInt32 = CFSwapInt32HostToLittle(1000)
        write(fd, &file_version, MemoryLayout<CInt>.size)
        write(fdx, &file_version, MemoryLayout<CInt>.size)
        
        // Byte 32 Shape Type Shape Type Integer Little (PolylineZ=13)
        var shape_type : UInt32 = CFSwapInt32HostToLittle(13)
        write(fd, &shape_type, MemoryLayout<CInt>.size)
        write(fdx, &shape_type, MemoryLayout<CInt>.size)
        
        let rect = computeBBox()
        let bmin = zpoint(rect.origin)
        let bmax = zpoint(CGPoint(x: rect.maxX, y: rect.maxY))
        // Byte 36 Bounding Box Xmin Double Little
        writeDouble(fd, d: bmin.x)
        writeDouble(fdx, d: bmin.x)
        // Byte 44 Bounding Box Ymin Double Little
        writeDouble(fd, d: bmin.y)
        writeDouble(fdx, d: bmin.y)
        // Byte 52 Bounding Box Xmax Double Little
        writeDouble(fd, d: bmax.x)
        writeDouble(fdx, d: bmax.x)
        // Byte 60 Bounding Box Ymax Double Little
        writeDouble(fd, d: bmax.y)
        writeDouble(fdx, d: bmax.y)
        // Byte 68* Bounding Box Zmin Double Little
        writeDouble(fd, d: bmin.z)
        writeDouble(fdx, d: bmin.z)
        // Byte 76* Bounding Box Zmax Double Little
        writeDouble(fd, d: bmax.z)
        writeDouble(fdx, d: bmax.z)
        // Byte 84* Bounding Box Mmin Double Little
        writeDouble(fd, d: 0.0)
        writeDouble(fdx, d: 0.0)
        // Byte 92* Bounding Box Mmax Double Little
        writeDouble(fd, d: 0.0)
        writeDouble(fdx, d: 0.0)
        
        var recordNumber : UInt32 = 1
        var offset : UInt32 = 50
        for alo in object.lines {
            let lo = alo as? LineObject
            
            var recordNumber_s = CFSwapInt32HostToBig(recordNumber)
            write(fd, &recordNumber_s, MemoryLayout<CInt>.size)
            let content_length = computeContentLength(lo!)
            var content_length_s = CFSwapInt32HostToBig(file_length)
            write(fd, &content_length_s, MemoryLayout<CInt>.size)
            
            writePolylineZ(fd, lo: lo!)
            
            var offset_s = CFSwapInt32HostToBig(offset)
            write(fdx, &offset_s, MemoryLayout<CInt>.size)
            write(fdx, &content_length_s, MemoryLayout<CInt>.size)

            recordNumber += 1
            offset += content_length + 4
        }
        
        close(fd)
        close(fdx)
    }
    
    func writeDouble(_ fd: CInt, d: Double) {
        let byteOrder = CFByteOrderGetCurrent()
        if( UInt32(byteOrder) == CFByteOrderLittleEndian.rawValue ) {
            var dd = d
            write(fd, &dd, MemoryLayout<Double>.size)
        } else {
            var swapped = CFConvertDoubleHostToSwapped(d)
            write(fd, &swapped, MemoryLayout<Double>.size)
        }
    }
    
    func computeFileLength() -> UInt32 {
        var length = 100 ; // Bit size of the header
        
        // PolylineZ shape
        for alo in object.lines {
            length += MemoryLayout<Int32>.size*2 // Record header
            length += MemoryLayout<Int32>.size // Shape Type
            length += MemoryLayout<Double>.size*4 // BBox
            length += MemoryLayout<Int32>.size // Number of parts (1)
            length += MemoryLayout<Int32>.size // Total Number of points
            length += MemoryLayout<Int32>.size * 1 // Index to First Point in Part
            
            let lo = alo as? LineObject
            let arrayData = lo!.pointData
            let len = arrayData.count/MemoryLayout<CGPoint>.size
            length += MemoryLayout<Double>.size*2*len // Points
            
            length += MemoryLayout<Double>.size*2 // Bounding Z Range
            length += MemoryLayout<Double>.size*len // Z Values for All Points
        }
        
        // Return the length in word-16 byte size
        return UInt32(length*8/16) ;
    }
    
    func computeContentLength(_ lo: LineObject) -> UInt32 {
        var length = 0
        
        length += MemoryLayout<Int32>.size // Shape Type
        length += MemoryLayout<Double>.size*4 // BBox
        length += MemoryLayout<Int32>.size // Number of parts (1)
        length += MemoryLayout<Int32>.size // Total Number of points
        length += MemoryLayout<Int32>.size * 1 // Index to First Point in Part
        
        let arrayData = lo.pointData
        let len = arrayData.count/MemoryLayout<CGPoint>.size
        length += MemoryLayout<Double>.size*2*len // Points
        
        length += MemoryLayout<Double>.size*2 // Bounding Z Range
        length += MemoryLayout<Double>.size*len // Z Values for All Points

        // Return the length in word-16 byte size
        return UInt32(length*8/16) ;
    }
    
    func computeBBox(_ lo: LineObject) -> CGRect {
        let arrayData = lo.pointData
        let array = Array(
            UnsafeBufferPointer(
                start: (arrayData as NSData).bytes.bindMemory(to: CGPoint.self, capacity: arrayData.count),
                count: arrayData.count/MemoryLayout<CGPoint>.size
            )
        )
        var minx : CGFloat = 1000000
        var miny : CGFloat = 1000000
        var maxx : CGFloat = -1000000
        var maxy : CGFloat = -1000000
        for i in 0 ..< array.count {
            minx = min(array[i].x, minx)
            miny = min(array[i].y, miny)
            maxx = max(array[i].x, maxx)
            maxy = max(array[i].y, maxy)
        }

        return CGRect(x: minx, y: miny, width: (maxx-minx), height: (maxy-miny))
    }
    
    func computeBBox() -> CGRect {
        var rect = CGRect()
        for alo in object.lines {
            rect = rect.union(computeBBox(alo as! LineObject))
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
    func writePolylineZ(_ fd: CInt, lo: LineObject) {
        
        var shape_type : UInt32 = CFSwapInt32HostToLittle(13)
        write(fd, &shape_type, MemoryLayout<CInt>.size)
        
        let rect = computeBBox(lo)
        let bmin = zpoint(rect.origin)
        let bmax = zpoint(CGPoint(x: rect.maxX, y: rect.maxY))
        // Byte 4 Bounding Box Xmin Double Little
        writeDouble(fd, d: bmin.x)
        // Byte 12 Bounding Box Ymin Double Little
        writeDouble(fd, d: bmin.y)
        // Byte 20 Bounding Box Xmax Double Little
        writeDouble(fd, d: bmax.x)
        // Byte 28 Bounding Box Ymax Double Little
        writeDouble(fd, d: bmax.y)

        var numPars : UInt32 = CFSwapInt32HostToLittle(1)
        write(fd, &numPars, MemoryLayout<CInt>.size)
        
        let arrayData = lo.pointData
        let array = Array(
            UnsafeBufferPointer(
                start: (arrayData as NSData).bytes.bindMemory(to: CGPoint.self, capacity: arrayData.count),
                count: arrayData.count/MemoryLayout<CGPoint>.size
            )
        )
        
        var numPoints : UInt32 = CFSwapInt32HostToLittle(UInt32(array.count))
        write(fd, &numPoints, MemoryLayout<CInt>.size)
        
        var indexPart : UInt32 = CFSwapInt32HostToLittle(0)
        write(fd, &indexPart, MemoryLayout<CInt>.size)
        
        // Array of x,y
        for i in 0 ..< array.count {
            let p = zpoint(array[i])
            writeDouble(fd, d: p.x)
            writeDouble(fd, d: p.y)
        }
        
        // Bounding Box Zmin Double Little
        writeDouble(fd, d: bmin.z)
        // Bounding Box ZMaz Double Little
        writeDouble(fd, d: bmax.z)

        // Array of z.
        for i in 0 ..< array.count {
            let p = zpoint(array[i])
            writeDouble(fd, d: p.z)
        }
    }
    
    func export_dbf(_ url: URL) {
        let df = FileManager.default
        if( df.fileExists(atPath: url.path) ) {
            do {
                try df.removeItem(atPath: url.path)
            } catch {
                
            }
        }
        df.createFile(atPath: url.path, contents: nil, attributes: nil)

        let filePath = (url as NSURL).fileSystemRepresentation
        let fd = open(filePath, O_WRONLY)
        if( fd < 0 ) {
            _ = errno
            return
        }
        
        var byte : CChar
        // DBF file type - 0
        byte = 0x03
        write(fd, &byte, MemoryLayout<CChar>.size)
        // Dummy date 1-3
        byte = 95
        write(fd, &byte, MemoryLayout<CChar>.size)
        byte = 7
        write(fd, &byte, MemoryLayout<CChar>.size)
        byte = 26
        write(fd, &byte, MemoryLayout<CChar>.size)
        // Number of records in file 4-7
        var nr : CInt = CInt(object.lines.count)
        write(fd, &nr, MemoryLayout<CInt>.size)
        // Position of first data record 8-9
        var headerLength : Int16 = 33
        // for each field sub-record add 32 bits
        // headerLength += 32 *
        write(fd, &headerLength, MemoryLayout<Int16>.size)
        // Lenght of one data record 10-11
        var nRecordLength : Int16 = 1
        write(fd, &nRecordLength, MemoryLayout<Int16>.size)
        // 12-27 reserved
        lseek(fd, 28*8, SEEK_SET)
        
        close(fd)
    }
}

class ExportAsGocadFile : Exporter {
    func export(prefix: String = "export") -> URL {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let url = appDelegate.applicationDocumentsDirectory.appendingPathComponent(
            "\(prefix)-gocad.txt"
        )
        export(url)
        return url
    }
    
    func export(_ url: URL) {
        let df = FileManager.default
        if( df.fileExists(atPath: url.path) ) {
            do {
               try df.removeItem(atPath: url.path)
            } catch {
                
            }
        }
        df.createFile(atPath: url.path, contents: nil, attributes: nil)
        
        var file : FileHandle?
        do {
            try file = FileHandle(forWritingTo: url)
        } catch {
            return
        }
        
        let space = (" " as NSString).data(using: String.Encoding.utf8.rawValue)
        var data = ("# Geometry of picks and image\n" as NSString).data(using: String.Encoding.utf8.rawValue)
        file?.write(data!)
        if( object.latitude != nil && object.longitude != nil ) {
            data = ("# Coordinate system is epsg:3857. Lat: " as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
            data = ((object.latitude!).stringValue).data(using: String.Encoding.utf8)
            file?.write(data!)
            data = (" Long: " as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
            data = ((object.longitude!).stringValue).data(using: String.Encoding.utf8)
            file?.write(data!)
            data = ("\n" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
        }
        data = ("# GOCAD Project must be setup with Z axis up\n" as NSString).data(using: String.Encoding.utf8.rawValue)
        file?.write(data!)
        
        
        // Write lines
        for alo in object.lines {
            let lo = alo as? LineObject

            data = ("GOCAD PLINE 1.0\n" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
            data = ("HEADER {\n" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
            data = ("name: " + lo!.name as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
            data = ("\n}\nILINE\n" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
            
            let arrayData = lo!.pointData
            let array = Array(
                UnsafeBufferPointer(
                    start: (arrayData as NSData).bytes.bindMemory(to: CGPoint.self, capacity: arrayData.count),
                    count: arrayData.count/MemoryLayout<CGPoint>.size
                )
            )
            for i in 0 ..< array.count {
                let p = zpoint(array[i])
                data = ("VRTX " as NSString).data(using: String.Encoding.utf8.rawValue)
                file?.write(data!)
                data = ((i as NSNumber).stringValue).data(using: String.Encoding.utf8)
                file?.write(data!)
                writePoint(file, p: p)
            }

            data = ("END\n" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
        }
        
        // Write voxet for localizing the image
        data = ("GOCAD VOXET 1.0\n" as NSString).data(using: String.Encoding.utf8.rawValue)
        file?.write(data!)
        data = ("HEADER {\n" as NSString).data(using: String.Encoding.utf8.rawValue)
        file?.write(data!)
        data = ("name: " + object.name as NSString).data(using: String.Encoding.utf8.rawValue)
        file?.write(data!)
        data = ("\n}\nCLASSIFICATION Image Cultural Image\n" as NSString).data(using: String.Encoding.utf8.rawValue)
        file?.write(data!)
        data = ("AXIS_O" as NSString).data(using: String.Encoding.utf8.rawValue)
        file?.write(data!)
        let p0 = zpoint(CGPoint(x: 0,y: 0))
        writePoint(file, p: p0)
        // U is along the vertical axis
        data = ("AXIS_U" as NSString).data(using: String.Encoding.utf8.rawValue)
        file?.write(data!)
        let py = zpoint(CGPoint(x: 0, y: yHeight))
        let du = DPoint3(x: py.x - p0.x, y: py.y - p0.y, z: py.z - p0.z)
        writePoint(file, p: du)
        // V is along the horizontal axis
        data = ("AXIS_V" as NSString).data(using: String.Encoding.utf8.rawValue)
        file?.write(data!)
        let px = zpoint(CGPoint(x: xLength, y: 0))
        let dv = DPoint3(x: px.x - p0.x, y: px.y - p0.y, z: px.z - p0.z)
        writePoint(file, p: dv)
        data = ("AXIS_W" as NSString).data(using: String.Encoding.utf8.rawValue)
        file?.write(data!)
        let dw = DPoint3(x: du.y*dv.z - du.z*dv.y, y: du.z*dv.x - du.x*dv.z, z: du.x*dv.y - du.y*dv.x)
        let dwl = dw.x * dw.x + dw.y * dw.y + dw.z * dw.z
        writePoint(file, p: DPoint3(x: dw.x/dwl, y: dw.y/dwl, z:dw.z/dwl))
        data = ("AXIS_MIN 0 0 0\nAXIS_MAX 1 1 1\nAXIS_N " as NSString).data(using: String.Encoding.utf8.rawValue)
        file?.write(data!)
        data = ((Int(yHeight) as NSNumber).stringValue).data(using: String.Encoding.utf8)
        file?.write(data!)
        file?.write(space!)
        data = ((Int(xLength) as NSNumber).stringValue).data(using: String.Encoding.utf8)
        file?.write(data!)
        data = (" 1\n" as NSString).data(using: String.Encoding.utf8.rawValue)
        file?.write(data!)
        data = ("#GOCAD does not support image properties in ASCII file.\n" +
                "#Use command to Import Image in an existing Voxet.\n" as NSString).data(using: String.Encoding.utf8.rawValue)
        file?.write(data!)
        data = ("END\n" as NSString).data(using: String.Encoding.utf8.rawValue)
        file?.write(data!)
        
        // Write dip meter points (organized by feature)
        var writtenFeature = Set<NSString>()
        for adpo in object.dipMeterPoints  {
            let dpo = adpo as! DipMeterPointObject
            if( writtenFeature.contains(dpo.feature as NSString) ) {
                continue
            }
            writtenFeature.insert(dpo.feature as NSString)

            data = ("GOCAD VSet 1.0\n" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
            data = ("HEADER {\n" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
            data = ("name: " + dpo.feature).data(using: String.Encoding.utf8)
            file?.write(data!)
            // display normal vectors as dip plane
            data = ("\n*vectors3d: true\n*vectors3d*mode: npolygon\n*vectors3d*variable: normal\n}" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
            data = ("\nPROPERTIES normal\nPROPERTY_CLASSES vector3d\nESIZES 3\nSUBVSET\n" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
            
            var vrtx_id = 0
            for iadpo in object.dipMeterPoints  {
                let idpo = iadpo as! DipMeterPointObject
                if( idpo.feature != dpo.feature ) {
                    continue;
                }
                data = ("PVRTX " as NSString).data(using: String.Encoding.utf8.rawValue)
                file?.write(data!)
                data = ((vrtx_id as NSNumber).stringValue).data(using: String.Encoding.utf8)
                vrtx_id += 1
                file?.write(data!)
                file?.write(space!)
                
                // gather information about the point
                let loc = idpo.locationInImage.cgPointValue
                let strike = idpo.strike.doubleValue * .pi/180
                let dip = idpo.dip.doubleValue * .pi / 180
                let normal = Vector3(x: cos(strike)*sin(dip), y: sin(strike)*sin(dip), z: cos(dip))
                var p : DPoint3
                if( loc?.x != 0 && loc?.y != 0 ) {
                    // locate from the picture
                    p = zpoint(loc!)
                } else {
                    // locate using real location
                    let rloc = idpo.realLocation as! CLLocation
                    let centerMapPoint = MKMapPointForCoordinate(rloc.coordinate)
                    p = DPoint3(x: centerMapPoint.x, y: centerMapPoint.y, z: rloc.altitude)
                }
                data = ((p.x as NSNumber).stringValue).data(using: String.Encoding.utf8)
                file?.write(data!)
                file?.write(space!)
                data = ((p.y as NSNumber).stringValue).data(using: String.Encoding.utf8)
                file?.write(data!)
                file?.write(space!)
                data = ((p.z as NSNumber).stringValue).data(using: String.Encoding.utf8)
                file?.write(data!)
                file?.write(space!)
                data = ((normal.y as NSNumber).stringValue).data(using: String.Encoding.utf8)
                file?.write(data!)
                file?.write(space!)
                data = ((normal.x as NSNumber).stringValue).data(using: String.Encoding.utf8)
                file?.write(data!)
                file?.write(space!)
                data = ((normal.z as NSNumber).stringValue).data(using: String.Encoding.utf8)
                file?.write(data!)
                data = ("\n" as NSString).data(using: String.Encoding.utf8.rawValue)
                file?.write(data!)
            }
            data = ("END\n" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
        }
        
        // Write facies columns 
        var columns = [FaciesColumn]()
        // Get the facies vignettes
        for afvo in object.faciesVignettes {
            let fvo = afvo as? FaciesVignetteObject
            let rect = fvo!.rect.cgRectValue
            let fv = FaciesVignette(rect: rect!, image: fvo!.imageName)
            let center = CGPoint(x: ((rect?.minX)!+(rect?.maxX)!)/2.0, y: ((rect?.minY)!+(rect?.maxY)!)/2.0)
            
            var inserted_in_column = false
            for fvc in columns {
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
                columns.append(nfc)
            }
        }
        for col in columns {
            data = ("GOCAD Well 1.0\n" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
            data = ("HEADER {\n" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
            data = ("name: " + object.name).data(using: String.Encoding.utf8)
            file?.write(data!)
            
            // Write first point of path
            let fv0 = col.faciesVignettes[0]
            let top = CGPoint(x: (fv0.rect.minX + fv0.rect.maxX)/2.0, y: fv0.rect.minY)
            let topp = zpoint(top)
            data = ("\n}\nWREF" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
            writePoint(file, p: topp)
            data = ("VRTX" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
            writePoint(file, p: topp)

            // Write last point
            let fv1 = col.faciesVignettes[col.faciesVignettes.count-1]
            let bot = CGPoint(x: top.x, y: fv1.rect.maxY)
            let botp = zpoint(bot)
            data = ("VRTX" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
            writePoint(file, p: botp)
            
            data = ("\nWELL_CURVE\nPROPERTY facies\nINTERPOLATION Block\nBLOCKED_INTERPOLATION_METHOD Below\n" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
            for fv in col.faciesVignettes {
                let ftop = CGPoint(x: top.x, y: fv.rect.minY)
                let ftopp = zpoint(ftop)
                let zm = topp.z - ftopp.z
                data = ("REC " as NSString).data(using: String.Encoding.utf8.rawValue)
                file?.write(data!)
                data = ((zm as NSNumber).stringValue).data(using: String.Encoding.utf8)
                file?.write(data!)
                file?.write(space!)
                var index =  -1
                if( faciesCatalog != nil ) {
                    index = faciesCatalog!.imageIndex(fv.imageName).index
                }
                data = ((index as NSNumber).stringValue).data(using: String.Encoding.utf8)
                file?.write(data!)
                data = ("\n" as NSString).data(using: String.Encoding.utf8.rawValue)
                file?.write(data!)
            }
            data = ("END_CURVE\nEND\n" as NSString).data(using: String.Encoding.utf8.rawValue)
            file?.write(data!)
        }

        
        file?.closeFile()
    }
    
    func writePoint(_ file: FileHandle?, p: DPoint3) {
        let space = (" " as NSString).data(using: String.Encoding.utf8.rawValue)
        file?.write(space!)
        var data = ((p.x as NSNumber).stringValue).data(using: String.Encoding.utf8)
        file?.write(data!)
        file?.write(space!)
        data = ((p.y as NSNumber).stringValue).data(using: String.Encoding.utf8)
        file?.write(data!)
        file?.write(space!)
        data = ((p.z as NSNumber).stringValue).data(using: String.Encoding.utf8)
        file?.write(data!)
        data = ("\n" as NSString).data(using: String.Encoding.utf8.rawValue)
        file?.write(data!)
    }
}
