//
//  FaciesPixmapViewController.swift
//  SnapMeasure
//
//  Created by next-shot on 6/16/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit
import CoreData


class FaciesCatalog {
    let faciesTypes = [
        "sandstone", "shale", "conglomerate", "limestone", "dolomite", "granites"
    ]
    let sedimentationStyles = [
        "planar-bedding", "cross-lamination", "ripple-marked-bedding", "gradded-bedding", "cut-and-fill-bedding"
    ]
    var faciesImages = [FaciesImageObject]()
    
    enum ImageType : Int { case Facies = 0, SedimentationStyle, UserDefined }
    
    func count(type: ImageType) -> Int {
        if( type == ImageType.Facies ) {
            return faciesTypes.count
        } else if( type == ImageType.SedimentationStyle ) {
            return sedimentationStyles.count;
        } else {
          return faciesImages.count
        }
    }
    
    func element(index: (type: ImageType, index: Int)) -> (name: String, image: UIImage) {
        var name : String
        var image: UIImage
        if( index.type == ImageType.Facies ) {
            image = UIImage(named: faciesTypes[index.index])!
            name = faciesTypes[index.index]

        } else if( index.type == ImageType.SedimentationStyle ) {
            image = UIImage(named: sedimentationStyles[index.index])!
            name = sedimentationStyles[index.index]

        } else {
            image = UIImage(data: faciesImages[index.index].imageData)!
            name = faciesImages[index.index].name
        }
        return (name, image)
    }
    
    func name(index: (type: ImageType, index: Int)) -> String {
        if( index.type == ImageType.Facies ) {
             return faciesTypes[index.index]
        } else if( index.type == ImageType.SedimentationStyle ) {
            return sedimentationStyles[index.index]
        } else {
            return faciesImages[index.index].name
        }
    }
    
    func image(name: String) -> (image: UIImage?, tile: Bool) {
        for n in faciesTypes {
            if( n == name ) {
                return (UIImage(named: name), true)
            }
        }
        for n in sedimentationStyles {
            if( n == name ) {
                return (UIImage(named: name), true)
            }
        }
        for fio in faciesImages {
            if( name == fio.name ) {
                return (UIImage(data: fio.imageData), fio.tilePixmap.boolValue)
            }
        }
        return (nil,false)
    }
    
    func imageIndex(name: String) -> (type: ImageType, index:Int) {
        for (i,n) in faciesTypes.enumerate() {
            if( n == name ) {
                return (ImageType.Facies, i)
            }
        }
        for (i,n) in sedimentationStyles.enumerate() {
            if( n == name ) {
                return (ImageType.SedimentationStyle, i)
            }
        }
        for (i,fio) in faciesImages.enumerate() {
            if( name == fio.name ) {
                return (ImageType.SedimentationStyle, i)
            }
        }
        return (ImageType.Facies, -1)
    }
    
    func remove(type: ImageType, index: Int) {
        if( type == ImageType.UserDefined ) {
           faciesImages.removeAtIndex(index)
        }
    }
    
    func loadImages() {
        // Get the full detailed object from the selected name
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName:"FaciesImageObject")
        do  {
           let images = try managedContext.executeFetchRequest(fetchRequest)
           self.faciesImages = images as! [FaciesImageObject]
        }  catch {
            
        }
    }
}

class FaciesTypeTablePickerController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    var faciesCatalog : FaciesCatalog?
    var typeButton : UIButton?
    var drawingView: DrawingView?
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return faciesCatalog!.count(FaciesCatalog.ImageType(rawValue: section)!)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PixmapCell", forIndexPath: indexPath)
        let imageInfo = faciesCatalog!.element((FaciesCatalog.ImageType(rawValue: indexPath.section)!, indexPath.row))
        cell.imageView!.image = imageInfo.image
        cell.textLabel!.text = imageInfo.name
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let name = faciesCatalog!.name((FaciesCatalog.ImageType(rawValue: indexPath.section)!, indexPath.row))
        typeButton?.setTitle(name, forState: UIControlState.Normal)
        drawingView?.faciesView.curImageName = name
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = FaciesCatalog.ImageType(rawValue: section)!
        if( section == FaciesCatalog.ImageType.Facies ) {
            return "Facies"
        } else if( section == FaciesCatalog.ImageType.SedimentationStyle ) {
            return "Sedimentation Structure"
        } else {
            return "User Defined"
        }
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        let section = FaciesCatalog.ImageType(rawValue: indexPath.section)!
        if( section != FaciesCatalog.ImageType.UserDefined ) {
            return UITableViewCellEditingStyle.None
        } else {
            return UITableViewCellEditingStyle.Delete
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let row = indexPath.row
        if( editingStyle == UITableViewCellEditingStyle.Delete ) {
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
            faciesCatalog!.remove(FaciesCatalog.ImageType.UserDefined, index: row)
        }
    }
    
}

