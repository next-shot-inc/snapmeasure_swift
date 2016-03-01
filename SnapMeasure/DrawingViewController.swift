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
import MessageUI

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
        drawingView?.curColor = (colorButton!.backgroundColor?.CGColor)!
        
        // Change current line (per Value)
        for (index, line) in drawingView!.lineView.lines.enumerate() {
            if( line.name == drawingView?.lineView.tool.lineName ) {
                var changedLine = line
                changedLine.color = (drawingView?.curColor)!
                drawingView!.lineView.lines.removeAtIndex(index)
                drawingView!.lineView.lines.insert(changedLine, atIndex: index)
                drawingView?.lineView.setNeedsDisplay()
                break
            }
        }
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
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
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
        
        // Change current line (per Value)
        for (index, line) in drawingView!.lineView.lines.enumerate() {
            if( line.name == drawingView?.lineView.tool.lineName ) {
                var changedLine = line
                changedLine.role = LineViewTool.role(horizonTypes[row])
                drawingView!.lineView.lines.removeAtIndex(index)
                drawingView!.lineView.lines.insert(changedLine, atIndex: index)
                drawingView?.lineView.setNeedsDisplay()
                break
            }
        }
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return horizonTypes.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return horizonTypes[row]
    }
}

class DrawingViewController: UIViewController, UITextFieldDelegate, MFMailComposeViewControllerDelegate, UIScrollViewDelegate {
    
    @IBOutlet var twoTapsGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet var oneTapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet weak var colButton: UIButton!
    //@IBOutlet weak var toolbarSegmentedControl: UISegmentedControl!
    @IBOutlet weak var scrollView: UIScrollView!
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
    @IBOutlet weak var eraseButton: UIButton!
    @IBOutlet weak var drawButton: UIButton!
    @IBOutlet weak var measureButton: UIButton!
    @IBOutlet weak var measureReferenceButton: UIButton!
    @IBOutlet weak var faciesButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var solidFillButton: UIButton!
    
    var imageView: UIImageView!
    var tilingView : TilingView?
    var image : UIImage?
    var imageInfo = ImageInfo()
    var colorPickerCtrler = ColorPickerController()
    var horizonTypePickerCtrler = HorizonTypePickerController()
    static var lineCount = 1
    var curButton : UIButton?

    var faciesCatalog = FaciesCatalog()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var managedContext : NSManagedObjectContext!
    var feature : FeatureObject?
    var detailedImage : DetailedImageObject?
    var newDetailedImage = false
    //var center = CGPoint()
    var hasChanges = false
    var defaultLayout = false
    
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
        
        //5. ImageView
        imageView = DrawingView(frame: CGRect(x: 0,y: 0,width: imageInfo.xDimension, height: imageInfo.yDimension))
        let drawingView = imageView as! DrawingView
        //imageView.image = image
        drawingView.imageSize = CGSize(width: imageInfo.xDimension, height: imageInfo.yDimension)
        scrollView.addSubview(imageView)
        imageView.userInteractionEnabled = true
        
        //6. ScrollView
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 5
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
        self.scrollView.contentSize = drawingView.imageSize;
        
        
        // compute minimum scale
        let scrollViewSize = self.scrollView.bounds.size;
        let zoomViewSize = self.imageView.bounds.size;
        var scaleToFit = min(scrollViewSize.width / zoomViewSize.width, scrollViewSize.height / zoomViewSize.height);
        if (scaleToFit > 1.0 ) {
            scaleToFit = 1.0;
        }
        self.scrollView.zoomScale = scaleToFit;
        //centerScrollViewContents()

        drawingView.faciesView.curImageName = "sandstone"
        drawingView.imageInfo = imageInfo
        drawingView.controller = self
        drawingView.faciesView.faciesCatalog = faciesCatalog
        drawingView.lineView.zoomScale = scaleToFit
        
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
        
        initButton(drawButton)
        initButton(eraseButton)
        initButton(defineFeatureButton)
        initButton(measureButton)
        initButton(measureReferenceButton)
        initButton(faciesButton)
        initButton(textButton)
        initButton(addDipMeterPointButton)
        initButton(setWidthButton)
        initButton(setHeightButton)
        
        solidFillButton.setBackgroundImage(
            UIImage(named: "solidfill"), forState: UIControlState.Selected
        )
        
        drawButton.selected = true
        curButton = drawButton

        managedContext = appDelegate.managedObjectContext!
        
