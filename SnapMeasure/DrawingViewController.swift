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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        let hue = CGFloat(row)/CGFloat(count)
        colorButton!.backgroundColor =
            UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        drawingView?.curColor = (colorButton!.backgroundColor?.cgColor)!
        
        // Change current line (per Value)
        for (index, line) in drawingView!.lineView.lines.enumerated() {
            if( line.name == drawingView?.lineView.tool.lineName ) {
                var changedLine = line
                changedLine.color = (drawingView?.curColor)!
                drawingView!.lineView.lines.remove(at: index)
                drawingView!.lineView.lines.insert(changedLine, at: index)
                drawingView?.lineView.setNeedsDisplay()
                drawingView?.controller?.hasChanges = true
                break
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return count
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 36
    }
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 36
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
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
    
    func selectNextColor(_ pickerView: UIPickerView) -> UIColor {
        var curColor = pickerView.selectedRow(inComponent: 0)
        curColor += 1
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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        typeButton?.setTitle(horizonTypes[row], for: UIControlState())
        drawingView?.lineView.tool.lineType = horizonTypes[row]
        
        // Change current line (per Value)
        for (index, line) in drawingView!.lineView.lines.enumerated() {
            if( line.name == drawingView?.lineView.tool.lineName ) {
                var changedLine = line
                changedLine.role = LineViewTool.role(horizonTypes[row])
                drawingView!.lineView.lines.remove(at: index)
                drawingView!.lineView.lines.insert(changedLine, at: index)
                drawingView?.lineView.setNeedsDisplay()
                drawingView?.controller?.hasChanges = true
                break
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return horizonTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
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
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
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
        oneTapGestureRecognizer.require(toFail: twoTapsGestureRecognizer)
        
        // Initialize widgets at the top
        // 1. Text field
        lineNameTextField.keyboardType = UIKeyboardType.default
        //lineNameTextField.placeholder = "Name"
        lineNameTextField.text = "H1"
        lineNameTextField.delegate = self
        
        referenceSizeTextField.keyboardType = UIKeyboardType.decimalPad
        referenceSizeTextField.placeholder = "Size"
        referenceSizeTextField.delegate = self
        
        // 2. Color picker
        colorPickerView.delegate = colorPickerCtrler
        colorPickerView.dataSource = colorPickerCtrler
        let color = colorPickerCtrler.selectNextColor(colorPickerView)
        
        // 3. Color button
        colButton.setTitle(" ", for: UIControlState())
        colButton.backgroundColor = color
        colorPickerCtrler.colorButton = colButton
        
        //4. Type pickers
        horizonTypePickerView.delegate = horizonTypePickerCtrler
        horizonTypePickerView.dataSource = horizonTypePickerCtrler
        horizonTypePickerCtrler.typeButton = horizonTypeButton
        horizonTypeButton.setTitle("Top", for: UIControlState())
        
        //5. ImageView
        imageView = DrawingView(frame: CGRect(x: 0,y: 0,width: imageInfo.xDimension, height: imageInfo.yDimension))
        let drawingView = imageView as! DrawingView
        //imageView.image = image
        drawingView.imageSize = CGSize(width: imageInfo.xDimension, height: imageInfo.yDimension)
        scrollView.addSubview(imageView)
        imageView.isUserInteractionEnabled = true
        
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
        self.scrollView.zoomScale = scaleToFit;
        //centerScrollViewContents()

        drawingView.faciesView.curImageName = "sandstone"
        drawingView.imageInfo = imageInfo
        drawingView.controller = self
        drawingView.faciesView.faciesCatalog = faciesCatalog
        drawingView.lineView.zoomScale = scaleToFit
        drawingView.lineView.scrollView = scrollView
        
        referenceSizeContainerView.isHidden = true
        //faciesTypeContainerView.hidden = true

        //make sure all buttons are in the right state
        self.colButton.isEnabled = true
        self.newLineButton.isEnabled = true
        //self.toolbarSegmentedControl.enabled = true

        self.defineFeatureButton.isEnabled = true
        self.defineFeatureButton.isHidden = false
        self.setWidthButton.isEnabled = false
        self.setWidthButton.isHidden = true
        self.setHeightButton.isEnabled = false
        self.setHeightButton.isHidden = true
        
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
            UIImage(named: "solidfill"), for: UIControlState.selected
        )
        
        drawButton.isSelected = true
        curButton = drawButton

        managedContext = appDelegate.managedObjectContext!
        
        if (detailedImage == nil) {
            detailedImage = NSEntityDescription.insertNewObject(forEntityName: "DetailedImageObject",
                into: managedContext) as? DetailedImageObject
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
        imageView.insertSubview(tilingView!, at: 0)
        
        faciesCatalog.loadImages()
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(DrawingViewController.keyboardWasShown(_:)), name: NSNotification.Name.UIKeyboardDidShow, object:nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(DrawingViewController.keyboardWillBeHidden(_:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let drawingView = imageView as! DrawingView
        drawingView.lineView.tool.lineName = lineNameTextField.text!
        drawingView.curColor = (colButton.backgroundColor?.cgColor)!
        drawingView.lineView.tool.lineType = horizonTypeButton.title(for: UIControlState())!
        
        colorPickerCtrler.drawingView = drawingView
        horizonTypePickerCtrler.drawingView = drawingView
        
        let scale = drawingView.getScale()
        if(!scale.defined) {
            self.measureButton.isEnabled = false
            self.defineFeatureButton.isEnabled = false
        }
    }
    
    deinit  {
        NotificationCenter.default.removeObserver(self)
        image = nil
    }
    
    func initButton(_ button: UIButton) {
        let buttonImage = button.image(for: UIControlState())
        if( buttonImage != nil ) {
           let buttonCGIImage = CIImage(image:buttonImage!)
           let filter = CIFilter(name:  "CIColorInvert", withInputParameters: [kCIInputImageKey: buttonCGIImage!])
           let invertedButtonImage = UIImage(ciImage: filter!.outputImage!)
           button.setImage(invertedButtonImage, for: UIControlState.selected)
        }
    }
    
    func highlightButton(_ sender: UIButton) {
        if( curButton != sender ) {
            sender.isSelected = true
            curButton?.isSelected = false
            curButton = sender
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    /* This function is called at each button click - Not good to change the zoom level then.
    override func viewWillLayoutSubviews() {
        // Center view and reset zoom
        let scrollViewSize = self.scrollView.bounds.size;
        let zoomViewSize = self.imageView.bounds.size;
        
        let scaleToFit = min(scrollViewSize.width / zoomViewSize.width, scrollViewSize.height / zoomViewSize.height);
        
        self.scrollView.zoomScale = scaleToFit;
        let drawingView = imageView as! DrawingView
        drawingView.lineView.zoomScale = scaleToFit
    }
 */
    
    // Mark: Bottom Toolbar methods
    @IBAction func newLineButtonPressed(_ sender: UIButton) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.draw
        
        referenceSizeContainerView.isHidden = true
        
        lineContainerView.isHidden = false
        
        highlightButton(sender)
    }
    
    @IBAction func eraseButtonPressed(_ sender: UIButton) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.erase
        
        referenceSizeContainerView.isHidden = true
        lineContainerView.isHidden = true
        
        highlightButton(sender)
    }
    
    @IBAction func measureButtonPressed(_ sender: UIButton) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.measure
        
        referenceSizeContainerView.isHidden = true
        //faciesTypeContainerView.hidden = true
        lineContainerView.isHidden = true
        
        highlightButton(sender)
    }
    
    @IBAction func drawReferenceButtonPressed(_ sender: UIButton) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.reference
        
        let alert = UIAlertController(title: "", message: "To define the image scale, enter the reference size and draw a line of that same size on the picture", preferredStyle: .alert)
        alert.addTextField { (textField) in
            let nf = NumberFormatter()
            textField.text =
                nf.string(from: NSNumber(value: drawingView.lineView.refMeasureValue == 0 ? Float(1.0) : drawingView.lineView.refMeasureValue))
            textField.placeholder = "Size"
            textField.keyboardType = UIKeyboardType.decimalPad
        }
        let noAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .default) { action -> Void in
        }
        alert.addAction(noAction)
        let yesAction: UIAlertAction = UIAlertAction(title: "Ok", style: .default) { action -> Void in
            let drawingView = self.imageView as! DrawingView
            drawingView.textView.setNeedsDisplay()
            
            let refSizeTextField = alert.textFields![0]
            drawingView.lineView.refMeasureValue = Float(refSizeTextField.text!)!
        }
        alert.addAction(yesAction)
        
        self.present(alert, animated: true, completion: nil)

        lineContainerView.isHidden = true
        highlightButton(sender)
        
        self.measureButton.isEnabled = true
        self.defineFeatureButton.isEnabled = true
    }
    
    @IBAction func faciesButtonPressed(_ sender: UIButton) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.facies
        
        referenceSizeContainerView.isHidden = true
        //faciesTypeContainerView.hidden = false
        lineContainerView.isHidden = true
        
        highlightButton(sender)
    }
    
    @IBAction func textboxButtonPressed(_ sender: UIButton) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode = DrawingView.ToolMode.text
        
        referenceSizeContainerView.isHidden = true
        //faciesTypeContainerView.hidden = true
        lineContainerView.isHidden = true
        
        highlightButton(sender)
    }
    
    var keyboardHeight : CGFloat = 0.0
    
    @objc func keyboardWasShown(_ notification: Notification) {
        let tmp : [AnyHashable: Any] = notification.userInfo!
        let rectV = tmp[UIKeyboardFrameBeginUserInfoKey]
        let rect = (rectV as AnyObject).cgRectValue
        keyboardHeight = rect!.height
        
        UIView.animate(withDuration: 0.25, animations: { ()-> Void in
            self.view.center.y -= self.keyboardHeight
        })
    }
    
    @objc func keyboardWillBeHidden(_ notification: Notification) {
        UIView.animate(withDuration: 0.25, animations: { ()-> Void in
            self.view.center.y += self.keyboardHeight
        })
    }
    
    //Mark: UITextFieldDelegate Methods
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if( textField === lineNameTextField ) {
            let drawingView = imageView as! DrawingView
            let oldName = drawingView.lineView.tool.lineName
            drawingView.lineView.tool.lineName = lineNameTextField.text!
            
            // Change current line (per Value)
            for (index, line) in drawingView.lineView.lines.enumerated() {
                if( line.name == oldName ) {
                    var changedLine = line
                    changedLine.name = lineNameTextField.text!
                    drawingView.lineView.lines.remove(at: index)
                    drawingView.lineView.lines.insert(changedLine, at: index)
                    drawingView.lineView.setNeedsDisplay()
                    hasChanges = true
                    break
                }
            }
        }
    }
    
    //Mark: UIScrollViewDelegate Methods
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let drawingView = imageView as! DrawingView
        drawingView.lineView.visibleRect = scrollView.convert(scrollView.bounds, to: drawingView)
        // Do not redraw while scrolling
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Redraw when scrolling is done.
        let drawingView = imageView as! DrawingView
        drawingView.lineView.setNeedsDisplay()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        // Recenter the image view when it is smaller than the scrollView
        //self.centerScrollViewContents()
        let drawingView = imageView as! DrawingView
        drawingView.lineView.zoomScale = scale
        drawingView.lineView.visibleRect = scrollView.convert(scrollView.bounds, to: drawingView)
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
    
    @IBAction func handlePinch(_ sender: AnyObject) {
        // Scrollview implements it now
    }
    
    @IBAction func handlePan(_ sender: AnyObject) {
        // Scrollview implements it now
    }
    
    @IBAction func handleTap(_ sender: AnyObject) {
        // Dismiss UI elements (end editing)
        referenceSizeTextField.resignFirstResponder()
        lineNameTextField.resignFirstResponder()
        colorPickerView.isHidden = true
        horizonTypePickerView.isHidden = true
        //self.imageView.center = center
        
        // Initialize drawing information
        let drawingView = imageView as! DrawingView
        
        if( drawingView.drawMode == DrawingView.ToolMode.reference ) {
            
        } else if( drawingView.drawMode == DrawingView.ToolMode.draw ) {
            drawingView.lineView.tool.lineName = lineNameTextField.text!
                    
        } else if( drawingView.drawMode == DrawingView.ToolMode.facies ) {
            //drawingView.faciesView.curImageName = faciesTypeButton.titleForState(UIControlState.Normal)!
        } else if( drawingView.drawMode == DrawingView.ToolMode.select ) {
            let point = sender.location(in: drawingView)
            
            // Find if an object is selected
            let line = drawingView.select(point)
            
            if( line != nil ) {
                // Initialize UI with selected object
                lineNameTextField.text = line!.name
                colButton.backgroundColor = UIColor(cgColor: line!.color)
                
                // Initialize drawing information
                drawingView.lineView.tool.lineName = line!.name
                drawingView.curColor = line!.color
                drawingView.lineView.tool.lineType = LineViewTool.typeName(line!.role)
                horizonTypeButton.setTitle(drawingView.lineView.tool.lineType, for: UIControlState())
            }
        }
    }
    
    @IBAction func handleDoubleTap(_ sender: AnyObject) {
        // Center view and reset zoom
        let scrollViewSize = self.scrollView.bounds.size;
        let zoomViewSize = self.imageView.bounds.size;
        
        let scaleToFit = min(scrollViewSize.width / zoomViewSize.width, scrollViewSize.height / zoomViewSize.height);
        //if (scaleToFit > 1.0 ) {
            //scaleToFit = 1.0;
        //}
        
        self.scrollView.zoomScale = scaleToFit;
        
        //self.centerScrollViewContents()
        
        let drawingView = imageView as! DrawingView
        drawingView.lineView.zoomScale = scaleToFit
        drawingView.lineView.visibleRect = scrollView.convert(scrollView.bounds, to: drawingView)
        drawingView.lineView.setNeedsDisplay()
    }
    
    func askText(_ label: UILabel) {
        var inputTextField : UITextField?
        let alert = UIAlertController(title: "", message: "Please specify text", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Label"
            inputTextField = textField
        }
        let noAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .default) { action -> Void in
        }
        alert.addAction(noAction)
        let yesAction: UIAlertAction = UIAlertAction(title: "Ok", style: .default) { action -> Void in
            label.text = inputTextField!.text
            let drawingView = self.imageView as! DrawingView
            drawingView.textView.setNeedsDisplay()
        }
        alert.addAction(yesAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func pushColButton(_ sender: AnyObject) {
        colorPickerView.isHidden = !colorPickerView.isHidden
        let drawingView = imageView as! DrawingView
        drawingView.curColor = (colButton.backgroundColor?.cgColor)!
    }
    
    @IBAction func pushNewLine(_ sender: AnyObject) {
        DrawingViewController.lineCount += 1
        lineNameTextField.text = String("H") + String(DrawingViewController.lineCount)
        
        let drawingView = imageView as! DrawingView
        let color = colorPickerCtrler.selectNextColor(colorPickerView)
        
        colButton.backgroundColor = color
        drawingView.lineView.tool.lineName = lineNameTextField.text!
        drawingView.lineView.tool.lineType = horizonTypeButton.title(for: UIControlState())!
        drawingView.curColor = color.cgColor
    }

    @IBAction func pushLineTypeButton(_ sender: AnyObject) {
        horizonTypePickerView.isHidden = !horizonTypePickerView.isHidden
    }
    
    @IBAction func closeWindow(_ sender: AnyObject) {
        if hasChanges || managedContext.hasChanges {
            let alert = UIAlertController(title: "", message: "Save before closing?", preferredStyle: .alert)
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
            let noAction: UIAlertAction = UIAlertAction(title: "NO", style: .default) { action -> Void in
                self.managedContext.rollback()
                self.performSegue(withIdentifier: "unwindFromDrawingToMain", sender: self)
                //self.dismissViewControllerAnimated(true, completion: nil)
            }
            alert.addAction(noAction)
        
            let yesAction: UIAlertAction = UIAlertAction(title: "YES", style: .default) { action -> Void in
                self.performSegue(withIdentifier: "showSavePopover", sender: self)
            }
            alert.addAction(yesAction)
        
            self.present(alert, animated: true, completion: nil)
        } else {
            self.performSegue(withIdentifier: "unwindFromDrawingToMain", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showSavePopover" {
            let savePopover = segue.destination as! SavePopoverViewController
            savePopover.drawingVC = self
            savePopover.preferredContentSize.height = CGFloat(295 + (51*self.detailedImage!.features.count))
            print(self.detailedImage!.features.count)
            savePopover.preferredContentSize.width = 500
            savePopover.intermediateSaveAction = false
            
        } else if( segue.identifier == "showIntermediateSavePopover" ) {
            let savePopover = segue.destination as! SavePopoverViewController
            savePopover.drawingVC = self
            savePopover.intermediateSaveAction = true
            
        } else if segue.identifier == "showFaciesPixmap" {
            let faciesPopover = segue.destination as! FaciesPixmapViewController
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
    
    @IBAction func pushDefineFeatureButton(_ sender : UIButton) {
        //disable all other buttons until Feature definition is complete
        self.addDipMeterPointButton.isHidden = true
        self.eraseButton.isHidden = true
        self.measureButton.isHidden = true
        self.measureReferenceButton.isHidden = true
        self.faciesButton.isHidden = true
        self.textButton.isHidden = true
        self.drawButton.isHidden = true
        lineContainerView.isHidden = true
        
        //create a new Feature
        feature = NSEntityDescription.insertNewObject(forEntityName: "FeatureObject",
            into: managedContext) as? FeatureObject
        feature!.image = detailedImage!
        
        let drawingView = imageView as! DrawingView
        if (drawingView.lineView.refMeasureValue.isZero || drawingView.lineView.refMeasureValue.isNaN) {
            let alert = UIAlertController(title: "", message: "Need to establish a reference before defining a Feature", preferredStyle: .alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .cancel) { action -> Void in
                //Do some stuff
            }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
            
            drawingView.drawMode = DrawingView.ToolMode.reference
            
        } else {
            drawingView.drawMode = DrawingView.ToolMode.measure
            self.defineFeatureButton.isHidden = true
            self.setHeightButton.isEnabled = true
            self.setHeightButton.isHidden = false
        }
        
        highlightButton(sender)
    }
    
    
    @IBAction func pushSetHeightButton(_ sender : UIButton) {
        let drawingView = imageView as! DrawingView
        let height = drawingView.lineView.currentMeasure as NSNumber
        if (height.isEqual(to: 0.0)) {
            let alert = UIAlertController(title: "", message: "Please draw a vertical line to define the Feature's height", preferredStyle: .alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: "Ok", style: .cancel) { action -> Void in
                //Do some stuff
            }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
            //just in case
            if (drawingView.drawMode != DrawingView.ToolMode.measure) {
                //self.toolbarSegmentedControl.selectedSegmentIndex = DrawingView.ToolMode.Measure.rawValue
                drawingView.drawMode = DrawingView.ToolMode.measure
            }
        } else {
            //set Feature.height = height
            if feature == nil {
                print("Feature is nil when attempting to set height")
            } else {
                feature!.height = height
            }
            print("height: ", height.floatValue)
            self.setHeightButton.isEnabled = false
            self.setHeightButton.isHidden = true
            self.setWidthButton.isEnabled = true
            self.setWidthButton.isHidden = false
            
            drawingView.drawMode = DrawingView.ToolMode.measure
            //Remove measurement line to force user to draw a new line to define the width
            drawingView.lineView.measure.removeAll(keepingCapacity: true)
            drawingView.lineView.currentMeasure = 0.0
            drawingView.lineView.setNeedsDisplay()
        }
        
        highlightButton(sender)
    }
    
    @IBAction func pushSetWdithButton(_ sender : UIButton) {
        let drawingView = imageView as! DrawingView
        let width = drawingView.lineView.currentMeasure as NSNumber
        if (width.isEqual(to: 0.0)) {
            let alert = UIAlertController(title: "", message: "Please draw a horizontal line to define the Feature's width", preferredStyle: .alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: "Ok", style: .cancel) { action -> Void in
                //Do some stuff
            }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
            //just in case
            if (drawingView.drawMode != DrawingView.ToolMode.measure) {
                drawingView.drawMode = DrawingView.ToolMode.measure
            }
        } else {
            //set Feature.width = width
            if feature == nil {
                print("Feature is nil when attempting to set type")
            } else {
                feature!.width = width
            }
            print("width: ",width.floatValue)
            self.setWidthButton.isEnabled = false
            self.setWidthButton.isHidden = true
            
            let nf = NumberFormatter()
            nf.numberStyle = NumberFormatter.Style.decimal
            let message = "Select a feature type for this feature of width: " +
                nf.string(from: feature!.width)! + " and height " +
                nf.string(from: feature!.height)!
            
            let alert = UIAlertController(
                title: "Define Feature type", message: message, preferredStyle: .alert
            )
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                self.managedContext.delete(self.feature!)
                let alert2 = UIAlertController(title: "", message: "Feature was deleted", preferredStyle: .alert)
                let cancelAction: UIAlertAction = UIAlertAction(title: "Ok", style: .cancel) { action -> Void in
                    //Do some stuff
                }
                alert2.addAction(cancelAction)
                self.present(alert2, animated: true, completion: nil)
            }
            alert.addAction(cancelAction)
            
            // Add buttons the alert action
            for type in possibleFeatureTypes {
                let nextAction: UIAlertAction = UIAlertAction(title: type, style: .default) { action -> Void in
                    //save Feature.type as type
                    if self.feature == nil {
                        print("Feature is nil when attempting to set type")
                    } else {
                        self.feature!.type = type
                    }
                }
                alert.addAction(nextAction)
            }
            self.present(alert, animated: true, completion: nil)
            
            // Manage UI components
            self.defineFeatureButton.isEnabled = true
            self.defineFeatureButton.isHidden = false
            self.setHeightButton.isHidden = true
            
            //Re-enable all other buttons when Feature definition is complete
            self.addDipMeterPointButton.isHidden = false
            self.eraseButton.isHidden = false
            self.measureButton.isHidden = false
            self.measureReferenceButton.isHidden = false
            self.faciesButton.isHidden = false
            self.textButton.isHidden = false
            self.drawButton.isHidden = false
            
            // Remove measurement line
            drawingView.lineView.measure.removeAll(keepingCapacity: true)
            drawingView.lineView.currentMeasure = 0.0
            drawingView.lineView.setNeedsDisplay()
        }
    }
    
    @IBAction func unwindToDrawing (_ segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func doMeasureDipAndStrike(_ sender: UIButton) {
        let ctrler = self.storyboard?.instantiateViewController(withIdentifier: "OrientationController") as! OrientationController
        
        ctrler.modalPresentationStyle = UIModalPresentationStyle.popover
        ctrler.popoverPresentationController?.sourceView = sender.forFirstBaselineLayout
        ctrler.popoverPresentationController?.sourceRect = sender.bounds
        ctrler.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.any
        let size = ctrler.view.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        ctrler.preferredContentSize = size
        
        ctrler.drawingViewController = self
        ctrler.currentButton = curButton
        
        self.present(ctrler, animated: true, completion: nil)
        
        highlightButton(sender)
    }
    
    @IBAction func doSendMail(_ sender: AnyObject) {
        var filename: URL
        var formatUserName : String
        
        let drawingView = imageView as! DrawingView
        let scale = drawingView.getScale()
        if(scale.defined) {
            detailedImage!.scale = scale.scale as NSNumber?
        }
        
        //UIImageWriteToSavedPhotosAlbum(imageView.image!, nil, nil, nil)
        
        if( detailedImage!.scale == nil || detailedImage!.scale! == 0 ||
            !MFMailComposeViewController.canSendMail()
        ){
            let alert = UIAlertController(title: "", message: "Need to establish a reference before sending it in 3D", preferredStyle: .alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .cancel) { action -> Void in
                //Do some stuff
            }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        } else {
        
            /*if( format == 0 ) {
            var exporter = ExportAsShapeFile(detailedImage: detailedImage!, faciesCatalog: faciesCatalog)
            filename = exporter.export()
            formatUserName = "Shape"
            } else {*/
            let exporter = ExportAsGocadFile(detailedImage: detailedImage!, faciesCatalog: faciesCatalog)
            filename = exporter.export() as URL
            formatUserName = "Gocad"
            //}
            
            var fileData = Data()
            do {
                try fileData = Data(contentsOf: URL(fileURLWithPath: filename.path), options: NSData.ReadingOptions.mappedIfSafe)
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
                detailedImage!.imageData()! as Data, mimeType: "impage/jpeg", fileName: detailedImage!.name + ".jpg"
            )
            
            mailComposer.setToRecipients([String]())
            mailComposer.mailComposeDelegate = self
            
            present(mailComposer, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        print(result)
        controller.dismiss(animated: true, completion: nil)
    }

    @IBAction func solidFillButtonPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let drawingView = imageView as! DrawingView
        drawingView.lineView.drawPolygon = sender.isSelected
        drawingView.lineView.computePolygon()
        drawingView.lineView.setNeedsDisplay()
    }
    
    @IBAction func editSelectSegmentedControllerChanged(_ sender: UISegmentedControl) {
        
        let drawingView = imageView as! DrawingView
        if( sender.selectedSegmentIndex == 1 ) {
            drawingView.drawMode = DrawingView.ToolMode.select
        } else {
            drawingView.drawMode = DrawingView.ToolMode.draw
        }
    }
}


