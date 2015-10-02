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
import CoreLocation

let CapturingStillImageContext = UnsafeMutablePointer<Void>()

struct ImageInfo {
    var focalLength : Float = 0.0
    var xDimension : Int = 0
    var yDimension : Int = 0
    var subjectDistance : Float = 0.0
    var longitude : Double? //represents a longitude value in degrees, positive values are east of the prime meridian
    var latitude : Double? //represents a latitude value in degrees, postive  values are north of the equator
    var compassOrienation : Double? //Degrees relative to north
    var altitude : Double?
    var date : NSDate = NSDate()
    var scale: Double? //in meters per point
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

extension UIImageOrientation {
    var uiInterfaceOrientation: UIInterfaceOrientation {
        get {
            switch self {
            case .Up:      return .Portrait
            case .Down:    return .PortraitUpsideDown
            case .Left:    return .LandscapeLeft
            case .Right:   return .LandscapeRight
            default:       return .Portrait
            }
        }
    }
    
    init(ui:UIInterfaceOrientation) {
        switch ui {
        case .LandscapeRight:       self = .Right;  break;
        case .LandscapeLeft:        self = .Left;   break;
        case .Portrait:             self = .Up;     break
        case .PortraitUpsideDown:   self = .Down;   break;
        default:                    self = .Up;     break;
        }
    }
}


extension UIImage {
    
    func fixOrientation() -> UIImage {
        
        // No-op if the orientation is already correct
        if (self.imageOrientation == UIImageOrientation.Up) {
            return UIImage(CGImage: self.CGImage!, scale: 1.0, orientation: UIImageOrientation.Right)
        }
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform:CGAffineTransform = CGAffineTransformIdentity
        
        if (self.imageOrientation == UIImageOrientation.Down
            || self.imageOrientation == UIImageOrientation.DownMirrored) {
                
                NSLog("Down");
                transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height)
                transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
        }
        
        if (self.imageOrientation == UIImageOrientation.Right
            || self.imageOrientation == UIImageOrientation.RightMirrored) {
                
                NSLog("Right");
                transform = CGAffineTransformTranslate(transform, self.size.width, 0)
                transform = CGAffineTransformRotate(transform, CGFloat(M_PI/2.0))
        }
        
        if (self.imageOrientation == UIImageOrientation.Left
            || self.imageOrientation == UIImageOrientation.LeftMirrored) {
                
                NSLog("Left");
                transform = CGAffineTransformTranslate(transform, 0, self.size.height);
                transform = CGAffineTransformRotate(transform,  CGFloat(3*M_PI/2.0));
        }
        
        if (self.imageOrientation == UIImageOrientation.UpMirrored
            || self.imageOrientation == UIImageOrientation.DownMirrored) {
                
                NSLog("Up/Down Mirrored");
                transform = CGAffineTransformTranslate(transform, self.size.width, 0)
                transform = CGAffineTransformScale(transform, -1, 1)
        }
        
        if (self.imageOrientation == UIImageOrientation.LeftMirrored
            || self.imageOrientation == UIImageOrientation.RightMirrored) {
                
                NSLog("Left/RightMirrored");
                transform = CGAffineTransformTranslate(transform, self.size.height, 0);
                transform = CGAffineTransformScale(transform, -1, 1);
        }
        
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        let ctx:CGContextRef = CGBitmapContextCreate(nil, Int(self.size.width), Int(self.size.height),
            CGImageGetBitsPerComponent(self.CGImage), 0,
            CGImageGetColorSpace(self.CGImage),
            CGImageGetBitmapInfo(self.CGImage).rawValue
        )!;
        CGContextConcatCTM(ctx, transform)
        
        if (self.imageOrientation == UIImageOrientation.Left
            || self.imageOrientation == UIImageOrientation.LeftMirrored
            || self.imageOrientation == UIImageOrientation.Right
            || self.imageOrientation == UIImageOrientation.RightMirrored
            ) {
                
                CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage)
        } else {
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage)
        }
        
        
        // And now we just create a new UIImage from the drawing context
        let cgimg:CGImageRef = CGBitmapContextCreateImage(ctx)!
        let imgEnd:UIImage = UIImage(CGImage: cgimg, scale: 1.0, orientation: UIImageOrientation.Right)
        
        return imgEnd
    }
}