        if (detailedImage == nil) {
            detailedImage = NSEntityDescription.insertNewObjectForEntityForName("DetailedImageObject",
                inManagedObjectContext: managedContext) as? DetailedImageObject
            newDetailedImage = true
            detailedImage!.project = currentProject
            detailedImage!.saveImage(image!)
            image = nil
            hasChanges = true
            //detailedImage!.features = NSSet()
        } else {
            drawingView.initFrame()
            drawingView.initFromObject(detailedImage!, catalog: faciesCatalog)
            drawingView.setNeedsDisplay()
        }
        
        if( detailedImage == nil ) {
            tilingView = TilingView(name: " ", size: image!.size)
        } else {
            tilingView = TilingView(name: (detailedImage?.imageFile)!, size: drawingView.imageSize)
        }
        imageView.insertSubview(tilingView!, atIndex: 0)
        
        faciesCatalog.loadImages()
        
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "keyboardWasShown:", name: UIKeyboardDidShowNotification, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self, selector: "keyboardWillBeHidden:", name: UIKeyboardDidHideNotification, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let drawingView = imageView as! DrawingView
        drawingView.lineView.tool.lineName = lineNameTextField.text!
        drawingView.curColor = (colButton.backgroundColor?.CGColor)!
        drawingView.lineView.tool.lineType = horizonTypeButton.titleForState(UIControlState.Normal)!
        
