//
//  DrawingViewController.swift
//  SnapMeasure
//
//  Created by next-shot on 5/21/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import CoreData
import UIKit

var possibleFeatureTypes = ["Channel","Lobe","Canyon", "Dune","Bar","Levee"]
let horizonTypes = ["Top", "Unconformity", "Fault"]


class ColorPickerController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    let count = 8
    var colorButton : UIButton?
    var drawingView: DrawingView?
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        let hue = CGFloat(row)/CGFloat(count)
        colorButton!.backgroundColor =
            UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        drawingView?.curColor = colorButton!.backgroundColor?.CGColor
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return count
    }
    
    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 36
    }
    func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 36
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView!) -> UIView {
        var pickerLabel = view as? UILabel
        if pickerLabel == nil {  //if no label there yet
            pickerLabel = UILabel()
            //color the label's background
            let hue = CGFloat(row)/CGFloat(count)
            pickerLabel!.backgroundColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        }
        pickerLabel!.text = " "
        return pickerLabel!
    }
    
    func selectNextColor(pickerView: UIPickerView) -> UIColor {
        var curColor = pickerView.selectedRowInComponent(0)
        curColor++
        if( curColor >= count ) {
            // cycle through
            curColor = 0
        }
        pickerView.selectRow(curColor, inComponent: 0, animated: false)
        let hue = CGFloat(curColor)/CGFloat(count)
        return UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
    }
}

class HorizonTypePickerController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var typeButton : UIButton?
    var drawingView: DrawingView?
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        typeButton?.setTitle(horizonTypes[row], forState: UIControlState.Normal)
        drawingView?.lineView.tool.lineType = horizonTypes[row]
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return horizonTypes.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return horizonTypes[row]
    }
}

class DrawingViewController: UIViewController {
    
    @IBOutlet var twoTapsGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet var oneTapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet weak var colButton: UIButton!
    @IBOutlet weak var toolbarSegmentedControl: UISegmentedControl!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var referenceSizeTextField: UITextField!
    @IBOutlet weak var lineNameTextField: UITextField!
    @IBOutlet weak var colorPickerView: UIPickerView!
    @IBOutlet weak var faciesTypeButton: UIButton!
    @IBOutlet weak var horizonTypePickerView: UIPickerView!
    @IBOutlet weak var newLineButton: UIButton!
    @IBOutlet weak var horizonTypeButton: UIButton!
    
    @IBOutlet weak var addDipMeterPointButton: UIButton!
    @IBOutlet weak var referenceSizeContainerView: UIView!
    @IBOutlet weak var faciesTypeContainerView: UIView!
    @IBOutlet weak var lineContainerView: UIView!
    @IBOutlet weak var emailButton: UIButton!
    @IBOutlet weak var defineFeatureButton : UIButton!
    @IBOutlet weak var setWidthButton : UIButton!
    @IBOutlet weak var setHeightButton : UIButton!
    
    var image : UIImage?
    var imageInfo = ImageInfo()
    var colorPickerCtrler = ColorPickerController()
    var horizonTypePickerCtrler = HorizonTypePickerController()
    static var lineCount = 1

    var faciesCatalog = FaciesCatalog()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var managedContext : NSManagedObjectContext!
    var feature : FeatureObject?
    var detailedImage : DetailedImageObject?
    var newDetailedImage = false
    
    var saveMenuController : PopupMenuController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Let the one tap wait for the double-tap to fail before firing
        oneTapGestureRecognizer.requireGestureRecognizerToFail(twoTapsGestureRecognizer)
        
        // Initialize widgets at the top
        // 1. Text field
        lineNameTextField.keyboardType = UIKeyboardType.Default
        lineNameTextField.placeholder = "Name"
        lineNameTextField.text = "H1"
        
        referenceSizeTextField.keyboardType = UIKeyboardType.DecimalPad
        referenceSizeTextField.placeholder = "Size"
        
        // 2. Color picker
        colorPickerView.delegate = colorPickerCtrler
        colorPickerView.dataSource = colorPickerCtrler
        let color = colorPickerCtrler.selectNextColor(colorPickerView)
        
