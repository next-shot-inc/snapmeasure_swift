//
//  CardTableViewCell.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 6/5/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import UIKit
import QuartzCore
import MessageUI

class CardTableViewCell: UITableViewCell {
    @IBOutlet var mainView: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var myImageView: UIImageView!

    var detailedImageProxy : DetailedImageProxy?
    //var faciesCatalog: FaciesCatalog?
    var controller: LoadingViewController?
    
    deinit {
        myImageView.image = nil
    }
    
    func useImage(detailedImage : DetailedImageProxy) {
        self.detailedImageProxy = detailedImage
        
        // Round those corners
        mainView.layer.cornerRadius = 10;
        mainView.layer.masksToBounds = true;
        
        //fill in the data
        nameLabel.text = detailedImage.name
        let detailedImage = detailedImageProxy?.getObject()
        if( detailedImage != nil ) {
            myImageView.image = detailedImage!.smallImage()
        }
        //myImageView.initFrame()
        //myImageView.initFromObject(detailedImage, catalog: faciesCatalog!)
        
    }
}