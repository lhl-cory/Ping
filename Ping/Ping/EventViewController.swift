//
//  EventViewController.swift
//  Ping
//
//  Created by Martin Zhang on 2016-08-12.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

import UIKit

class EventViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: Outlets
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: Properties 
    var event:Event!
    var userManager:UserManager!
    var timePeriods:[TimePeriod]? // note can't be nil if no timePeriods will have empty array
    var uuids = [String]()
    var currentTimePeriod:TimePeriod?
    // Definint theme background color:
    let thmeBackGroundColor = UIColor(netHex:0xD9FAAA)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.backgroundColor = thmeBackGroundColor
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        timeSlider.minimumValue = 0
        
        updateTimePeriods()
        timeSlider.value = timeSlider.maximumValue
        
        currentTimePeriod = getCurrentTimePeriodForSliderValue(UInt(timeSlider.value))
        uuids = getUUIDsForTimePeriod(currentTimePeriod)
        
        if let startTime = currentTimePeriod?.startTime {
            updateDateLabelWithDate(startTime)
        }
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 130

    }
    
    override func viewWillAppear(animated: Bool) {
        print("appaer")
    }
    
    func updateTimePeriods() {
        
        self.timePeriods = TimePeriod.sortArray(event.timePeriods, byDateAscending: true) as?[TimePeriod] //implemented in objective-C because realm-objective-C hates swift
        
        if let timePeriods = self.timePeriods {
            
            if timePeriods.count > 0 {
                timeSlider.maximumValue = Float(timePeriods.count) - 1
                return
            }
            
            timeSlider.maximumValue = 0
            
        }
    }

    // CR: get
    func getCurrentTimePeriodForSliderValue(sliderValue:UInt) -> TimePeriod? {
        // CR: if-let where

        
        if let timePeriods = timePeriods
            where timePeriods.count != 0 &&
                Int(sliderValue) < timePeriods.count {
            
        }
        if let timePeriods = timePeriods {
            if timePeriods.count != 0 {
                if Int(sliderValue) < timePeriods.count {
                    return timePeriods[Int(sliderValue)]
                }
            }
        }
        return nil
    }
    
    func getUUIDsForTimePeriod(timePeriod:TimePeriod?) -> [String] {
        let recMan = RecordManager()
        
        if let timePeriod = timePeriod {
            return recMan.UUIDsSortedAtTime(timePeriod.startTime)
        } else {
            return [String]()
        }
    }
    
    func updateDateLabelWithDate(date:NSDate) {
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.ShortStyle
        formatter.timeStyle = .ShortStyle
        
        dateLabel.text = formatter.stringFromDate(date)
    }
    
    
    // MARK: delegate/datasource methods
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return uuids.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // refactor to reorder cells & insert and delete
        let cell:UserTableViewCell = tableView.dequeueReusableCellWithIdentifier("UserTableViewCell") as! UserTableViewCell
        
        if let user = userManager.userForUUID(uuids[indexPath.row]) {
            cell.configureWithUser(user)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let user = self.userManager.userForUUID(uuids[indexPath.row])
        
        if let user = user {
            LISDKDeeplinkHelper.sharedInstance().viewOtherProfile(user.linkedInID, withState: "eventCellSelected", showGoToAppStoreDialog: false, success: nil, error: nil)
        }
        
    }
    
    func colorForIndex(index: Int) -> UIColor {
        
        let userCount = uuids.count - 1
        let transparency = (CGFloat(index) / CGFloat(userCount)) * 0.6
        return UIColor(red: 0.44314, green: 0.95686, blue: 0.81961, alpha: transparency)
        
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = colorForIndex(indexPath.row)
    }
    
    // MARK: Actions
    
    @IBAction func timerSliderFinishSliding(sender: UISlider) {
        print("timeSliderFinishSlidingFired")
        timeSlider.value = roundf(sender.value)
        
        // ToDo Refactor so we are reordering cells, inserting and deleting instead of reloading table view
        currentTimePeriod = getCurrentTimePeriodForSliderValue(UInt(timeSlider.value))
        
        if let currentTimePeriod = currentTimePeriod {
            
            uuids = getUUIDsForTimePeriod(currentTimePeriod)
            tableView.reloadData()
        }
        
    }
    
    @IBAction func sliderValueChanged(sender: UISlider) {
        // ToDo Make Dry, code repeated in timeSliderFinishSliding
        timeSlider.value = roundf(sender.value)
        currentTimePeriod = getCurrentTimePeriodForSliderValue(UInt(timeSlider.value))
        
        if let currentTimePeriod = currentTimePeriod {
            updateDateLabelWithDate(currentTimePeriod.startTime)
        } else {
            updateDateLabelWithDate(event.startTime)
        }
    }
    

    @IBAction func backButtonPressed(sender: AnyObject) {
        performSegueWithIdentifier("unwindFromEventToEventList", sender: self)
    }

}