        colorPickerCtrler.drawingView = drawingView
        horizonTypePickerCtrler.drawingView = drawingView
    }
    
    deinit  {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        image = nil
    }
    
    func initButton(button: UIButton) {
        let buttonImage = button.imageForState(UIControlState.Normal)
        if( buttonImage != nil ) {
           let buttonCGIImage = CIImage(image:buttonImage!)
           let filter = CIFilter(name:  "CIColorInvert", withInputParameters: [kCIInputImageKey: buttonCGIImage!])
           let invertedButtonImage = UIImage(CIImage: filter!.outputImage!)
           button.setImage(invertedButtonImage, forState: UIControlState.Selected)
        }
    }
    
    func highlightButton(sender: UIButton) {
        if( curButton != sender ) {
            sender.selected = true
            curButton?.selected = false
            curButton = sender
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
        
        highlightButton(sender)
    }
    
    @IBAction func eraseButtonPressed(sender: UIButton) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.Erase
        
        referenceSizeContainerView.hidden = true
        //faciesTypeContainerView.hidden = true
        lineContainerView.hidden = true
        
        highlightButton(sender)
    }
    
    @IBAction func measureButtonPressed(sender: UIButton) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.Measure
        
        referenceSizeContainerView.hidden = true
        //faciesTypeContainerView.hidden = true
        lineContainerView.hidden = true
        
        highlightButton(sender)
    }
    
    @IBAction func drawReferenceButtonPressed(sender: UIButton) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.Reference
        
        let nf = NSNumberFormatter()
        referenceSizeTextField.text =
            nf.stringFromNumber(drawingView.lineView.refMeasureValue == 0 ? 1 : drawingView.lineView.refMeasureValue)
        
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
        highlightButton(sender)
    }
    
    @IBAction func faciesButtonPressed(sender: UIButton) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.Facies
        
        referenceSizeContainerView.hidden = true
        //faciesTypeContainerView.hidden = false
        lineContainerView.hidden = true
        
        highlightButton(sender)
    }
    
    @IBAction func textboxButtonPressed(sender: UIButton) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.Text
        
        referenceSizeContainerView.hidden = true
        //faciesTypeContainerView.hidden = true
        lineContainerView.hidden = true
        
        highlightButton(sender)
    }
    
    @IBAction func dipMeterButtonPressed(sender: UIButton) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.DipMarker
        
        referenceSizeContainerView.hidden = true
        //faciesTypeContainerView.hidden = true
        lineContainerView.hidden = true
        
        highlightButton(sender)
    }
    
    var keyboardHeight : CGFloat = 0.0
    
    func keyboardWasShown(notification: NSNotification) {
        let tmp : [NSObject : AnyObject] = notification.userInfo!
        let rectV = tmp[UIKeyboardFrameBeginUserInfoKey]
        let rect = rectV?.CGRectValue
        keyboardHeight = rect!.height
        
        UIView.animateWithDuration(0.25, animations: { ()-> Void in
            self.view.center.y -= self.keyboardHeight
        })
    }
    
    func keyboardWillBeHidden(notification: NSNotification) {
        UIView.animateWithDuration(0.25, animations: { ()-> Void in
            self.view.center.y += self.keyboardHeight
        })
    }
    
    //Mark: UITextFieldDelegate Methods
    func textFieldDidBeginEditing(textField: UITextField) {
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if( textField === lineNameTextField ) {
            let drawingView = imageView as! DrawingView
            let oldName = drawingView.lineView.tool.lineName
            drawingView.lineView.tool.lineName = lineNameTextField.text!
            
            // Change current line (per Value)
            for (index, line) in drawingView.lineView.lines.enumerate() {
                if( line.name == oldName ) {
                    var changedLine = line
                    changedLine.name = lineNameTextField.text!
                    drawingView.lineView.lines.removeAtIndex(index)
                    drawingView.lineView.lines.insert(changedLine, atIndex: index)
                    drawingView.lineView.setNeedsDisplay()
                    break
                }
            }
        }
    }
    
    //Mark: UIScrollViewDelegate Methods
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        // Recenter the image view when it is smaller than the scrollView
        //self.centerScrollViewContents()
        let drawingView = imageView as! DrawingView
        drawingView.lineView.zoomScale = scale
        drawingView.lineView.setNeedsDisplay()
    }
    
    func centerScrollViewContents() {
        let boundsSize = self.scrollView.bounds.size
        var contentsFrame = self.imageView.frame
        //var contentsFrame = self.tilingView!.frame
        
        if (contentsFrame.size.width < boundsSize.width) {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0;
        } else {
            contentsFrame.origin.x = 0.0;
        }
        
        if (contentsFrame.size.height < boundsSize.height) {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0;
        } else {
            contentsFrame.origin.y = 0.0;
        }
        
        self.imageView.frame = contentsFrame
        //self.tilingView!.frame = contentsFrame
    }
    
    @IBAction func handlePinch(sender: AnyObject) {
        // Scrollview implements it now
    }
    
    @IBAction func handlePan(sender: AnyObject) {
        // Scrollview implements it now
    }
    
    @IBAction func handleTap(sender: AnyObject) {
        // Dismiss UI elements (end editing)
        referenceSizeTextField.resignFirstResponder()
        lineNameTextField.resignFirstResponder()
        colorPickerView.hidden = true
        horizonTypePickerView.hidden = true
        //self.imageView.center = center
        
        // Initialize drawing information
        let drawingView = imageView as! DrawingView
        
        if( drawingView.drawMode == DrawingView.ToolMode.Reference ) {
            let nf = NSNumberFormatter()
            let ns = nf.numberFromString(referenceSizeTextField.text!)
            if( ns != nil ) {
                drawingView.lineView.refMeasureValue = ns!.floatValue
            }
        } else if( drawingView.drawMode == DrawingView.ToolMode.Draw ) {
            drawingView.lineView.tool.lineName = lineNameTextField.text!
                    
        } else if( drawingView.drawMode == DrawingView.ToolMode.Facies ) {
            //drawingView.faciesView.curImageName = faciesTypeButton.titleForState(UIControlState.Normal)!
        } else if( drawingView.drawMode == DrawingView.ToolMode.Select ) {
            let point = sender.locationInView(drawingView)
            
            // Find if an object is selected
            let line = drawingView.select(point)
            
            if( line != nil ) {
                // Initialize UI with selected object
                lineNameTextField.text = line!.name
                colButton.backgroundColor = UIColor(CGColor: line!.color)
                
                // Initialize drawing information
                drawingView.lineView.tool.lineName = line!.name
                drawingView.curColor = line!.color
                drawingView.lineView.tool.lineType = LineViewTool.typeName(line!.role)
                horizonTypeButton.setTitle(drawingView.lineView.tool.lineType, forState: UIControlState.Normal)
            }
        }
    }
    
    @IBAction func handleDoubleTap(sender: AnyObject) {
        // Center view and reset zoom
        let scrollViewSize = self.scrollView.bounds.size;
        let zoomViewSize = self.imageView.bounds.size;
        
        var scaleToFit = min(scrollViewSize.width / zoomViewSize.width, scrollViewSize.height / zoomViewSize.height);
        if (scaleToFit > 1.0 ) {
            scaleToFit = 1.0;
        }
        
        self.scrollView.zoomScale = scaleToFit;
        //self.centerScrollViewContents()
        
        let drawingView = imageView as! DrawingView
        drawingView.lineView.zoomScale = scaleToFit
        drawingView.lineView.setNeedsDisplay()
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
        drawingView.curColor = (colButton.backgroundColor?.CGColor)!
    }
    
    @IBAction func pushNewLine(sender: AnyObject) {
        lineNameTextField.text = String("H") +
                                      String(++DrawingViewController.lineCount)
        
        let drawingView = imageView as! DrawingView
        let color = colorPickerCtrler.selectNextColor(colorPickerView)
        
        colButton.backgroundColor = color
        drawingView.lineView.tool.lineName = lineNameTextField.text!
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
        if hasChanges || managedContext.hasChanges {
            let alert = UIAlertController(title: "", message: "Save before closing?", preferredStyle: .Alert)
            //let drawingView = self.imageView as! DrawingView
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
            //let size = faciesPopover.view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
            //faciesPopover.preferredContentSize = size
        } else if segue.identifier == "unwindFromDrawingToMain" || segue.identifier == "cancelUnwind" {
            image = nil
            imageView.image = nil
            if( newDetailedImage && detailedImage!.hasChanges ) {
                detailedImage?.removeImage()
            }
            managedContext.reset() // Free all ImageDetailedObjects and ProjectObjects
            projects.removeAll()
        }
    }
    
    @IBAction func pushDefineFeatureButton(sender : UIButton) {
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
        
        highlightButton(sender)
    }
    
    
    @IBAction func pushSetHeightButton(sender : UIButton) {
        let drawingView = imageView as! DrawingView
        let height = drawingView.lineView.currentMeasure as NSNumber
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
                print("Feature is nil when attempting to set height")
            } else {
                feature!.height = height
            }
            print("height: ", height.floatValue)
            self.setHeightButton.enabled = false
            self.setHeightButton.hidden = true
            self.setWidthButton.enabled = true
            self.setWidthButton.hidden = false
            
            //Remove measurement line to force user to draw a new line to define the width
            drawingView.lineView.measure.removeAll(keepCapacity: true)
            drawingView.lineView.currentMeasure = 0.0
            drawingView.lineView.setNeedsDisplay()
        }
        
        highlightButton(sender)
    }
    
    @IBAction func pushSetWdithButton(sender : UIButton) {
        let drawingView = imageView as! DrawingView
        let width = drawingView.lineView.currentMeasure as NSNumber
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
                print("Feature is nil when attempting to set type")
            } else {
                feature!.width = width
            }
            print("width: ",width.floatValue)
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
                let nextAction: UIAlertAction = UIAlertAction(title: type, style: .Default) { action -> Void in
                    //save Feature.type as type
                    if self.feature == nil {
                        print("Feature is nil when attempting to set type")
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
            drawingView.lineView.currentMeasure = 0.0
            drawingView.lineView.setNeedsDisplay()
        }
        highlightButton(sender)
    }
    
    @IBAction func unwindToDrawing (segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func doMeasureDipAndStrike(sender: UIButton) {
        let ctrler = self.storyboard?.instantiateViewControllerWithIdentifier("OrientationController") as! OrientationController
        
        ctrler.modalPresentationStyle = UIModalPresentationStyle.Popover
        ctrler.popoverPresentationController?.sourceView = sender.viewForFirstBaselineLayout
        ctrler.popoverPresentationController?.sourceRect = sender.bounds
        ctrler.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Any
        let size = ctrler.view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        ctrler.preferredContentSize = size
        
        ctrler.drawingViewController = self
        ctrler.currentButton = curButton
        
        self.presentViewController(ctrler, animated: true, completion: nil)
        
        highlightButton(sender)
    }
    
    @IBAction func doSendMail(sender: AnyObject) {
        var filename: NSURL
        var formatUserName : String
        
        let drawingView = imageView as! DrawingView
        let scale = drawingView.getScale()
        if(scale.defined) {
            detailedImage!.scale = scale.scale
        }
        
        //UIImageWriteToSavedPhotosAlbum(imageView.image!, nil, nil, nil)
        
        if( detailedImage!.scale == nil || detailedImage!.scale! == 0 ||
            !MFMailComposeViewController.canSendMail()
        ){
            let alert = UIAlertController(title: "", message: "Need to establish a reference before sending it in 3D", preferredStyle: .Alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .Cancel) { action -> Void in
                //Do some stuff
            }
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
        
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
                detailedImage!.imageData()!, mimeType: "impage/jpeg", fileName: detailedImage!.name + ".jpg"
            )
            
            mailComposer.setToRecipients([String]())
            mailComposer.mailComposeDelegate = self
            
            presentViewController(mailComposer, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        print(result)
        controller.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func solidFillButtonPressed(sender: UIButton) {
        sender.selected = !sender.selected
        let drawingView = imageView as! DrawingView
        drawingView.lineView.drawPolygon = sender.selected
        drawingView.lineView.computePolygon()
        drawingView.lineView.setNeedsDisplay()
    }
    
    @IBAction func editSelectSegmentedControllerChanged(sender: UISegmentedControl) {
        
        let drawingView = imageView as! DrawingView
        if( sender.selectedSegmentIndex == 1 ) {
            drawingView.drawMode = DrawingView.ToolMode.Select
        } else {
            drawingView.drawMode = DrawingView.ToolMode.Draw
        }
    }
}


