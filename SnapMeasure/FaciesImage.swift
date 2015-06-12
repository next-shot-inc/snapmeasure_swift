//
//  FaciesImage.swift
//  SnapMeasure
//
//  Created by next-shot on 6/10/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import CoreData

class FaciesImage: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var imageData: NSData

}
