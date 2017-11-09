//
//  SavePopoverViewController.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 7/7/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit
import CoreData


class SavePopoverViewController: UIViewController, UITableViewDataSource, FeatureCellDelegate {
    var drawingVC : DrawingViewController?
    var menuController : PopupMenuController?
    var features : [FeatureObject] = []
    
    @IBOutlet weak var projectNameLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var featureTable: UITableView!
    @IBOutlet weak var warningLabel: UILabel!
    
    override func viewDidLoad() {
        currentProject = drawingVC!.detailedImage!.project
        projectNameLabel.text = currentProject.name
        nameTextField.text = drawingVC!.detailedImage!.name
        // If the image name is the default value (from the data model) or is empty
        if( nameTextField.text == "New Image" || nameTextField.text == "" ) {
            // Provide a self incrementing image name (this latest image is already in the count)
            nameTextField.text = "Image " + String(currentProject.detailedImages.count)
        }
        
        let drawingView = drawingVC!.imageView as! DrawingView
        //get scale for the image
        let scale = drawingView.getScale()
        if(!scale.defined) {
            warningLabel.isHidden = false
            warningLabel.text = "WARNING:\nNo scale defined for this image"
            warningLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
            warningLabel.numberOfLines = 0
        }
        
        for feat in drawingVC!.detailedImage!.features {
            features.append(feat as! FeatureObject)
        }
        
        featureTable.dataSource = self
        featureTable.rowHeight = 51
        featureTable.tableFooterView = UIView(frame: CGRect.zero)
        featureTable.reloadData()
        
    }
    
