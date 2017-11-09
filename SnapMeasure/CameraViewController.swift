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

struct ImageInfo {
    var focalLength : Float = 0.0
    var xDimension : Int = 0
    var yDimension : Int = 0
    var subjectDistance : Float = 0.0
    var longitude : Double? //represents a longitude value in degrees, positive values are east of the prime meridian
    var latitude : Double? //represents a latitude value in degrees, postive  values are north of the equator
    var compassOrienation : Double? //Degrees relative to north
    var altitude : Double?
    var date : Date = Date()
    var scale: Double? //in meters per point
}

var CapturingStillImageContext = "CapturingStillImageContext"

extension AVCaptureVideoOrientation {
    var uiInterfaceOrientation: UIInterfaceOrientation {
        get {
            switch self {
            case .landscapeLeft:        return .landscapeLeft
            case .landscapeRight:       return .landscapeRight
            case .portrait:             return .portrait
            case .portraitUpsideDown:   return .portraitUpsideDown
            }
        }
    }
    
    init(ui:UIInterfaceOrientation) {
        switch ui {
        case .landscapeRight:       self = .landscapeRight
        case .landscapeLeft:        self = .landscapeLeft
        case .portrait:             self = .portrait
        case .portraitUpsideDown:   self = .portraitUpsideDown
        default:                    self = .portrait
        }
    }
}

extension UIImageOrientation {
    var uiInterfaceOrientation: UIInterfaceOrientation {
        get {
            switch self {
            case .up:      return .portrait
            case .down:    return .portraitUpsideDown
            case .left:    return .landscapeLeft
            case .right:   return .landscapeRight
            default:       return .portrait
            }
        }
    }
    
    init(ui:UIInterfaceOrientation) {
        switch ui {
        case .landscapeRight:       self = .right;  break;
        case .landscapeLeft:        self = .left;   break;
        case .portrait:             self = .up;     break
        case .portraitUpsideDown:   self = .down;   break;
        default:                    self = .up;     break;
        }
    }
}


extension UIImage {
    
    func fixOrientation() -> UIImage {
        
        // No-op if the orientation is already correct
        if (self.imageOrientation == UIImageOrientation.up) {
            return UIImage(cgImage: self.cgImage!, scale: 1.0, orientation: UIImageOrientation.right)
        }
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform:CGAffineTransform = CGAffineTransform.identity
        
        if (self.imageOrientation == UIImageOrientation.down
            || self.imageOrientation == UIImageOrientation.downMirrored) {
                
                NSLog("Down");
                transform = transform.translatedBy(x: self.size.width, y: self.size.height)
                transform = transform.rotated(by: CGFloat(Double.pi))
        }
        
        if (self.imageOrientation == UIImageOrientation.right
            || self.imageOrientation == UIImageOrientation.rightMirrored) {
                
                NSLog("Right");
                transform = transform.translatedBy(x: self.size.width, y: 0)
                transform = transform.rotated(by: CGFloat(.pi/2.0))
        }
        
        if (self.imageOrientation == UIImageOrientation.left
            || self.imageOrientation == UIImageOrientation.leftMirrored) {
                
                NSLog("Left");
                transform = transform.translatedBy(x: 0, y: self.size.height);
                transform = transform.rotated(by: CGFloat(3*Double.pi/2.0));
        }
        
        if (self.imageOrientation == UIImageOrientation.upMirrored
            || self.imageOrientation == UIImageOrientation.downMirrored) {
                
                NSLog("Up/Down Mirrored");
                transform = transform.translatedBy(x: self.size.width, y: 0)
                transform = transform.scaledBy(x: -1, y: 1)
        }
        
        if (self.imageOrientation == UIImageOrientation.leftMirrored
            || self.imageOrientation == UIImageOrientation.rightMirrored) {
                
                NSLog("Left/RightMirrored");
                transform = transform.translatedBy(x: self.size.height, y: 0);
                transform = transform.scaledBy(x: -1, y: 1);
        }
        
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        let ctx:CGContext = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height),
            bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0,
            space: self.cgImage!.colorSpace!,
            bitmapInfo: self.cgImage!.bitmapInfo.rawValue
        )!;
        ctx.concatenate(transform)
        
        if (self.imageOrientation == UIImageOrientation.left
            || self.imageOrientation == UIImageOrientation.leftMirrored
            || self.imageOrientation == UIImageOrientation.right
            || self.imageOrientation == UIImageOrientation.rightMirrored
        ) {
            ctx.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.height,height: self.size.width))
        } else {
            ctx.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.width,height: self.size.height))
        }
        
        
        // And now we just create a new UIImage from the drawing context
        let cgimg:CGImage = ctx.makeImage()!
        let imgEnd:UIImage = UIImage(cgImage: cgimg, scale: 1.0, orientation: UIImageOrientation.right)
        
        return imgEnd
    }
}

