//
//  ViewController.swift
//  SnapMeasure
//
//  Created by next-shot on 5/21/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import UIKit
import CoreData

class ExistingPickerController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    var existing = [String]()
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return existing.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return existing[row]
    }
}


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let picker = UIImagePickerController()
    var image :  UIImage?
    var imageInfo = ImageInfo()
    var lines = [Line]()
    var existingPicker = ExistingPickerController()

    @IBOutlet weak var existingPickerView: UIPickerView!
    
    @IBOutlet weak var selectExistingButton: UIButton!
    @IBOutlet weak var loadPicture: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        picker.delegate = self
        
        existingPickerView.delegate = existingPicker
        existingPickerView.dataSource = existingPicker
        
        // List all existing outcrops
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName:"DetailedImageObject")
        
        var error: NSError?
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest,
            error: &error) as? [NSManagedObject]
        
        if let results = fetchedResults {
            for r in results {
                let di = r as! DetailedImageObject
                existingPicker.existing.append(di.name)
            }
        } else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }

        if( existingPicker.existing.count == 0 ) {
            selectExistingButton.enabled = false
        }
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
        
        //self.performSegueWithIdentifier("toDrawingView", sender: nil)
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
                destinationVC!.lines = lines
                destinationVC!.imageInfo = imageInfo
            }
        }
    }
    
    @IBAction func selectFromExisting(sender: AnyObject) {
        existingPickerView.hidden = !existingPickerView.hidden
        
        if( existingPickerView.hidden == true ) {
            let row = existingPickerView.selectedRowInComponent(0)
            if( row < 0 || row > existingPicker.existing.count ) {
                return
            }
            let name = existingPicker.existing[row]
            if( read(name) ) {
               self.performSegueWithIdentifier("toDrawingView", sender: nil)
            }
        }
    }
    
    func read(name: String) -> Bool {
        // Get the full detailed object from the selected name
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName:"DetailedImageObject")
        // TODO: Add Predicate to speed-up the request.
        
        var error: NSError?
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest,
            error: &error) as? [NSManagedObject]
        
        if let results = fetchedResults {
            for r in results {
                let di = r as! DetailedImageObject
                if( di.name == name ) {
                    // Get the image
                    self.image = UIImage(data: di.imageData)!
                    
                    // Get the lines via the DetailedView NSSet.
                    for alo in di.lines {
                        let lo = alo as? LineObject
                        var line = Line()
                        line.name = lo!.name
                        let color = NSKeyedUnarchiver.unarchiveObjectWithData(lo!.colorData) as? UIColor
                        line.color = color?.CGColor
                        let arrayData = lo!.pointData
                        let array = Array(
                            UnsafeBufferPointer(
                                start: UnsafePointer<CGPoint>(arrayData.bytes),
                                count: arrayData.length/sizeof(CGPoint)
                            )
                        )
                        for( var i=0; i < array.count; i++ ) {
                            line.points.append(array[i])
                        }
                        self.lines.append(line)
                    }
                    return true
                }
            }
        } else {
            println("Could not fetch \(error), \(error!.userInfo)")
            return false
        }
        return false
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

