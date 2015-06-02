//
//  DrawingViewController.swift
//  SnapMeasure
//
//  Created by next-shot on 5/21/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation

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
    
    @IBOutlet weak var colButton: UIButton!
    @IBOutlet weak var toolbarSegmentedControl: UISegmentedControl!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var referenceSizeTextField: UITextField!
    @IBOutlet weak var colorPickerView: UIPickerView!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var typePickerView: UIPickerView!
    
    var image : UIImage?
    var imageInfo = ImageInfo()
    var colorPickerCtrler = ColorPickerController()
    var typePickerCtrler = TypePickerController()
    static var lineCount = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
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
        referenceSizeTextField.resignFirstResponder()
        colorPickerView.hidden = true
        typePickerView.hidden = true
        
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
    
    @IBAction func pushTypeButton(sender: AnyObject) {
        typePickerView.hidden = !typePickerView.hidden
        
        //let drawingView = imageView as! DrawingView
    }
    
    @IBAction func closeWindow(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}