class CameraViewController: UIViewController, CLLocationManagerDelegate, AVCapturePhotoCaptureDelegate {
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var videoDeviceInput: AVCaptureDeviceInput?
    var image : UIImage?
    var imageInfo = ImageInfo()
    
    var locationManager: CLLocationManager?
    var bestEffortAtLocation : CLLocation?
    var currentHeading : CLLocationDirection?
    
    @IBOutlet weak var stillButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var elevationLabel: UILabel!
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.captureSession = AVCaptureSession()
        self.captureSession!.sessionPreset = AVCaptureSession.Preset.photo
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        if( backCamera == nil ) {
            return
        }
        
        let input = try? AVCaptureDeviceInput(device: backCamera!)
        
        if input != nil && self.captureSession!.canAddInput(input!) {
            self.captureSession!.addInput(input!)
            self.videoDeviceInput = input;
            
            stillImageOutput = AVCapturePhotoOutput()
            
        
            if self.captureSession!.canAddOutput(stillImageOutput!) {
                self.captureSession!.addOutput(stillImageOutput!)
                
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                if let connection = previewLayer?.connection {
                    connection.videoOrientation = AVCaptureVideoOrientation(ui:UIApplication.shared.statusBarOrientation)

                }
                previewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
                previewView.layer.addSublayer(previewLayer!)
                
                self.captureSession!.startRunning()
            }
        }
        
