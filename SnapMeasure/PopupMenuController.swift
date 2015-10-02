//
//  PopupMenuController.swift
//  SnapMeasure
//
//  Created by Camille Dulac on 6/18/15.
//  Copyright (c) 2015 next-shot. All rights reserved.
//

import Foundation
import UIKit

class PopupMenuController: UITableViewController {
    var cellContents : [[UIView]] = [[UIView]]()
    var dividers : Bool = true
    
    func initCellContents(rows : Int, cols: Int) {
        cellContents = Array(count: rows, repeatedValue: [UIView]())
        for i in 0..<rows {
            cellContents[i] = Array(count: cols, repeatedValue: UIView())
        }
    }
    
    override func viewDidLoad() {
        //self.tableView.tableFooterView = UIView()
        self.tableView.setFrameWidth(150)
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        //self.tableView.rowHeight = 45
        self.tableView.alwaysBounceVertical = false
        self.tableView.reloadData()
    }
    
    func preferredHeight () -> CGFloat {
        return CGFloat(cellContents.count * 45)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        if( indexPath.row == 0 ) {
            // Empty cell at the top. Draw thick line below.
            if( dividers ) {
               let lineView = UIView(frame: CGRectMake(0, cell.contentView.frame.size.height - 1.0, cell.contentView.frame.size.width, 2))
               lineView.backgroundColor = UIColor.lightGrayColor()
               cell.contentView.addSubview(lineView)
            }
            return cell
        }
        
        if (cellContents.count > 0) {
            cellContents[indexPath.row-1][indexPath.section].center = cell.contentView.center
            cell.contentView.addSubview(cellContents[indexPath.row-1][indexPath.section])
            if ( dividers ) {
                // Draw thick line below last.
                let lineWidth = indexPath.row < cellContents.count ? CGFloat(1) : CGFloat(2)
                let lineView = UIView(frame: CGRectMake(0, cell.contentView.frame.size.height - 1.0, cell.contentView.frame.size.width, lineWidth))
                lineView.backgroundColor = UIColor.lightGrayColor()
                cell.contentView.addSubview(lineView)
            }
        }

        return cell
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return cellContents[0].count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Add an empty cell at the top to give some room
        return cellContents.count + 1
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
}