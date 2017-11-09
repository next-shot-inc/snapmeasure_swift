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
    
    var rotatedYLabel : UILabel!
    var histogramData : HistogramData?
    var titleLabelText  = "Title (Click to Edit)"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        histogramView.isHidden = false
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(HistogramDetailViewController.doubleTappedLabel(_:)))
        doubleTap.numberOfTapsRequired = 2
        titleLabel.addGestureRecognizer(doubleTap)
        
        rotatedYLabel = UILabel()
        rotatedYLabel.isHidden = true
        self.view.addSubview(rotatedYLabel)
        
        // Setup initial histogram with features sorted by type
        histogramData = HistogramData()
        drawHistogram(possibleFeatureTypes.count, features: histogramData!.getFeatures(), sortedBy: "Type")
    }
    
    @objc func doubleTappedLabel(_ sender: AnyObject) { // sender is doubleTap
        let label = (sender as! UITapGestureRecognizer).view as! UILabel
        let textField = UITextField(frame: label.bounds)
        textField.text = label.text
        textField.textAlignment = NSTextAlignment.center
        textField.textColor = label.textColor
        textField.font = label.font
        textField.backgroundColor = UIColor.white
        textField.delegate = self
        textField.becomeFirstResponder() //open keyboard when
        label.isUserInteractionEnabled = false
        label.addSubview(textField)
        
    }
    
    func drawHistogram(_ numBins: Int, features: [FeatureObject], sortedBy: String) {
        let barHeights : [Int]
        let xAxisScale : [AnyObject]
        if sortedBy.isEqual("Type") {
            barHeights = self.getBarHeightsForSortingByType(features)
            xAxisScale = possibleFeatureTypes as [AnyObject]
            xLabel.text = "Type"
        } else if sortedBy.isEqual("Width"){
            let result = getBarHeightsForSortingByWidth(numBins, features: features)
            barHeights = result.barHeights
            xAxisScale = result.scale as [AnyObject]
            xLabel.text = "Width (m)"
        } else if sortedBy.isEqual("Height"){
            let result = getBarHeightsForSortingByHeight(numBins, features: features)
            barHeights = result.barHeights
            xAxisScale = result.scale as [AnyObject]
            xLabel.text = "Height (m)"
        } else {
            let e = NSException(name: NSExceptionName(rawValue: "InvalidFeatureSortingType"), reason: ("Sorted By: "+sortedBy), userInfo: nil)
            e.raise()
            xAxisScale = []
            barHeights = []
        }
        
        histogramView.initAttributes(barHeights, xAxisScale: xAxisScale)
        histogramView.isHidden = false
        histogramView.setNeedsDisplay()
        
        titleLabel.isUserInteractionEnabled = true
        titleLabel.text = titleLabelText
        titleLabel.textColor = UIColor.lightGray
        titleLabel.textAlignment = NSTextAlignment.center
        titleLabel.isHidden = false
        titleLabel.font = UIFont.boldSystemFont(ofSize: titleLabel.frame.height*4/5)
        titleLabel.adjustsFontSizeToFitWidth = true
        
        xLabel.textColor = UIColor.darkGray
        xLabel.textAlignment = NSTextAlignment.center
        xLabel.isHidden = false
        xLabel.font = UIFont.systemFont(ofSize: xLabel.frame.height*4/5)
        xLabel.adjustsFontSizeToFitWidth = true
        
        // Manually place the true Y Axis label (rotated 90 deg)
        rotatedYLabel.textColor = UIColor.darkGray
        rotatedYLabel.textAlignment = NSTextAlignment.center
        rotatedYLabel.isHidden = false
        rotatedYLabel.text = "# of Features"
        rotatedYLabel.font = UIFont.systemFont(ofSize: yLabel.frame.height*4/5)
        let t = rotatedYLabel.text! as NSString
        let size = t.size(withAttributes: [NSAttributedStringKey.font: rotatedYLabel.font])
        rotatedYLabel.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height);
        rotatedYLabel.center = CGPoint(x: 0, y: 0)
        //rotatedYLabel.layer.anchorPoint = CGPointMake(size.width/2, size.height/2)
        rotatedYLabel.transform =
            CGAffineTransform(rotationAngle: CGFloat(-Double.pi/2)).concatenating(CGAffineTransform(translationX: yLabel.frame.origin.x, y: yLabel.frame.origin.y)
        )
        yLabel.isHidden = true
        
    }
    
    //Mark: - UITextFeildDelegate Methods
    func textFieldDidEndEditing(_ textField: UITextField) {
        let label = textField.superview as! UILabel
        label.text = textField.text
        label.textColor = UIColor.darkGray
        label.isUserInteractionEnabled = true
        textField.removeFromSuperview()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    
    func getBarHeightsForSortingByType(_ features: [FeatureObject]) -> [Int]{
        //global var possibleFeatureTypes = ["Channel","Lobe","Canyon", "Dune","Bar","Levee"]
        var barHeights = [Int](repeating: 0, count: possibleFeatureTypes.count)
        for feature in features {
            let index = possibleFeatureTypes.index(of: feature.type)! //feature.type should always be found in possibleFeatureTypes
            barHeights[index] = barHeights[index] + 1
        }
        return barHeights
    }
    
    func getBarHeightsForSortingByWidth(_ numBins: Int, features: [FeatureObject]) -> (barHeights: [Int], scale: [Double]) {
        var barHeights = [Int](repeating: 0, count: numBins)
        if( features.count == 0 ) {
            return (barHeights, [0.0])
        }
        var maxValue = features[0].width.floatValue
        var minValue = features[0].width.floatValue
        for i in 1 ..< features.count {
            minValue = min(minValue, features[i].width.floatValue)
            maxValue = max(maxValue, features[i].width.floatValue)
        }
        var delta = maxValue - minValue
        if( delta == 0 ) {
            delta = 1
        }
        let binSize = delta/Float(numBins)
        for i in 0 ..< features.count  {
            var bin = Int(floor((features[i].width.floatValue-minValue)/binSize)+0.5) //feature belongs in bin if binLeast < f.w <= binMost
            bin = max(bin,0)
            bin = min(bin, numBins-1)
            barHeights[bin] = barHeights[bin] + 1
        }
        var scale = [Double]()
        for k in 0 ... numBins {
            scale.append(Double(binSize*Float(k)+minValue))
        }
        
        return (barHeights, scale)
    }
    
    func getBarHeightsForSortingByHeight(_ numBins: Int, features: [FeatureObject]) -> (barHeights: [Int], scale: [Double]) {
        var barHeights = [Int](repeating: 0, count: numBins)
        if( features.count == 0 ) {
            return (barHeights, [0.0])
        }
        var maxValue = features[0].height.floatValue
        var minValue = features[0].height.floatValue
        for i in 1 ..< features.count  {
            minValue = min(minValue, features[i].height.floatValue)
            maxValue = max(maxValue, features[i].height.floatValue)
        }
        var delta = maxValue - minValue
        if( delta == 0 ) {
           delta = 1
        }
        let binSize = delta/Float(numBins)
        for i in 0 ..< features.count  {
            var bin = Int(floor((features[i].height.floatValue-minValue)/binSize)+0.5) //feature belongs in bin if binLeast < f.w <= binMost
            bin = max(bin,0)
            bin = min(bin, numBins-1)
            barHeights[bin] = barHeights[bin] + 1
        }
        var scale = [Double]()
        for k in  0 ... numBins {
            scale.append(Double(binSize*Float(k)+minValue))
        }
        
        return (barHeights, scale)
    }
    
    @IBAction func cancelAction(_ sender: AnyObject) {
        //self.dismissViewControllerAnimated(true, completion: nil)
        //self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        //self.splitViewController?.dismissViewControllerAnimated(true, completion: nil)
        //splitViewController?.performSegueWithIdentifier("unwindToMainFromSplit", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier == "toHistogramMasterView") {
            let destinationVC = segue.destination as? HistogramMasterViewController
            if( destinationVC != nil ) {
               destinationVC!.delegate = self
                destinationVC!.histogramData = self.histogramData
            }
        }
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
    
    func initAttributes(_ barHeights: [Int], xAxisScale: [AnyObject]) {
        self.barHeights = barHeights
        self.xScaleLables = xAxisScale
        self.maxBarHeight = CGFloat(barHeights.max()!)
        self.xScalePoints = []
        self.yScalePoints = []
        self.initialized = true
    }
    
    override func draw(_ rect: CGRect) {
        let font = UIFont.systemFont(ofSize: 20)

        if (initialized) {
            let context = UIGraphicsGetCurrentContext()!
            context.setStrokeColor(UIColor.darkGray.cgColor)

            let adjust = font.pointSize/2
            let axisRect = CGRect(x: rect.origin.x+50, y: rect.origin.y+adjust, width: rect.width-100, height: rect.height-50-adjust)
            self.drawXAxis(axisRect, context: context)
            self.drawYAxis(axisRect, context: context)
            context.strokePath()
        
            context.setFillColor(UIColor(red: 0, green: 122/255, blue: 1, alpha: 1).cgColor)
            self.drawBars(context)
        
            context.strokePath()
        } else {
            let context = UIGraphicsGetCurrentContext()!
            context.setStrokeColor(UIColor.lightGray.cgColor)
            context.setFillColor(UIColor.lightGray.cgColor)

            
            let adjust = font.pointSize/2
            let axisRect = CGRect(x: rect.origin.x+50, y: rect.origin.y+adjust, width: rect.width-100, height: rect.height-50-adjust)
            context.setLineWidth(axisWidth)
            context.move(to: CGPoint(x: axisRect.origin.x, y: axisRect.origin.y-2))
            context.addLine(to: CGPoint(x: axisRect.origin.x, y: axisRect.origin.y+axisRect.height+2))
            context.strokePath()
            
            //draw x axis
            context.setLineWidth(axisWidth)
            context.move(to: CGPoint(x: axisRect.origin.x, y: axisRect.origin.y+axisRect.height))
            context.addLine(to: CGPoint(x: axisRect.origin.x + axisRect.width+2, y: axisRect.origin.y+axisRect.height))
            context.strokePath()
            
            let fillRect = CGRect(x: axisRect.origin.x + 5, y: axisRect.origin.y - 5, width: axisRect.width-5, height: axisRect.height-5)
            context.fill(fillRect)
        }
    }
    
    func drawBars(_ context: CGContext) {
        for i in 0  ..< barHeights!.count {
            let x1 = xScalePoints![i]
            let x2 = xScalePoints![i+1]
            let y1 = yScalePoints![0]-axisWidth/2
            let y2 = yScalePoints![barHeights![i]]
            
            let width = x2-x1
            let xSpace = width/10
            
            
            let barRect = CGRect(x: x1+xSpace, y: y1, width: width-xSpace*2, height: y2-y1)
            context.fill(barRect)
        }
    }
    
    func drawYAxis (_ rect: CGRect, context: CGContext) {
        context.setLineWidth(axisWidth)
        context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y-2))
        context.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y+rect.height+2))
        context.strokePath()
        
        context.setLineWidth(tickWidth)
        self.drawYScale(rect.origin.y+rect.height, endY: rect.origin.y, x: rect.origin.x, context: context)
    }
    
    func drawYScale (_ startY: CGFloat, endY: CGFloat, x: CGFloat, context: CGContext) {
        //define scale from bottom to the top, dy will be negative
        let dy = (endY - startY)/maxBarHeight!
        
        //used to format and display the labels
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byClipping
        paragraphStyle.alignment = NSTextAlignment.center
        
        let font = UIFont.systemFont(ofSize: 20)
        
        let labelAttributes = [ NSAttributedStringKey.font: font,
            NSAttributedStringKey.foregroundColor: UIColor.darkGray,
            NSAttributedStringKey.paragraphStyle: paragraphStyle
        ]
        
        var ticksSkipped : CGFloat = 0
        if abs(dy) < font.pointSize*2 {
            ticksSkipped = floor(font.pointSize*2/abs(dy))
        }
        
        var yPos : CGFloat = startY
        
        let numFormatter = NumberFormatter()
        numFormatter.numberStyle = NumberFormatter.Style.decimal
        numFormatter.maximumFractionDigits = 0
        yScalePoints!.removeAll(keepingCapacity: false)
        for i in 0 ... Int(maxBarHeight!) {
            
            //draw tick mark
            context.move(to: CGPoint(x: x, y: yPos))
            context.addLine(to: CGPoint(x: x-tickLength, y: yPos))
            yScalePoints!.append(yPos)
            
            if ticksSkipped == 0 {
                let label = numFormatter.string(from: NSNumber(value: i))
            
                let attributedLabel = NSMutableAttributedString(string: label!, attributes: labelAttributes)
            
                let labelSize = attributedLabel.size()
                let textRect = CGRect(origin: CGPoint(x: x-tickLength-font.pointSize, y: yPos-labelSize.height/2), size: labelSize)
                attributedLabel.draw(in: textRect)
            } else if (CGFloat(i).truncatingRemainder(dividingBy: (ticksSkipped+1))) == 0 {
                let label = numFormatter.string(from: NSNumber(value: i))
                
                let attributedLabel = NSMutableAttributedString(string: label!, attributes: labelAttributes)
                
                let labelSize = attributedLabel.size()
                let textRect = CGRect(origin: CGPoint(x: x-tickLength-font.pointSize, y: yPos-labelSize.height/2), size: labelSize)
                attributedLabel.draw(in: textRect)
            }
            
            yPos = yPos + dy
            
        }
        
    }
    
    func drawXAxis (_ rect: CGRect, context : CGContext){
        //draw x axis
        context.setLineWidth(axisWidth)
        context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y+rect.height))
        context.addLine(to: CGPoint(x: rect.origin.x + rect.width+2, y: rect.origin.y+rect.height))
        context.strokePath()
        
        context.setLineWidth(tickWidth)
        self.drawXScale(rect.origin.x, endX: rect.origin.x+rect.width, y: rect.origin.y+rect.height, context: context)
        context.strokePath()
    }
    
    func drawXScale (_ startX : CGFloat, endX : CGFloat, y: CGFloat, context: CGContext) {
        var StringsNotNumbers: Bool
        let numSections = CGFloat(barHeights!.count)
        let dx = (endX-startX)/numSections
        
        var font = UIFont.systemFont(ofSize: 20)
        
        //this section gets the smallest font used and starts the formatting of the labels
        var attributedLabels : [NSMutableAttributedString] = []
        if xScaleLables![0].isKind(of: NSString.self) {
            StringsNotNumbers = true
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = NSLineBreakMode.byClipping
            paragraphStyle.alignment = NSTextAlignment.center
            
            for object in xScaleLables! {
                let label = object as! String
                
                let labelAttributes = [ NSAttributedStringKey.font: font,
                    NSAttributedStringKey.foregroundColor: UIColor.darkGray,
                    NSAttributedStringKey.paragraphStyle: paragraphStyle
                ]
                
                let attributedLabel = NSMutableAttributedString(string: label, attributes: labelAttributes)
                let range = NSRange(location: 0,length: attributedLabel.length)
                var labelSize = attributedLabel.size()
                while labelSize.width > dx { //need the tick label width to be less than the distance between two ticks
                    font = UIFont.systemFont(ofSize: font.pointSize - 2)
                    attributedLabel.removeAttribute(NSAttributedStringKey.font, range: range)
                    attributedLabel.addAttribute(NSAttributedStringKey.font, value: font, range: range)
                    labelSize = attributedLabel.size()
                }
                
                attributedLabels.append(attributedLabel)
            }
            
        } else {
            StringsNotNumbers = false
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = NSLineBreakMode.byClipping
            paragraphStyle.alignment = NSTextAlignment.center
            
            let numFormatter = NumberFormatter()
            numFormatter.numberStyle = NumberFormatter.Style.decimal
            numFormatter.usesSignificantDigits = true
            numFormatter.maximumSignificantDigits = 3
            numFormatter.minimumSignificantDigits = 0
            for object in xScaleLables! {
                let labelNum = object as! NSNumber
                let label = numFormatter.string(from: labelNum)!
                
                let labelAttributes = [ NSAttributedStringKey.font: font,
                    NSAttributedStringKey.foregroundColor: UIColor.darkGray,
                    NSAttributedStringKey.paragraphStyle: paragraphStyle
                ]
                
                let attributedLabel = NSMutableAttributedString(string: label, attributes: labelAttributes)
                var labelSize = attributedLabel.size()
                let range = NSRange(location: 0,length: attributedLabel.length)
                while labelSize.width > dx { //need the tick label width to be less than the distance between two ticks
                    font = UIFont.systemFont(ofSize: font.pointSize - 2)
                    attributedLabel.removeAttribute(NSAttributedStringKey.font, range: range)
                    attributedLabel.addAttribute(NSAttributedStringKey.font, value: font, range: range)
                    labelSize = attributedLabel.size()
                }
                
                attributedLabels.append(attributedLabel)
            }
        }
        
        //draw the Scale
        xScalePoints!.removeAll(keepingCapacity: false)
        var i = 0
        var xPos = startX
        while ( xPos <= endX+dx/2 )  {
            //draw tick mark
            context.move(to: CGPoint(x: xPos, y: y))
            context.addLine(to: CGPoint(x: xPos, y: y+tickLength))
            xScalePoints!.append(xPos)
            
            //draw ticklabel
            if( i < attributedLabels.count ) {
                if StringsNotNumbers  {
                    let attributedLabel = attributedLabels[i]
                    let range = NSRange(location: 0,length: attributedLabel.length)
                    attributedLabel.removeAttribute(NSAttributedStringKey.font, range: range)
                    attributedLabel.addAttribute(NSAttributedStringKey.font, value: font, range: range)
                    
                    let labelSize = attributedLabel.size()
                    let textRect = CGRect(origin: CGPoint(x: xPos+dx/2-labelSize.width/2, y: y+tickLength+5), size: labelSize)
                    attributedLabel.draw(in: textRect)
                } else  {
                    let attributedLabel = attributedLabels[i]
                    let range = NSRange(location: 0,length: attributedLabel.length)
                    attributedLabel.removeAttribute(NSAttributedStringKey.font, range: range)
                    attributedLabel.addAttribute(NSAttributedStringKey.font, value: font, range: range)
                    
                    let labelSize = attributedLabel.size()
                    let textRect = CGRect(origin: CGPoint(x: xPos-labelSize.width/2, y: y+tickLength+5), size: labelSize)
                    attributedLabel.draw(in: textRect)
                    
                }
            }
            i += 1
            xPos = xPos+dx
        }
        
    }
}