class CameraViewController: UIViewController, CLLocationManagerDelegate {
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var videoDeviceInput: AVCaptureDeviceInput?
    var image : UIImage?
    var imageInfo = ImageInfo()
    
    var locationManager: CLLocationManager?
    var bestEffortAtLocation : CLLocation?
    var currentHeading : CLLocationDirection?
    
    @IBOutlet weak var stillButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var flipCameraButton: UIButton!
    
    @IBOutlet weak var previewView: UIView!
    //@IBOutlet var superPreviewView: UIView!
    
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
        
        self.captureSession = AVCaptureSession()
        self.captureSession!.sessionPreset = AVCaptureSessionPresetPhoto
        
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        let input = try? AVCaptureDeviceInput(device: backCamera)
        
        if input != nil && self.captureSession!.canAddInput(input!) {
            self.captureSession!.addInput(input!)
            self.videoDeviceInput = input;
            
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            if self.captureSession!.canAddOutput(stillImageOutput) {
                self.captureSession!.addOutput(stillImageOutput)
                CameraViewController.setFlashMode(AVCaptureFlashMode.Auto, forDevice: backCamera)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                if let connection = previewLayer?.connection {
                    connection.videoOrientation = AVCaptureVideoOrientation(ui:UIApplication.sharedApplication().statusBarOrientation)

                }
                previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                previewView.layer.addSublayer(previewLayer!)
                
                self.captureSession!.startRunning()
            }
        }
        
        // Add a single tap gesture to focus on the point tapped, then lock focus
        let singleTap = UITapGestureRecognizer(target: self, action: "focusAndExposeTap:")
        singleTap.numberOfTapsRequired = 1
        previewView.addGestureRecognizer(singleTap)
        
        // Add a double tap gesture to reset the focus mode to continuous auto focus
        let doubleTap = UITapGestureRecognizer(target: self, action: "doubleTaptoContinuouslyAutofocus:")
        doubleTap.numberOfTapsRequired = 2
        singleTap.requireGestureRecognizerToFail(doubleTap)
        previewView.addGestureRecognizer(doubleTap)
        
        //setup corelocation manger
        //if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Restricted || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            // IMPORTANT!!! kCLLocationAccuracyBest should not be used for comparison with location coordinate or altitidue
            // accuracy because it is a negative value. Instead, compare against some predetermined "real" measure of
            // acceptable accuracy, or depend on the timeout to stop updating.
            locationManager!.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager!.headingFilter = 5
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined {
                locationManager!.requestWhenInUseAuthorization()
            }
        //}
        
