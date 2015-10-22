//
//  ViewController.swift
//  SnapMeasure
//
//  Created by next-shot on 5/21/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import UIKit
import CoreData

//global data types
var projects : [ProjectObject] = []
var currentProject : ProjectObject!

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    let picker = UIImagePickerController()
    var image :  UIImage?
    var imageInfo = ImageInfo()
    var menuController : PopupMenuController?
    var managedContext : NSManagedObjectContext?
    var activityView : UIActivityIndicatorView?
    
    @IBOutlet weak var selectExistingButton: UIButton!
    @IBOutlet weak var loadPicture: UIButton!
    @IBOutlet weak var newPicture: UIButton!
    @IBOutlet weak var showHistogram: UIButton!
    @IBOutlet weak var showMap: UIButton!
    @IBOutlet weak var projectNameLabel: UILabel!
    @IBOutlet weak var newProjectButton: UIButton!
    @IBOutlet weak var loadProjectButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        picker.delegate = self
        
        // Test if there are existing DetailedImageObject
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!
        
        var fetchRequest = NSFetchRequest(entityName:"DetailedImageObject")
        var error: NSError?
        var fetchedResultsCount = managedContext!.countForFetchRequest(fetchRequest,
            error: &error)
        selectExistingButton.enabled = fetchedResultsCount > 0
        
        if projects.count == 0 { //just opened app
            //get the most recent project worked on
            fetchRequest = NSFetchRequest(entityName: "ProjectObject")
            //sort so most recent is first
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            fetchedResultsCount = managedContext!.countForFetchRequest(fetchRequest,
                error: &error)
        
            if fetchedResultsCount > 0 {
                //println("Project already exists in context")
                let fprojects = try? managedContext!.executeFetchRequest(fetchRequest)
                if( fprojects != nil ) {
                   projects = fprojects as! [ProjectObject]
                   currentProject = projects[0] as ProjectObject
                }

            } else {
                //println("Creating a new default project")
                let project = NSEntityDescription.insertNewObjectForEntityForName(
                    "ProjectObject",
                    inManagedObjectContext: managedContext!
                ) as! ProjectObject
                project.name = "Project 1"
                project.date = NSDate()
                currentProject = project
                projects.append(project)
                do {
                    try managedContext!.save()
                } catch {
                    
                }
            }
        }
        
        projectNameLabel.text = currentProject.name
        
        // Initialize button look
        /*
        let radius : CGFloat = 10.0
        let bgColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
        //UIButton.appearance().layer.cornerRadius = radius
        //UIButton.appearance().backgroundColor = bgColor
       
        selectExistingButton.layer.cornerRadius = radius
        selectExistingButton.backgroundColor = bgColor
        loadPicture.layer.cornerRadius = radius
        loadPicture.backgroundColor = bgColor
        newPicture.layer.cornerRadius = radius
        newPicture.backgroundColor = bgColor
        showHistogram.layer.cornerRadius = radius
        showHistogram.backgroundColor = bgColor
        showMap.layer.cornerRadius = radius
        showMap.backgroundColor = bgColor
        newProjectButton.layer.cornerRadius = radius
        newProjectButton.backgroundColor = bgColor
        newProjectButton.layer.cornerRadius = radius
        newProjectButton.backgroundColor = bgColor
        loadProjectButton.layer.cornerRadius = radius
        loadProjectButton.backgroundColor = bgColor
        */

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imagePickerController(
        picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]
    ) {
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        image = chosenImage
        imageInfo.xDimension = Int(image!.size.width)
        imageInfo.yDimension = Int(image!.size.height)
        let cimage = image!.CIImage
        if( cimage != nil ) {
            cimage?.properties
        }
        dismissViewControllerAnimated(true, completion: nil)
        
        self.performSegueWithIdentifier("toDrawingView", sender: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func selectPhotoFromLibrary(sender: AnyObject) {
        picker.allowsEditing = false
        picker.sourceType = .PhotoLibrary
        presentViewController(picker, animated: true, completion: nil)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if( segue.identifier == "toDrawingView" ) {
            let destinationVC = segue.destinationViewController as? DrawingViewController
            if( destinationVC != nil ) {
                destinationVC!.image = image
                destinationVC!.imageInfo = imageInfo
            } else {
                let navigationVC = segue.destinationViewController as? UINavigationController
                if( navigationVC != nil ) {
                    for vc in navigationVC!.viewControllers {
                        let dvc = vc as? DrawingViewController
                        if( dvc != nil) {
                            dvc!.image = image
                            dvc!.imageInfo = imageInfo
                        }
                    }
                }
            }
        } else if( segue.identifier == "toLoadingView" || segue.identifier == "toMapView" ) {
            activityView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
            activityView!.color = UIColor.blueColor()
            activityView!.center = self.view.center
            activityView!.startAnimating()
            self.view.addSubview(activityView!)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        var fetchRequest = NSFetchRequest(entityName:"DetailedImageObject")
        var error: NSError?
        var fetchedResultsCount = managedContext.countForFetchRequest(fetchRequest,
            error: &error)
        
        selectExistingButton.enabled = fetchedResultsCount > 0
        
        fetchRequest = NSFetchRequest(entityName:"FeatureObject") //default fetch request is for all Features
        fetchRequest.predicate = NSPredicate(format: "image.project.name==%@", currentProject.name)
        fetchedResultsCount = managedContext.countForFetchRequest(fetchRequest,
            error: &error)
        
        showHistogram.enabled = fetchedResultsCount > 1
    }
    
    override func viewDidDisappear(animated: Bool) {
        if( activityView != nil ) {
            activityView!.stopAnimating()
            activityView!.removeFromSuperview()
            activityView = nil
        }
    }
    
    @IBAction func selectFromExisting(sender: AnyObject) {
        //self.performSegueWithIdentifier("toSelectExisting", sender: nil)
    }
    
    @IBAction func newProjectButtonTapped(sender: UIButton) {
        menuController = PopupMenuController()
        menuController!.initCellContents(1, cols: 1)
        
        let width : CGFloat = sender.frame.width+20
        let height : CGFloat = 45
        
        let textFeild = UITextField(frame: CGRect(x: 0, y: 0, width: width-10, height: height-10))
        textFeild.placeholder = "New Project"
        textFeild.delegate = self
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
        let project = NSEntityDescription.insertNewObjectForEntityForName("ProjectObject",
            inManagedObjectContext: managedContext!) as! ProjectObject
        if textField.text == "" {
            project.name = "Project " + NSNumberFormatter().stringFromNumber(projects.count+1)!
        } else {
            project.name = textField.text!
        }
        project.date = NSDate()
        currentProject = project
        projects.append(project)
        
        do {
           try managedContext!.save()
        } catch {
            
        }
        
        projectNameLabel.text = currentProject.name
        menuController!.dismissViewControllerAnimated(true, completion: nil)

    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func loadProjectButtonTapped(sender: UIButton) {
        menuController = PopupMenuController()
        menuController!.initCellContents(projects.count, cols: 1)
        
        let width : CGFloat = sender.frame.width+20
        let height : CGFloat = 45
        for i in 0..<projects.count {
            let button = UIButton(type: UIButtonType.System)
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
       
    @IBAction func unwindToMainMenu (segue: UIStoryboardSegue) {
    
    }
}

