//
//  CurrentSurroundingsViewController.swift
//  Ping
//
//  Created by Martin Zhang on 2016-08-10.
//  Copyright © 2016 thomas minshull. All rights reserved.
//

import UIKit

class CurrentSurroundingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Outlets
    @IBOutlet weak var longBackButton: UIButton!
    @IBOutlet weak var currentSurroundingTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Properties 
    let userManager:UserManager?
    let btm = BlueToothManager.sharedBluetoothManager()
    
    var users = [User]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userManager!.fetchUsersWthCompletion { (userArray) in
            self.updateTableView()
        }
        
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(CurrentSurroundingsViewController.updateTableView), forControlEvents: UIControlEvents.ValueChanged)
        
        currentSurroundingTableView.backgroundColor = UIColor(netHex:0xD9FAAA)
        currentSurroundingTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        currentSurroundingTableView.tableFooterView = UIView(frame: CGRectZero)
    }

    
    // MARK: TableView Delegate/DataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 136
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let userCell = tableView.dequeueReusableCellWithIdentifier("UserCell", forIndexPath: indexPath) as! UserTableViewCell
        
        userCell.selectionStyle = UITableViewCellSelectionStyle.Default
        
        userCell.configureWithUser(users[indexPath.row]);
        
        return userCell;
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor =  colorForIndex(indexPath.row)
    }
    
    // MARK: Custom Methods
    
    func updateTableView() {
        updateUsers()
        
        if users.count == 0 {
            if !activityIndicator.isAnimating() {
                activityIndicator.startAnimating()
            }
            
            btm.setUpBluetooth()
            
            NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector:#selector(CurrentSurroundingsViewController.updateTableView), userInfo: nil, repeats: false)
            
        } else {
            activityIndicator.hidesWhenStopped = true
            activityIndicator.stopAnimating()
            currentSurroundingTableView.reloadData()
        }
    }
    
    func updateUsers() {
        let recMan = RecordManager()
        let sortedUUIDs = recMan.UUIDsSortedAtTime(NSDate()) ?? []
        
        users.removeAll()
        
        for uuid:String in sortedUUIDs {
            if let user = userManager!.userForUUID(uuid) {
                users.append(user)
            }
        }
        
    }
    
    func colorForIndex(index: Int) -> UIColor {
        
        let itemIndex = users.count - 1
        let transparency = (CGFloat(index) / CGFloat(itemIndex)) * 0.6
        
        return UIColor(red: 0.85098, green: 0.98039, blue: 0.66667, alpha: transparency)
    }
    
    
    // MARK: Actions
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        btm.stop()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }

}




//extension UIColor {
//    convenience init(red: Int, green: Int, blue: Int) {
//        assert(red >= 0 && red <= 255, "Invalid red component")
//        assert(green >= 0 && green <= 255, "Invalid green component")
//        assert(blue >= 0 && blue <= 255, "Invalid blue component")
//        
//        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
//    }
//    
//    convenience init(netHex:Int) {
//        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
//    }
//}
