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
    var date: Date
    var nb_interps = 0
    init(name: String, project: String, date: Date) {
        self.name = name
        self.project = project
        self.date = date
    }
    
    func getObject() -> DetailedImageObject? {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"DetailedImageObject")
        fetchRequest.predicate = NSPredicate(format: "date == %@", date as CVarArg)
        do {
            let objects = try managedContext.fetch(fetchRequest)
            if( objects.count == 1 ) {
                return objects[0] as? DetailedImageObject
            } else {
                for o in objects {
                    let dio = o as? DetailedImageObject
                    if( dio != nil && dio!.name == name ) {
                        return dio;
                    }
                }
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
    var searchController : UISearchController!
    var managedContext : NSManagedObjectContext!
    //var faciesCatalog = FaciesCatalog()
    var edited = false
    var scopeSelected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // appearance and layout customization
        // self.tableView.backgroundView = UIImageView(image:UIImage(named:"loadingBackground"))
        self.tableView.estimatedRowHeight = 280
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        //self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.alwaysBounceVertical = false
        //self.tableView.allowsSelection = false
        
        self.searchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.showsScopeBar = true
            controller.searchBar.scopeButtonTitles = ["All"]
            var selectedScopeButton = 0
            for (index,project) in projects.enumerated() {
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
        
        definesPresentationContext = true
        
        loadImages()
        
        updateSearchResults(for: searchController)
        
        self.tableView.reloadData()
        
        scopeSelected = true
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if( searchController != nil ) {
           searchController.dismiss(animated: false, completion: nil)
           searchController.searchBar.delegate = nil
           searchController.searchResultsUpdater = nil
           tableView.tableHeaderView = nil
           searchController = nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func loadImages() {
        // Get the full detailed object from the selected name
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"DetailedImageObject")
        fetchRequest.includesSubentities = false
        fetchRequest.propertiesToFetch = [ "name", "project.name", "date"]
        fetchRequest.resultType = NSFetchRequestResultType.dictionaryResultType
        
        
        
        do {
            let objects = try managedContext.fetch(fetchRequest)
            for obj in objects {
                let name = (obj as AnyObject).value(forKey: "name") as? NSString
                let project = (obj as AnyObject).value(forKey: "project.name") as? NSString
                let date = (obj as AnyObject).value(forKey: "date") as? Date
                if( name != nil && project != nil ) {
                    
                    let LOfetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"LineObject")
                    LOfetchRequest.predicate = NSPredicate(format: "image.name==%@ and image.project.name==%@", name!, project!)
                    var fetchedResultsCount = 0
                    do {
                        try fetchedResultsCount = managedContext.count(for: LOfetchRequest)
                    } catch {
                        
                    }
                    
                    let dip = DetailedImageProxy(name: name! as String, project: project! as String, date: date!)
                    dip.nb_interps = fetchedResultsCount
                    detailedImages.append(dip)
                    
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
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if( (searchController != nil && searchController.isActive) || scopeSelected ){
            return filteredDetailedImages.count
        } else {
            return detailedImages.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Card", for: indexPath) as! CardTableViewCell
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        var detailedImage: DetailedImageProxy
        if ( (searchController != nil && searchController.isActive) || scopeSelected) {
            detailedImage = filteredDetailedImages[indexPath.row]
        } else {
            detailedImage = detailedImages[indexPath.row]
        }
        
        cell.useImage(detailedImage)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (!(searchController != nil && self.searchController.isActive) ) {
            self.performSegue(withIdentifier: "loadingToDrawing", sender: self)
        } else {
            // do something that deals with the fact that search controller is active
        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "loadingToDrawing" {
            let drawingNC = segue.destination as! UINavigationController
            let drawingVC = drawingNC.topViewController as! DrawingViewController
            var destinationDetailedImageProxy : DetailedImageProxy
            if (self.searchController.isActive || scopeSelected ) {
                let indexPath = self.tableView.indexPathForSelectedRow!
                destinationDetailedImageProxy = filteredDetailedImages[indexPath.row]
            } else {
                let indexPath = self.tableView.indexPathForSelectedRow!
                destinationDetailedImageProxy = detailedImages[indexPath.row]
            }
            
            let destinationDetailedImage = destinationDetailedImageProxy.getObject()
            if( destinationDetailedImage != nil ) {
                drawingVC.detailedImage = destinationDetailedImage!
                let imageSize = CGSize(
                    width: Int(destinationDetailedImage!.imageWidth!.int32Value), height: Int(destinationDetailedImage!.imageHeight!.int32Value)
                )
                
                //get ImageInfo
                var imageInfo = ImageInfo()
                imageInfo.xDimension = Int(imageSize.width)
                imageInfo.yDimension = Int(imageSize.height)
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
        
        // Free memory
        for cell in self.tableView.visibleCells {
            let c = cell as? CardTableViewCell
            if( c != nil ) {
                c!.cleanImage()
            }
        }
    }
    
    // Mark: - Deletion
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            
            if (self.searchController.isActive || scopeSelected) {
                let deletedImage = filteredDetailedImages[indexPath.row].getObject()
                if( deletedImage != nil ) {
                    var fullIndex : Int?
                    for (index, di) in detailedImages.enumerated() {
                        if( di.date == deletedImage!.date as Date && di.name == deletedImage!.name ) {
                            fullIndex = index
                            break
                        }
                    }
                    if( fullIndex != nil ) {
                        // Count the number of times an image file has been referenced.
                        var countRef = 0
                        for di in detailedImages {
                            let od = di.getObject()
                            if( od?.imageFile == deletedImage?.imageFile ) {
                                countRef += 1
                            }
                        }
                        if( countRef == 1 ) {
                            // Remove Image files
                            deletedImage?.removeImage()
                        }
                        managedContext.delete(deletedImage!)
                        detailedImages.remove(at: fullIndex!)
                        
                        filteredDetailedImages.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                        
                        edited = true
                    }
                }
                
            } else {
                // Count the number of times an image file has been referenced.
                let deletedImage = detailedImages[indexPath.row].getObject()
                var countRef = 0
                for di in detailedImages {
                    let od = di.getObject()
                    if( od?.imageFile == deletedImage?.imageFile ) {
                        countRef += 1
                    }
                }
                if( countRef == 1 ) {
                    // Remove Image files
                    deletedImage?.removeImage()
                }
                
                if( deletedImage != nil ) {
                   managedContext.delete(deletedImage!)
                }
                
                detailedImages.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                
                edited = true
            }
        }
    }
    
    // Mark: - Filtering
    func updateSearchResults(for searchController: UISearchController) {
        let scopes = self.searchController.searchBar.scopeButtonTitles
        if( scopes != nil ) {
           filteredDetailedImages.removeAll(keepingCapacity: false)
           let selectedScope = scopes![self.searchController.searchBar.selectedScopeButtonIndex]
           self.filterContentForSearchText(searchController.searchBar.text!, scope: selectedScope)
           self.tableView.reloadData();
        }
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        // Filter the array using the filter method
        self.filteredDetailedImages = self.detailedImages.filter({( detailedImage: DetailedImageProxy) -> Bool in
            let categoryMatch = (scope == "All") || (detailedImage.project == scope)
            let stringMatch = detailedImage.name.range(of: searchText)
            return categoryMatch && (searchText.isEmpty || stringMatch != nil)
            //return (stringMatch != nil)
        })
    }
    
    func filterContentForScope(_ scope: String = "All") {
        self.filteredDetailedImages = self.detailedImages.filter({( detailedImage: DetailedImageProxy) -> Bool in
            let categoryMatch = (scope == "All") || (detailedImage.project == scope)
            return categoryMatch
        })
    }
    

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print(selectedScope)
        if self.searchController.isActive {
            self.updateSearchResults(for: self.searchController)
        } else {
            let scopes = self.searchController.searchBar.scopeButtonTitles!
            let scope = scopes[selectedScope]
            scopeSelected = true
            self.filterContentForScope(scope)
            self.tableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        scopeSelected = false
        //self.tableView.reloadData()
    }

    
    
    /** Deprecated
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
    self.filterContentForSearchText(searchString)
    return true
    } **/
    
    @IBAction func unwindToLoading (_ segue: UIStoryboardSegue) {
        
    }
    
}
