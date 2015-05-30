//
//  CameraViewController.swift
//  SnapMeasure
//
//  Created by next-shot on 5/21/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import ImageIO

struct ImageInfo {
    var focalLength : Float = 0.0
    var xDimension : Int = 0
    var yDimension : Int = 0
    var subjectDistance : Float = 0.0
}

extension AVCaptureVideoOrientation {
    var uiInterfaceOrientation: UIInterfaceOrientation {
        get {
            switch self {
            case .LandscapeLeft:        return .LandscapeLeft
            case .LandscapeRight:       return .LandscapeRight
            case .Portrait:             return .Portrait
            case .PortraitUpsideDown:   return .PortraitUpsideDown
            }
        }
    }
    
    init(ui:UIInterfaceOrientation) {
        switch ui {
        case .LandscapeRight:       self = .LandscapeRight
        case .LandscapeLeft:        self = .LandscapeLeft
        case .Portrait:             self = .Portrait
        case .PortraitUpsideDown:   self = .PortraitUpsideDown
        default:                    self = .Portrait
        }
    }
}

class CameraViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var image : UIImage?
    var imageInfo = ImageInfo()
    
    @IBOutlet weak var previewView: UIImageView!
    @IBOutlet var superPreviewView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPresetPhoto
        
        var backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        var error: NSError?
        var input = AVCaptureDeviceInput(device: backCamera, error: &error)
        
        if error == nil && captureSession!.canAddInput(input) {
            captureSession!.addInput(input)
            
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            if captureSession!.canAddOutput(stillImageOutput) {
                captureSession!.addOutput(stillImageOutput)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                if let connection = previewLayer?.connection {
                    connection.videoOrientation = AVCaptureVideoOrientation(ui:UIApplication.sharedApplication().statusBarOrientation)

                }
                previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                previewView.layer.addSublayer(previewLayer)
                
                captureSession!.startRunning()
            }
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer!.frame = previewView.bounds
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if( segue.identifier == "toDrawingView" ) {
            let destinationVC = segue.destinationViewController as? DrawingViewController
            if( destinationVC != nil ) {
                destinationVC!.image = image
                destinationVC!.imageInfo = imageInfo
            }
        }
    }

    
    @IBAction func takePhoto(sender: AnyObject) {
        if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo) {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                if (sampleBuffer != nil) {
                    var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    var dataProvider = CGDataProviderCreateWithCFData(imageData)
                    var cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, kCGRenderingIntentDefault)
                    
                    var image = UIImage(CGImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.Right)
                    self.image = image
                    
                    let exifAttachUnManaged = CMGetAttachment(
                        sampleBuffer, kCGImagePropertyExifDictionary, nil
                    )
                    //let exifAttach = exifAttachUnManaged.takeUnretainedValue() as! CFDictionaryRef
                    let exifAttach = exifAttachUnManaged.takeUnretainedValue() as? NSDictionary
                    if( exifAttach != nil ) {
                        let focalLengthObj: AnyObject? = exifAttach![kCGImagePropertyExifFocalLength as NSString]
                        let flNumber = focalLengthObj as? NSNumber
                        if( flNumber != nil ) {
                            let focalLength = flNumber!.floatValue
                            self.imageInfo.focalLength = focalLength/1000.0 // (in meters)
                        }
                        let pixelXObj: AnyObject? = exifAttach![kCGImagePropertyExifPixelXDimension as NSString]
                        let pxNumber = pixelXObj as? NSNumber
                        if( pxNumber != nil ) {
                            let px = pxNumber!.intValue
                            self.imageInfo.xDimension = Int(px)
                        }
                        let pixelYObj: AnyObject? = exifAttach![kCGImagePropertyExifPixelYDimension as NSString]
                        let pyNumber = pixelYObj as? NSNumber
                        if( pyNumber != nil ) {
                            let py = pyNumber!.intValue
                            self.imageInfo.yDimension = Int(py)
                        }
                        let distObj: AnyObject? = exifAttach![kCGImagePropertyExifSubjectDistRange as NSString]
                        let diNumber = distObj as? NSNumber
                        if( diNumber != nil ) {
                            let di = diNumber!.floatValue
                            self.imageInfo.subjectDistance = di
                        }
                    }
                    
                    self.captureSession!.stopRunning()
                    
                    self.performSegueWithIdentifier("toDrawingView", sender: nil)
                }
            })
        }
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.rawValue);
    }
    
     override func viewWillTransitionToSize(size: CGSize,
        withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            
            // willRotateToInterfaceOrientation code goes here
            
            coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
                // willAnimateRotationToInterfaceOrientation code goes here
                super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
                
                }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                    
                    // didRotateFromInterfaceOrientation goes here
                    if let connection = self.previewLayer?.connection {
                        connection.videoOrientation = AVCaptureVideoOrientation(ui:UIApplication.sharedApplication().statusBarOrientation)
                        
                        /**
                        switch connection.videoOrientation {
                        case AVCaptureVideoOrientation.LandscapeLeft: NSLog("LandscapeLeft");
                        case AVCaptureVideoOrientation.LandscapeRight: NSLog("LandscapeRight");
                        case AVCaptureVideoOrientation.Portrait: NSLog("Portrait");
                        case AVCaptureVideoOrientation.PortraitUpsideDown: NSLog("LandscapeLeft");
                        } **/

                    }
                    self.previewLayer!.frame = self.previewView.bounds

                    self.previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                    NSLog("Omg Rotation!")

            })

            /**
            [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                // willAnimateRotationToInterfaceOrientation code goes here
                [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
                if(self.showsShadow){
                CGPathRef oldShadowPath = self.centerContainerView.layer.shadowPath;
                if(oldShadowPath){
                CFRetain(oldShadowPath);
                }
                
                [self updateShadowForCenterView];
                
                if (oldShadowPath) {
                [self.centerContainerView.layer addAnimation:((^ {
                CABasicAnimation *transition = [CABasicAnimation animationWithKeyPath:@"shadowPath"];
                transition.fromValue = (__bridge id)oldShadowPath;
                transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                return transition;
                })()) forKey:@"transition"];
                CFRelease(oldShadowPath);
                }
                }
                
                } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                // didRotateFromInterfaceOrientation goes here (nothing for now)
                
                }];
**/
        
    }

    /**
    func willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
    {
    [[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)toInterfaceOrientation];
    } **/
    
    @IBAction func closeWindow(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}


