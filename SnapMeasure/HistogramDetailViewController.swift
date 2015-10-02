//
//  HistogramDetailViewController.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 6/22/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit


class HistogramDetailViewController: UIViewController, HistogramCreationDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var histogramView: HistogramView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var xLabel: UILabel!
    @IBOutlet weak var yLabel: UILabel!
    
    var titleLabelText  = "Title"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        histogramView.hidden = true
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
        
        let doubleTap = UITapGestureRecognizer(target: self, action: "doubleTappedLabel:")
        doubleTap.numberOfTapsRequired = 2
        titleLabel.addGestureRecognizer(doubleTap)
    }
    
    override func viewWillTransitionToSize(size: CGSize,
        withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            // willRotateToInterfaceOrientation code goes here
            coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
                // willAnimateRotationToInterfaceOrientation code goes here
                super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
                
                }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                    // didRotateFromInterfaceOrientation goes here
                    self.histogramView.setNeedsDisplay()
            })
    }
    
    func doubleTappedLabel(sender: AnyObject) { // sender is doubleTap
        let label = (sender as! UITapGestureRecognizer).view as! UILabel
        let textFeild = UITextField(frame: label.bounds)
        textFeild.text = label.text
        textFeild.textAlignment = NSTextAlignment.Center
        textFeild.textColor = label.textColor
        textFeild.font = label.font
        textFeild.backgroundColor = UIColor.whiteColor()
        textFeild.delegate = self
        textFeild.becomeFirstResponder() //open keyboard when
        label.userInteractionEnabled = false
        label.addSubview(textFeild)
        
    }
    
    func drawHistogram(numBins: Int, features: [FeatureObject], sortedBy: String) {
        let barHeights : [Int]
        let xAxisScale : [AnyObject]
        if sortedBy.isEqual("Type") {
            barHeights = self.getBarHeightsForSortingByType(features)
            xAxisScale = possibleFeatureTypes
            xLabel.text = "Type"
        } else if sortedBy.isEqual("Width"){
            let result = getBarHeightsForSortingByWidth(numBins, features: features)
            barHeights = result.barHeights
            xAxisScale = result.scale
            xLabel.text = "Width (m)"
        } else if sortedBy.isEqual("Height"){
            let result = getBarHeightsForSortingByHeight(numBins, features: features)
            barHeights = result.barHeights
            xAxisScale = result.scale
            xLabel.text = "Height (m)"
        } else {
            let e = NSException(name: "InvalidFeatureSortingType", reason: ("Sorted By: "+sortedBy), userInfo: nil)
            e.raise()
            xAxisScale = []
            barHeights = []
        }
        
        histogramView.initAttributes(barHeights, xAxisScale: xAxisScale)
        histogramView.hidden = false
        histogramView.setNeedsDisplay()
        
        titleLabel.userInteractionEnabled = true
        titleLabel.text = titleLabelText
        titleLabel.textColor = UIColor.lightGrayColor()
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.hidden = false
        titleLabel.font = UIFont.boldSystemFontOfSize(titleLabel.frame.height*4/5)
        titleLabel.adjustsFontSizeToFitWidth = true
        
        xLabel.textColor = UIColor.darkGrayColor()
        xLabel.textAlignment = NSTextAlignment.Center
        xLabel.hidden = false
        xLabel.font = UIFont.systemFontOfSize(xLabel.frame.height*4/5)
        xLabel.adjustsFontSizeToFitWidth = true
        
        
        yLabel.textColor = UIColor.darkGrayColor()
        yLabel.textAlignment = NSTextAlignment.Center
        yLabel.hidden = false
        yLabel.text = "# of Features"
        yLabel.font = UIFont.systemFontOfSize(yLabel.frame.height*4/5)
        yLabel.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
        
    }
    
    //Mark: - UITextFeildDelegate Methods
    func textFieldDidEndEditing(textField: UITextField) {
        let label = textField.superview as! UILabel
        label.text = textField.text
        label.textColor = UIColor.darkGrayColor()
        label.userInteractionEnabled = true
        textField.removeFromSuperview()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    
    func getBarHeightsForSortingByType(features: [FeatureObject]) -> [Int]{
        //global var possibleFeatureTypes = ["Channel","Lobe","Canyon", "Dune","Bar","Levee"]
        var barHeights = [Int](count: possibleFeatureTypes.count, repeatedValue: 0)
        for feature in features {
            let index = possibleFeatureTypes.indexOf(feature.type)! //feature.type should always be found in possibleFeatureTypes
            barHeights[index] = barHeights[index] + 1
        }
        return barHeights
    }
    
    func getBarHeightsForSortingByWidth(numBins: Int, features: [FeatureObject]) -> (barHeights: [Int], scale: [Double]) {
        var barHeights = [Int](count: numBins, repeatedValue: 0)
        if( features.count == 0 ) {
            return (barHeights, [0.0])
        }
        var maxValue = features[0].width.floatValue
        var minValue = features[0].width.floatValue
        for var i=1 ; i < features.count; i++  {
            minValue = min(minValue, features[i].width.floatValue)
            maxValue = max(maxValue, features[i].width.floatValue)
        }
        let delta = maxValue - minValue
        let binSize = delta/Float(numBins)
        for var i = 0; i < features.count; i++  {
            var bin = Int(floor((features[i].width.floatValue-minValue)/binSize)+0.5) //feature belongs in bin if binLeast < f.w <= binMost
            bin = max(bin,0)
            bin = min(bin, numBins-1)
            barHeights[bin] = barHeights[bin] + 1
        }
        var scale = [Double]()
        for var k = 0; k <= numBins; k++ {
            scale.append(Double(binSize*Float(k)+minValue))
        }
        
        return (barHeights, scale)
    }
    
    func getBarHeightsForSortingByHeight(numBins: Int, features: [FeatureObject]) -> (barHeights: [Int], scale: [Double]) {
        var barHeights = [Int](count: numBins, repeatedValue: 0)
        if( features.count == 0 ) {
            return (barHeights, [0.0])
        }
        var maxValue = features[0].height.floatValue
        var minValue = features[0].height.floatValue
        for var i=1 ; i < features.count; i++  {
            minValue = min(minValue, features[i].height.floatValue)
            maxValue = max(maxValue, features[i].height.floatValue)
        }
        let delta = maxValue - minValue
        let binSize = delta/Float(numBins)
        for var i = 0; i < features.count; i++  {
            var bin = Int(floor((features[i].height.floatValue-minValue)/binSize)+0.5) //feature belongs in bin if binLeast < f.w <= binMost
            bin = max(bin,0)
            bin = min(bin, numBins-1)
            barHeights[bin] = barHeights[bin] + 1
        }
        var scale = [Double]()
        for var k = 0; k <= numBins; k++ {
            scale.append(Double(binSize*Float(k)+minValue))
        }
        
        return (barHeights, scale)
    }

}

