//
//  OrientationController.swift
//  SnapMeasure
//
//  Created by next-shot on 7/1/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit
import CoreMotion
import CoreLocation

struct Vector3 {
    var x : Double // North
    var y : Double // East
    var z : Double // Vertical
    
    func strikeAndDip() -> (strike: Double, dip: Double) {
        var strike = acos(x/sqrt(x*x+y*y))
        var dip = asin(sqrt(x*x+y*y)/sqrt(x*x+y*y+z*z))
        
        dip = 180/Double.pi * dip
        strike = 180/Double.pi * strike
        return (strike, dip)
    }
}

class OrientationController : UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var dipLabel: UILabel!
    @IBOutlet weak var strikeLabel: UILabel!
    
    var motionManager = CMMotionManager()
    var locationManager = CLLocationManager()
    var curNormal = Vector3(x: 0, y: 0, z:0)
    var curLocation : CLLocation?
    var drawingViewController : DrawingViewController?
    var currentButton : UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(
            using: CMAttitudeReferenceFrame.xTrueNorthZVertical,
            to: OperationQueue.current!, withHandler: { (motion, error) -> Void in
                if( motion == nil ) {
                    return
                }
                let rotquat = motion!.attitude.quaternion
                // find the normal vector to the device
                let norm = self.rotate(rotquat, vec: Vector3(x: 0, y:0, z:1))
                self.curNormal = norm
                // compute strike and dip from the normal vector
                let sad = norm.strikeAndDip()
                // display
                self.dipLabel.attributedText = Utility.formatAngle(sad.dip, orient: false)
                self.strikeLabel.attributedText = Utility.formatAngle(sad.strike, orient: true)
            }
        )
        
        locationManager.delegate = self
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func rotate( _ quat: CMQuaternion, vec: Vector3) -> Vector3 {
       let num = quat.x * 2.0;
       let num2 = quat.y * 2.0;
       let num3 = quat.z * 2.0;
       let num4 = quat.x * num;
       let num5 = quat.y * num2;
       let num6 = quat.z * num3;
       let num7 = quat.x * num2;
       let num8 = quat.x * num3;
       let num9 = quat.y * num3;
       let num10 = quat.w * num;
       let num11 = quat.w * num2;
       let num12 = quat.w * num3;
       return Vector3(
         x : (1.0 - (num5 + num6)) * vec.x + (num7 - num12) * vec.y + (num8 + num11) * vec.z,
         y : (num7 + num12) * vec.x + (1.0 - (num4 + num6)) * vec.y + (num9 - num10) * vec.z,
         z : (num8 - num11) * vec.x + (num9 + num10) * vec.y + (1.0 - (num4 + num5)) * vec.z
       )
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // test the age of the location measurement to determine if the measurement is cached
        // in most cases you will not want to rely on cached measurements
        let newLocation = locations.last
        if( newLocation == nil ) {
            return
        }
        let locationAge = newLocation!.timestamp.timeIntervalSinceNow;
        if (abs(locationAge) > 5.0) {
            return;
        }
        // test that the horizontal accuracy does not indicate an invalid measurement
        if (newLocation!.horizontalAccuracy < 0) {
            return;
        }
        if( curLocation == nil || curLocation!.horizontalAccuracy > newLocation!.horizontalAccuracy ) {
            curLocation = newLocation!
        }
    }
    
    // this is called when authorization status changes and when locationManager is initialiazed
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedAlways || status == CLAuthorizationStatus.authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }

    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
    }
    
    @IBAction func doLocate(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
        if( drawingViewController != nil ) {
            let drawingView = drawingViewController!.imageView as! DrawingView
            drawingView.dipMarkerView.pickTool = DipMarkerPickTool(
                normal: curNormal,
                realLocation: curLocation,
                toolMode: drawingView.drawMode.rawValue,
                prevButton: currentButton
            )
            drawingView.drawMode = DrawingView.ToolMode.dipMarker
        }
    }
    
    @IBAction func doStore(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
        if( drawingViewController != nil && curLocation != nil ) {
            let drawingView = drawingViewController!.imageView as! DrawingView
            drawingView.dipMarkerView.addPoint(realLocation: curLocation!, normal: curNormal)
            drawingViewController?.highlightButton(currentButton!)
        }
    }
    
    @IBAction func doCancel(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }

}