        let radius : CGFloat = 10.0
        let bgColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
        stillButton.layer.cornerRadius = radius
        stillButton.backgroundColor = bgColor
        flipCameraButton.layer.cornerRadius = radius
        flipCameraButton.backgroundColor = bgColor
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer!.frame = previewView.bounds
        self.addNotificationObservers()
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.removeNotificationObservers()
        self.captureSession.stopRunning()
        super.viewDidDisappear(animated)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (context == CapturingStillImageContext) {
            let isCapturingStillImage = change![NSKeyValueChangeNewKey]?.boolValue
            if (isCapturingStillImage!) {
                self.runStillImageCaptureAnimation()
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if( segue.identifier == "toDrawingView" ) {
            let destinationVC = segue.destinationViewController as? DrawingViewController
            if( destinationVC != nil ) {
                destinationVC!.image = image?.fixOrientation()
                destinationVC!.imageInfo = imageInfo
            }
        }
    }

    
    @IBAction func takePhoto(sender: AnyObject) {
        if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo) {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                if (sampleBuffer != nil) {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProviderCreateWithCFData(imageData)
                    let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
                    
                    let image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation(ui:UIApplication.sharedApplication().statusBarOrientation))
                    //var image = UIImage.init(data: imageData)
                    NSLog("image Orientation %i", image.imageOrientation.rawValue)
                    self.image = image
                    
                    let exifAttachUnManaged = CMGetAttachment(
                        sampleBuffer, kCGImagePropertyExifDictionary, nil
                    )
                    //NSLog("attachments %@", exifAttachUnManaged);
                    //let exifAttach = exifAttachUnManaged.takeUnretainedValue() as! CFDictionaryRef
                    let exifAttach = exifAttachUnManaged as? NSDictionary
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
                    
                    if (CLLocationManager.locationServicesEnabled()) {
                        self.getLocation()
                        self.imageInfo.latitude = self.bestEffortAtLocation!.coordinate.latitude
                        self.imageInfo.longitude = self.bestEffortAtLocation!.coordinate.longitude
                        if (self.currentHeading != nil) {
                            self.imageInfo.compassOrienation = self.currentHeading!
                        }
                        self.imageInfo.altitude = self.bestEffortAtLocation!.altitude
                    
                        self.stopUpdatingLocationWithMessage("Still Image Captured:")
                        self.locationManager?.stopUpdatingHeading()
                        self.captureSession!.stopRunning()
                    }
                    self.imageInfo.date = NSDate()
                    
                    self.performSegueWithIdentifier("toDrawingView", sender: nil)
                }
            })
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.All;
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
                        
                        
                        switch connection.videoOrientation {
                        case AVCaptureVideoOrientation.LandscapeLeft: NSLog("LandscapeLeft");
                        case AVCaptureVideoOrientation.LandscapeRight: NSLog("LandscapeRight");
                        case AVCaptureVideoOrientation.Portrait: NSLog("Portrait");
                        case AVCaptureVideoOrientation.PortraitUpsideDown: NSLog("LandscapeLeft");
                        }

                    }
                    self.previewLayer!.frame = self.previewView.bounds

                    self.previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                    NSLog("Omg Rotation!")

            })
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true;
    }
    
    @IBAction func changeCamera (sender: AnyObject) {
        self.stillButton.userInteractionEnabled = false
        self.flipCameraButton.userInteractionEnabled = false
        
        //dispatch block to sessionQueue
        let currentVideoDevice = self.videoDeviceInput?.device
        var preferredPosition = AVCaptureDevicePosition.Unspecified
        let currentPosition = currentVideoDevice?.position
        if (currentPosition == AVCaptureDevicePosition.Unspecified) {
            
        }
        //change preferred camera postion so flip happens
        switch (currentPosition!) {
        case AVCaptureDevicePosition.Unspecified:
            preferredPosition = AVCaptureDevicePosition.Back; break;
        case AVCaptureDevicePosition.Back:
            preferredPosition = AVCaptureDevicePosition.Front; break;
        case AVCaptureDevicePosition.Front:
            preferredPosition = AVCaptureDevicePosition.Back; break;
        }

        //AVCaptureDevice *videoDevice = [CameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
        let videoDevice = CameraViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: preferredPosition)
        
        let input = try? AVCaptureDeviceInput(device: videoDevice)

        
        //[[self session] beginConfiguration];
        self.captureSession!.beginConfiguration()
        
        self.captureSession!.removeInput(self.videoDeviceInput)
        
        
        if (self.captureSession!.canAddInput(input)) {
            NSNotificationCenter.defaultCenter().removeObserver(self, name:AVCaptureDeviceSubjectAreaDidChangeNotification, object: currentVideoDevice)
            CameraViewController.setFlashMode(AVCaptureFlashMode.Auto, forDevice: videoDevice)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "subjectAreaDidChange:", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: currentVideoDevice)
            self.captureSession!.addInput(input)
            self.videoDeviceInput = input
            
        } else {
            self.captureSession!.addInput(self.videoDeviceInput)
        }
        
        self.captureSession!.commitConfiguration()
        
        self.stillButton.userInteractionEnabled = true
        self.flipCameraButton.userInteractionEnabled = true
    
    }
    
    func focusAndExposeTap(gestureRecognizer : UIGestureRecognizer) {
        let devicePoint = self.previewLayer?.captureDevicePointOfInterestForPoint(gestureRecognizer.locationInView(gestureRecognizer.view))
        NSLog("FocusPoint (%f,%f)",devicePoint!.x,devicePoint!.y)
        self.focusWithMode(AVCaptureFocusMode.AutoFocus, exposeWithMode: AVCaptureExposureMode.AutoExpose, atDevicePoint: devicePoint!, monitorSubjectAreaChange: true)
        //NSLog("No Continuous Focus")
        self.drawFocusBox(devicePoint!)
        
    }
    
    func doubleTaptoContinuouslyAutofocus(gestureRecognizer : UIGestureRecognizer) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5);
        self.focusWithMode(AVCaptureFocusMode.ContinuousAutoFocus, exposeWithMode: AVCaptureExposureMode.ContinuousAutoExposure, atDevicePoint: devicePoint, monitorSubjectAreaChange: true)
        removeFocusBox()
        NSLog("Continuous Focus")
    }
    
    @IBAction func closeWindow(sender: AnyObject) {
        let destinationVC = self.presentingViewController as? ViewController
        if( destinationVC != nil ) {
            destinationVC!.image = image
        }
        locationManager?.stopUpdatingLocation()
        locationManager?.stopUpdatingHeading()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    class func deviceWithMediaType(mediaType: NSString, preferringPosition position: AVCaptureDevicePosition) -> AVCaptureDevice {
        let devices = AVCaptureDevice.devicesWithMediaType(mediaType as String) as! [AVCaptureDevice]
        var captureDevice = devices[0]
        
        for device in devices {
            if device.position == position {
                captureDevice = device
                break
            }
        }
        
        return captureDevice;
    }
    
    func focusWithMode(focusMode: AVCaptureFocusMode, exposeWithMode exposureMode: AVCaptureExposureMode, atDevicePoint point: CGPoint, monitorSubjectAreaChange monitorSubjectAreachange: (Bool)) {
        let device = self.videoDeviceInput?.device

        do {
            try device!.lockForConfiguration()
            if (device!.focusPointOfInterestSupported && device!.isFocusModeSupported(focusMode)) {
                device!.focusMode = focusMode
                device!.focusPointOfInterest = point
            }
            if (device!.exposurePointOfInterestSupported && device!.isExposureModeSupported(exposureMode)) {
                device!.exposureMode = exposureMode
                device!.exposurePointOfInterest = point
            }
            device!.subjectAreaChangeMonitoringEnabled = monitorSubjectAreachange
            device!.unlockForConfiguration()
        } catch {
            //error
        }
    }
    
    
    func drawFocusBox (centerPoint: CGPoint) {
        removeFocusBox()
        //Box h=w=100
        let focusView : UIImageView = UIImageView(image: UIImage(named: "focusSquare.png"))
        let topLeftPoint = CGPoint(x: (1.0-centerPoint.x)*self.previewView.bounds.width, y: (1.0-centerPoint.y)*self.previewView.bounds.height)
        NSLog("topLeftPoint (%i,%i)",Int(topLeftPoint.x),Int(topLeftPoint.y))
        focusView.frame = CGRect(x: topLeftPoint.x-75.0, y: topLeftPoint.y-75.0, width: 150.0, height: 150.0)
        self.previewView.addSubview(focusView)
        
        UIView.animateWithDuration(0.4, delay: 0.1, usingSpringWithDamping: 0.15, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                focusView.transform=CGAffineTransformMakeScale(0.6, 0.6);
            }, completion: { (value: Bool) in
                focusView.transform=CGAffineTransformMakeScale(0.6, 0.6);
        })
    }
    
    func removeFocusBox () {
        //check to see if a focusBox is already being displayed
        for subview in previewView.subviews {
            //if so delete it from previewView
            if(subview.isKindOfClass(UIImageView)){
                subview.removeFromSuperview()
            }
        }
    }
    
    func runStillImageCaptureAnimation() {
        //dispatch to main queue?
        self.previewView.layer.opacity = 0.0;
        UIView.animateWithDuration(0.25, animations: {
            self.previewView.layer.opacity = 1.0
        })
    }

    
    class func setFlashMode(flashMode: AVCaptureFlashMode, forDevice device: AVCaptureDevice) {
        if (device.hasFlash && device.isFlashModeSupported(flashMode)) {
            do {
                try device.lockForConfiguration()
                device.flashMode = flashMode
                device.unlockForConfiguration()
            } catch {
                //error
            }
        }
    }
    
    // Mark: CLManager Delegate Methods
    func locationManager(manager: CLLocationManager,
        didChangeAuthorizationStatus status: CLAuthorizationStatus) //this is called when authorization status changes and when locationManager is initialiazed
    {
        if status == CLAuthorizationStatus.AuthorizedAlways || status == CLAuthorizationStatus.AuthorizedWhenInUse {
            manager.startUpdatingLocation()
            if (CLLocationManager.headingAvailable()) {
                manager.startUpdatingHeading()
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // test the age of the location measurement to determine if the measurement is cached
        // in most cases you will not want to rely on cached measurements
        let newLocation = locations.last!
        let locationAge = newLocation.timestamp.timeIntervalSinceNow;
        if (abs(locationAge) > 5.0) {
            return;
        }
        
        // test that the horizontal accuracy does not indicate an invalid measurement
        if (newLocation.horizontalAccuracy < 0) {
            return;
        }
        
        // test the measurement to see if it is more accurate than the previous measurement
        if (self.bestEffortAtLocation == nil || self.bestEffortAtLocation?.horizontalAccuracy > newLocation.horizontalAccuracy) {
            // store the location as the "best effort"
            self.bestEffortAtLocation = newLocation;
            let lat : Double = bestEffortAtLocation!.coordinate.latitude
            let long : Double = bestEffortAtLocation!.coordinate.longitude
            print("%f, %f", lat, long)
            
            // test the measurement to see if it meets the desired accuracy
            if (newLocation.horizontalAccuracy <= self.locationManager!.desiredAccuracy) {
                // we have a measurement that meets our requirements, so we can stop updating the location
                //
                // IMPORTANT!!! Minimize power usage by stopping the location manager as soon as possible.
                //
                self.stopUpdatingLocationWithMessage("Acquired location: ")
                
                // we can also cancel our previous performSelector:withObject:afterDelay: - it's no longer necessary
                //NSObject.cancelPreviousPerformRequestsWithTarget(self, selector:"stopUpdatingLocationWithMessage:", object:nil);
            }
        }
    }
    
    func locationManager(manager : CLLocationManager, didUpdateHeading newHeading : CLHeading) {
        if (newHeading.headingAccuracy < 0) {
            return;
        }
    
        // Use the true heading if it is valid.
        var theHeading = ((newHeading.trueHeading > 0) ?
            newHeading.trueHeading : newHeading.magneticHeading)
        
        // the location manager assumes that the top of the device in portrait mode represents due north (0 degrees) by default
        switch UIApplication.sharedApplication().statusBarOrientation {
           case UIInterfaceOrientation.Portrait: break // Nothing to do
           case UIInterfaceOrientation.LandscapeRight: theHeading += 90
           case UIInterfaceOrientation.PortraitUpsideDown: theHeading += 180
           case UIInterfaceOrientation.LandscapeLeft: theHeading += 270
           case UIInterfaceOrientation.Unknown: break // Nothing intelligent to do
        }
        if( theHeading < 0 ) {
            theHeading += 360
        } else if( theHeading > 360 ) {
            theHeading -= 360
        }
        
        self.currentHeading = theHeading;
        self.locationLabel.attributedText = Utility.formatAngle(theHeading, orient: true)
    }

    
    func stopUpdatingLocationWithMessage(message: NSString) {
        // Do not stop as heading can still change
        //self.locationManager!.stopUpdatingLocation()
        //self.locationManager!.delegate = nil;
        print(message)
        let lat : Double = bestEffortAtLocation!.coordinate.latitude
        let long : Double = bestEffortAtLocation!.coordinate.longitude
        print("%f, %f", lat, long)
    }
    
    func getLocation() {
        if (bestEffortAtLocation != nil) {
            let locationAge = bestEffortAtLocation!.timestamp.timeIntervalSinceNow
            if (abs(locationAge) > 60) {
                locationManager?.stopUpdatingLocation()
                locationManager?.startUpdatingLocation()
            } else {
                //keep current location value
            }
        } else {
            locationManager?.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        NSLog("%@",error)
        locationManager?.stopUpdatingLocation()
    }
    
    //    MARK: Observers
    func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint : CGPoint = CGPoint(x: 0.5, y: 0.5)
        self.focusWithMode(AVCaptureFocusMode.ContinuousAutoFocus, exposeWithMode: AVCaptureExposureMode.ContinuousAutoExposure, atDevicePoint: devicePoint, monitorSubjectAreaChange: false)
        removeFocusBox()
        
    }
    
    func addNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "subjectAreaDidChange:", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: self.videoDeviceInput?.device)
        self.addObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", options: NSKeyValueObservingOptions.New, context: CapturingStillImageContext)
    }
    
    func removeNotificationObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: self.videoDeviceInput?.device)
        self.removeObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", context: CapturingStillImageContext)
    }
    
    @IBAction func unwindToCamera (segue: UIStoryboardSegue) {
        
    }
}


