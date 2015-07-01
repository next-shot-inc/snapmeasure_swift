//
//  CardTableViewCell.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 6/5/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import UIKit
import QuartzCore

class CardTableViewCell: UITableViewCell {
    @IBOutlet var mainView: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var myImageView: DrawingView!
    var detailedImage : DetailedImageObject?
    var faciesCatalog: FaciesCatalog?
    
    func useImage(detailedImage : DetailedImageObject) {
        self.detailedImage = detailedImage
        
        // Round those corners
        mainView.layer.cornerRadius = 10;
        mainView.layer.masksToBounds = true;
        
        //fill in the data
        nameLabel.text = detailedImage.name
        myImageView.image = UIImage(data: detailedImage.imageData)
        myImageView.initFrame()
        myImageView.initFromObject(detailedImage, catalog: faciesCatalog!)
    }
}