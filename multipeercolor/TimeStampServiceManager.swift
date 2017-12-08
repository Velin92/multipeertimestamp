//
//  TimeStampServiceManager.swift
//  multipeercolor
//
//  Created by Mauro Romito on 08/12/17.
//  Copyright © 2017 Mauro Romito. All rights reserved.
//

import Foundation
import MultipeerConnectivity

//the protocol to see the connected devices and to set their timestamp once sent
protocol TimeStampServiceManagerDelegate {
    
    func connectedDevicesChanged(manager : TimeStampServiceManager, connectedDevices: [String])
    func setTimeStamp(manager : TimeStampServiceManager, timeStamp: String)
    
}

class TimeStampServiceManager: NSObject {
    // Service type must be a unique string, at most 15 characters long
    // and can contain only ASCII lowercase letters, numbers and hyphens.
    private let timeStampServiceType = "timestamp"
    
    //the peerId is to identify the peer
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    
    //this is to creare an advertiser for the service (it says to other peers, hey i'm here)
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    
    //this is to browse for the service (it scans for other peers)
    private let serviceBrowser : MCNearbyServiceBrowser
    
    //this lazy var is used to create an exchange session for the timestamps
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    //a delegate for the service
    var delegate : TimeStampServiceManagerDelegate?
    
    override init() {
        //initializing the advertiser and the browser
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: timeStampServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: timeStampServiceType)
        //initializing the NSObject
        super.init()
        //giving the delegate to itself and starting the advertising of the service
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        //same as above, but to start the service to scan for peers
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    //when the servicve is deallocated is also stopped
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
    }
    //this is the function that sends the timestamp
    func sendTime(timestamp : String) {
        //this is to log the send
        NSLog("%@", "sendTime: \(timestamp) to \(session.connectedPeers.count) peers")
        //if the number of peers is more than one
        if session.connectedPeers.count > 0 {
            //send this timestamp
            do {
                //sends the timestamp as a utf8 string
                try self.session.send(timestamp.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            }
            // in case of errors, log it
            catch let error {
                NSLog("%@", "Error for sending: \(error)")
            }
        }
        
    }
}
//this is to make the service manager also a delegate for the advertising
extension TimeStampServiceManager : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        //this makes yuou automatically accept any invitation you received
        //Note: This code accepts all incoming connections automatically. This would be like a public chat and you need to be very careful to check and sanitize any data you receive over the network as you cannot trust the peers.
       // To keep sessions private the user should be notified and asked to confirm incoming connections. This can be implemented using the MCAdvertiserAssistant classes.
        invitationHandler(true, self.session)
    }
    
}

//this is to make the servicve manager also a delegate for browsing
extension TimeStampServiceManager : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        //this is used to auto-invite any peer that is discovered, the timeout is 10 seconds
        //Note: This code invites any peer automatically. The MCBrowserViewController class could be used to scan for peers and invite them manually.
        NSLog("%@", "invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
    
}
//this is used to make the service also a delegate to create its own exchange session
extension TimeStampServiceManager : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state)")
        //this is used to have the system notified of connections
        self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
        let str = String(data: data, encoding: .utf8)!
        //this is used to have the system notified that the timestamp arrived from another device
        self.delegate?.setTimeStamp(manager: self, timeStamp: str)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    
}
