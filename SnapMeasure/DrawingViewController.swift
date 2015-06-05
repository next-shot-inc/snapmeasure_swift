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

class ColorPickerController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    let count = 8
    var colorButton : UIButton?
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        let hue = CGFloat(row)/CGFloat(count)
        colorButton!.backgroundColor =
            UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
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

class TypePickerController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    let types = ["Top", "Unconformity", "Fault"]
    var typeButton : UIButton?
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        typeButton?.setTitle(types[row], forState: UIControlState.Normal)
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return types.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return types[row]
    }
}

class DrawingViewController: UIViewController {
    
    @IBOutlet var twoTapsGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet var oneTapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet weak var colButton: UIButton!
    @IBOutlet weak var toolbarSegmentedControl: UISegmentedControl!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var referenceSizeTextField: UITextField!
    @IBOutlet weak var colorPickerView: UIPickerView!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var typePickerView: UIPickerView!
    @IBOutlet weak var newLineButton: UIButton!
    
    
    @IBOutlet weak var defineFeatureButton : UIButton!
    @IBOutlet weak var setWidthButton : UIButton!
    @IBOutlet weak var setHeightButton : UIButton!
    
    var image : UIImage?
    var lines = [Line]()
    var imageInfo = ImageInfo()
    var colorPickerCtrler = ColorPickerController()
    var typePickerCtrler = TypePickerController()
    static var lineCount = 1
    //TODO: Add Feature Type Names
    var possibleFeatureTypes = ["Type 1","Type 2","Type 3","Type 4","Type 5"]
    
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var managedContext : NSManagedObjectContext!
    var feature : FeatureObject?
    var detailedImage : DetailedImageObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Let the one tap wait for the double-tap to fail before firing
        oneTapGestureRecognizer.requireGestureRecognizerToFail(twoTapsGestureRecognizer)
        
        // Initialize widgets at the top
        // 1. Text field
        referenceSizeTextField.keyboardType = UIKeyboardType.Default
        referenceSizeTextField.placeholder = "Name"
        referenceSizeTextField.text = "H1"
        
        //let recognizer = UITapGestureRecognizer(target: self, action: Selector("handleTap:"))
        //self.view.addGestureRecognizer(recognizer)
        
        // 2. Color picker
        colorPickerView.delegate = colorPickerCtrler
        colorPickerView.dataSource = colorPickerCtrler
        let color = colorPickerCtrler.selectNextColor(colorPickerView)
        
        // 3. Color button
        colButton.setTitle(" ", forState: UIControlState.Normal)
        colButton.backgroundColor = color
        colorPickerCtrler.colorButton = colButton
        
        //make sure all buttons are in the right state
        self.colButton.userInteractionEnabled = true
        self.newLineButton.userInteractionEnabled = true
        self.toolbarSegmentedControl.userInteractionEnabled = true

        self.defineFeatureButton.userInteractionEnabled = true
        self.defineFeatureButton.hidden = false
        self.setWidthButton.userInteractionEnabled = false
        self.setWidthButton.hidden = true
        self.setHeightButton.userInteractionEnabled = false
        self.setHeightButton.hidden = true

        managedContext = appDelegate.managedObjectContext!
        
