//
//  ViewController.swift
//  SnapMeasure
//
//  Created by next-shot on 5/21/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import UIKit
import CoreData


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let picker = UIImagePickerController()
    var image :  UIImage?
    var imageInfo = ImageInfo()
    
    @IBOutlet weak var selectExistingButton: UIButton!
    @IBOutlet weak var loadPicture: UIButton!
    @IBOutlet weak var newPicture: UIButton!
    @IBOutlet weak var showHistogram: UIButton!
    @IBOutlet weak var showMap: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        picker.delegate = self
        
        // Test if there are existing DetailedImageObject
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName:"DetailedImageObject")
        var error: NSError?
        let fetchedResultsCount = managedContext.countForFetchRequest(fetchRequest,
            error: &error)
        selectExistingButton.enabled = fetchedResultsCount > 0
        
        // Initialize button look
        let radius : CGFloat = 10.0
        let bgColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
        //UIButton.appearance().layer.cornerRadius = radius
        //UIButton.appearance().backgroundColor = bgColor
        
        selectExistingButton.layer.cornerRadius = radius
        selectExistingButton.backgroundColor = bgColor
        loadPicture.layer.cornerRadius = radius
        loadPicture.backgroundColor = bgColor
        newPicture.layer.cornerRadius = radius
        newPicture.backgroundColor = bgColor
        showHistogram.layer.cornerRadius = radius
        showHistogram.backgroundColor = bgColor
        showMap.layer.cornerRadius = radius
        showMap.backgroundColor = bgColor

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imagePickerController(
        picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]
    ) {
        var chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        image = chosenImage
        imageInfo.xDimension = Int(image!.size.width)
        imageInfo.yDimension = Int(image!.size.height)
        let cimage = image!.CIImage
        if( cimage != nil ) {
            cimage?.properties()
        }
        dismissViewControllerAnimated(true, completion: nil)
        
        self.performSegueWithIdentifier("toDrawingView", sender: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func selectPhotoFromLibrary(sender: AnyObject) {
        picker.allowsEditing = false
        picker.sourceType = .PhotoLibrary
        presentViewController(picker, animated: true, completion: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if( segue.identifier == "toDrawingView" ) {
            let destinationVC = segue.destinationViewController as? DrawingViewController
            if( destinationVC != nil ) {
                destinationVC!.image = image
                destinationVC!.imageInfo = imageInfo
            }
        }
    }
    
    @IBAction func selectFromExisting(sender: AnyObject) {
        //self.performSegueWithIdentifier("toSelectExisting", sender: nil)
    }
       
    @IBAction func unwindToMainMenu (segue: UIStoryboardSegue) {
    
    }
    
    /** This is now done in DrawingViewController
    @IBAction func saveButtonPushed(sender: AnyObject) {
        // Copy lines and image to DetailedImageObject and LineObjects and save

        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext!
        let detailedImage = NSEntityDescription.insertNewObjectForEntityForName("DetailedImageObject",
            inManagedObjectContext: managedContext) as? DetailedImageObject
        
        detailedImage!.name = outcropName.text!
        detailedImage!.imageData = UIImageJPEGRepresentation(image, 1.0)
        
        let linesSet = NSMutableSet()
        
        for line in lines  {
            let lineObject = NSEntityDescription.insertNewObjectForEntityForName("LineObject",
                inManagedObjectContext: managedContext) as? LineObject
            
            lineObject!.name = line.name
            lineObject!.colorData = NSKeyedArchiver.archivedDataWithRootObject(
                UIColor(CGColor: line.color)!
            )
            
            var points : [CGPoint] = Array<CGPoint>(count: line.points.count, repeatedValue: CGPoint(x: 0, y:0))
            for( var i=0; i < line.points.count; ++i ) {
                points[i].x = line.points[i].x
                points[i].y = line.points[i].y
            }
            lineObject!.pointData = NSData(bytes: points, length: points.count * sizeof(CGPoint))
            lineObject!.image = detailedImage!
            linesSet.addObject(lineObject!)
        }
        
        detailedImage!.lines = linesSet
    
        var error: NSError?
        if !managedContext.save(&error) {
           println("Could not save \(error), \(error?.userInfo)")
        }
    
     } **/

}

