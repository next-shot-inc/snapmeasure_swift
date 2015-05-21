//
//  DrawingViewController.swift
//  SnapMeasure
//
//  Created by next-shot on 5/21/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation

import UIKit

class DrawingViewController: UIViewController {
    
    @IBOutlet weak var toolbarSegmentedControl: UISegmentedControl!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var referenceSizeTextField: UITextField!
    var image : UIImage?
    var imageInfo = ImageInfo()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let recognizer = UITapGestureRecognizer(target: self, action: Selector("handleTap:"))
        self.view.addGestureRecognizer(recognizer)
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
    }
    
    func handleTap(recognizer: UITapGestureRecognizer) {
        referenceSizeTextField.resignFirstResponder()
        let drawingView = imageView as! DrawingView
        var nf = NSNumberFormatter()
        var ns = nf.numberFromString(referenceSizeTextField.text)
        if( ns != nil ) {
           drawingView.lineView.refMeasureValue = ns!.floatValue
        }
    }
    
    @IBAction func closeWindow(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}



