//
//  ImageAnnotation.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 6/9/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//
import Foundation
import MapKit
import UIKit

class ImageAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let detailedImage : DetailedImageObject
    let image : UIImage
    let compassOrientation: CLLocationDirection?
    let name : String
    let date : Date
    let length : Double?
    
    /**
    init(name: String, date: NSDate, image: UIImage, coordinate: CLLocationCoordinate2D, compassOrientation: CLLocationDirection) {
        self.name = name
        self.image = image
        self.coordinate = coordinate
        self.compassOrientation = compassOrientation
        self.date = date
    }
        **/
    init(detailedImage: DetailedImageObject) {
        self.detailedImage = detailedImage
        self.name = detailedImage.name
        self.image = detailedImage.image()!
        self.compassOrientation = detailedImage.compassOrientation?.doubleValue
        self.coordinate = CLLocationCoordinate2D(latitude: detailedImage.latitude!.doubleValue, longitude: detailedImage.longitude!.doubleValue)
        self.date = detailedImage.date as Date
        if (detailedImage.scale != nil) {
            self.length = detailedImage.scale!.doubleValue * Double(image.size.width)
            //println(["Annotation.length = %d", self.length!])
        } else {
            self.length = nil
        }
    }
    
    var title: String? {
        return name
    }
    
    var subtitle: String? {
        return DateFormatter.localizedString(from: date, dateStyle: DateFormatter.Style.medium, timeStyle: DateFormatter.Style.short)
    }
}
