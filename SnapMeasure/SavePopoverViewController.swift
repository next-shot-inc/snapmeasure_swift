//
//  SavePopoverViewController.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 7/7/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit
import CoreData


class SavePopoverViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, FeatureCellDelegate {
    var drawingVC : DrawingViewController?
    var menuController : PopupMenuController?
    var features : [FeatureObject] = []
    
    @IBOutlet weak var projectNameLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var featureTable: UITableView!
    @IBOutlet weak var warningLabel: UILabel!
    
    override func viewDidLoad() {
        currentProject = drawingVC!.detailedImage!.project
        projectNameLabel.text = currentProject.name
        nameTextField.text = drawingVC!.detailedImage!.name
        
        let drawingView = drawingVC!.imageView as! DrawingView
        //get scale for the image
        let scale = drawingView.getScale()
        if(!scale.defined) {
            warningLabel.hidden = false
            warningLabel.text = "WARNING:\nNo scale defined for this image"
            warningLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
            warningLabel.numberOfLines = 0
        }
        
        for feat in drawingVC!.detailedImage!.features {
            features.append(feat as! FeatureObject)
        }
        
        featureTable.dataSource = self
        featureTable.rowHeight = 51
        featureTable.tableFooterView = UIView(frame: CGRect.zero)
        featureTable.reloadData()
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "keyboardWasShown:", name: UIKeyboardDidShowNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "keyboardWillBeHidden:", name: UIKeyboardDidHideNotification, object: nil)
    }
    
    deinit  {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @IBAction func newProjectButtonPressed(sender: UIButton) {
        menuController = PopupMenuController()
        menuController!.initCellContents(1, cols: 1)
        
        let width : CGFloat = 100
        let height : CGFloat = 45
        
        let textField = UITextField(frame: CGRect(x: 0, y: 0, width: width-10, height: height-10))
        textField.placeholder = "New Project"
        textField.delegate = self
        textField.tag = 1
        textField.becomeFirstResponder()
        
        menuController!.cellContents[0][0] = textField
        
        //set up menu Controller
        menuController!.modalPresentationStyle = UIModalPresentationStyle.Popover
        menuController!.preferredContentSize.width = width
        menuController!.tableView.rowHeight = height
        menuController!.preferredContentSize.height = menuController!.preferredHeight()
        menuController!.popoverPresentationController?.sourceRect = sender.bounds
        menuController!.popoverPresentationController?.sourceView = sender as UIView
        menuController!.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Up //will use a different direction if it can't be to the left
        
        self.presentViewController(menuController!, animated: true, completion: nil)
    }
    
    //Mark: - UITextFieldDelegateMethods
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.tag == 1 { //new project textfeild
            let project = NSEntityDescription.insertNewObjectForEntityForName("ProjectObject",
                inManagedObjectContext: drawingVC!.managedContext!) as! ProjectObject
            if textField.text == "" {
                project.name = "Project " + NSNumberFormatter().stringFromNumber(projects.count+1)!
            } else {
                project.name = textField.text!
            }
            project.date = NSDate()
            currentProject = project
            projects.append(project)
            
            do {
                try drawingVC!.managedContext!.save()
            } catch let error as NSError {
                print(error)
            }
            
            projectNameLabel.text = currentProject.name
            menuController!.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func loadProjectButtonPressed(sender: UIButton) {
        menuController = PopupMenuController()
        menuController!.initCellContents(projects.count, cols: 1)
        
        var labelWidth : CGFloat = 0
        for i in 0..<projects.count {
           let t = projects[i].name as NSString
           let size = t.sizeWithAttributes([NSFontAttributeName: UIFont.systemFontOfSize(UIFont.buttonFontSize())])
           labelWidth = max(labelWidth, size.width)
        }
        
        let width : CGFloat = max(sender.frame.width+40, labelWidth+40)
        let height : CGFloat = 45
        for i in 0..<projects.count {
            let button = UIButton(type: UIButtonType.System)
            button.setTitle(projects[i].name, forState: UIControlState.Normal)
            button.tag = i
            button.frame = CGRect(x: 0, y: 0, width: width, height: height)
            button.addTarget(self, action: "loadProject:", forControlEvents: UIControlEvents.TouchUpInside)
            menuController!.cellContents[i][0] = button
            
        }
        
        //set up menu Controller
        menuController!.modalPresentationStyle = UIModalPresentationStyle.Popover
        menuController!.preferredContentSize.width = width
        menuController!.tableView.rowHeight = height
        menuController!.preferredContentSize.height = menuController!.preferredHeight()
        menuController!.popoverPresentationController?.sourceRect = sender.bounds
        menuController!.popoverPresentationController?.sourceView = sender as UIView
        menuController!.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Up
        
        self.presentViewController(menuController!, animated: true, completion: nil)
    }
    
    func loadProject(sender: UIButton) {
        currentProject = projects[sender.tag]
        projectNameLabel.text = currentProject.name
        menuController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func saveAsNewButtonPressed(sender: AnyObject) {
        let managedContext = drawingVC!.managedContext
        //create a new detailedImageObject in the contect
        let newImage = NSEntityDescription.insertNewObjectForEntityForName("DetailedImageObject",
            inManagedObjectContext: drawingVC!.managedContext) as! DetailedImageObject
        
        let drawingView = drawingVC!.imageView as! DrawingView
        //get scale for the image
        let scale = drawingView.getScale()
        if(scale.defined) {
            newImage.scale = scale.scale
        } else {
            
        }
        
        //update detailedImage and lines
        //detailedImage!.name = outcropName.text!
        newImage.saveImage(drawingVC!.image!)
        newImage.longitude = drawingVC!.imageInfo.longitude
        newImage.latitude = drawingVC!.imageInfo.latitude
        newImage.compassOrientation = drawingVC!.imageInfo.compassOrienation
        newImage.altitude = drawingVC!.imageInfo.altitude
        newImage.date = NSDate()
        newImage.project = currentProject
        newImage.features = drawingVC!.detailedImage!.features.copy() as! NSSet
        if (nameTextField.text != "") {
            newImage.name = nameTextField.text!
        } else {
            newImage.name = "New Image " + String(currentProject.detailedImages.count+1)
        }
        
        // Update project date
        currentProject.date = NSDate()
        
        saveDrawingView(drawingView, image: newImage, managedContext: managedContext)
        
        //save the managedObjectContext
        do {
           try drawingVC!.managedContext.save()
           print("Saved the ManagedObjectContext")
        } catch let error as NSError {
            print("Could not save in DrawingViewController \(error), \(error.userInfo)")
        }

        drawingVC!.hasChanges = false

        self.dismissViewControllerAnimated(true, completion: nil)
        drawingVC!.performSegueWithIdentifier("unwindFromDrawingToMain", sender: drawingVC!)
    }
    
    @IBAction func saveButtonPressed(sender: AnyObject) {
        let managedContext = drawingVC!.managedContext
        //create a new detailedImageObject in the contect
        let currentImage = drawingVC!.detailedImage!
        
        let drawingView = drawingVC!.imageView as! DrawingView
        //get scale for the image
        let scale = drawingView.getScale()
        if(scale.defined) {
            currentImage.scale = scale.scale
        } else {

        }
        
        //update detailedImage and lines
        //detailedImage!.name = outcropName.text!
        currentImage.saveImage(drawingVC!.image!)
        currentImage.project = currentProject
        currentImage.longitude = drawingVC!.imageInfo.longitude
        currentImage.latitude = drawingVC!.imageInfo.latitude
        currentImage.compassOrientation = drawingVC!.imageInfo.compassOrienation
        currentImage.altitude = drawingVC!.imageInfo.altitude
        currentImage.date = drawingVC!.imageInfo.date
        if (nameTextField.text != "") {
            currentImage.name = nameTextField.text!
        } else {
            currentImage.name = "New Image " + String(currentProject.detailedImages.count+1)
        }
        
        // Update project date
        currentProject.date = NSDate()
   
        saveDrawingView(drawingView, image: currentImage, managedContext: managedContext)
        
        //save the managedObjectContext
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save in DrawingViewController \(error), \(error.userInfo)")
        }
        self.dismissViewControllerAnimated(true, completion: nil)
        
        
        drawingVC!.hasChanges = false
        drawingVC!.performSegueWithIdentifier("unwindFromDrawingToMain", sender: drawingVC!)
    }
    
    func saveDrawingView(drawingView: DrawingView, image: DetailedImageObject, managedContext: NSManagedObjectContext) {
        let linesSet = NSMutableSet()
        
        // Always store the coordinates in image coordinates (reverse any viewing transform due to scaling)
        let affineTransform = CGAffineTransformInvert(drawingView.affineTransform)
        for line in drawingView.lineView.lines  {
            let lineObject = NSEntityDescription.insertNewObjectForEntityForName("LineObject",
                inManagedObjectContext: managedContext) as? LineObject
            
            lineObject!.name = line.name
            lineObject!.colorData = NSKeyedArchiver.archivedDataWithRootObject(
                UIColor(CGColor: line.color)
            )
            lineObject!.type = LineViewTool.typeName(line.role)
            
            var points : [CGPoint] = Array<CGPoint>(count: line.points.count, repeatedValue: CGPoint(x: 0, y:0))
            for( var i=0; i < line.points.count; ++i ) {
                points[i] = CGPointApplyAffineTransform(line.points[i], affineTransform)
            }
            lineObject!.pointData = NSData(bytes: points, length: points.count * sizeof(CGPoint))
            lineObject!.image = image
            linesSet.addObject(lineObject!)
            print("Added a line")
        }
        image.lines = linesSet
        
        
        let faciesVignetteSet = NSMutableSet()
        
        for fc in drawingView.faciesView.faciesColumns {
            for fv in fc.faciesVignettes {
                let faciesVignetteObject = NSEntityDescription.insertNewObjectForEntityForName(
                    "FaciesVignetteObject", inManagedObjectContext: managedContext) as? FaciesVignetteObject
                
                faciesVignetteObject!.imageName = fv.imageName
                let scaledRect = CGRectApplyAffineTransform(fv.rect, affineTransform)
                faciesVignetteObject!.rect = NSValue(CGRect: scaledRect)
                faciesVignetteSet.addObject(faciesVignetteObject!)
            }
        }
        image.faciesVignettes = faciesVignetteSet
        
        let textSet = NSMutableSet()
        for tv in drawingView.textView.subviews {
            let label = tv as? UILabel
            if( label != nil ) {
                let textObject = NSEntityDescription.insertNewObjectForEntityForName(
                    "TextObject", inManagedObjectContext: managedContext) as? TextObject
                
                let scaledRect = CGRectApplyAffineTransform(tv.frame, affineTransform)
                textObject!.rect = NSValue(CGRect: scaledRect)
                
                textObject!.string = label!.text!
                
                textSet.addObject(textObject!)
            }
        }
        image.texts = textSet
        
        let dipMeterPoints = NSMutableSet()
        for dmp in drawingView.dipMarkerView.points {
            let dmpo = NSEntityDescription.insertNewObjectForEntityForName(
                "DipMeterPointObject", inManagedObjectContext: managedContext) as? DipMeterPointObject
            var tpoint = dmp.loc
            if( dmp.loc.x != 0 && dmp.loc.y != 0 ) {
                tpoint = CGPointApplyAffineTransform(dmp.loc, affineTransform)
            }
            dmpo!.locationInImage = NSValue(CGPoint: tpoint)
            dmpo!.realLocation = dmp.realLocation
            let sad = dmp.normal.strikeAndDip()
            dmpo!.strike = sad.strike
            dmpo!.dip = sad.dip
            if( dmp.snappedLine != nil ) {
                dmpo!.feature = dmp.snappedLine!.name
            } else {
                dmpo!.feature = "unassigned"
            }
            dipMeterPoints.addObject(dmpo!)
        }
        image.dipMeterPoints = dipMeterPoints
        
    }
    
    //Mark: UITableView Data Source Methods for table of Features
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Features"
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return features.count == 0 ? 1 : features.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if( features.count == 0 ) {
            return tableView.dequeueReusableCellWithIdentifier("NoFeaturesCell", forIndexPath: indexPath)
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("featureCell", forIndexPath: indexPath) as! FeatureCell
            cell.useFeature(features[indexPath.row])
            cell.tag = indexPath.row
            cell.delegate = self
            return cell
        }
    }
    
    //Mark : FeatureCellDelegate Methods
    
    func deleteFeature(cell: FeatureCell) {
        //delete from data store
        drawingVC!.managedContext.deleteObject(cell.feature!)
        
        //delete from table view
        
        features.removeAtIndex(cell.tag)
        let indexPath = featureTable.indexPathForCell(cell)!
        
        featureTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        //featureTable.reloadData()
    }
    
    // Mark : Keyboard management
    var keyboardHeight : CGFloat = 0.0
    
    func keyboardWasShown(notification: NSNotification) {
        let tmp : [NSObject : AnyObject] = notification.userInfo!
        let rectV = tmp[UIKeyboardFrameBeginUserInfoKey]
        let rect = rectV?.CGRectValue
        keyboardHeight = rect!.height
        
        //UIView.animateWithDuration(0.25, animations: { ()-> Void in
            //self.view.center.y -= self.keyboardHeight
        //})
    }
    
    func keyboardWillBeHidden(notification: NSNotification) {
       // UIView.animateWithDuration(0.25, animations: { ()-> Void in
            //self.view.center.y += self.keyboardHeight
        //})
    }

}

protocol FeatureCellDelegate: class {
    func deleteFeature(cell : FeatureCell)
}

class FeatureCell: UITableViewCell {

    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    
    var feature : FeatureObject?
    var delegate : FeatureCellDelegate?
    
    func useFeature(feat : FeatureObject) {
        self.feature = feat
        typeLabel.text = feat.type
        
        let numFormatter = NSNumberFormatter()
        sizeLabel.text = "Height: " + numFormatter.stringFromNumber(feat.height)! + " Width: " + numFormatter.stringFromNumber(feat.width)!
    }
    
    @IBAction func deleteButtonPressed(sender: UIButton) {
        self.delegate?.deleteFeature(self)
    }
    
}