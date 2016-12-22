//
//  FaciesPixmapViewController.swift
//  SnapMeasure
//
//  Created by next-shot on 6/16/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit
import CoreData


class FaciesCatalog {
    let faciesTypes = [
        "sandstone", "shale", "conglomerate", "limestone", "dolomite", "granites"
    ]
    let sedimentationStyles = [
        "planar-bedding", "cross-lamination", "ripple-marked-bedding", "gradded-bedding", "cut-and-fill-bedding"
    ]
    var faciesImages = [FaciesImageObject]()
    
    enum ImageType : Int { case facies = 0, sedimentationStyle, userDefined }
    
    func count(_ type: ImageType) -> Int {
        if( type == ImageType.facies ) {
            return faciesTypes.count
        } else if( type == ImageType.sedimentationStyle ) {
            return sedimentationStyles.count;
        } else {
          return faciesImages.count
        }
    }
    
    func element(_ index: (type: ImageType, index: Int)) -> (name: String, image: UIImage) {
        var name : String
        var image: UIImage
        if( index.type == ImageType.facies ) {
            image = UIImage(named: faciesTypes[index.index])!
            name = faciesTypes[index.index]

        } else if( index.type == ImageType.sedimentationStyle ) {
            image = UIImage(named: sedimentationStyles[index.index])!
            name = sedimentationStyles[index.index]

        } else {
            image = UIImage(data: faciesImages[index.index].imageData as Data)!
            name = faciesImages[index.index].name
        }
        return (name, image)
    }
    
    func name(_ index: (type: ImageType, index: Int)) -> String {
        if( index.type == ImageType.facies ) {
             return faciesTypes[index.index]
        } else if( index.type == ImageType.sedimentationStyle ) {
            return sedimentationStyles[index.index]
        } else {
            return faciesImages[index.index].name
        }
    }
    
    func image(_ name: String) -> (image: UIImage?, tile: Bool) {
        for n in faciesTypes {
            if( n == name ) {
                return (UIImage(named: name), true)
            }
        }
        for n in sedimentationStyles {
            if( n == name ) {
                return (UIImage(named: name), true)
            }
        }
        for fio in faciesImages {
            if( name == fio.name ) {
                return (UIImage(data: fio.imageData as Data), fio.tilePixmap.boolValue)
            }
        }
        return (nil,false)
    }
    
    func imageIndex(_ name: String) -> (type: ImageType, index:Int) {
        for (i,n) in faciesTypes.enumerated() {
            if( n == name ) {
                return (ImageType.facies, i)
            }
        }
        for (i,n) in sedimentationStyles.enumerated() {
            if( n == name ) {
                return (ImageType.sedimentationStyle, i)
            }
        }
        for (i,fio) in faciesImages.enumerated() {
            if( name == fio.name ) {
                return (ImageType.sedimentationStyle, i)
            }
        }
        return (ImageType.facies, -1)
    }
    
    func remove(_ type: ImageType, index: Int) {
        if( type == ImageType.userDefined ) {
           faciesImages.remove(at: index)
        }
    }
    
    func loadImages() {
        // Get the full detailed object from the selected name
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"FaciesImageObject")
        do  {
           let images = try managedContext.fetch(fetchRequest)
           self.faciesImages = images as! [FaciesImageObject]
        }  catch {
            
        }
    }
}

class FaciesTypeTablePickerController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    var faciesCatalog : FaciesCatalog?
    var typeButton : UIButton?
    var drawingView: DrawingView?
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return faciesCatalog!.count(FaciesCatalog.ImageType(rawValue: section)!)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PixmapCell", for: indexPath)
        let imageInfo = faciesCatalog!.element((FaciesCatalog.ImageType(rawValue: indexPath.section)!, indexPath.row))
        cell.imageView!.image = imageInfo.image
        cell.textLabel!.text = imageInfo.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let name = faciesCatalog!.name((FaciesCatalog.ImageType(rawValue: indexPath.section)!, indexPath.row))
        typeButton?.setTitle(name, for: UIControlState())
        drawingView?.faciesView.curImageName = name
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = FaciesCatalog.ImageType(rawValue: section)!
        if( section == FaciesCatalog.ImageType.facies ) {
            return "Facies"
        } else if( section == FaciesCatalog.ImageType.sedimentationStyle ) {
            return "Sedimentation Structure"
        } else {
            return "User Defined"
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        let section = FaciesCatalog.ImageType(rawValue: indexPath.section)!
        if( section != FaciesCatalog.ImageType.userDefined ) {
            return UITableViewCellEditingStyle.none
        } else {
            return UITableViewCellEditingStyle.delete
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let row = indexPath.row
        if( editingStyle == UITableViewCellEditingStyle.delete ) {
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.none)
            faciesCatalog!.remove(FaciesCatalog.ImageType.userDefined, index: row)
        }
    }
    
}

