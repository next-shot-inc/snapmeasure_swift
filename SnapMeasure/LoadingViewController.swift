//
//  LoadingViewController.swift
//  SnapMeasure
//
//  Created by next-shot on 5/27/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class DetailedImageProxy {
    var name: String
    var project: String
    var date: NSDate
    init(name: String, project: String, date: NSDate) {
        self.name = name
        self.project = project
        self.date = date
    }
    
    func getObject() -> DetailedImageObject? {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName:"DetailedImageObject")
        fetchRequest.predicate = NSPredicate(format: "date == %@", date)
        do {
            let objects = try managedContext.executeFetchRequest(fetchRequest)
            if( objects.count == 1 ) {
                return objects[0] as? DetailedImageObject
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}

class LoadingViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    var detailedImages: [DetailedImageProxy] = []
    var filteredDetailedImages: [DetailedImageProxy] = []
    var searchController = UISearchController()
    var managedContext : NSManagedObjectContext!
    var faciesCatalog = FaciesCatalog()
    var edited = false
    var scopeSelected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // appearance and layout customization
        self.tableView.backgroundView = UIImageView(image:UIImage(named:"loadingBackground"))
        self.tableView.estimatedRowHeight = 280
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.alwaysBounceVertical = false
        //self.tableView.allowsSelection = false
        
        self.searchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.showsScopeBar = true
            controller.searchBar.scopeButtonTitles = ["All"]
            var selectedScopeButton = 0
            for (index,project) in projects.enumerate() {
                controller.searchBar.scopeButtonTitles!.append(project.name)
                if( project == currentProject ) {
                    selectedScopeButton = index+1
                }
            }
            controller.searchBar.delegate = self
            controller.hidesNavigationBarDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.searchBar.selectedScopeButtonIndex = selectedScopeButton

            self.tableView.tableHeaderView = controller.searchBar
            return controller
        })()
        
        loadImages()
        
        updateSearchResultsForSearchController(searchController)
        
        self.tableView.reloadData()
        
        scopeSelected = true
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        detailedImages.removeAll(keepCapacity: false)
        filteredDetailedImages.removeAll(keepCapacity: false)
        faciesCatalog = FaciesCatalog()
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func loadImages() {
        // Get the full detailed object from the selected name
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName:"DetailedImageObject")
        fetchRequest.includesSubentities = false
        fetchRequest.propertiesToFetch = [ "name", "project.name", "date"]
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        
        do {
            let objects = try managedContext.executeFetchRequest(fetchRequest)
            for obj in objects {
                let name = obj.valueForKey("name") as? NSString
                let project = obj.valueForKey("project.name") as? NSString
                let date = obj.valueForKey("date") as? NSDate
                if( name != nil && project != nil ) {
                    detailedImages.append(DetailedImageProxy(name: name! as String, project: project! as String, date: date!))
                }
            }
        } catch {
            
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Mark: - Table View
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active || scopeSelected {
            return filteredDetailedImages.count
        } else {
            return detailedImages.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Card", forIndexPath: indexPath) as! CardTableViewCell
        cell.backgroundColor = UIColor.clearColor()
        cell.faciesCatalog = faciesCatalog
        cell.controller = self
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        var detailedImage: DetailedImageProxy
        if (searchController.active || scopeSelected) {
            detailedImage = filteredDetailedImages[indexPath.row]
        } else {
            detailedImage = detailedImages[indexPath.row]
        }
        
        cell.useImage(detailedImage)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (!self.searchController.active) {
            self.performSegueWithIdentifier("loadingToDrawing", sender: self)
        } else {
            // do something that deals with the fact that search controller is active
        }

    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "loadingToDrawing" {
            let drawingNC = segue.destinationViewController as! UINavigationController
            let drawingVC = drawingNC.topViewController as! DrawingViewController
            var destinationDetailedImageProxy : DetailedImageProxy
            if (self.searchController.active || scopeSelected ) {
                let indexPath = self.tableView.indexPathForSelectedRow!
                destinationDetailedImageProxy = filteredDetailedImages[indexPath.row]
            } else {
                let indexPath = self.tableView.indexPathForSelectedRow!
                destinationDetailedImageProxy = detailedImages[indexPath.row]
            }
            
            let destinationDetailedImage = destinationDetailedImageProxy.getObject()
            if( destinationDetailedImage != nil ) {
                drawingVC.detailedImage = destinationDetailedImage!
                drawingVC.image = UIImage(data: destinationDetailedImage!.imageData)
                
                //get ImageInfo
                var imageInfo = ImageInfo()
                imageInfo.xDimension = Int(drawingVC.image!.size.width)
                imageInfo.yDimension = Int(drawingVC.image!.size.height)
                imageInfo.latitude = destinationDetailedImage!.latitude?.doubleValue
                imageInfo.longitude = destinationDetailedImage!.longitude?.doubleValue
                imageInfo.compassOrienation = destinationDetailedImage!.compassOrientation?.doubleValue
                imageInfo.date = destinationDetailedImage!.date
                imageInfo.scale = destinationDetailedImage!.scale?.doubleValue
                
                drawingVC.imageInfo = imageInfo
            }
        }
        
        if( edited ) {
            do {
              try self.managedContext.save()
            } catch let error as NSError {
                print("Could not save in LoadingingViewController \(error), \(error.userInfo)")
            }
        }
    }
    
    // Mark: - Deletion
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            
            if (self.searchController.active || scopeSelected) {
                
            } else {
                
                let deletedImage = detailedImages[indexPath.row].getObject()
                if( deletedImage != nil ) {
                   managedContext.deleteObject(deletedImage!)
                }
                
                detailedImages.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                
                edited = true
            }
        }
    }
    
    // Mark: - Filtering
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filteredDetailedImages.removeAll(keepCapacity: false)
        let scopes = self.searchController.searchBar.scopeButtonTitles!
        let selectedScope = scopes[self.searchController.searchBar.selectedScopeButtonIndex]
        self.filterContentForSearchText(searchController.searchBar.text!, scope: selectedScope)
        self.tableView.reloadData();
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        // Filter the array using the filter method
        self.filteredDetailedImages = self.detailedImages.filter({( detailedImage: DetailedImageProxy) -> Bool in
            let categoryMatch = (scope == "All") || (detailedImage.project == scope)
            let stringMatch = detailedImage.name.rangeOfString(searchText)
            return categoryMatch && (searchText.isEmpty || stringMatch != nil)
            //return (stringMatch != nil)
        })
    }
    
    func filterContentForScope(scope: String = "All") {
        self.filteredDetailedImages = self.detailedImages.filter({( detailedImage: DetailedImageProxy) -> Bool in
            let categoryMatch = (scope == "All") || (detailedImage.project == scope)
            return categoryMatch
        })
    }
    

    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print(selectedScope)
        if self.searchController.active {
            self.updateSearchResultsForSearchController(self.searchController)
        } else {
            let scopes = self.searchController.searchBar.scopeButtonTitles!
            let scope = scopes[selectedScope]
            scopeSelected = true
            self.filterContentForScope(scope)
            self.tableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        scopeSelected = false
        //self.tableView.reloadData()
    }

    
    
    /** Deprecated
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
    self.filterContentForSearchText(searchString)
    return true
    } **/
    
    @IBAction func unwindToLoading (segue: UIStoryboardSegue) {
        
    }
    
}
