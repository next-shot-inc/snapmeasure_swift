//
//  ViewController.swift
//  SnapMeasure
//
//  Created by next-shot on 5/21/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import UIKit
import CoreData
import MessageUI

//global data types
var projects : [ProjectObject] = []
var currentProject : ProjectObject!

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate {
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
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!
        
        var fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"DetailedImageObject")
        var fetchedResultsCount = 0
        do {
            try fetchedResultsCount = managedContext!.count(for: fetchRequest)
        } catch {
        }
        selectExistingButton.isEnabled = fetchedResultsCount > 0
        
        if projects.count == 0 { //just opened app
            //get the most recent project worked on
            fetchRequest = NSFetchRequest(entityName: "ProjectObject")
            //sort so most recent is first
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            var fetchedResultsCount = 0
            do {
               try fetchedResultsCount = managedContext!.count(for: fetchRequest)
            } catch {
                
            }
        
            if fetchedResultsCount > 0 {
                //println("Project already exists in context")
                let fprojects = try? managedContext!.fetch(fetchRequest)
                if( fprojects != nil ) {
                   projects = fprojects as! [ProjectObject]
                   currentProject = projects[0] as ProjectObject
                }

            } else {
                //println("Creating a new default project")
                let project = NSEntityDescription.insertNewObject(
                    forEntityName: "ProjectObject",
                    into: managedContext!
                ) as! ProjectObject
                project.name = "Project 1"
                project.date = Date()
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
        _ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]
    ) {
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        dismiss(animated: true, completion: nil)
        
        askForPictureSize(chosenImage)
    }
    
    // Ask to lower potentially the resolution of the image
    // And perform segue
    func askForPictureSize(_ image: UIImage) {
        if( image.size.width < 1024 || image.size.height < 1024 ) {
            self.image = image
            self.imageInfo.xDimension = Int(image.size.width)
            self.imageInfo.yDimension = Int(image.size.height)
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
            self.image = image
            self.imageInfo.xDimension = Int(image.size.width)
            self.imageInfo.yDimension = Int(image.size.height)
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

    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func selectPhotoFromLibrary(_ sender: AnyObject) {
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier == "toDrawingView" ) {
            let destinationVC = segue.destination as? DrawingViewController
            if( destinationVC != nil ) {
                destinationVC!.image = image
                destinationVC!.imageInfo = imageInfo
            } else {
                let navigationVC = segue.destination as? UINavigationController
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
            activityView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            activityView!.color = UIColor.blue
            activityView!.center = self.view.center
            activityView!.startAnimating()
            self.view.addSubview(activityView!)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        var fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"DetailedImageObject")
        var fetchedResultsCount = 0
        do {
            try fetchedResultsCount = managedContext.count(for: fetchRequest)
        } catch {
            
        }
        
        selectExistingButton.isEnabled = fetchedResultsCount > 0
        
        fetchRequest = NSFetchRequest(entityName:"FeatureObject") //default fetch request is for all Features
        fetchRequest.predicate = NSPredicate(format: "image.project.name==%@", currentProject.name)
        do {
           try fetchedResultsCount = managedContext.count(for: fetchRequest)
        } catch {
            
        }
        
        showHistogram.isEnabled = fetchedResultsCount > 1
        
        if projects.count == 0 {
            //get the most recent project worked on
            fetchRequest = NSFetchRequest(entityName: "ProjectObject")
            //sort so most recent is first
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            do {
               try fetchedResultsCount = managedContext.count(for: fetchRequest)
            } catch {
            }
            
            if fetchedResultsCount > 0 {
                //println("Project already exists in context")
                let fprojects = try? managedContext.fetch(fetchRequest)
                if( fprojects != nil ) {
                    projects = fprojects as! [ProjectObject]
                    currentProject = projects[0] as ProjectObject
                }
            }
        }

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if( activityView != nil ) {
            activityView!.stopAnimating()
            activityView!.removeFromSuperview()
            activityView = nil
        }
    }
    
    @IBAction func selectFromExisting(_ sender: AnyObject) {
        //self.performSegueWithIdentifier("toSelectExisting", sender: nil)
    }
    
    @IBAction func newProjectButtonTapped(_ sender: UIButton) {
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
    
    // Perform the creation of the new project 
    func setNewProject(_ textField: UITextField) {
        let project = NSEntityDescription.insertNewObject(forEntityName: "ProjectObject",
            into: managedContext!) as! ProjectObject
        if textField.text == "" {
            project.name = "Project " + NumberFormatter().string(from: NSNumber(value: projects.count+1))!
        } else {
            project.name = textField.text!
        }
        project.date = Date()
        currentProject = project
        projects.append(project)
        
        do {
           try managedContext!.save()
        } catch {
            
        }
        
        projectNameLabel.text = currentProject.name
    }
    
    @IBAction func loadProjectButtonTapped(_ sender: UIButton) {
        menuController = PopupMenuController()
        menuController!.initCellContents(projects.count, cols: 1)
        
        let longDateFormatter = DateFormatter()
        longDateFormatter.locale = Locale.current
        longDateFormatter.setLocalizedDateFormatFromTemplate("MMM d YY")
        longDateFormatter.timeZone = TimeZone.current
        
        let width : CGFloat = self.view.frame.width
        let height : CGFloat = 45
        for i in 0..<projects.count {
            let button = UIButton(type: UIButtonType.system)
            let longDate = longDateFormatter.string(from: projects[i].date)
            // Display some information about the project (name, number of images, date of last modification)
            button.setTitle("\(projects[i].name) (\(projects[i].detailedImages.count)) - \(longDate)", for: UIControlState())
            button.tag = i
            button.frame = CGRect(x: 0, y: 0, width: width, height: height)
            button.addTarget(self, action: #selector(ViewController.loadProject(_:)), for: UIControlEvents.touchUpInside)
            menuController!.cellContents[i][0] = button

        }
        
        //set up menu Controller
        menuController!.modalPresentationStyle = UIModalPresentationStyle.popover
        //menuController!.preferredContentSize.width = width
        menuController!.tableView.rowHeight = height
        //menuController!.preferredContentSize.height = menuController!.preferredHeight()
        menuController!.popoverPresentationController?.sourceRect = sender.bounds
        menuController!.popoverPresentationController?.sourceView = sender as UIView
        menuController!.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.left
        
        self.present(menuController!, animated: true, completion: nil)

    }
    
    // Callback linked to each button of the PopupMenuController initialized in the loadProjectButtonTapped
    @objc func loadProject(_ sender: UIButton) {
        currentProject = projects[sender.tag]
        projectNameLabel.text = currentProject.name
        menuController!.dismiss(animated: true, completion: nil)
    }
       
    @IBAction func deleteProject(_ sender: AnyObject) {
        let alertController = UIAlertController(
            title: "Do you really want to delete project", message: currentProject.name + "?", preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
            (action : UIAlertAction!) -> Void in
        })
        let saveAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: {
            alert -> Void in
            
            self.doDeleteCurrentProject()
        })
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: false, completion: nil)
    }
    
    // Perform the deletion of the curent project
    func doDeleteCurrentProject() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        for (i,p) in projects.enumerated(){
            if( p === currentProject ) {
                projects.remove(at: i)
                for imageobj in currentProject.detailedImages {
                    let io = imageobj as? DetailedImageObject
                    if( io != nil ) {
                        io!.removeImage()
                    }
                }
                managedContext.delete(currentProject)
                
                // Reset current project
                currentProject = projects[0]
                projectNameLabel.text = currentProject.name
                break
            }
        }
        
        // Persist project destruction
        do {
            try managedContext.save()
        } catch {
            
        }
    }
    
    @IBAction func unwindToMainMenu (_ segue: UIStoryboardSegue) {
    
    }
    
    // Send support/enhancement request
    @IBAction func sendMail(_ sender: UIButton) {
        if( !MFMailComposeViewController.canSendMail() ) {
            print("Mail service unavailable")
            return
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.setSubject("Issue with .../Suggestion for ...")
        mailComposer.setToRecipients(["support@next-shot-inc.com"])
        mailComposer.setMessageBody("Thank you for your feedback - from the development team @next-shot", isHTML: true)
        mailComposer.mailComposeDelegate = self
        present(mailComposer, animated: true, completion: nil)
    }
    
    func mailComposeController(
        _ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?
    ) {
        print(result)
        controller.dismiss(animated: true, completion: nil)
    }
    
    // Clean orphans image files linked to old bugs.
    @IBAction func cleanImages(_ sender: Any) {
        var imageNames = [String]()
        for p in projects {
            for imageobj in p.detailedImages {
                let io = imageobj as? DetailedImageObject
                if( io != nil ) {
                    imageNames.append(io!.imageFile)
                    imageNames.append(io!.thumbImageFile)
                }
            }
        }
        
        let fileMngr = FileManager.default;
        
        // Full path to documents directory
        let docs = fileMngr.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        
        // List all contents of directory and test if the file is an orphan image File
        do {
            let files = try fileMngr.contentsOfDirectory(atPath:docs)
            for f in files {
                var found = false
                for imf in imageNames {
                    // Tile image files have suffix _I_J
                    if( f.endIndex >= imf.endIndex && f[..<imf.endIndex] == imf ) {
                        found = true
                        break
                    }
                }
                if( !found ) {
                    // It is not an existing image File
                    let testUUid = UUID()
                    let uidString = testUUid.uuidString
                    if( f.endIndex >= uidString.endIndex ) {
                        // Test if can be an image File (loading its name into a UUID)
                        let substring = f[..<uidString.endIndex]
                        let uuidTest = UUID(uuidString: String(substring))
                        if( uuidTest != nil ) {
                            // It is an orphan image file or tile image file, remove it
                            print(f)
                            let filePath = "\(docs)/\(f)"
                            if( fileMngr.fileExists(atPath: filePath) ) {
                                do {
                                    try fileMngr.removeItem(atPath: filePath)
                                } catch {
                                    
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            
        }
    
        // Redo lost thumbImage files (due to a intermediary version bug)
        for p in projects {
            for imageobj in p.detailedImages {
                let io = imageobj as? DetailedImageObject
                if( io != nil ) {
                    let thumbfilePath = "\(docs)/\(io!.thumbImageFile)"
                    if( !fileMngr.fileExists(atPath: thumbfilePath) ) {
                        let filePath = "\(docs)/\(io!.imageFile)"
                        let image = UIImage(contentsOfFile:filePath)
                        if( image == nil ) {
                            continue
                        }
                        
                        // Create thumbNail version of it - Around 100x100 pixels
                        let scalex = image!.size.width/128.0
                        let scaley = image!.size.height/128.0
                        let scale = min(scalex, scaley)
                        let small_image = DetailedImageObject.resizeImage(
                            image!,
                            newSize: CGSize(width: ceil(image!.size.width/scale), height: ceil(image!.size.height/scale))
                        )
                        
                        let small_data = UIImageJPEGRepresentation(small_image, 1.0)
                        if( small_data == nil ) {
                            print("Could not generate JPEG representation of small image")
                        }
                        
                        if( ((try? small_data!.write(to: URL(fileURLWithPath: thumbfilePath), options: [.atomic])) != nil) == false ) {
                            print("Could not save thumb image file")
                        }
                    }
                }
            }
        }
    }
}

