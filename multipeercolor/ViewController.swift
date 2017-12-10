//
//  ViewController.swift
//  multipeercolor
//
//  Created by Mauro Romito on 08/12/17.
//  Copyright © 2017 Mauro Romito. All rights reserved.
//

import UIKit
import GameKit

class ViewController: UIViewController {

    // i istanciate the servi e manager for timestamps
    let timestampService = TimeStampServiceManager()
    //this is an array of chars that I will reorder
    //according to a common seed shared by the two devices
    var chars = ["A", "B", "C", "D", "E","F"]
    //the general session seed randomizer
    //it's obatined through the use of the own device seed and peer device seed
    var randomizer: GKARC4RandomSource? {
        get {
            guard let myS = mySeed else {
                //just to test if anything goes wrong
                return nil
            }
            guard let peerS = peerSeed else {
                //same as above
                return nil
            }
            //this is used to convert to the type Data the result
            //the result is a xor of the two int seeds
            var resultInt = myS ^ peerS
            let resultData = Data(buffer: UnsafeBufferPointer(start: &resultInt, count: 1))
            return GKARC4RandomSource(seed: resultData)
        }
    }
    //the seed of this device
    var mySeed: Int?
    //the seed of the peer
    var peerSeed: Int?
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var connectionsLabel: UILabel!
    @IBOutlet weak var myTimeStampLabel: UILabel!
    @IBOutlet weak var peerTimeStampLabel: UILabel!
    @IBOutlet weak var charsLabel: UILabel!
    @IBOutlet weak var rearrangeButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //setting the delegate of timeStampService as self
        timestampService.delegate = self
        charsLabel.text = "\(chars)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //this function will rearrange the array of chars according
    //to the seed of the session
    @IBAction func rearrange(_ sender: UIButton) {
        guard let random = randomizer else {
            return
        }
        //temp copy of the default chars arrangement
        var charsCopy: [String] = []
        for char in chars {
            charsCopy.append(char)
        }
        //an empty array which fills with the shuffled chars
        var shuffled: [String] = []
        for _ in 0..<charsCopy.count {
            let randIndex = random.nextInt(upperBound: charsCopy.count)
            shuffled.append(charsCopy[randIndex])
            charsCopy.remove(at: randIndex)
        }
        charsLabel.text = "\(shuffled)"
    }
    @IBAction func send(_ sender: UIButton) {
        //getting current date and setting it in a formatted year-month-day-hour-minute-second String
        let date = Date()
        //storing this value as a seed
        //setting a string for the calendar
        let calender = Calendar.current
        let components = calender.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
        
        let year = components.year
        let month = components.month
        let day = components.day
        let hour = components.hour
        let minute = components.minute
        let second = components.second
        
        let todayString = String(year!) + "-" + String(month!) + "-" + String(day!) + " " + String(hour!)  + ":" + String(minute!) + ":" +  String(second!)
        //setting my timestamp label
        myTimeStampLabel.text = "My TimeStamp: \(todayString)"
        //saving as an int through the use of hasvalue, a seed for the device timestamp
        mySeed = todayString.hashValue
        //sending the timestamp to peers
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
    
    //this will set the timestamp in the peer label when it arrives
    func setTimeStamp(manager: TimeStampServiceManager, timeStamp: String) {
        OperationQueue.main.addOperation {
            self.peerTimeStampLabel.text = "Peer Timestamp: \(timeStamp)"
            self.peerSeed = timeStamp.hashValue
            }
        }
}