        // Add a single tap gesture to focus on the point tapped, then lock focus
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(CameraViewController.focusAndExposeTap(_:)))
        singleTap.numberOfTapsRequired = 1
        previewView.addGestureRecognizer(singleTap)
        
        // Add a double tap gesture to reset the focus mode to continuous auto focus
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(CameraViewController.doubleTaptoContinuouslyAutofocus(_:)))
        doubleTap.numberOfTapsRequired = 2
        singleTap.require(toFail: doubleTap)
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
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.notDetermined {
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if( previewLayer != nil ) {
             previewLayer!.frame = previewView.bounds
        }
        self.addNotificationObservers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.removeNotificationObservers()
        self.captureSession.stopRunning()
        super.viewDidDisappear(animated)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (context == &CapturingStillImageContext) {
            let isCapturingStillImage = (change![NSKeyValueChangeKey.newKey] as AnyObject).boolValue
            if (isCapturingStillImage!) {
                self.runStillImageCaptureAnimation()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier == "toDrawingView" ) {
            let drawingNC = segue.destination as! UINavigationController
            let destinationVC = drawingNC.topViewController as? DrawingViewController
            if( destinationVC != nil ) {
                destinationVC!.image = image
                destinationVC!.imageInfo = imageInfo
            }
        }
    }

    
    @IBAction func takePhoto(_ sender: AnyObject) {
        if( stillImageOutput == nil ) {
            return
        }
        if let videoConnection = stillImageOutput!.connection(with: AVMediaType.video) {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])
            if( stillImageOutput!.supportedFlashModes.contains(AVCaptureDevice.FlashMode.auto) ) {
               settings.flashMode = AVCaptureDevice.FlashMode.auto
            }
            
            stillImageOutput?.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
    
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        let sampleBuffer = photoSampleBuffer
        let previewBuffer = previewPhotoSampleBuffer
        if( sampleBuffer == nil ) {
            return
        }
        let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer!, previewPhotoSampleBuffer: previewBuffer)
        if( imageData == nil ) {
            return
        }
    
        let dataProvider = CGDataProvider(data: imageData! as CFData)
        let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        
        let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation(ui:UIApplication.shared.statusBarOrientation)).fixOrientation()
        //var image = UIImage.init(data: imageData)
        NSLog("image Orientation %i", image.imageOrientation.rawValue)
        self.image = image
        
        let exifAttachUnManaged = CMGetAttachment(
            photoSampleBuffer!, kCGImagePropertyExifDictionary, nil
        )
        //NSLog("attachments %@", exifAttachUnManaged);
        //let exifAttach = exifAttachUnManaged.takeUnretainedValue() as! CFDictionaryRef
        let exifAttach = exifAttachUnManaged as? NSDictionary
        if( exifAttach != nil ) {
            let flNumber = exifAttach!.value(forKey: kCGImagePropertyExifFocalLength as String) as? NSNumber
            if( flNumber != nil ) {
                let focalLength = flNumber!.floatValue
                self.imageInfo.focalLength = focalLength/1000.0 // (in meters)
            }
            let pxNumber = exifAttach!.value(forKey: kCGImagePropertyExifPixelXDimension as String) as? NSNumber
            if( pxNumber != nil ) {
                let px = pxNumber!.int32Value
                self.imageInfo.xDimension = Int(px)
            }
            let pyNumber = exifAttach!.value(forKey: kCGImagePropertyExifPixelYDimension as String) as? NSNumber
            if( pyNumber != nil ) {
                let py = pyNumber!.int32Value
                self.imageInfo.yDimension = Int(py)
            }
            let diNumber = exifAttach!.value(forKey: kCGImagePropertyExifSubjectDistRange as String) as?NSNumber
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
        self.imageInfo.date = Date()
        self.imageInfo.xDimension = Int(image.size.width)
        self.imageInfo.yDimension = Int(image.size.height)
        
        // Ask for resolution and then segue to drawingView
        self.askForPictureSize(image)
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.all;
    }
    
     override func viewWillTransition(to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator) {
            
            // willRotateToInterfaceOrientation code goes here
            
            coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                // willAnimateRotationToInterfaceOrientation code goes here
                super.viewWillTransition(to: size, with: coordinator)
                
                }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                    
                    // didRotateFromInterfaceOrientation goes here
                    if let connection = self.previewLayer?.connection {
                        connection.videoOrientation = AVCaptureVideoOrientation(ui:UIApplication.shared.statusBarOrientation)
                        
                        switch connection.videoOrientation {
                        case AVCaptureVideoOrientation.landscapeLeft: NSLog("LandscapeLeft");
                        case AVCaptureVideoOrientation.landscapeRight: NSLog("LandscapeRight");
                        case AVCaptureVideoOrientation.portrait: NSLog("Portrait");
                        case AVCaptureVideoOrientation.portraitUpsideDown: NSLog("LandscapeLeft");
                        }

                    }
                    self.previewLayer!.frame = self.previewView.bounds

                    self.previewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    NSLog("Omg Rotation!")

            })
        
    }
    
    override var prefersStatusBarHidden : Bool {
        return true;
    }
    
    @IBAction func changeCamera (_ sender: AnyObject) {
        self.stillButton.isUserInteractionEnabled = false
        self.flipCameraButton.isUserInteractionEnabled = false
        
        //dispatch block to sessionQueue
        let currentVideoDevice = self.videoDeviceInput?.device
        var preferredPosition = AVCaptureDevice.Position.unspecified
        let currentPosition = currentVideoDevice?.position
        if (currentPosition == AVCaptureDevice.Position.unspecified || currentPosition == nil ) {
            return
        }
        //change preferred camera postion so flip happens
        switch (currentPosition!) {
        case AVCaptureDevice.Position.unspecified:
            preferredPosition = AVCaptureDevice.Position.back; break;
        case AVCaptureDevice.Position.back:
            preferredPosition = AVCaptureDevice.Position.front; break;
        case AVCaptureDevice.Position.front:
            preferredPosition = AVCaptureDevice.Position.back; break;
        }

        //AVCaptureDevice *videoDevice = [CameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
        let videoDevice = CameraViewController.deviceWithMediaType(AVMediaType.video as NSString, preferringPosition: preferredPosition)
        
        let input = try? AVCaptureDeviceInput(device: videoDevice)

        
        //[[self session] beginConfiguration];
        self.captureSession!.beginConfiguration()
        
        self.captureSession!.removeInput(self.videoDeviceInput!)
        
        
        if (self.captureSession!.canAddInput(input!)) {
            NotificationCenter.default.removeObserver(self, name:NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: currentVideoDevice)
            
            NotificationCenter.default.addObserver(self, selector: #selector(CameraViewController.subjectAreaDidChange(_:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: currentVideoDevice)
            self.captureSession!.addInput(input!)
            self.videoDeviceInput = input
            
        } else {
            self.captureSession!.addInput(self.videoDeviceInput!)
        }
        
        self.captureSession!.commitConfiguration()
        
        self.stillButton.isUserInteractionEnabled = true
        self.flipCameraButton.isUserInteractionEnabled = true
    
    }
    
    @objc func focusAndExposeTap(_ gestureRecognizer : UIGestureRecognizer) {
        let devicePoint = self.previewLayer?.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view))
        NSLog("FocusPoint (%f,%f)",devicePoint!.x,devicePoint!.y)
        self.focusWithMode(AVCaptureDevice.FocusMode.autoFocus, exposeWithMode: AVCaptureDevice.ExposureMode.autoExpose, atDevicePoint: devicePoint!, monitorSubjectAreaChange: true)
        //NSLog("No Continuous Focus")
        self.drawFocusBox(devicePoint!)
        
    }
    
    @objc func doubleTaptoContinuouslyAutofocus(_ gestureRecognizer : UIGestureRecognizer) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5);
        self.focusWithMode(AVCaptureDevice.FocusMode.continuousAutoFocus, exposeWithMode: AVCaptureDevice.ExposureMode.continuousAutoExposure, atDevicePoint: devicePoint, monitorSubjectAreaChange: true)
        removeFocusBox()
        NSLog("Continuous Focus")
    }
    
    @IBAction func closeWindow(_ sender: AnyObject) {
        let destinationVC = self.presentingViewController as? ViewController
        if( destinationVC != nil ) {
            destinationVC!.image = image
        }
        locationManager?.stopUpdatingLocation()
        locationManager?.stopUpdatingHeading()
        self.dismiss(animated: true, completion: nil)
    }
    
    class func deviceWithMediaType(_ mediaType: NSString, preferringPosition position: AVCaptureDevice.Position) -> AVCaptureDevice {
        let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType(rawValue: mediaType as String), position: position)
        if( device == nil ) {
            return AVCaptureDevice.default(for: AVMediaType(rawValue: mediaType as String))!
        }
        return device!
    }
    
    func focusWithMode(_ focusMode: AVCaptureDevice.FocusMode, exposeWithMode exposureMode: AVCaptureDevice.ExposureMode, atDevicePoint point: CGPoint, monitorSubjectAreaChange monitorSubjectAreachange: (Bool)) {
        let device = self.videoDeviceInput?.device

        do {
            try device!.lockForConfiguration()
            if (device!.isFocusPointOfInterestSupported && device!.isFocusModeSupported(focusMode)) {
                device!.focusMode = focusMode
                device!.focusPointOfInterest = point
            }
            if (device!.isExposurePointOfInterestSupported && device!.isExposureModeSupported(exposureMode)) {
                device!.exposureMode = exposureMode
                device!.exposurePointOfInterest = point
            }
            device!.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreachange
            device!.unlockForConfiguration()
        } catch {
            //error
        }
    }
    
    
    func drawFocusBox (_ centerPoint: CGPoint) {
        removeFocusBox()
        //Box h=w=100
        let focusView : UIImageView = UIImageView(image: UIImage(named: "focusSquare.png"))
        let topLeftPoint = CGPoint(x: (1.0-centerPoint.x)*self.previewView.bounds.width, y: (1.0-centerPoint.y)*self.previewView.bounds.height)
        NSLog("topLeftPoint (%i,%i)",Int(topLeftPoint.x),Int(topLeftPoint.y))
        focusView.frame = CGRect(x: topLeftPoint.x-75.0, y: topLeftPoint.y-75.0, width: 150.0, height: 150.0)
        self.previewView.addSubview(focusView)
        
        UIView.animate(withDuration: 0.4, delay: 0.1, usingSpringWithDamping: 0.15, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.beginFromCurrentState, animations: {
                focusView.transform=CGAffineTransform(scaleX: 0.6, y: 0.6);
            }, completion: { (value: Bool) in
                focusView.transform=CGAffineTransform(scaleX: 0.6, y: 0.6);
        })
    }
    
    func removeFocusBox () {
        //check to see if a focusBox is already being displayed
        for subview in previewView.subviews {
            //if so delete it from previewView
            if(subview.isKind(of: UIImageView.self)){
                subview.removeFromSuperview()
            }
        }
    }
    
    func runStillImageCaptureAnimation() {
        //dispatch to main queue?
        self.previewView.layer.opacity = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.previewView.layer.opacity = 1.0
        })
    }
    
    // Mark: CLManager Delegate Methods
    func locationManager(_ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus) //this is called when authorization status changes and when locationManager is initialiazed
    {
        if status == CLAuthorizationStatus.authorizedAlways || status == CLAuthorizationStatus.authorizedWhenInUse {
            manager.startUpdatingLocation()
            if (CLLocationManager.headingAvailable()) {
                manager.startUpdatingHeading()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
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
        if (self.bestEffortAtLocation == nil || self.bestEffortAtLocation!.horizontalAccuracy > newLocation.horizontalAccuracy) {
            // store the location as the "best effort"
            self.bestEffortAtLocation = newLocation;
            let lat : Double = bestEffortAtLocation!.coordinate.latitude
            let long : Double = bestEffortAtLocation!.coordinate.longitude
            print(lat, long, newLocation.altitude)
            
            // Show altitude to user
            let nf = NumberFormatter()
            let number = nf.string(from: NSNumber(value: bestEffortAtLocation!.altitude))
            self.elevationLabel.text = number! + "m"
            
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
    
    func locationManager(_ manager : CLLocationManager, didUpdateHeading newHeading : CLHeading) {
        if (newHeading.headingAccuracy < 0) {
            return;
        }
    
        // Use the true heading if it is valid.
        var theHeading = ((newHeading.trueHeading > 0) ?
            newHeading.trueHeading : newHeading.magneticHeading)
        
        // the location manager assumes that the top of the device in portrait mode represents due north (0 degrees) by default
        switch UIApplication.shared.statusBarOrientation {
           case UIInterfaceOrientation.portrait: break // Nothing to do
           case UIInterfaceOrientation.landscapeRight: theHeading += 90
           case UIInterfaceOrientation.portraitUpsideDown: theHeading += 180
           case UIInterfaceOrientation.landscapeLeft: theHeading += 270
           case UIInterfaceOrientation.unknown: break // Nothing intelligent to do
        }
        if( theHeading < 0 ) {
            theHeading += 360
        } else if( theHeading > 360 ) {
            theHeading -= 360
        }
        
        self.currentHeading = theHeading;
        self.locationLabel.attributedText = Utility.formatAngle(theHeading, orient: true)
    }

    
    func stopUpdatingLocationWithMessage(_ message: NSString) {
        // Do not stop as heading can still change
        //self.locationManager!.stopUpdatingLocation()
        //self.locationManager!.delegate = nil;
        print(message)
        let lat : Double = bestEffortAtLocation!.coordinate.latitude
        let long : Double = bestEffortAtLocation!.coordinate.longitude
        print(lat, long, bestEffortAtLocation!.altitude)
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
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager?.stopUpdatingLocation()
    }
    
    //    MARK: Observers
    @objc func subjectAreaDidChange(_ notification: Notification) {
        let devicePoint : CGPoint = CGPoint(x: 0.5, y: 0.5)
        self.focusWithMode(AVCaptureDevice.FocusMode.continuousAutoFocus, exposeWithMode: AVCaptureDevice.ExposureMode.continuousAutoExposure, atDevicePoint: devicePoint, monitorSubjectAreaChange: false)
        removeFocusBox()
        
    }
    
    func addNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(CameraViewController.subjectAreaDidChange(_:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.videoDeviceInput?.device)
        self.addObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", options: NSKeyValueObservingOptions.new, context: &CapturingStillImageContext)
    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.videoDeviceInput?.device)
        self.removeObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", context: &CapturingStillImageContext)
    }
    
    @IBAction func unwindToCamera (_ segue: UIStoryboardSegue) {
        
    }
    
    // Ask to lower potentially the resolution of the image
    // And perform segue
    func askForPictureSize(_ image: UIImage) {
        if( image.size.width < 1024 || image.size.height < 1024 ) {
            self.performSegue(withIdentifier: "toDrawingView", sender: nil)
        }
        
        let nf = NumberFormatter()
        let message = "The resolution of the image is " +
            nf.string(from: NSNumber(value: Float(image.size.width)))! + "x" +
            nf.string(from: NSNumber(value: Float(image.size.height)))! + ". You can lower the resolution to simplify digitizing."
        let alert = UIAlertController(
            title: "Image Resolution", message: message, preferredStyle: .alert
        )
        let cancelAction: UIAlertAction = UIAlertAction(title: "Actual Size", style: .cancel) { action -> Void in
            self.performSegue(withIdentifier: "toDrawingView", sender: nil)
        }
        alert.addAction(cancelAction)
        
        // Minimum image size 1024x1024
        let scalex = image.size.width/1024.0
        let scaley = image.size.height/1024.0
        let scale = min(scalex, scaley)
        for inc in 0 ..< Int(scale) {
            let scaled_width = ceil(image.size.width/(scale - CGFloat(inc)))
            let scaled_height = ceil(image.size.height/(scale - CGFloat(inc)))
            let title = nf.string(from: NSNumber(value: Float(scaled_width)))! + "x" +
                nf.string(from: NSNumber(value: Float(scaled_height)))!
            let nextAction: UIAlertAction = UIAlertAction(title: title, style: .default) { action -> Void in
                // Resize image
                self.image = DetailedImageObject.resizeImage(image, newSize: CGSize(width: scaled_width, height: scaled_height))
                self.imageInfo.xDimension = Int(scaled_width)
                self.imageInfo.yDimension = Int(scaled_height)
                self.performSegue(withIdentifier: "toDrawingView", sender: nil)
            }
            alert.addAction(nextAction)
        }
        self.present(alert, animated: true, completion: nil)
    }
}