class FaciesPixmapViewController : UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var tableController = FaciesTypeTablePickerController()
    var picker = UIImagePickerController()
    var typeButton : UIButton?
    var drawingView: DrawingView?
    var faciesCatalog: FaciesCatalog?
    var drawingController : DrawingViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = tableController
        tableView.dataSource = tableController
        tableController.typeButton = typeButton
        tableController.drawingView = drawingView
        tableController.faciesCatalog = faciesCatalog
        
        picker.delegate = self
    }
    
    override func viewDidDisappear(animated: Bool) {
        if( drawingController != nil ) {
            //drawingController!.imageView.center = drawingController!.center
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        if( drawingView != nil && faciesCatalog != nil ) {
            let index = faciesCatalog!.imageIndex(drawingView!.faciesView.curImageName)
            tableView.selectRowAtIndexPath(
                NSIndexPath(
                    forRow: index.index, inSection: index.type.rawValue
                ),
                animated: true, scrollPosition: UITableViewScrollPosition.Middle
            )
        }
    }
    
    @IBAction func AddPixmap(sender: AnyObject) {
        picker.allowsEditing = false
        picker.sourceType = .PhotoLibrary
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(
        picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject]
    ) {
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        dismissViewControllerAnimated(true, completion: nil)
        askImageName(chosenImage)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func askImageName(image: UIImage) {
        var inputTextField : UITextField?
        let alert = UIAlertController(title: "Please give image a name", message: "And choose import method", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Name"
            inputTextField = textField
        }
        let noAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Default) { action -> Void in
        }
        alert.addAction(noAction)
        let yesScaleAction: UIAlertAction = UIAlertAction(title: "Ok & Scale", style: .Default) { action -> Void in
            // scale to 128 pixels.
            let scale = 128.0/max(image.size.width, image.size.height)
            let size = CGSize(width: image.size.width*scale, height: image.size.height*scale)
            let nimage = self.resizeImage(image, newSize: size)
            
            // Create ImageObject
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            
            let detailedImage = NSEntityDescription.insertNewObjectForEntityForName("FaciesImageObject",
                inManagedObjectContext: managedContext) as? FaciesImageObject
            
            detailedImage!.imageData = UIImageJPEGRepresentation(nimage, 1.0)!
            detailedImage!.name = inputTextField!.text!
            detailedImage!.tilePixmap = true
            
            self.tableController.faciesCatalog!.faciesImages.append(detailedImage!)
            self.tableView.reloadData()
        }
        alert.addAction(yesScaleAction)
        
        let yesNoScaleAction: UIAlertAction = UIAlertAction(title: "Ok & Use as is", style: .Default) { action -> Void in
            // Create ImageObject
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            
            let detailedImage = NSEntityDescription.insertNewObjectForEntityForName("FaciesImageObject",
                inManagedObjectContext: managedContext) as? FaciesImageObject
            
            detailedImage!.imageData = UIImageJPEGRepresentation(image, 1.0)!
            detailedImage!.name = inputTextField!.text!
            detailedImage!.tilePixmap = false
            
            self.tableController.faciesCatalog!.faciesImages.append(detailedImage!)
            self.tableView.reloadData()
        }
        alert.addAction(yesNoScaleAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
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
        let newImage = UIImage(CGImage: newImageRef!)
        
        // Get the resized image from the context and a UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
