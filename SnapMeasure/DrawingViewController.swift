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

class DrawingViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var twoTapsGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet var oneTapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet weak var colButton: UIButton!
    //@IBOutlet weak var toolbarSegmentedControl: UISegmentedControl!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var referenceSizeTextField: UITextField!
    @IBOutlet weak var lineNameTextField: UITextField!
    @IBOutlet weak var colorPickerView: UIPickerView!
    //@IBOutlet weak var faciesTypeButton: UIButton!
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
    var center = CGPoint()
    
    var saveMenuController : PopupMenuController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Let the one tap wait for the double-tap to fail before firing
        oneTapGestureRecognizer.requireGestureRecognizerToFail(twoTapsGestureRecognizer)
        
        // Initialize widgets at the top
        // 1. Text field
        lineNameTextField.keyboardType = UIKeyboardType.Default
        //lineNameTextField.placeholder = "Name"
        lineNameTextField.text = "H1"
        lineNameTextField.delegate = self
        
        referenceSizeTextField.keyboardType = UIKeyboardType.DecimalPad
        referenceSizeTextField.placeholder = "Size"
        referenceSizeTextField.delegate = self
        
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
        
        faciesTypeButton.setTitle("sandstone", forState: UIControlState.Normal)

        referenceSizeContainerView.hidden = true
        //faciesTypeContainerView.hidden = true

        //make sure all buttons are in the right state
        self.colButton.enabled = true
        self.newLineButton.enabled = true
        //self.toolbarSegmentedControl.enabled = true

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
        drawingView.faciesView.curImageName = faciesTypeButton.titleForState(UIControlState.Normal)!
        
        colorPickerCtrler.drawingView = drawingView
        horizonTypePickerCtrler.drawingView = drawingView
        center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds))
    }
    
    /**
    @IBAction func toolChanged(sender: AnyObject) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode =
            DrawingView.ToolMode(rawValue: toolbarSegmentedControl.selectedSegmentIndex)!
        
        referenceSizeContainerView.hidden = true
        //faciesTypeContainerView.hidden = true
        lineContainerView.hidden = true
        
        if( drawingView.drawMode == DrawingView.ToolMode.Reference ) {
            
            let nf = NSNumberFormatter()
            referenceSizeTextField.text =
                nf.stringFromNumber(drawingView.lineView.refMeasureValue)
            referenceSizeContainerView.hidden = false
            
        } else if( drawingView.drawMode == DrawingView.ToolMode.Draw ) {
            
            lineContainerView.hidden = false
            
        } else if( drawingView.drawMode == DrawingView.ToolMode.Facies ) {
            //faciesTypeContainerView.hidden = false
        }
    } **/
    
    // Mark: Bottom Toolbar methods
    @IBAction func newLineButtonPressed(sender: UIButton) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.Draw
        
        referenceSizeContainerView.hidden = true
        //faciesTypeContainerView.hidden = true
        
        //from storyboard height = 49 and width = 235
        let centerX = sender.frame.origin.x + sender.frame.size.width/2
        let originY = self.view.frameBottom - 100
        let originX = centerX-235/2
        if originX < 0 {
            lineContainerView.frame = CGRect(x: 0, y: originY, width: 235, height: 49)
        } else {
            lineContainerView.frame = CGRect(x: originX, y: originY, width: 235, height: 49)
        }
        
        lineContainerView.hidden = false
    }
    
    @IBAction func eraseButtonPressed(sender: UIButton) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.Erase
        
        referenceSizeContainerView.hidden = true
        //faciesTypeContainerView.hidden = true
        lineContainerView.hidden = true
    }
    
    @IBAction func measureButtonPressed(sender: UIButton) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.Measure
        
        referenceSizeContainerView.hidden = true
        //faciesTypeContainerView.hidden = true
        lineContainerView.hidden = true
    }
    
    @IBAction func drawReferenceButtonPressed(sender: AnyObject) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.Reference
        
        let nf = NSNumberFormatter()
        referenceSizeTextField.text =
            nf.stringFromNumber(drawingView.lineView.refMeasureValue)
        
        //from storyboard height = 49 and width = 186
        let centerX = sender.frame.origin.x + sender.frame.size.width/2
        let originY = self.view.frameBottom - 100
        let originX = centerX-186/2
        if originX < 0 {
            referenceSizeContainerView.frame = CGRect(x: 0, y: originY, width: 186, height: 49)
        } else if originX+186 > self.view.frameRight  {
            referenceSizeContainerView.frame = CGRect(x: self.view.frameRight-186, y: originY, width: 186, height: 49)
        } else{
            referenceSizeContainerView.frame = CGRect(x: originX, y: originY, width: 186, height: 49)
        }
        
        referenceSizeContainerView.hidden = false
        //faciesTypeContainerView.hidden = true
        lineContainerView.hidden = true
    }
    
    @IBAction func faciesButtonPressed(sender: AnyObject) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.Facies
        
        referenceSizeContainerView.hidden = true
        //faciesTypeContainerView.hidden = false
        lineContainerView.hidden = true
    }
    
    @IBAction func textboxButtonPressed(sender: UIButton) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.Text
        
        referenceSizeContainerView.hidden = true
        //faciesTypeContainerView.hidden = true
        lineContainerView.hidden = true
    }
    
    @IBAction func dipMeterButtonPressed(sender: AnyObject) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.DipMarker
        
        referenceSizeContainerView.hidden = true
        //faciesTypeContainerView.hidden = true
        lineContainerView.hidden = true
    }
    
    //Mark: UITextFeildDelegateMethods 
    //This doesn't work ... ????????
    func textFieldDidBeginEditing(textField: UITextField) {
        
        if textField.tag == 1 { //lineNameTextField
            var newFrame = lineContainerView.frame
            newFrame.origin.y -= self.view.frameHeight*2/3
            
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationBeginsFromCurrentState(true)
            
            UIView.setAnimationDuration(NSTimeInterval(0.25))
            
            lineContainerView.frame = newFrame
            
            UIView.commitAnimations()

        } else { //referenceSizeTextFeild tag = 2
            referenceSizeContainerView.frame.origin = CGPoint(x: referenceSizeContainerView.frame.origin.x, y: referenceSizeContainerView.frame.origin.y-self.view.frameHeight*2/3)
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        if textField.tag == 1 { //lineNameTextField
            var newFrame = lineContainerView.frame
            newFrame.origin.y += self.view.frameHeight*2/3
            
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationBeginsFromCurrentState(true)
            
            UIView.setAnimationDuration(NSTimeInterval(0.25))
            
            lineContainerView.frame = newFrame
            
            UIView.commitAnimations()
        } else { //referenceSizeTextFeild tag = 2
            referenceSizeContainerView.frame.origin = CGPoint(x: referenceSizeContainerView.frame.origin.x, y: self.view.frameHeight-100)
        }
        
    }
    
    
    @IBAction func handlePinch(sender: AnyObject) {
        let recognizer = sender as! UIPinchGestureRecognizer
        let scaleFactor = recognizer.scale
        self.imageView.transform = CGAffineTransformScale(self.imageView.transform, scaleFactor, scaleFactor)
        recognizer.scale = 1
    }
    
    @IBAction func handlePan(sender: AnyObject) {
        let recognizer = sender as! UIPanGestureRecognizer
        let translation = recognizer.translationInView(self.view)
        self.imageView.center = CGPointMake(self.imageView.center.x + translation.x,
            self.imageView.center.y + translation.y);
        recognizer.setTranslation(CGPoint(x: 0,y: 0), inView: self.view)
        center = self.imageView.center
    }
    
    @IBAction func handleTap(sender: AnyObject) {
        // Dismiss UI elements (end editing)
        referenceSizeTextField.resignFirstResponder()
        lineNameTextField.resignFirstResponder()
        colorPickerView.hidden = true
        horizonTypePickerView.hidden = true
        self.imageView.center = center
        
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
            //drawingView.faciesView.curImageName = faciesTypeButton.titleForState(UIControlState.Normal)!
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
            self.imageView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds))
            self.imageView.transform = CGAffineTransformIdentity
            center = self.imageView.center
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
    
    /**
    @IBAction func pushTypeButton(sender: AnyObject) {
        let drawingView = imageView as! DrawingView
        let ctrler = self.storyboard?.instantiateViewControllerWithIdentifier("FaciesPixmapController") as! FaciesPixmapViewController
        //ctrler.typeButton = self.faciesTypeButton
        ctrler.drawingView = drawingView
        ctrler.faciesCatalog = faciesCatalog
        ctrler.drawingController = self
        
        ctrler.modalPresentationStyle = UIModalPresentationStyle.Popover
        ctrler.preferredContentSize.width = 150
        ctrler.preferredContentSize.height = 400
        ctrler.popoverPresentationController?.sourceView = sender as! UIView
        ctrler.popoverPresentationController?.sourceRect = sender.bounds
        ctrler.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Any
        let size = ctrler.view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        ctrler.preferredContentSize = size
        
        self.presentViewController(ctrler, animated: true, completion: nil)
    } **/

    @IBAction func pushLineTypeButton(sender: AnyObject) {
        horizonTypePickerView.hidden = !horizonTypePickerView.hidden
    }
    
    @IBAction func closeWindow(sender: AnyObject) {
        if managedContext.hasChanges {
            let alert = UIAlertController(title: "", message: "Save before closing?", preferredStyle: .Alert)
            let drawingView = self.imageView as! DrawingView
            //get scale for the image
            /**
            let scale = drawingView.getScale()
            if(scale.defined) {
                self.detailedImage!.scale = scale.scale
            } else {
                alert.title = "Save before closing?"
                alert.message = "WARNING: No scale for this image. Draw a reference line to define a scale."
            } **/
            let noAction: UIAlertAction = UIAlertAction(title: "NO", style: .Default) { action -> Void in
                self.managedContext.rollback()
                self.performSegueWithIdentifier("unwindFromDrawingToMain", sender: self)
                //self.dismissViewControllerAnimated(true, completion: nil)
            }
            alert.addAction(noAction)
        
            let yesAction: UIAlertAction = UIAlertAction(title: "YES", style: .Default) { action -> Void in
                self.performSegueWithIdentifier("showSavePopover", sender: self)
            }
            alert.addAction(yesAction)
        
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            self.performSegueWithIdentifier("unwindFromDrawingToMain", sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showSavePopover" {
            let savePopover = segue.destinationViewController as! SavePopoverViewController
            savePopover.drawingVC = self
            savePopover.preferredContentSize.height = CGFloat(295 + (51*self.detailedImage!.features.count))
            print(self.detailedImage!.features.count)
            savePopover.preferredContentSize.width = 500
            
        } else if segue.identifier == "showFaciesPixmap" {
            let faciesPopover = segue.destinationViewController as! FaciesPixmapViewController
            faciesPopover.drawingView = (imageView as! DrawingView)
            faciesPopover.faciesCatalog = faciesCatalog
            faciesPopover.drawingController = self
            let size = faciesPopover.view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
            faciesPopover.preferredContentSize = size
        }
    }
    
    @IBAction func pushDefineFeatureButton(sender : AnyObject) {
        //disable all other buttons until Feature definition is complete
        //self.toolbarSegmentedControl.enabled = false
        self.addDipMeterPointButton.enabled = false
        
        //create a new Feature
        feature = NSEntityDescription.insertNewObjectForEntityForName("FeatureObject",
            inManagedObjectContext: managedContext) as? FeatureObject
        feature!.image = detailedImage!
        
        let drawingView = imageView as! DrawingView
        if (drawingView.lineView.refMeasureValue.isZero || drawingView.lineView.refMeasureValue.isNaN) {
            let alert = UIAlertController(title: "", message: "Need to establish a reference before defining a Feature", preferredStyle: .Alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in
                //Do some stuff
            }
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
            
            //self.toolbarSegmentedControl.selectedSegmentIndex = DrawingView.ToolMode.Reference.rawValue
            drawingView.drawMode = DrawingView.ToolMode.Reference
            let nf = NSNumberFormatter()
            referenceSizeTextField.text = nf.stringFromNumber(drawingView.lineView.refMeasureValue)
            
        } else {
            //self.toolbarSegmentedControl.selectedSegmentIndex = DrawingView.ToolMode.Measure.rawValue
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
                //self.toolbarSegmentedControl.selectedSegmentIndex = DrawingView.ToolMode.Measure.rawValue
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
                //self.toolbarSegmentedControl.selectedSegmentIndex = DrawingView.ToolMode.Measure.rawValue
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
            //self.toolbarSegmentedControl.enabled = true
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