        // 3. Color button
        colButton.setTitle(" ", forState: UIControlState.Normal)
        colButton.backgroundColor = color
        colorPickerCtrler.colorButton = colButton
        
        //4. Type pickers
        horizonTypePickerView.delegate = horizonTypePickerCtrler
        horizonTypePickerView.dataSource = horizonTypePickerCtrler
        horizonTypePickerCtrler.typeButton = horizonTypeButton
        horizonTypeButton.setTitle("Top", forState: UIControlState.Normal)
        
        referenceSizeContainerView.hidden = true
        faciesTypeContainerView.hidden = true

        //make sure all buttons are in the right state
        self.colButton.enabled = true
        self.newLineButton.enabled = true
        self.toolbarSegmentedControl.enabled = true

        self.defineFeatureButton.enabled = true
        self.defineFeatureButton.hidden = false
        self.setWidthButton.enabled = false
        self.setWidthButton.hidden = true
        self.setHeightButton.enabled = false
        self.setHeightButton.hidden = true

        managedContext = appDelegate.managedObjectContext!
        
        if (detailedImage == nil) {
            detailedImage = NSEntityDescription.insertNewObjectForEntityForName("DetailedImageObject",
                inManagedObjectContext: managedContext) as? DetailedImageObject
            newDetailedImage = true
            detailedImage!.project = currentProject
            //detailedImage!.features = NSSet()
        }
        
        faciesCatalog.loadImages()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        imageView.setNeedsDisplay()
        
        let drawingView = imageView as! DrawingView
        drawingView.image = image
        drawingView.imageInfo = imageInfo
        drawingView.controller = self
        drawingView.initFrame()
        drawingView.initFromObject(detailedImage!, catalog: faciesCatalog)
        
        drawingView.lineView.tool.lineName = lineNameTextField.text
        drawingView.curColor = colButton.backgroundColor?.CGColor
        drawingView.lineView.tool.lineType = horizonTypeButton.titleForState(UIControlState.Normal)!
        
