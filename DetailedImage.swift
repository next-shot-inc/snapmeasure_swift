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
    @NSManaged var date: NSDate
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
    
    func setCoordinate(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.latitude = NSNumber(double: latitude)
        self.longitude = NSNumber(double: longitude)
    }
    
    func removeImage() {
        let df = NSFileManager.defaultManager()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let url = appDelegate.applicationDocumentsDirectory.URLByAppendingPathComponent(
            imageFile
        )
        if( df.fileExistsAtPath(url.path!) ) {
            do {
                try df.removeItemAtPath(url.path!)
            } catch {
                
            }
        }
        
        let tileSize = CGSize(width: 1024,height: 1024)
        let lastCol = Int(floor(CGFloat(imageWidth!.integerValue-1) / tileSize.width))
        let lastRow = Int(floor(CGFloat(imageHeight!.integerValue-1) / tileSize.height))
        for (var row = 0; row <= lastRow; row++) {
            for (var col = 0; col <= lastCol; col++) {
                let tileName = NSString(format: "%@_%d_%d", imageFile, col, row)
                let tileUrl = appDelegate.applicationDocumentsDirectory.URLByAppendingPathComponent(
                    tileName as String
                )
                if( df.fileExistsAtPath(tileUrl.path!) ) {
                    do {
                        try df.removeItemAtPath(tileUrl.path!)
                    } catch {
                        
                    }
                }
            }
        }

        
        let small_url = appDelegate.applicationDocumentsDirectory.URLByAppendingPathComponent(
            thumbImageFile
        )
        if( df.fileExistsAtPath(small_url.path!) ) {
            do {
                try df.removeItemAtPath(small_url.path!)
            } catch {
                
            }
        }
    }
    
    func imageData() -> NSData? {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let url = appDelegate.applicationDocumentsDirectory.URLByAppendingPathComponent(
            imageFile
        )
        do {
            return try NSData(contentsOfURL: url, options: NSDataReadingOptions.DataReadingMappedIfSafe)
        } catch {
            return nil
        }
    }
    
    func image() -> UIImage? {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let url = appDelegate.applicationDocumentsDirectory.URLByAppendingPathComponent(
            imageFile
        )
        if( url.path != nil ) {
            return UIImage(contentsOfFile: url.path!)
        } else {
            return nil
        }
    }
    
    func smallImage() -> UIImage? {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let url = appDelegate.applicationDocumentsDirectory.URLByAppendingPathComponent(
            thumbImageFile
        )
        if( url.path != nil ) {
            return UIImage(contentsOfFile: url.path!)
        } else {
            return nil
        }
    }
    
    func saveImage(image: UIImage) {
        if( !imageFile.isEmpty ) {
            return
        }
        imageWidth = image.size.width
        imageHeight = image.size.height
        
        // Write large image
        let uid = NSUUID()
        imageFile = uid.UUIDString
        
        let rawImage = normalizedImage(image)
        let data = UIImageJPEGRepresentation(rawImage, 1.0)
        if( data == nil ) {
            print("Could not generate JPEG representation of image")
            return
        }
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let url = appDelegate.applicationDocumentsDirectory.URLByAppendingPathComponent(
            imageFile
        )
        if( data!.writeToURL(url, atomically: true) == false ) {
            print("Could not save image file")
        }
        
        // Create tiled images (1024x1024)
        let tileSize = CGSize(width: 1024,height: 1024)
        let lastCol = Int(floor((image.size.width-1) / tileSize.width))
        let lastRow = Int(floor((image.size.height-1) / tileSize.height))
        for (var row = 0; row <= lastRow; row++) {
            for (var col = 0; col <= lastCol; col++) {
                let imageArea = CGRectMake(
                    CGFloat(col*1024), CGFloat(row*1024),
                    min(CGFloat(col+1)*1024-1,image.size.width-1) - CGFloat(col*1024),
                    min(CGFloat(row+1)*1024-1,image.size.height-1) - CGFloat(row*1024)
                )
                let subImage = CGImageCreateWithImageInRect(rawImage.CGImage, imageArea)
                if( subImage != nil ) {
                    let tileData = UIImageJPEGRepresentation(UIImage(CGImage: subImage!), 1.0)
                    let tileName = NSString(format: "%@_%d_%d", imageFile, col, row)
                    let tileUrl = appDelegate.applicationDocumentsDirectory.URLByAppendingPathComponent(
                        tileName as String
                    )
                    if( tileData!.writeToURL(tileUrl, atomically: true) == false ) {
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
        let small_uid = NSUUID()
        thumbImageFile = small_uid.UUIDString
        let small_data = UIImageJPEGRepresentation(small_image, 1.0)
        if( small_data == nil ) {
            print("Could not generate JPEG representation of small image")
            return
        }
        
        let small_url = appDelegate.applicationDocumentsDirectory.URLByAppendingPathComponent(
            thumbImageFile
        )
        if( small_data!.writeToURL(small_url, atomically: true) == false ) {
            print("Could not save thumb image file")
        }
    }
    
    class func resizeImage(image: UIImage, newSize: CGSize) -> (UIImage) {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        let context = UIGraphicsGetCurrentContext()
        
        // Set the quality level to use when rescaling
        CGContextSetInterpolationQuality(context, CGInterpolationQuality.High)
        image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // Get the resized image from the context and a UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func normalizedImage(image : UIImage) -> UIImage {
        if (image.imageOrientation == UIImageOrientation.Up) {
            return image;
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0);
        image.drawInRect(CGRectMake(0, 0, image.size.width, image.size.height))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return normalizedImage
    }

}
