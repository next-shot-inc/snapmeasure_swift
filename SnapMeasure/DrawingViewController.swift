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
    let count = 5
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("colorCell", forIndexPath: indexPath) as! UITableViewCell
        cell.accessoryType = UITableViewCellAccessoryType.Checkmark
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        var cell = tableView.dequeueReusableCellWithIdentifier("colorCell", forIndexPath: indexPath) as! UITableViewCell
        cell.accessoryType = UITableViewCellAccessoryType.None
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("colorCell", forIndexPath: indexPath) as! UITableViewCell
        //let hue = CGFloat(indexPath.row)/CGFloat(count)
        //cell.contentView.backgroundColor =
            //UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        //cell.textLabel?.backgroundColor = cell.contentView.backgroundColor
        cell.textLabel?.text = String(indexPath.row)
        return cell
    }

}

class DrawingViewController: UIViewController {
    
    @IBOutlet weak var colButton: UIButton!
    @IBOutlet weak var toolbarSegmentedControl: UISegmentedControl!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var referenceSizeTextField: UITextField!
    @IBOutlet weak var colorPickerView: UIPickerView!
    
    var image : UIImage?
    var imageInfo = ImageInfo()
    var colorPickerCtrler = ColorPickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let recognizer = UITapGestureRecognizer(target: self, action: Selector("handleTap:"))
        self.view.addGestureRecognizer(recognizer)
        
        colorPickerView.delegate = colorPickerCtrler
        colorPickerView.dataSource = colorPickerCtrler
        
        colButton.setTitle(" ", forState: UIControlState.Normal)
        colButton.backgroundColor = UIColor.blackColor()
        colorPickerCtrler.colorButton = colButton
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        imageView.image = image
        imageView.setNeedsDisplay()

        let drawingView = imageView as! DrawingView
        drawingView.imageInfo = imageInfo
    }
    
    @IBAction func toolChanged(sender: AnyObject) {
        let drawingView = imageView as! DrawingView
        drawingView.drawMode =
            DrawingView.ToolMode(rawValue: toolbarSegmentedControl.selectedSegmentIndex)!
        
        if( drawingView.drawMode == DrawingView.ToolMode.Reference ) {
            referenceSizeTextField.keyboardType = UIKeyboardType.DecimalPad
        } else if( drawingView.drawMode == DrawingView.ToolMode.Draw ) {
            referenceSizeTextField.keyboardType = UIKeyboardType.Default
        }
    }
    
    func handleTap(recognizer: UITapGestureRecognizer) {
        referenceSizeTextField.resignFirstResponder()
        let drawingView = imageView as! DrawingView
        
        if( drawingView.drawMode == DrawingView.ToolMode.Reference ) {
            var nf = NSNumberFormatter()
            var ns = nf.numberFromString(referenceSizeTextField.text)
            if( ns != nil ) {
                drawingView.lineView.refMeasureValue = ns!.floatValue
            }
        } else if( drawingView.drawMode == DrawingView.ToolMode.Draw ) {
            drawingView.lineView.currentLineName = referenceSizeTextField.text
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
    
    @IBAction func pushColButton(sender: AnyObject) {
        colorPickerView.hidden = !colorPickerView.hidden
    }
    
    @IBAction func closeWindow(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}