        if (detailedImage == nil) {
            detailedImage = NSEntityDescription.insertNewObjectForEntityForName("DetailedImageObject",
                inManagedObjectContext: managedContext) as? DetailedImageObject
        }
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
        drawingView.initFrame()
        drawingView.lineView.lines = lines
        drawingView.lineView.setNeedsDisplay()
    }
    
    
    @IBAction func toolChanged(sender: AnyObject) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode =
            DrawingView.ToolMode(rawValue: toolbarSegmentedControl.selectedSegmentIndex)!
        
        if( drawingView.drawMode == DrawingView.ToolMode.Reference ) {
            
            referenceSizeTextField.keyboardType = UIKeyboardType.DecimalPad
            referenceSizeTextField.placeholder = "Size"
            let nf = NSNumberFormatter()
            referenceSizeTextField.text = nf.stringFromNumber(drawingView.lineView.refMeasureValue)
            
        } else if( drawingView.drawMode == DrawingView.ToolMode.Draw ) {
            
            referenceSizeTextField.keyboardType = UIKeyboardType.Default
            referenceSizeTextField.placeholder = "Name"
            referenceSizeTextField.text = drawingView.lineView.currentLineName
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
        colorPickerView.hidden = true
        typePickerView.hidden = true
        
        // Initialize drawing information
        let drawingView = imageView as! DrawingView
        
        if( drawingView.drawMode == DrawingView.ToolMode.Reference ) {
            var nf = NSNumberFormatter()
            var ns = nf.numberFromString(referenceSizeTextField.text)
            if( ns != nil ) {
                drawingView.lineView.refMeasureValue = ns!.floatValue
            }
        } else if( drawingView.drawMode == DrawingView.ToolMode.Draw ) {
            drawingView.lineView.currentLineName = referenceSizeTextField.text
            drawingView.curColor = colButton.backgroundColor?.CGColor
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
            referenceSizeTextField.text = line!.name
            colButton.backgroundColor = UIColor(CGColor: line!.color)
            
            // Initialize drawing information
            drawingView.lineView.currentLineName = line!.name
            drawingView.curColor = line!.color
        } else {
            self.imageView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
            self.imageView.transform = CGAffineTransformIdentity;
        }
    }
    
    @IBAction func pushColButton(sender: AnyObject) {
        colorPickerView.hidden = !colorPickerView.hidden
        let drawingView = imageView as! DrawingView
        drawingView.curColor = colButton.backgroundColor?.CGColor
    }
    
    @IBAction func pushNewLine(sender: AnyObject) {
        referenceSizeTextField.text = String("H") +
                                      String(++DrawingViewController.lineCount)
        
        let drawingView = imageView as! DrawingView
        let color = colorPickerCtrler.selectNextColor(colorPickerView)
        
        colButton.backgroundColor = color
        drawingView.lineView.currentLineName = referenceSizeTextField.text
        drawingView.curColor = color.CGColor
    }
    /**
    @IBAction func pushTypeButton(sender: AnyObject) {
        typePickerView.hidden = !typePickerView.hidden
        
        //let drawingView = imageView as! DrawingView
    }
    **/
    @IBAction func closeWindow(sender: AnyObject) {
        var inputTextField : UITextField?
        let alert = UIAlertController(title: "", message: "Save before closing?", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Name"
            inputTextField = textField
        }
        let noAction: UIAlertAction = UIAlertAction(title: "NO", style: .Default) { action -> Void in
            self.managedContext.rollback()
            self.dismissViewControllerAnimated(true, completion: nil)

        }
        alert.addAction(noAction)
        let yesAction: UIAlertAction = UIAlertAction(title: "YES", style: .Default) { action -> Void in
            
            //update detailedImage and lines
            //detailedImage!.name = outcropName.text!
            self.detailedImage!.imageData = UIImageJPEGRepresentation(self.image, 1.0)
            if (inputTextField != nil) {
                self.detailedImage?.name = inputTextField!.text
            }
            let linesSet = NSMutableSet()
            
            let drawingView = self.imageView as! DrawingView
            for line in drawingView.lineView.lines  {
                let lineObject = NSEntityDescription.insertNewObjectForEntityForName("LineObject",
                    inManagedObjectContext: self.managedContext) as? LineObject
                
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
                lineObject!.image = self.detailedImage!
                linesSet.addObject(lineObject!)
                println("Added a line")
            }
            
            self.detailedImage!.lines = linesSet
            
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
    
    @IBAction func pushDefineFeatureButton(sender : AnyObject) {
        //disable all other buttons until Feature definition is complete
        self.colButton.userInteractionEnabled = false
        self.newLineButton.userInteractionEnabled = false
        self.toolbarSegmentedControl.userInteractionEnabled = false
        
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
            
            self.toolbarSegmentedControl.selectedSegmentIndex = DrawingView.ToolMode.Reference.rawValue
            drawingView.drawMode = DrawingView.ToolMode.Reference
            referenceSizeTextField.keyboardType = UIKeyboardType.DecimalPad
            referenceSizeTextField.placeholder = "Size"
            let nf = NSNumberFormatter()
            referenceSizeTextField.text = nf.stringFromNumber(drawingView.lineView.refMeasureValue)
            
        } else {
            self.toolbarSegmentedControl.selectedSegmentIndex = DrawingView.ToolMode.Measure.rawValue
            drawingView.drawMode = DrawingView.ToolMode.Measure
            self.defineFeatureButton.userInteractionEnabled = false
            self.defineFeatureButton.hidden = true
            self.setHeightButton.userInteractionEnabled = true
            self.setHeightButton.hidden = false
        }
    }
    
    
    @IBAction func pushSetHeightButton(sender : AnyObject) {
        let drawingView = imageView as! DrawingView
        var height = 0.0 as NSNumber
        if drawingView.lineView.label.text != nil {
            height = NSNumberFormatter().numberFromString(drawingView.lineView.label.text!)!
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
            self.setHeightButton.userInteractionEnabled = false
            self.setHeightButton.hidden = true
            self.setWidthButton.userInteractionEnabled = true
            self.setWidthButton.hidden = false
            //TODO: Remove measurement line to force user to draw a new line to define the width
        }
    }
    
    @IBAction func pushSetWdithButton(sender : AnyObject) {
        let drawingView = imageView as! DrawingView
        var width = 0.0 as NSNumber
        if drawingView.lineView.label.text != nil {
            width = NSNumberFormatter().numberFromString(drawingView.lineView.label.text!)!
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
            println("width: %f",width.floatValue)
            self.setWidthButton.userInteractionEnabled = false
            self.setWidthButton.hidden = true
            
            let alert = UIAlertController(title: "", message: "Select a Feature type for this Feature", preferredStyle: .Alert)
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
            
            //TODO: Remove measurement line
            self.defineFeatureButton.userInteractionEnabled = true
            self.defineFeatureButton.hidden = false
        }
        
    }
    



}


