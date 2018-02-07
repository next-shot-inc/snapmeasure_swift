//
//  DetailedImage.swift
//  SnapMeasure
//
//  Created by next-shot on 6/3/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import CoreLocation

class DetailedImageObject: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var imageFile: String
    @NSManaged var thumbImageFile: String
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var altitude: NSNumber?
    @NSManaged var compassOrientation: NSNumber?
    @NSManaged var lines: NSSet
    @NSManaged var features: NSSet
    @NSManaged var date: Date
    @NSManaged var scale: NSNumber? // in meters per point
    @NSManaged var faciesVignettes: NSSet
    @NSManaged var texts : NSSet
    @NSManaged var dipMeterPoints: NSSet
    @NSManaged var project : ProjectObject
    @NSManaged var imageWidth : NSNumber?
    @NSManaged var imageHeight : NSNumber?

    
    var coordinate : CLLocationCoordinate2D? {
        if self.latitude != nil && self.longitude != nil {
            return CLLocationCoordinate2D(latitude: self.latitude!.doubleValue, longitude: self.longitude!.doubleValue)
        } else {
            return nil
        }
    }
    
    func setCoordinate(_ latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.latitude = NSNumber(value: latitude as Double)
        self.longitude = NSNumber(value: longitude as Double)
    }
    
    func removeImage() {
        let df = FileManager.default
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let url = appDelegate.applicationSupportDirectory.appendingPathComponent(
            imageFile
        )
        if( df.fileExists(atPath: url.path) ) {
            do {
                try df.removeItem(atPath: url.path)
            } catch {
                
            }
        }
        
        let tileSize = CGSize(width: 1024,height: 1024)
        let lastCol = Int(floor(CGFloat(imageWidth!.intValue-1) / tileSize.width))
        let lastRow = Int(floor(CGFloat(imageHeight!.intValue-1) / tileSize.height))
        for  row  in  0 ... lastRow {
            for col in  0 ... lastCol {
                let tileName = NSString(format: "%@_%d_%d", imageFile, col, row)
                let tileUrl = appDelegate.applicationSupportDirectory.appendingPathComponent(
                    tileName as String
                )
                if( df.fileExists(atPath: tileUrl.path) ) {
                    do {
                        try df.removeItem(atPath: tileUrl.path)
                    } catch {
                        
                    }
                }
            }
        }

        
        let small_url = appDelegate.applicationSupportDirectory.appendingPathComponent(
            thumbImageFile
        )
        if( df.fileExists(atPath: small_url.path) ) {
            do {
                try df.removeItem(atPath: small_url.path)
            } catch {
                
            }
        }
    }
    
    func imageData() -> Data? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let url = appDelegate.applicationSupportDirectory.appendingPathComponent(
            imageFile
        )
        do {
            return try Data(contentsOf: url, options: NSData.ReadingOptions.mappedIfSafe)
        } catch {
            return nil
        }
    }
    
    func image() -> UIImage? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let url = appDelegate.applicationSupportDirectory.appendingPathComponent(
            imageFile
        )
        return UIImage(contentsOfFile: url.path)
    }
    
    func smallImage() -> UIImage? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let url = appDelegate.applicationSupportDirectory.appendingPathComponent(
            thumbImageFile
        )
        return UIImage(contentsOfFile: url.path)
    }
    
    func saveImage(_ image: UIImage) {
        if( !imageFile.isEmpty ) {
            return
        }
        imageWidth = image.size.width as NSNumber?
        imageHeight = image.size.height as NSNumber?
        
        // Write large image
        let uid = UUID()
        imageFile = uid.uuidString
        
        let rawImage = normalizedImage(image)
        let data = UIImageJPEGRepresentation(rawImage, 1.0)
        if( data == nil ) {
            print("Could not generate JPEG representation of image")
            return
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let url = appDelegate.applicationSupportDirectory.appendingPathComponent(
            imageFile
        )
        if( ((try? data!.write(to: url, options: [.atomic])) != nil) == false ) {
            print("Could not save image file")
        }
        
        // Create tiled images (1024x1024)
        let tileSize = CGSize(width: 1024,height: 1024)
        let lastCol = Int(floor((image.size.width-1) / tileSize.width))
        let lastRow = Int(floor((image.size.height-1) / tileSize.height))
        for row in  0 ... lastRow {
            for col in  0 ... lastCol {
                let imageArea = CGRect(
                    x: CGFloat(col*1024), y: CGFloat(row*1024),
                    width: min(CGFloat(col+1)*1024-1,image.size.width-1) - CGFloat(col*1024),
                    height: min(CGFloat(row+1)*1024-1,image.size.height-1) - CGFloat(row*1024)
                )
                let subImage = rawImage.cgImage?.cropping(to: imageArea)
                if( subImage != nil ) {
                    let tileData = UIImageJPEGRepresentation(UIImage(cgImage: subImage!), 1.0)
                    let tileName = NSString(format: "%@_%d_%d", imageFile, col, row)
                    let tileUrl = appDelegate.applicationSupportDirectory.appendingPathComponent(
                        tileName as String
                    )
                    if( ((try? tileData!.write(to: tileUrl, options: [.atomic])) != nil) == false ) {
                        print("Could not save image file")
                    }
                }
            }
        }

        
        // Create thumbNail version of it - Around 100x100 pixels
        let scalex = image.size.width/128.0
        let scaley = image.size.height/128.0
        let scale = min(scalex, scaley)
        let small_image = DetailedImageObject.resizeImage(
            rawImage, newSize: CGSize(width: ceil(image.size.width/scale), height: ceil(image.size.height/scale))
        )
        let small_uid = UUID()
        thumbImageFile = small_uid.uuidString
        let small_data = UIImageJPEGRepresentation(small_image, 1.0)
        if( small_data == nil ) {
            print("Could not generate JPEG representation of small image")
            return
        }
        
        let small_url = appDelegate.applicationSupportDirectory.appendingPathComponent(
            thumbImageFile
        )
        if( ((try? small_data!.write(to: small_url, options: [.atomic])) != nil) == false ) {
            print("Could not save thumb image file")
        }
    }
    
    class func resizeImage(_ image: UIImage, newSize: CGSize) -> (UIImage) {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        let context = UIGraphicsGetCurrentContext()
        
        // Set the quality level to use when rescaling
        context!.interpolationQuality = CGInterpolationQuality.high
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // Get the resized image from the context and a UIImage
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func normalizedImage(_ image : UIImage) -> UIImage {
        if (image.imageOrientation == UIImageOrientation.up) {
            return image;
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0);
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return normalizedImage!
    }

}