class FaciesPixmapViewController : UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var tableController = FaciesTypeTablePickerController()
    var picker = UIImagePickerController()
    var typeButton : UIButton?
    var drawingView: DrawingView?
    var faciesCatalog: FaciesCatalog?
    var drawingController : DrawingViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = tableController
        tableView.dataSource = tableController
        tableController.typeButton = typeButton
        tableController.drawingView = drawingView
        tableController.faciesCatalog = faciesCatalog
        
        picker.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if( drawingController != nil ) {
            //drawingController!.imageView.center = drawingController!.center
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if( drawingView != nil && faciesCatalog != nil ) {
            let index = faciesCatalog!.imageIndex(drawingView!.faciesView.curImageName)
            tableView.selectRow(
                at: IndexPath(
                    row: index.index, section: index.type.rawValue
                ),
                animated: true, scrollPosition: UITableViewScrollPosition.middle
            )
        }
    }
    
    @IBAction func AddPixmap(_ sender: AnyObject) {
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : Any]
    ) {
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        dismiss(animated: true, completion: nil)
        askImageName(chosenImage)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    func askImageName(_ image: UIImage) {
        var inputTextField : UITextField?
        let alert = UIAlertController(title: "Please give image a name", message: "And choose import method", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Name"
            inputTextField = textField
        }
        let noAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .default) { action -> Void in
        }
        alert.addAction(noAction)
        let yesScaleAction: UIAlertAction = UIAlertAction(title: "Ok & Scale", style: .default) { action -> Void in
            // scale to 128 pixels.
            let scale = 128.0/max(image.size.width, image.size.height)
            let size = CGSize(width: image.size.width*scale, height: image.size.height*scale)
            let nimage = self.resizeImage(image, newSize: size)
            
            // Create ImageObject
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            
            let detailedImage = NSEntityDescription.insertNewObject(forEntityName: "FaciesImageObject",
                into: managedContext) as? FaciesImageObject
            
            detailedImage!.imageData = UIImageJPEGRepresentation(nimage, 1.0)!
            detailedImage!.name = inputTextField!.text!
            detailedImage!.tilePixmap = true
            
            self.tableController.faciesCatalog!.faciesImages.append(detailedImage!)
            self.tableView.reloadData()
        }
        alert.addAction(yesScaleAction)
        
        let yesNoScaleAction: UIAlertAction = UIAlertAction(title: "Ok & Use as is", style: .default) { action -> Void in
            // Create ImageObject
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            
            let detailedImage = NSEntityDescription.insertNewObject(forEntityName: "FaciesImageObject",
                into: managedContext) as? FaciesImageObject
            
            detailedImage!.imageData = UIImageJPEGRepresentation(image, 1.0)!
            detailedImage!.name = inputTextField!.text!
            detailedImage!.tilePixmap = false
            
            self.tableController.faciesCatalog!.faciesImages.append(detailedImage!)
            self.tableView.reloadData()
        }
        alert.addAction(yesNoScaleAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func resizeImage(_ image: UIImage, newSize: CGSize) -> (UIImage) {
        let newRect = CGRect(x: 0,y: 0, width: newSize.width, height: newSize.height).integral
        let imageRef = image.cgImage
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        // Set the quality level to use when rescaling
        context!.interpolationQuality = CGInterpolationQuality.high
        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        
        context?.concatenate(flipVertical)
        // Draw into the context; this scales the image
        context?.draw(imageRef!, in: newRect)
        
        let newImageRef = context?.makeImage()
        let newImage = UIImage(cgImage: newImageRef!)
        
        // Get the resized image from the context and a UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
