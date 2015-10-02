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

class CardTableViewCell: UITableViewCell,  MFMailComposeViewControllerDelegate {
    @IBOutlet var mainView: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var myImageView: UIImageView!

    var detailedImageProxy : DetailedImageProxy?
    var faciesCatalog: FaciesCatalog?
    var controller: LoadingViewController?
    
    func useImage(detailedImage : DetailedImageProxy) {
        self.detailedImageProxy = detailedImage
        
        // Round those corners
        mainView.layer.cornerRadius = 10;
        mainView.layer.masksToBounds = true;
        
        //fill in the data
        nameLabel.text = detailedImage.name
        let detailedImage = detailedImageProxy?.getObject()
        if( detailedImage != nil ) {
            let image = UIImage(data: detailedImage!.imageData)
            if( image != nil ) {
               myImageView.image = resizeImage(
                  image!, newSize: CGSize(width: image!.size.width/8, height: image!.size.height/8)
               )
            }
            
        }
        //myImageView.initFrame()
        //myImageView.initFromObject(detailedImage, catalog: faciesCatalog!)
        
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
        
        let newImageRef = CGBitmapContextCreateImage(context)
        let newImage = UIImage(CGImage: newImageRef!, scale: 1.0, orientation: UIImageOrientation.Right)
        
        // Get the resized image from the context and a UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }

    
    @IBAction func sendMail(sender: AnyObject) {
        //var format = 1
        var filename: NSURL
        var formatUserName : String
        let detailedImage = detailedImageProxy?.getObject()
        if( detailedImage == nil ) {
            return
        }
        
        /*if( format == 0 ) {
            var exporter = ExportAsShapeFile(detailedImage: detailedImage!, faciesCatalog: faciesCatalog)
            filename = exporter.export()
            formatUserName = "Shape"
        } else {*/
            let exporter = ExportAsGocadFile(detailedImage: detailedImage!, faciesCatalog: faciesCatalog)
            filename = exporter.export()
            formatUserName = "Gocad"
        //}
        
        var fileData = NSData()
        do {
            try fileData = NSData(contentsOfFile: filename.path!, options: NSDataReadingOptions.DataReadingMappedIfSafe)
        } catch {
            print("Could not read data to send")
            return
        }

        let mailComposer = MFMailComposeViewController()
        mailComposer.setSubject("Sending " + formatUserName + " file for Outcrop " + detailedImage!.name)
        
        /*if( format == 0 ) {
            mailComposer.addAttachmentData(
                fileData, mimeType: "application/shp", fileName: detailedImage!.name + ".shp"
            )
        } else {*/
            mailComposer.addAttachmentData(
                fileData, mimeType: "text/plain", fileName: detailedImage!.name + "_gocad.txt"
            )
        //}
        mailComposer.addAttachmentData(
            detailedImage!.imageData, mimeType: "impage/jpeg", fileName: detailedImage!.name + ".jpg"
        )
        
        mailComposer.setToRecipients([String]())
        mailComposer.mailComposeDelegate = self
        
        controller!.presentViewController(mailComposer, animated: true, completion: nil)
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        print(result)
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}