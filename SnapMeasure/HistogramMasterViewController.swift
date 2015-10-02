//
//  HistogramMasterViewController.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 6/22/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit
import CoreData

protocol HistogramCreationDelegate: class {
    func drawHistogram(numBins: Int, features : [FeatureObject], sortedBy : String)
}


class HistogramMasterViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {


    @IBOutlet weak var binNumSlider: UISlider!
    @IBOutlet weak var maxNumBins: UILabel!
    @IBOutlet weak var binNumLabel: UILabel!
    @IBOutlet weak var generateHistogramButton: UIButton!
    
    @IBOutlet weak var sortingPickerView: UIPickerView!

    var possibleSortingCats = ["Type","Width","Height"]
    var selectedCat = "Type" //Default sorting by type
    
    var binNum = 1
    
    weak var delegate : HistogramCreationDelegate?
    
    var managedContext: NSManagedObjectContext!
    var fetchRequest : NSFetchRequest!
    var featureCount: Int!
    var features : [FeatureObject] = []
    
    //global var possibleFeatureTypes = ["Channel","Lobe","Canyon", "Dune","Bar","Levee"]

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.lightGrayColor()
        
        //set up PickerView
        sortingPickerView.delegate = self
        sortingPickerView.dataSource = self
                
        //set up intitial fetchRequest with no sort or predicate
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!
        fetchRequest = NSFetchRequest(entityName:"FeatureObject") //default fetch request is for all Features
        fetchRequest.predicate = NSPredicate(format: "image.project.name==%@", currentProject.name)
        self.getFeatureCountForCurrentFetchRequest()
        
        //set up Slider
        binNumSlider.maximumValue = Float(featureCount)
        binNumSlider.minimumValue = 1
        binNumSlider.value  = Float(featureCount)/2
        self.sliderValueChanged("")
        self.pickerView(sortingPickerView, didSelectRow: 0, inComponent: 0)
        
        maxNumBins.text = String(featureCount)
    }
    
    func getFeatureCountForCurrentFetchRequest() {
        featureCount = managedContext.countForFetchRequest(fetchRequest, error: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        if featureCount == 0 {
            let alert = UIAlertController(title: nil, message: "No feature data available to plot. Features can be defined in the image editor", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default) { action -> Void in
                alert.dismissViewControllerAnimated(true, completion: nil)
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            alert.addAction(action)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        generateHistogramButton.enabled = featureCount > 0
    }
    
    func loadFeatures() {
        do {
           features = (try managedContext.executeFetchRequest(fetchRequest) as? [FeatureObject])!
        } catch {
            
        }
    }
    
    //Mark: - UIPickerView Methods
    
    //columns of data
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //number of rows
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return possibleSortingCats.count
    }
    
    //set what is in the pickerview
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return possibleSortingCats[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCat = possibleSortingCats[row]
        
        //we want the result of the fetch request to be sorted according to the category selected by the user
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: selectedCat.lowercaseString, ascending: true)]
        
        if selectedCat.isEqual("Type") {
            binNumSlider.userInteractionEnabled = false
            binNumLabel.text = String(possibleFeatureTypes.count) + "\n set by # of possible feature types" //second line isn't currently visible, TODO: investigate better location? or different message
            binNum = possibleFeatureTypes.count
            binNumSlider.value = Float(binNum)
        } else {
            binNum = Int(round(binNumSlider.value))
            binNumLabel.text = String(binNum)
            binNumSlider.userInteractionEnabled = true

        }
    }
    
    //Mark: UISlider
    @IBAction func sliderValueChanged(sender: AnyObject) {
        binNum = Int(round(binNumSlider.value))
        binNumLabel.text = String(binNum)
    }
    
    @IBAction func genertateHistogramButtonPressed(sender: AnyObject) {
        loadFeatures()
        delegate?.drawHistogram(binNum, features: features, sortedBy: selectedCat)
    }
}
