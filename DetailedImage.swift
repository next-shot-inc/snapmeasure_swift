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
        let data = imageData()
        if( data != nil ) {
            return UIImage(data: data!)
        } else {
            return nil
        }
    }
    
    func smallImage() -> UIImage? {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let url = appDelegate.applicationDocumentsDirectory.URLByAppendingPathComponent(
            thumbImageFile
        )
        var data: NSData?
        do {
            data = try NSData(contentsOfURL: url, options: NSDataReadingOptions.DataReadingMappedIfSafe)
        }
        catch {
        }
        if( data != nil ) {
            return UIImage(data: data!)
        } else {
            return nil
        }
    }
    
    func saveImage(image: UIImage) {
        if( !imageFile.isEmpty ) {
            return
        }
        
        // Write large image
        let uid = NSUUID()
        imageFile = uid.UUIDString
        let data = UIImageJPEGRepresentation(image, 1.0)
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
        
        // Create thumbNail version of it - Around 100x100 pixels
        let scalex = image.size.width/128.0
        let scaley = image.size.height/128.0
        let scale = min(scalex, scaley)
        let small_image = resizeImage(
            image, newSize: CGSize(width: ceil(image.size.width/scale), height: ceil(image.size.height/scale))
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
    
    func resizeImage(image: UIImage, newSize: CGSize) -> (UIImage) {
        let newRect = CGRectIntegral(CGRectMake(0,0, newSize.width, newSize.height))
        let imageRef = image.CGImage
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        // Set the quality level to use when rescaling
        CGContextSetInterpolationQuality(context, CGInterpolationQuality.High)
        let flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height)
        
        CGContextConcatCTM(context, flipVertical)
        // Draw into the context; this scales the image
        CGContextDrawImage(context, newRect, imageRef)
        
        //let newImageRef = CGBitmapContextCreateImage(context)
        let newImage = UIGraphicsGetImageFromCurrentImageContext().fixOrientation()
        
        // Get the resized image from the context and a UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }

}