    @IBAction func newProjectButtonPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Enter project name", message: "", preferredStyle: .alert)
        alertController.addTextField { (textField: UITextField) -> Void in
            textField.placeholder = "New Project"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: {
            (action : UIAlertAction!) -> Void in
        })
        let saveAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {
            alert -> Void in
            
            let firstTextField = alertController.textFields![0] as UITextField
            self.setNewProject(firstTextField)
        })

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: false, completion: nil)
    }
    
    func setNewProject(_ textField: UITextField) {
        let project = NSEntityDescription.insertNewObject(forEntityName: "ProjectObject",
            into: drawingVC!.managedContext!) as! ProjectObject
        if textField.text == "" {
            project.name = "Project " + NumberFormatter().string(from: NSNumber(value: projects.count+1))!
        } else {
            project.name = textField.text!
        }
        project.date = Date()
        currentProject = project
        projects.append(project)
        
        do {
            try drawingVC!.managedContext!.save()
        } catch let error as NSError {
            print(error)
        }
        
        projectNameLabel.text = currentProject.name
        
    }
    
    @IBAction func loadProjectButtonPressed(_ sender: UIButton) {
        menuController = PopupMenuController()
        menuController!.initCellContents(projects.count, cols: 1)
        
        var labelWidth : CGFloat = 0
        for i in 0..<projects.count {
           let t = projects[i].name as NSString
           let size = t.size(withAttributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: UIFont.buttonFontSize)])
           labelWidth = max(labelWidth, size.width)
        }
        
        let width : CGFloat = max(sender.frame.width+40, labelWidth+40)
        let height : CGFloat = 45
        for i in 0..<projects.count {
            let button = UIButton(type: UIButtonType.system)
            button.setTitle(projects[i].name, for: UIControlState())
            button.tag = i
            button.frame = CGRect(x: 0, y: 0, width: width, height: height)
            button.addTarget(self, action: #selector(SavePopoverViewController.loadProject(_:)), for: UIControlEvents.touchUpInside)
            menuController!.cellContents[i][0] = button
            
        }
        
        //set up menu Controller
        menuController!.modalPresentationStyle = UIModalPresentationStyle.popover
        //menuController!.preferredContentSize.width = width
        menuController!.tableView.rowHeight = height
        //menuController!.preferredContentSize.height = menuController!.preferredHeight()
        menuController!.popoverPresentationController?.sourceRect = sender.bounds
        menuController!.popoverPresentationController?.sourceView = sender as UIView
        menuController!.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
        
        self.present(menuController!, animated: true, completion: nil)
    }
    
    @objc func loadProject(_ sender: UIButton) {
        currentProject = projects[sender.tag]
        projectNameLabel.text = currentProject.name
        menuController!.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveAsNewButtonPressed(_ sender: AnyObject) {
        let managedContext = drawingVC!.managedContext
        //create a new detailedImageObject in the contect
        let newImage = NSEntityDescription.insertNewObject(forEntityName: "DetailedImageObject",
            into: drawingVC!.managedContext) as! DetailedImageObject
        
        let drawingView = drawingVC!.imageView as! DrawingView
        //get scale for the image
        let scale = drawingView.getScale()
        if(scale.defined) {
            newImage.scale = scale.scale as NSNumber?
        } else {
            
        }
        
        //update detailedImage and lines
        //detailedImage!.name = outcropName.text!
        newImage.longitude = drawingVC!.imageInfo.longitude as NSNumber?
        newImage.latitude = drawingVC!.imageInfo.latitude as NSNumber?
        newImage.compassOrientation = drawingVC!.imageInfo.compassOrienation as NSNumber?
        newImage.altitude = drawingVC!.imageInfo.altitude as NSNumber?
        newImage.date = Date()
        newImage.project = currentProject
        newImage.features = drawingVC!.detailedImage!.features.copy() as! NSSet
        if (nameTextField.text != "") {
            newImage.name = nameTextField.text!
        } else {
            newImage.name = "Image " + String(currentProject.detailedImages.count)
        }
        
        // Attention: image files are shared between different version of the same interpretation.
        let currentImage = drawingVC!.detailedImage!
        newImage.imageFile = currentImage.imageFile
        newImage.thumbImageFile = currentImage.thumbImageFile
        newImage.imageWidth = currentImage.imageWidth
        newImage.imageHeight = currentImage.imageHeight
        
        // Update project date
        currentProject.date = Date()
        
        saveDrawingView(drawingView, image: newImage, managedContext: managedContext!)
        
        //save the managedObjectContext
        do {
           try drawingVC!.managedContext.save()
           print("Saved the ManagedObjectContext")
        } catch let error as NSError {
            print("Could not save in DrawingViewController \(error), \(error.userInfo)")
        }

        drawingVC!.hasChanges = false

        self.dismiss(animated: true, completion: nil)
        drawingVC!.performSegue(withIdentifier: "unwindFromDrawingToMain", sender: drawingVC!)
    }
    
    @IBAction func saveButtonPressed(_ sender: AnyObject) {
        let managedContext = drawingVC!.managedContext
        //create a new detailedImageObject in the contect
        let currentImage = drawingVC!.detailedImage!
        
        let drawingView = drawingVC!.imageView as! DrawingView
        //get scale for the image
        let scale = drawingView.getScale()
        if(scale.defined) {
            currentImage.scale = scale.scale as NSNumber?
        } else {

        }
        
        //update detailedImage and lines
        //detailedImage!.name = outcropName.text!
        currentImage.project = currentProject
        currentImage.longitude = drawingVC!.imageInfo.longitude as NSNumber?
        currentImage.latitude = drawingVC!.imageInfo.latitude as NSNumber?
        currentImage.compassOrientation = drawingVC!.imageInfo.compassOrienation as NSNumber?
        currentImage.altitude = drawingVC!.imageInfo.altitude as NSNumber?
        currentImage.date = drawingVC!.imageInfo.date
        if (nameTextField.text != "") {
            currentImage.name = nameTextField.text!
        } else {
            currentImage.name = "Image " + String(currentProject.detailedImages.count+1)
        }
        
        // Update project date
        currentProject.date = Date()
   
        saveDrawingView(drawingView, image: currentImage, managedContext: managedContext!)
        
        //save the managedObjectContext
        do {
            try managedContext?.save()
        } catch let error as NSError {
            print("Could not save in DrawingViewController \(error), \(error.userInfo)")
        }
        self.dismiss(animated: true, completion: nil)
        
        drawingVC!.hasChanges = false
        drawingVC!.performSegue(withIdentifier: "unwindFromDrawingToMain", sender: drawingVC!)
    }
    
    func saveDrawingView(_ drawingView: DrawingView, image: DetailedImageObject, managedContext: NSManagedObjectContext) {
        let linesSet = NSMutableSet()
        
        // Always store the coordinates in image coordinates (reverse any viewing transform due to scaling)
        let affineTransform = drawingView.affineTransform.inverted()
        for line in drawingView.lineView.lines  {
            let lineObject = NSEntityDescription.insertNewObject(forEntityName: "LineObject",
                into: managedContext) as? LineObject
            
            lineObject!.name = line.name
            lineObject!.colorData = NSKeyedArchiver.archivedData(
                withRootObject: UIColor(cgColor: line.color)
            )
            lineObject!.type = LineViewTool.typeName(line.role)
            
            var points : [CGPoint] = Array<CGPoint>(repeating: CGPoint(x: 0, y:0), count: line.points.count)
            for i in 0 ..< line.points.count {
                points[i] = line.points[i].applying(affineTransform)
            }
            
            lineObject!.pointData = Data(bytes: points, count: points.count * MemoryLayout<CGPoint>.size)
            
            lineObject!.image = image
            linesSet.add(lineObject!)
        }
        image.lines = linesSet
        
        let faciesVignetteSet = NSMutableSet()
        
        for fc in drawingView.faciesView.faciesColumns {
            for fv in fc.faciesVignettes {
                let faciesVignetteObject = NSEntityDescription.insertNewObject(
                    forEntityName: "FaciesVignetteObject", into: managedContext) as? FaciesVignetteObject
                
                faciesVignetteObject!.imageName = fv.imageName
                let scaledRect = fv.rect.applying(affineTransform)
                faciesVignetteObject!.rect = NSValue(cgRect: scaledRect)
                faciesVignetteSet.add(faciesVignetteObject!)
            }
        }
        image.faciesVignettes = faciesVignetteSet
        
        let textSet = NSMutableSet()
        for tv in drawingView.textView.subviews {
            let label = tv as? UILabel
            if( label != nil ) {
                let textObject = NSEntityDescription.insertNewObject(
                    forEntityName: "TextObject", into: managedContext) as? TextObject
                
                let scaledRect = tv.frame.applying(affineTransform)
                textObject!.rect = NSValue(cgRect: scaledRect)
                
                textObject!.string = label!.text!
                
                textSet.add(textObject!)
            }
        }
        image.texts = textSet
        
        let dipMeterPoints = NSMutableSet()
        for dmp in drawingView.dipMarkerView.points {
            let dmpo = NSEntityDescription.insertNewObject(
                forEntityName: "DipMeterPointObject", into: managedContext) as? DipMeterPointObject
            var tpoint = dmp.loc
            if( dmp.loc.x != 0 && dmp.loc.y != 0 ) {
                tpoint = dmp.loc.applying(affineTransform)
            }
            dmpo!.locationInImage = NSValue(cgPoint: tpoint)
            dmpo!.realLocation = dmp.realLocation
            let sad = dmp.normal.strikeAndDip()
            dmpo!.strike = NSNumber(value: sad.strike)
            dmpo!.dip = NSNumber(value: sad.dip)
            if( dmp.snappedLine != nil ) {
                dmpo!.feature = dmp.snappedLine!.name
            } else {
                dmpo!.feature = "unassigned"
            }
            dipMeterPoints.add(dmpo!)
        }
        image.dipMeterPoints = dipMeterPoints
        
    }
    
    //Mark: UITableView Data Source Methods for table of Features
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Features"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return features.count == 0 ? 1 : features.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if( features.count == 0 ) {
            return tableView.dequeueReusableCell(withIdentifier: "NoFeaturesCell", for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "featureCell", for: indexPath) as! FeatureCell
            cell.useFeature(features[indexPath.row])
            cell.tag = indexPath.row
            cell.delegate = self
            return cell
        }
    }
    
    //Mark : FeatureCellDelegate Methods
    
    func deleteFeature(_ cell: FeatureCell) {
        //delete from data store
        drawingVC!.managedContext.delete(cell.feature!)
        
        //delete from table view
        
        features.remove(at: cell.tag)
        let indexPath = featureTable.indexPath(for: cell)!
        
        featureTable.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
        //featureTable.reloadData()
    }
    
}

protocol FeatureCellDelegate: class {
    func deleteFeature(_ cell : FeatureCell)
}

class FeatureCell: UITableViewCell {

    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    
    var feature : FeatureObject?
    var delegate : FeatureCellDelegate?
    
    func useFeature(_ feat : FeatureObject) {
        self.feature = feat
        typeLabel.text = feat.type
        
        let numFormatter = NumberFormatter()
        numFormatter.numberStyle = NumberFormatter.Style.decimal
        numFormatter.usesSignificantDigits = true
        numFormatter.maximumSignificantDigits = 3
        numFormatter.minimumSignificantDigits = 0
        sizeLabel.text = "Height: " + numFormatter.string(from: feat.height)! + " Width: " + numFormatter.string(from: feat.width)!
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        self.delegate?.deleteFeature(self)
    }
    
}
