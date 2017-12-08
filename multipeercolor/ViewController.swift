//
//  ViewController.swift
//  multipeercolor
//
//  Created by Mauro Romito on 08/12/17.
//  Copyright © 2017 Mauro Romito. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let timestampService = TimeStampServiceManager()
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var connectionsLabel: UILabel!
    @IBOutlet weak var myTimeStampLabel: UILabel!
    @IBOutlet weak var peerTimeStampLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //setting the delegate of timeStampService as self
        timestampService.delegate = self

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func send(_ sender: UIButton) {
        //getting current date and setting it in a formatted year-month-day-hour-minute-second String
        let date = Date()
        let calender = Calendar.current
        let components = calender.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
        
        let year = components.year
        let month = components.month
        let day = components.day
        let hour = components.hour
        let minute = components.minute
        let second = components.second
        
        let todayString = String(year!) + "-" + String(month!) + "-" + String(day!) + " " + String(hour!)  + ":" + String(minute!) + ":" +  String(second!)
        myTimeStampLabel.text = "My TimeStamp: \(todayString)"
        timestampService.sendTime(timestamp: todayString)
    }
    
}
// extending ViewController as a delegate of TimeStampServiceManager
extension ViewController : TimeStampServiceManagerDelegate {
    
    //this will change the text of the label to show connected devices
    func connectedDevicesChanged(manager: TimeStampServiceManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            self.connectionsLabel.text = "Connections: \(connectedDevices)"
        }
    }
    
    //this will set the timestamp in the peer label
    func setTimeStamp(manager: TimeStampServiceManager, timeStamp: String) {
        OperationQueue.main.addOperation {
            self.peerTimeStampLabel.text = "Peer Timestamp: \(timeStamp)"
            }
        }
}

