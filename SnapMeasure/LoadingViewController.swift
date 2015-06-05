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

//TODO: Fix Deprecation of UISearchDisplayController to UISearchController
class LoadingViewController: UITableViewController, UISearchResultsUpdating {
    var detailedImages: [DetailedImageObject] = []
    var filteredDetailedImages: [DetailedImageObject] = []
    var searchController = UISearchController()
    var managedContext : NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        super.viewDidLoad()
        
        // appearance and layout customization
        self.tableView.backgroundView = UIImageView(image:UIImage(named:"loadingBackground"))
        self.tableView.estimatedRowHeight = 280
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        self.tableView.rowHeight = UITableViewAutomaticDimension
        //self.tableView.allowsSelection = false
        
        self.searchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()
            
            self.tableView.tableHeaderView = controller.searchBar
            return controller
        })()
        
        loadImages()
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
        if searchController.active {
            return filteredDetailedImages.count
        } else {
            return detailedImages.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Card", forIndexPath: indexPath) as! CardTableViewCell
        cell.backgroundColor = UIColor.clearColor()
        
        var detailedImage: DetailedImageObject
        if (searchController.active) {
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
            
            // Get the lines via the DetailedView NSSet.
            var lines = [Line]()
            for alo in destinationDetailedImage.lines {
                println("got a line")
                let lo = alo as? LineObject
                var line = Line()
                line.name = lo!.name
                let color = NSKeyedUnarchiver.unarchiveObjectWithData(lo!.colorData) as? UIColor
                line.color = color?.CGColor
                let arrayData = lo!.pointData
                let array = Array(
                    UnsafeBufferPointer(
                        start: UnsafePointer<CGPoint>(arrayData.bytes),
                        count: arrayData.length/sizeof(CGPoint)
                    )
                )
                for( var i=0; i < array.count; i++ ) {
                    line.points.append(array[i])
                }
                lines.append(line)
            }
            
            drawingVC.detailedImage = destinationDetailedImage
            drawingVC.image = UIImage(data: destinationDetailedImage.imageData)
            drawingVC.lines = lines
            
            //get ImageInfo
            var imageInfo = ImageInfo()
            imageInfo.xDimension = Int(drawingVC.image!.size.width)
            imageInfo.yDimension = Int(drawingVC.image!.size.height)
            
            drawingVC.imageInfo = imageInfo
            
        }
    }
    
    // Mark: - Deletion
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    /**
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            if (self.searchController.active) {
                
            } else {
                let deletedImage = detailedImages[indexPath.row]
                managedContext.deleteObject(deletedImage)
                
                detailedImages.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            }
        }
    } **/
    
    // Mark: - Filtering
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filteredDetailedImages.removeAll(keepCapacity: false)
        self.filterContentForSearchText(searchController.searchBar.text)
        self.tableView.reloadData();
    }
    
    func filterContentForSearchText(searchText: String) {
        // Filter the array using the filter method
        self.filteredDetailedImages = self.detailedImages.filter({( detailedImage: DetailedImageObject) -> Bool in
            //let categoryMatch = (scope == "All") || (candy.category == scope)
            let stringMatch = detailedImage.name.rangeOfString(searchText)
            //return categoryMatch && (stringMatch != nil)
            return (stringMatch != nil)
        })
    }
    
    /** Deprecated
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
    self.filterContentForSearchText(searchString)
    return true
    } **/
    
}