class HistogramView : UIView {
    var barHeights : [Int]?
    var xScaleLables : [AnyObject]?
    var xScalePoints : [CGFloat]?
    var maxBarHeight : CGFloat?
    var yScalePoints: [CGFloat]?
    let tickLength : CGFloat = 10
    
    var initialized = false
    var axisWidth : CGFloat = 3
    var tickWidth : CGFloat = 2
    var font = UIFont.systemFontOfSize(20)
    
    func initAttributes(barHeights: [Int], xAxisScale: [AnyObject]) {
        self.barHeights = barHeights
        self.xScaleLables = xAxisScale
        self.maxBarHeight = CGFloat(barHeights.maxElement()!)
        self.xScalePoints = []
        self.yScalePoints = []
        
        self.initialized = true
    }
    
    override func drawRect(rect: CGRect) {
        if (initialized) {
            let context = UIGraphicsGetCurrentContext()!
            CGContextSetStrokeColorWithColor(context, UIColor.darkGrayColor().CGColor)

            let adjust = font.pointSize/2
            let axisRect = CGRect(x: rect.origin.x+50, y: rect.origin.y+adjust, width: rect.width-100, height: rect.height-50-adjust)
            self.drawXAxis(axisRect, context: context)
            self.drawYAxis(axisRect, context: context)
            CGContextStrokePath(context)
        
            CGContextSetFillColorWithColor(context, UIColor(red: 0, green: 122/255, blue: 1, alpha: 1).CGColor)
            self.drawBars(context)
        
            CGContextStrokePath(context)
        }
    }
    
