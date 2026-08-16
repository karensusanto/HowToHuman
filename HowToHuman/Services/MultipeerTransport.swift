//
//  MultipeerTransport.swift
//  HowToHuman
//
//  Created by Syauqi Auliya M on 15/08/26.
//

import Foundation
import MultipeerConnectivity
import Combine

// Defines every possible type of data transmitted between peers
enum GameMessage: Codable {
    case stateSync(Room)
    case phaseChanged(GamePhase)
    case submitQuestion(String)
    case submitInstruction(String)
    case submitNarration(String)
    case reactionSent(Int)
}

final class MultipeerTransport: NSObject, ObservableObject {
    private let serviceType = "howtohuman"
    
    private let myPeerId: MCPeerID
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    
    let messageReceived = PassthroughSubject<(GameMessage, MCPeerID), Never>()
    let peerConnectionStateChanged = PassthroughSubject<(MCPeerID, MCSessionState), Never>()
    
    init(displayName: String) {
        self.myPeerId = MCPeerID(displayName: displayName)
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        
        super.init()
        
        self.session.delegate = self
        self.advertiser.delegate = self
        self.browser.delegate = self
    }
    
    func startHosting() { advertiser.startAdvertisingPeer() }
    func startBrowsing() { browser.startBrowsingForPeers() }
    func stopNetworking() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
    }
    
    func send(message: GameMessage, to peers: [MCPeerID], reliably: Bool = true) {
        guard !peers.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(message)
            let mode: MCSessionSendDataMode = reliably ? .reliable : .unreliable
            try session.send(data, toPeers: peers, with: mode)
        } catch {
            print("Failed to encode or send message: \(error)")
        }
    }
    
    func broadcast(message: GameMessage, reliably: Bool = true) {
            send(message: message, to: session.connectedPeers, reliably: reliably)
        }
}

extension MultipeerTransport: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { self.peerConnectionStateChanged.send((peerID, state)) }
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let message = try JSONDecoder().decode(GameMessage.self, from: data)
            DispatchQueue.main.async { self.messageReceived.send((message, peerID)) }
        } catch {
            print("Failed to decode incoming data from \(peerID.displayName): \(error)")
        }
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerTransport: MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, self.session)
    }
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
