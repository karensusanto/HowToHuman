//
//  GameStore.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//

import Combine
import Foundation
import SwiftUI
import MultipeerConnectivity
import CouchbaseLiteSwift

enum AppState {
    case home
    case howToPlay
    case lobbySearch
    case customizeAlien
    case lobby
    case transition
    case askHuman
    case answerAlien
    case narrateExperience
    case reviewExperience
    case voting
    //    case transitionToAlien
    //    case transitionToHuman
    //    case transitionToExperience
    //    case transitionToReview
    //    case transitionToVote
}

enum GamePhase {
    //    case none
    case askHuman
    case answerAlien
    case narrateExperience
    case reviewExperience
    case voting
}

@MainActor
final class GameStore: ObservableObject {
    private let transport: MultipeerTransport
    
    private var cancellables = Set<AnyCancellable>()
    
    
    @Published var state: AppState = .home
    @Published var phase: GamePhase = .askHuman
    //    @Published var isMigratingHost: Bool = false
    @Published var currRoom: Room?
    
    init() {
        // Initialize the transport with a temporary device name
        self.transport = MultipeerTransport(displayName: UIDevice.current.name)
        
        // Subscribe to network state changes (who joined/left)
        self.transport.peerConnectionStateChanged
            .receive(on: RunLoop.main) // Ensure UI updates happen on the main thread
            .sink { [weak self] peerID, state in
                self?.handlePeerStateChange(peerID: peerID, state: state)
            }
            .store(in: &cancellables) // Toss it in the bucket
        
        // Subscribe to incoming game messages (the actual game data)
        self.transport.messageReceived
            .receive(on: RunLoop.main)
            .sink { [weak self] message, peerID in
                self?.handleIncomingMessage(message, from: peerID)
            }
            .store(in: &cancellables)
    }
    
    
    // MARK: - Network Event Handlers
    
    private func handlePeerStateChange(peerID: MCPeerID, state: MCSessionState) {
        switch state {
        case .connected:
            print("🟢 \(peerID.displayName) joined the lobby!")
            // TODO: Add this player to the current Room
            
        case .notConnected:
            print("🔴 \(peerID.displayName) disconnected.")
            // TODO: Remove this player or trigger the graceful exit
            
        case .connecting:
            print("🟡 \(peerID.displayName) is connecting...")
            
        @unknown default:
            break
        }
    }
    
    private func handleIncomingMessage(_ message: GameMessage, from peerID: MCPeerID) {
        // TODO: Switch on the GameMessage enum and update our @Published variables
        print("Received message from \(peerID.displayName): \(message)")
    }
}