    func drawBars(context: CGContext) {
        for var i = 0; i < barHeights!.count; i++ {
            let x1 = xScalePoints![i]
            let x2 = xScalePoints![i+1]
            let y1 = yScalePoints![0]-axisWidth/2
            let y2 = yScalePoints![barHeights![i]]
            
            let width = x2-x1
            let xSpace = width/10
            
            
            let barRect = CGRect(x: x1+xSpace, y: y1, width: width-xSpace*2, height: y2-y1)
            CGContextFillRect(context, barRect)
        }
    }
    
    func drawYAxis (rect: CGRect, context: CGContext) {
        CGContextSetLineWidth(context, axisWidth)
        CGContextMoveToPoint(context, rect.origin.x, rect.origin.y-2)
        CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y+rect.height+2)
        CGContextStrokePath(context)
        
        CGContextSetLineWidth(context, tickWidth)
        self.drawYScale(rect.origin.y+rect.height, endY: rect.origin.y, x: rect.origin.x, context: context)
    }
    
    func drawYScale (startY: CGFloat, endY: CGFloat, x: CGFloat, context: CGContext) {
        //define scale from bottom to the top, dy will be negative
        let dy = (endY - startY)/maxBarHeight!
        
        //used to format and display the labels
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByClipping
        paragraphStyle.alignment = NSTextAlignment.Center
        
        let labelAttributes = [ NSFontAttributeName: font,
            NSForegroundColorAttributeName: UIColor.darkGrayColor(),
            NSParagraphStyleAttributeName: paragraphStyle
        ]
        
        var ticksSkipped : CGFloat = 0
        if abs(dy) < font.pointSize*2 {
            ticksSkipped = floor(font.pointSize*2/abs(dy))
        }
        
        var yPos : CGFloat = startY
        
        let numFormatter = NSNumberFormatter()
        numFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        numFormatter.maximumFractionDigits = 0
        yScalePoints!.removeAll(keepCapacity: false)
        for var i : CGFloat = 0; i <= maxBarHeight; i = i + 1 {
            
            //draw tick mark
            CGContextMoveToPoint(context, x, yPos)
            CGContextAddLineToPoint(context, x-tickLength, yPos)
            yScalePoints!.append(yPos)
            
            if ticksSkipped == 0 {
                let label = numFormatter.stringFromNumber(i)!
            
                let attributedLabel = NSMutableAttributedString(string: label, attributes: labelAttributes)
            
                let labelSize = attributedLabel.size()
                let textRect = CGRect(origin: CGPoint(x: x-tickLength-font.pointSize, y: yPos-labelSize.height/2), size: labelSize)
                attributedLabel.drawInRect(textRect)
            } else if (i%(ticksSkipped+1)) == 0 {
                let label = numFormatter.stringFromNumber(i)!
                
                let attributedLabel = NSMutableAttributedString(string: label, attributes: labelAttributes)
                
                let labelSize = attributedLabel.size()
                let textRect = CGRect(origin: CGPoint(x: x-tickLength-font.pointSize, y: yPos-labelSize.height/2), size: labelSize)
                attributedLabel.drawInRect(textRect)
            }
            
            yPos = yPos + dy
            
        }
        
    }
    
    func drawXAxis (rect: CGRect, context : CGContext){
        //draw x axis
        CGContextSetLineWidth(context, axisWidth)
        CGContextMoveToPoint(context, rect.origin.x, rect.origin.y+rect.height)
        CGContextAddLineToPoint(context, rect.origin.x + rect.width+2, rect.origin.y+rect.height)
        CGContextStrokePath(context)
        
        CGContextSetLineWidth(context, tickWidth)
        self.drawXScale(rect.origin.x, endX: rect.origin.x+rect.width, y: rect.origin.y+rect.height, context: context)
        CGContextStrokePath(context)
    }
    
    func drawXScale (startX : CGFloat, endX : CGFloat, y: CGFloat, context: CGContext) {
        var StringsNotNumbers: Bool
        let numSections = CGFloat(barHeights!.count)
        let dx = (endX-startX)/numSections
        
        //this section gets the smallest font used and starts the formatting of the labels
        var attributedLabels : [NSMutableAttributedString] = []
        if xScaleLables![0].isKindOfClass(NSString) {
            StringsNotNumbers = true
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = NSLineBreakMode.ByClipping
            paragraphStyle.alignment = NSTextAlignment.Center
            
            for object in xScaleLables! {
                let label = object as! String
                
                let labelAttributes = [ NSFontAttributeName: font,
                    NSForegroundColorAttributeName: UIColor.darkGrayColor(),
                    NSParagraphStyleAttributeName: paragraphStyle
                ]
                
                let attributedLabel = NSMutableAttributedString(string: label, attributes: labelAttributes)
                let range = NSRange(location: 0,length: attributedLabel.length)
                var labelSize = attributedLabel.size()
                while labelSize.width > dx { //need the tick label width to be less than the distance between two ticks
                    font = UIFont.systemFontOfSize(font.pointSize - 2)
                    attributedLabel.removeAttribute(NSFontAttributeName, range: range)
                    attributedLabel.addAttribute(NSFontAttributeName, value: font, range: range)
                    labelSize = attributedLabel.size()
                }
                
                attributedLabels.append(attributedLabel)
            }
            
        } else {
            StringsNotNumbers = false
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = NSLineBreakMode.ByClipping
            paragraphStyle.alignment = NSTextAlignment.Center
            
            let numFormatter = NSNumberFormatter()
            numFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
            numFormatter.usesSignificantDigits = true
            numFormatter.maximumSignificantDigits = 3
            numFormatter.minimumSignificantDigits = 3
            for object in xScaleLables! {
                let labelNum = object as! NSNumber
                let label = numFormatter.stringFromNumber(labelNum)!
                
                let labelAttributes = [ NSFontAttributeName: font,
                    NSForegroundColorAttributeName: UIColor.darkGrayColor(),
                    NSParagraphStyleAttributeName: paragraphStyle
                ]
                
                let attributedLabel = NSMutableAttributedString(string: label, attributes: labelAttributes)
                
                attributedLabels.append(attributedLabel)
            }
        }
        
        //draw the Scale
        xScalePoints!.removeAll(keepCapacity: false)
        var i = 0
        for var xPos = startX; xPos <= endX+dx/2; xPos = xPos+dx {
            //draw tick mark
            CGContextMoveToPoint(context, xPos, y)
            CGContextAddLineToPoint(context, xPos, y+tickLength)
            xScalePoints!.append(xPos)
            
            //draw ticklabel
            if( i < attributedLabels.count ) {
                if StringsNotNumbers  {
                    let attributedLabel = attributedLabels[i]
                    let range = NSRange(location: 0,length: attributedLabel.length)
                    attributedLabel.removeAttribute(NSFontAttributeName, range: range)
                    attributedLabel.addAttribute(NSFontAttributeName, value: font, range: range)
                    
                    let labelSize = attributedLabel.size()
                    let textRect = CGRect(origin: CGPoint(x: xPos+dx/2-labelSize.width/2, y: y+tickLength+5), size: labelSize)
                    attributedLabel.drawInRect(textRect)
                } else  {
                    let attributedLabel = attributedLabels[i]
                    
                    let labelSize = attributedLabel.size()
                    let textRect = CGRect(origin: CGPoint(x: xPos-labelSize.width/2, y: y+tickLength+5), size: labelSize)
                    attributedLabel.drawInRect(textRect)
                    
                }
            }
            i++
        }
        
    }
}