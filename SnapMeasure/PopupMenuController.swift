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
    var cellContents : [UIControl] = []
    
    override func viewDidLoad() {
        self.tableView.tableFooterView = UIView()
        self.tableView.setFrameWidth(150)
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        self.tableView.rowHeight = 45
        self.tableView.alwaysBounceVertical = false
        self.tableView.reloadData()
    }
    
    func preferredHeight () -> CGFloat {
        return CGFloat(cellContents.count * 45)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        
        if (cellContents.count > 0) {
            cell.contentView.addSubview(cellContents[indexPath.row])
          if (indexPath.row < cellContents.count-1) {
                let lineView = UIView(frame: CGRectMake(0, cell.contentView.frame.size.height - 1.0, cell.contentView.frame.size.width, 1))
                
                lineView.backgroundColor = UIColor.lightGrayColor()
                cell.contentView.addSubview(lineView)
            }
        }

        return cell
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellContents.count
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
}