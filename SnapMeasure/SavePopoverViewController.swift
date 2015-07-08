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


class SavePopoverViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource {
    var drawingVC : DrawingViewController?
    var menuController : PopupMenuController?
    var features : [FeatureObject] = []
    
    @IBOutlet weak var projectNameLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var featureTable: UITableView!
    
    override func viewDidLoad() {
        projectNameLabel.text = currentProject.name
        nameTextField.text = drawingVC!.detailedImage!.name
        
        for feat in drawingVC!.detailedImage!.features {
            features.append(feat as! FeatureObject)
        }
        
        featureTable.dataSource = self
        featureTable.rowHeight = 51
        featureTable.tableFooterView = UIView(frame: CGRect.zeroRect)
        featureTable.reloadData()
    }
    
    @IBAction func newProjectButtonPressed(sender: UIButton) {
        menuController = PopupMenuController()
        menuController!.initCellContents(1, cols: 1)
        
        let width : CGFloat = sender.frame.width+20
        let height : CGFloat = 45
        
        let textFeild = UITextField(frame: CGRect(x: 0, y: 0, width: width-10, height: height-10))
        textFeild.placeholder = "New Project"
        textFeild.delegate = self
        textFeild.tag = 1
        textFeild.becomeFirstResponder()
        
        menuController!.cellContents[0][0] = textFeild
        
        //set up menu Controller
        menuController!.modalPresentationStyle = UIModalPresentationStyle.Popover
        menuController!.preferredContentSize.width = width
        menuController!.tableView.rowHeight = height
        menuController!.preferredContentSize.height = menuController!.preferredHeight()
        menuController!.popoverPresentationController?.sourceRect = sender.bounds
        menuController!.popoverPresentationController?.sourceView = sender as UIView
        menuController!.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Left //will use a different direction if it can't be to the left
        
        self.presentViewController(menuController!, animated: true, completion: nil)
    }
    
    //Mark: - UITextFeildDelegateMethods
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField.tag == 1 {
            let project = NSEntityDescription.insertNewObjectForEntityForName("ProjectObject",
                inManagedObjectContext: drawingVC!.managedContext!) as! ProjectObject
            if textField.text == "" {
                project.name = "Project " + NSNumberFormatter().stringFromNumber(projects.count+1)!
            } else {
                project.name = textField.text
            }
            project.date = NSDate()
            currentProject = project
            projects.append(project)
            
            var error: NSError?
            drawingVC!.managedContext!.save(&error)
            
            projectNameLabel.text = currentProject.name
            menuController!.dismissViewControllerAnimated(true, completion: nil)
        }
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func loadProjectButtonPressed(sender: UIButton) {
        menuController = PopupMenuController()
        menuController!.initCellContents(projects.count, cols: 1)
        
        let width : CGFloat = sender.frame.width+20
        let height : CGFloat = 45
        for i in 0..<projects.count {
            let button = UIButton.buttonWithType(UIButtonType.System) as! UIButton
            button.setTitle(projects[i].name, forState: UIControlState.Normal)
            button.tag = i
            button.frame = CGRect(x: 0, y: 0, width: width, height: height)
            button.addTarget(self, action: "loadProject:", forControlEvents: UIControlEvents.TouchUpInside)
            menuController!.cellContents[i][0] = button
            
        }
        
        //set up menu Controller
        menuController!.modalPresentationStyle = UIModalPresentationStyle.Popover
        menuController!.preferredContentSize.width = width
        menuController!.tableView.rowHeight = height
        menuController!.preferredContentSize.height = menuController!.preferredHeight()
        menuController!.popoverPresentationController?.sourceRect = sender.bounds
        menuController!.popoverPresentationController?.sourceView = sender as UIView
        menuController!.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Left
        
        self.presentViewController(menuController!, animated: true, completion: nil)
    }
    
    func loadProject(sender: UIButton) {
        currentProject = projects[sender.tag]
        projectNameLabel.text = currentProject.name
        menuController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func saveAsNewButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func saveButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //Mark: UITableView Data Source Methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Features"
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return drawingVC!.detailedImage!.features.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("featureCell", forIndexPath: indexPath) as! FeatureCell
        cell.useFeature(features[indexPath.row])
        return cell
    }
    
}

class FeatureCell: UITableViewCell {

    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    
    var feature : FeatureObject?
    
    func useFeature(feat : FeatureObject) {
        self.feature = feat
        typeLabel.text = feat.type
        
        let numFormatter = NSNumberFormatter()
        sizeLabel.text = "Height: " + numFormatter.stringFromNumber(feat.height)! + " Width: " + numFormatter.stringFromNumber(feat.width)!
    }
    
}