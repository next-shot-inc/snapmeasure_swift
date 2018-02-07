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
    @IBOutlet weak var nbInterpretations: UILabel!
    
    var detailedImageProxy : DetailedImageProxy?
    
    deinit {
        myImageView.image = nil
    }
    
    func useImage(_ detailedImage : DetailedImageProxy) {
        self.detailedImageProxy = detailedImage
        
        // Round those corners
        mainView.layer.cornerRadius = 10;
        mainView.layer.masksToBounds = true;
        
        //fill in the data
        nameLabel.text = detailedImage.name
        let detailedImageObject = detailedImageProxy?.getObject()
        if( detailedImageObject != nil ) {
            myImageView.image = detailedImageObject!.smallImage()
        }
        
        nbInterpretations.text = "\(detailedImage.nb_interps) Interpretations"
    }
    
    func cleanImage() {
        myImageView.image = nil
    }
}
