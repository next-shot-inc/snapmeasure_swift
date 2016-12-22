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
    func drawHistogram(_ numBins: Int, features : [FeatureObject], sortedBy : String)
}

class HistogramData {
    var managedContext: NSManagedObjectContext!
    var fetchRequest : NSFetchRequest<NSFetchRequestResult>!
    var featureCount: Int!
    var selectedCat = "Type" //Default sorting by type
    fileprivate var features : [FeatureObject] = []
    
    init() {
        //set up intitial fetchRequest
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        managedContext = appDelegate.managedObjectContext!
        fetchRequest = NSFetchRequest(entityName:"FeatureObject") //default fetch request is for all Features
        
        // Default to current project
        fetchRequest.predicate = NSPredicate(format: "image.project.name==%@", currentProject.name)
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "type", ascending: true)] // default sorting
        self.getFeatureCountForCurrentFetchRequest()
    }
    
    func getFeatureCountForCurrentFetchRequest() {
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: selectedCat.lowercased(), ascending: true)]
        do {
           try featureCount = managedContext.count(for: fetchRequest)
        } catch {
            
        }
    }
    
    func getFeatures() -> [FeatureObject] {
        do {
            features = (try managedContext.fetch(fetchRequest) as? [FeatureObject])!
        } catch {
            
        }
        return features
    }
}

class HistogramMasterViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {


    @IBOutlet weak var binNumSlider: UISlider!
    @IBOutlet weak var maxNumBins: UILabel!
    @IBOutlet weak var binNumLabel: UILabel!
    @IBOutlet weak var generateHistogramButton: UIButton!
    
    @IBOutlet weak var sortingPickerView: UIPickerView!

    var possibleSortingCats = ["Type","Width","Height"]
    var binNum = 1
    
    weak var delegate : HistogramCreationDelegate?
    var histogramData : HistogramData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.view.backgroundColor = UIColor.lightGrayColor()
        
        //set up PickerView
        let rowIndex = possibleSortingCats.index(of: histogramData!.selectedCat)!
        sortingPickerView.delegate = self
        sortingPickerView.dataSource = self
        sortingPickerView.selectRow(rowIndex, inComponent: 0, animated: false)
        
        //set up Slider
        binNumSlider.maximumValue = Float(histogramData!.featureCount)
        binNumSlider.minimumValue = 1
        binNumSlider.value  = Float(histogramData!.featureCount)/2
        self.sliderValueChanged("" as AnyObject)
        self.pickerView(sortingPickerView, didSelectRow: rowIndex,inComponent: 0)
        
        maxNumBins.text = String(histogramData!.featureCount)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        if histogramData!.featureCount == 0 {
            let alert = UIAlertController(title: nil, message: "No feature data available to plot. Features can be defined in the image editor", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default) { action -> Void in
                alert.dismiss(animated: true, completion: nil)
                self.dismiss(animated: true, completion: nil)
            }
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
        
        generateHistogramButton.isEnabled = histogramData!.featureCount > 0
    }
    
    
    
    //Mark: - UIPickerView Methods
    
    //columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //number of rows
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return possibleSortingCats.count
    }
    
    //set what is in the pickerview
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return possibleSortingCats[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        histogramData!.selectedCat = possibleSortingCats[row]
        
        //we want the result of the fetch request to be sorted according to the category selected by the user
        
        if histogramData!.selectedCat.isEqual("Type") {
            binNumSlider.isEnabled = false
            binNumLabel.text = String(possibleFeatureTypes.count) + "\n set by # of possible feature types" //second line isn't currently visible, TODO: investigate better location? or different message
            binNum = possibleFeatureTypes.count
            binNumSlider.value = Float(binNum)
        } else {
            binNum = Int(round(binNumSlider.value))
            binNumLabel.text = String(binNum)
            binNumSlider.isEnabled = true

        }
    }
    
    //Mark: UISlider
    @IBAction func sliderValueChanged(_ sender: AnyObject) {
        binNum = Int(round(binNumSlider.value))
        binNumLabel.text = String(binNum)
    }
    
    @IBAction func generateHistogramButtonPressed(_ sender: AnyObject) {
        delegate?.drawHistogram(
            binNum, features: histogramData!.getFeatures(), sortedBy: histogramData!.selectedCat
        )
        dismiss(animated: true, completion: nil)
    }
}
