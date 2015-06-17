//
//  FaciesImageObject.swift
//  SnapMeasure
//
//  Created by next-shot on 6/16/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import CoreData

class FaciesImageObject: NSManagedObject {

    @NSManaged var imageData: NSData
    @NSManaged var name: String
    @NSManaged var tilePixmap: NSNumber

}