        colorPickerCtrler.drawingView = drawingView
        horizonTypePickerCtrler.drawingView = drawingView
    }
    
    
    @IBAction func toolChanged(sender: AnyObject) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode =
            DrawingView.ToolMode(rawValue: toolbarSegmentedControl.selectedSegmentIndex)!
        
        referenceSizeContainerView.hidden = true
        faciesTypeContainerView.hidden = true
        lineContainerView.hidden = true
        
        if( drawingView.drawMode == DrawingView.ToolMode.Reference ) {
            
            let nf = NSNumberFormatter()
            referenceSizeTextField.text =
                nf.stringFromNumber(drawingView.lineView.refMeasureValue)
            referenceSizeContainerView.hidden = false
            
        } else if( drawingView.drawMode == DrawingView.ToolMode.Draw ) {
            
            lineContainerView.hidden = false
            
        } else if( drawingView.drawMode == DrawingView.ToolMode.Facies ) {
            faciesTypeContainerView.hidden = false
        }
    }
    
    @IBAction func handlePinch(sender: AnyObject) {
        let recognizer = sender as! UIPinchGestureRecognizer
        let scaleFactor = recognizer.scale
        recognizer.view!.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
    }
    
    @IBAction func handlePan(sender: AnyObject) {
        let recognizer = sender as! UIPanGestureRecognizer
        let translation = recognizer.translationInView(self.view)
        recognizer.view!.center = CGPointMake(recognizer.view!.center.x + translation.x,
            recognizer.view!.center.y + translation.y);
        recognizer.setTranslation(CGPoint(x: 0,y: 0), inView: self.view)
    }
    
    @IBAction func handleTap(sender: AnyObject) {
        // Dismiss UI elements (end editing)
        referenceSizeTextField.resignFirstResponder()
        lineNameTextField.resignFirstResponder()
        colorPickerView.hidden = true
        horizonTypePickerView.hidden = true
        
        // Initialize drawing information
        let drawingView = imageView as! DrawingView
        
        if( drawingView.drawMode == DrawingView.ToolMode.Reference ) {
            var nf = NSNumberFormatter()
            var ns = nf.numberFromString(referenceSizeTextField.text)
            if( ns != nil ) {
                drawingView.lineView.refMeasureValue = ns!.floatValue
            }
        } else if( drawingView.drawMode == DrawingView.ToolMode.Draw ) {
            drawingView.lineView.tool.lineName = lineNameTextField.text
                    
        } else if( drawingView.drawMode == DrawingView.ToolMode.Facies ) {
            drawingView.faciesView.curImageName = faciesTypeButton.titleForState(UIControlState.Normal)!
        }
    }
    
    @IBAction func handleDoubleTap(sender: AnyObject) {
        let drawingView = imageView as! DrawingView
        let recognizer = sender as! UITapGestureRecognizer
        let point = recognizer.locationInView(drawingView)
        
        // Find if an object is selected
        let line = drawingView.select(point)
        
        if( line != nil && drawingView.drawMode == DrawingView.ToolMode.Draw ) {
            // Initialize UI with selected object
            lineNameTextField.text = line!.name
            colButton.backgroundColor = UIColor(CGColor: line!.color)
            
            // Initialize drawing information
            drawingView.lineView.tool.lineName = line!.name
            drawingView.curColor = line!.color
            drawingView.lineView.tool.lineType = LineViewTool.typeName(line!.role)
            horizonTypeButton.setTitle(drawingView.lineView.tool.lineType, forState: UIControlState.Normal)
        } else {
            self.imageView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
            self.imageView.transform = CGAffineTransformIdentity;
        }
    }
    
    func askText(label: UILabel) {
        var inputTextField : UITextField?
        let alert = UIAlertController(title: "", message: "Please specify text", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Label"
            inputTextField = textField
        }
        let noAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Default) { action -> Void in
        }
        alert.addAction(noAction)
        let yesAction: UIAlertAction = UIAlertAction(title: "Ok", style: .Default) { action -> Void in
            label.text = inputTextField!.text
            let drawingView = self.imageView as! DrawingView
            drawingView.textView.setNeedsDisplay()
        }
        alert.addAction(yesAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func pushColButton(sender: AnyObject) {
        colorPickerView.hidden = !colorPickerView.hidden
        let drawingView = imageView as! DrawingView
        drawingView.curColor = colButton.backgroundColor?.CGColor
    }
    
    @IBAction func pushNewLine(sender: AnyObject) {
        lineNameTextField.text = String("H") +
                                      String(++DrawingViewController.lineCount)
        
        let drawingView = imageView as! DrawingView
        let color = colorPickerCtrler.selectNextColor(colorPickerView)
        
        colButton.backgroundColor = color
        drawingView.lineView.tool.lineName = lineNameTextField.text
        drawingView.lineView.tool.lineType = horizonTypeButton.titleForState(UIControlState.Normal)!
        drawingView.curColor = color.CGColor
    }
    
    @IBAction func pushTypeButton(sender: AnyObject) {
        let drawingView = imageView as! DrawingView
        let ctrler = self.storyboard?.instantiateViewControllerWithIdentifier("FaciesPixmapController") as! FaciesPixmapViewController
        ctrler.typeButton = self.faciesTypeButton
        ctrler.drawingView = drawingView
        ctrler.faciesCatalog = faciesCatalog
        
        ctrler.modalPresentationStyle = UIModalPresentationStyle.Popover
        ctrler.preferredContentSize.width = 150
        ctrler.preferredContentSize.height = 400
        ctrler.popoverPresentationController?.sourceView = sender as! UIView
        ctrler.popoverPresentationController?.sourceRect = sender.bounds
        ctrler.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Any
        
        self.presentViewController(ctrler, animated: true, completion: nil)
    }
    
    @IBAction func closeWindow(sender: AnyObject) {
        var inputTextField : UITextField?
        let alert = UIAlertController(title: "", message: "Save before closing?", preferredStyle: .Alert)
        if( newDetailedImage ) {
            alert.addTextFieldWithConfigurationHandler { (textField) in
                textField.placeholder = "Name"
                inputTextField = textField
            }
        }
        let drawingView = self.imageView as! DrawingView
        //get scale for the image
        let scale = drawingView.getScale()
        if(scale.defined) {
            self.detailedImage!.scale = scale.scale
        } else {
            alert.title = "Save before closing?"
            alert.message = "WARNING: No scale for this image. Draw a reference line to define a scale."
        }
        let noAction: UIAlertAction = UIAlertAction(title: "NO", style: .Default) { action -> Void in
            self.managedContext.rollback()
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alert.addAction(noAction)
        
        let cancelAction : UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            alert.dismissViewControllerAnimated(true, completion: nil)
        }
        alert.addAction(cancelAction)
        
        let yesAction: UIAlertAction = UIAlertAction(title: "YES", style: .Default) { action -> Void in
            
            //update detailedImage and lines
            //detailedImage!.name = outcropName.text!
            self.detailedImage!.imageData = UIImageJPEGRepresentation(self.image, 1.0)
            self.detailedImage!.longitude = self.imageInfo.longitude
            self.detailedImage!.latitude = self.imageInfo.latitude
            self.detailedImage!.compassOrientation = self.imageInfo.compassOrienation
            self.detailedImage!.altitude = self.imageInfo.altitude
            self.detailedImage!.date = self.imageInfo.date
            if (inputTextField != nil) {
                self.detailedImage?.name = inputTextField!.text
            }
            let linesSet = NSMutableSet()
            
            let drawingView = self.imageView as! DrawingView
            // Always store the coordinates in image coordinates (reverse any viewing transform due to scaling)
            let affineTransform = CGAffineTransformInvert(drawingView.affineTransform)
            for line in drawingView.lineView.lines  {
                let lineObject = NSEntityDescription.insertNewObjectForEntityForName("LineObject",
                    inManagedObjectContext: self.managedContext) as? LineObject
                
                lineObject!.name = line.name
                lineObject!.colorData = NSKeyedArchiver.archivedDataWithRootObject(
                    UIColor(CGColor: line.color)!
                )
                lineObject!.type = LineViewTool.typeName(line.role)
                
                var points : [CGPoint] = Array<CGPoint>(count: line.points.count, repeatedValue: CGPoint(x: 0, y:0))
                for( var i=0; i < line.points.count; ++i ) {
                    points[i] = CGPointApplyAffineTransform(line.points[i], affineTransform)
                }
                lineObject!.pointData = NSData(bytes: points, length: points.count * sizeof(CGPoint))
                lineObject!.image = self.detailedImage!
                linesSet.addObject(lineObject!)
                println("Added a line")
            }
            self.detailedImage!.lines = linesSet

            
            let faciesVignetteSet = NSMutableSet()
            
            for fc in drawingView.faciesView.faciesColumns {
                for fv in fc.faciesVignettes {
                    let faciesVignetteObject = NSEntityDescription.insertNewObjectForEntityForName(
                        "FaciesVignetteObject", inManagedObjectContext: self.managedContext) as? FaciesVignetteObject
                    
                    faciesVignetteObject!.imageName = fv.imageName
                    let scaledRect = CGRectApplyAffineTransform(fv.rect, affineTransform)
                    faciesVignetteObject!.rect = NSValue(CGRect: scaledRect)
                    faciesVignetteSet.addObject(faciesVignetteObject!)
                }
            }
            self.detailedImage!.faciesVignettes = faciesVignetteSet
            
            let textSet = NSMutableSet()
            for tv in drawingView.textView.subviews {
                let label = tv as? UILabel
                if( label != nil ) {
                    let textObject = NSEntityDescription.insertNewObjectForEntityForName(
                        "TextObject", inManagedObjectContext: self.managedContext) as? TextObject
                    
                    let scaledRect = CGRectApplyAffineTransform(tv.frame, affineTransform)
                    textObject!.rect = NSValue(CGRect: scaledRect)
                    
                    textObject!.string = label!.text!
                    
                    textSet.addObject(textObject!)
                }
            }
            self.detailedImage!.texts = textSet
            
            let dipMeterPoints = NSMutableSet()
            for dmp in drawingView.dipMarkerView.points {
                let dmpo = NSEntityDescription.insertNewObjectForEntityForName(
                        "DipMeterPointObject", inManagedObjectContext: self.managedContext) as? DipMeterPointObject
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
            self.detailedImage!.dipMeterPoints = dipMeterPoints
            
            //save the managedObjectContext
            var error: NSError?
            if !self.managedContext.save(&error) {
                println("Could not save in DrawingViewController \(error), \(error?.userInfo)")
            }
            println("Saved the ManagedObjectContext")
            self.dismissViewControllerAnimated(true, completion: nil)

            
        }
        alert.addAction(yesAction)
        
        self.presentViewController(alert, animated: true, completion: nil)

        //self.dismissViewControllerAnimated(true, completion: nil)
        /**
        let drawingView = imageView as! DrawingView
        var destinationVC = self.presentingViewController as? ViewController
        if( destinationVC == nil ) {
            destinationVC = self.presentingViewController?.presentingViewController as? ViewController
        }
        if( destinationVC != nil ) {
            destinationVC!.image = image
            destinationVC!.lines = drawingView.lineView.lines
        } **/
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showSavePopover" {
            let savePopover = segue.destinationViewController as! SavePopoverViewController
            savePopover.drawingVC = self
            savePopover.popoverPresentationController!.permittedArrowDirections = nil
        }
    }
    
    @IBAction func pushDefineFeatureButton(sender : AnyObject) {
        //disable all other buttons until Feature definition is complete
        self.toolbarSegmentedControl.enabled = false
        self.addDipMeterPointButton.enabled = false
        
        //create a new Feature
        feature = NSEntityDescription.insertNewObjectForEntityForName("FeatureObject",
            inManagedObjectContext: managedContext) as? FeatureObject
        feature!.image = detailedImage!
        //detailedImage!.features.setByAddingObject(feature!)
        
        let drawingView = imageView as! DrawingView
        if (drawingView.lineView.refMeasureValue.isZero || drawingView.lineView.refMeasureValue.isNaN) {
            let alert = UIAlertController(title: "", message: "Need to establish a reference before defining a Feature", preferredStyle: .Alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in
                //Do some stuff
            }
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
            
            self.toolbarSegmentedControl.selectedSegmentIndex = DrawingView.ToolMode.Reference.rawValue
            drawingView.drawMode = DrawingView.ToolMode.Reference
            let nf = NSNumberFormatter()
            referenceSizeTextField.text = nf.stringFromNumber(drawingView.lineView.refMeasureValue)
            
        } else {
            self.toolbarSegmentedControl.selectedSegmentIndex = DrawingView.ToolMode.Measure.rawValue
            drawingView.drawMode = DrawingView.ToolMode.Measure
            self.defineFeatureButton.hidden = true
            self.setHeightButton.enabled = true
            self.setHeightButton.hidden = false
        }
    }
    
    
    @IBAction func pushSetHeightButton(sender : AnyObject) {
        let drawingView = imageView as! DrawingView
        var height = 0.0 as NSNumber
        if( drawingView.lineView.label.text != nil ) {
            var decode_height = NSNumberFormatter().numberFromString(drawingView.lineView.label.text!)
            height = decode_height == nil ? 0.0 : decode_height!
        }
        if (height.isEqualToNumber(0.0)) {
            let alert = UIAlertController(title: "", message: "Need to add a measurement line to define the Feature's height ", preferredStyle: .Alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: "Ok", style: .Cancel) { action -> Void in
                //Do some stuff
            }
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
            //just in case
            if (drawingView.drawMode != DrawingView.ToolMode.Measure) {
                self.toolbarSegmentedControl.selectedSegmentIndex = DrawingView.ToolMode.Measure.rawValue
                drawingView.drawMode = DrawingView.ToolMode.Measure
            }
        } else {
            //set Feature.height = height
            if feature == nil {
                println("Feature is nil when attempting to set height")
            } else {
                feature!.height = height
            }
            println("height: ", height.floatValue)
            self.setHeightButton.enabled = false
            self.setHeightButton.hidden = true
            self.setWidthButton.enabled = true
            self.setWidthButton.hidden = false
            
            //Remove measurement line to force user to draw a new line to define the width
            drawingView.lineView.measure.removeAll(keepCapacity: true)
            drawingView.lineView.setNeedsDisplay()
        }
    }
    
    @IBAction func pushSetWdithButton(sender : AnyObject) {
        let drawingView = imageView as! DrawingView
        var width = 0.0 as NSNumber
        if( drawingView.lineView.label.text != nil ) {
            let decode_width = NSNumberFormatter().numberFromString(drawingView.lineView.label.text!)
            width = decode_width == nil ? 0.0 : decode_width!
        }
        if (width.isEqualToNumber(0.0)) {
            let alert = UIAlertController(title: "", message: "Need to add a measurement line to define the Feature's width ", preferredStyle: .Alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: "Ok", style: .Cancel) { action -> Void in
                //Do some stuff
            }
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
            //just in case
            if (drawingView.drawMode != DrawingView.ToolMode.Measure) {
                self.toolbarSegmentedControl.selectedSegmentIndex = DrawingView.ToolMode.Measure.rawValue
                drawingView.drawMode = DrawingView.ToolMode.Measure
            }
        } else {
            //set Feature.width = width
            if feature == nil {
                println("Feature is nil when attempting to set type")
            } else {
                feature!.width = width
            }
            println("width: ",width.floatValue)
            self.setWidthButton.enabled = false
            self.setWidthButton.hidden = true
            
            let nf = NSNumberFormatter()
            nf.numberStyle = NSNumberFormatterStyle.DecimalStyle
            let message = "Select a feature type for this feature of width: " +
                nf.stringFromNumber(feature!.width)! + " and height " +
                nf.stringFromNumber(feature!.height)!
            
            let alert = UIAlertController(
                title: "Define Feature type", message: message, preferredStyle: .Alert
            )
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
                self.managedContext.deleteObject(self.feature!)
                let alert2 = UIAlertController(title: "", message: "Feature was deleted", preferredStyle: .Alert)
                let cancelAction: UIAlertAction = UIAlertAction(title: "Ok", style: .Cancel) { action -> Void in
                    //Do some stuff
                }
                alert2.addAction(cancelAction)
                self.presentViewController(alert2, animated: true, completion: nil)
            }
            alert.addAction(cancelAction)
            
            // Add buttons the alert action
            for type in possibleFeatureTypes {
                var nextAction: UIAlertAction = UIAlertAction(title: type, style: .Default) { action -> Void in
                    //save Feature.type as type
                    if self.feature == nil {
                        println("Feature is nil when attempting to set type")
                    } else {
                        self.feature!.type = type
                    }
                }
                alert.addAction(nextAction)
            }
            self.presentViewController(alert, animated: true, completion: nil)
            
            // Manage UI components
            self.defineFeatureButton.enabled = true
            self.defineFeatureButton.hidden = false
            
            //Re-enable all other buttons until Feature definition is complete
            self.toolbarSegmentedControl.enabled = true
            self.addDipMeterPointButton.enabled = true
            
            // Remove measurement line
            drawingView.lineView.measure.removeAll(keepCapacity: true)
            drawingView.lineView.setNeedsDisplay()
        }
    }
    
    @IBAction func unwindToDrawing (segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func doMeasureDipAndStrike(sender: AnyObject) {
        let ctrler = self.storyboard?.instantiateViewControllerWithIdentifier("OrientationController") as! OrientationController
        
        ctrler.modalPresentationStyle = UIModalPresentationStyle.Popover
        ctrler.popoverPresentationController?.sourceView = sender as! UIView
        ctrler.popoverPresentationController?.sourceRect = sender.bounds
        ctrler.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Any
        let size = ctrler.view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        ctrler.preferredContentSize = size
        
        self.presentViewController(ctrler, animated: true, completion: nil)
    }
    
}


