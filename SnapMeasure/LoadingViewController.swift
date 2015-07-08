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

class LoadingViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    var detailedImages: [DetailedImageObject] = []
    var filteredDetailedImages: [DetailedImageObject] = []
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
            for project in projects {
                controller.searchBar.scopeButtonTitles!.append(project.name)
            }
            controller.searchBar.delegate = self
            controller.hidesNavigationBarDuringPresentation = false
            controller.searchBar.sizeToFit()

            self.tableView.tableHeaderView = controller.searchBar
            return controller
        })()
        
    
        
        loadImages()
        faciesCatalog.loadImages()
        
        self.tableView.reloadData()
    }
    
    func loadImages() {
        // Get the full detailed object from the selected name
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName:"DetailedImageObject")
        // TODO: Add Predicate to speed-up the request.
        
        var error: NSError?
        detailedImages = (managedContext.executeFetchRequest(fetchRequest,
            error: &error) as? [DetailedImageObject])!
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
        
        var detailedImage: DetailedImageObject
        if (searchController.active || scopeSelected) {
            detailedImage = filteredDetailedImages[indexPath.row]
        } else {
            detailedImage = detailedImages[indexPath.row]
        }
        
        cell.useImage(detailedImage)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("loadingToDrawing", sender: tableView)
        //let detailedImage = detailedImages[indexPath]
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "loadingToDrawing" {
            let drawingVC = segue.destinationViewController as! DrawingViewController
            var destinationDetailedImage : DetailedImageObject
            if self.searchController.active {
                let indexPath = self.tableView.indexPathForSelectedRow()
                destinationDetailedImage = filteredDetailedImages[indexPath!.row]
            } else {
                let indexPath = self.tableView.indexPathForSelectedRow()
                destinationDetailedImage = detailedImages[indexPath!.row]
            }
            
            drawingVC.detailedImage = destinationDetailedImage
            drawingVC.image = UIImage(data: destinationDetailedImage.imageData)
            
            //get ImageInfo
            var imageInfo = ImageInfo()
            imageInfo.xDimension = Int(drawingVC.image!.size.width)
            imageInfo.yDimension = Int(drawingVC.image!.size.height)
            imageInfo.latitude = destinationDetailedImage.latitude?.doubleValue
            imageInfo.longitude = destinationDetailedImage.longitude?.doubleValue
            imageInfo.compassOrienation = destinationDetailedImage.compassOrientation?.doubleValue
            imageInfo.date = destinationDetailedImage.date
            imageInfo.scale = destinationDetailedImage.scale?.doubleValue
            
            
            drawingVC.imageInfo = imageInfo
        }
        
        if( edited ) {
            var error: NSError?
            if !self.managedContext.save(&error) {
                println("Could not save in LoadingingViewController \(error), \(error?.userInfo)")
            } else {
                println("LoadingViewController saved the ManagedObjectContext")
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
                
                let deletedImage = detailedImages[indexPath.row]
                managedContext.deleteObject(deletedImage)
                
                detailedImages.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                
                edited = true
            }
        }
    }
    
    // Mark: - Filtering
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filteredDetailedImages.removeAll(keepCapacity: false)
        let scopes = self.searchController.searchBar.scopeButtonTitles as! [String]
        let selectedScope = scopes[self.searchController.searchBar.selectedScopeButtonIndex]
        self.filterContentForSearchText(searchController.searchBar.text, scope: selectedScope)
        self.tableView.reloadData();
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        // Filter the array using the filter method
        self.filteredDetailedImages = self.detailedImages.filter({( detailedImage: DetailedImageObject) -> Bool in
            let categoryMatch = (scope == "All") || (detailedImage.project.name == scope)
            let stringMatch = detailedImage.name.rangeOfString(searchText)
            return categoryMatch && (stringMatch != nil)
            //return (stringMatch != nil)
        })
    }
    
    func filterContentForScope(scope: String = "All") {
        self.filteredDetailedImages = self.detailedImages.filter({( detailedImage: DetailedImageObject) -> Bool in
            let categoryMatch = (scope == "All") || (detailedImage.project.name == scope)
            return categoryMatch
        })
    }
    

    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print(selectedScope)
        if self.searchController.active {
            self.updateSearchResultsForSearchController(self.searchController)
        } else {
            let scopes = self.searchController.searchBar.scopeButtonTitles as! [String]
            let scope = scopes[selectedScope]
            scopeSelected = true
            self.filterContentForScope(scope: scope)
            self.tableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        scopeSelected = false
    }

    
    
    /** Deprecated
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
    self.filterContentForSearchText(searchString)
    return true
    } **/
    
    @IBAction func unwindToLoading (segue: UIStoryboardSegue) {
        
    }
    
}
