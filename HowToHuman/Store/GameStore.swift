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

enum GamePhase: String, Codable {
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
    
    // A high-speed pipeline exclusively for transient UI animations
    let incomingReactions = PassthroughSubject<String, Never>()
    
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
            let newPlayer = Player(id: UUID(), name: peerID.displayName)
            
            // Safely append them to the room if the room exists
            if currRoom != nil {
                if !currRoom!.players.contains(where: { $0.name == newPlayer.name }) {
                    currRoom?.players.append(newPlayer)
                }
                
                // HOST ACTION: Distribute the authoritative room state to all clients
                transport.broadcast(message: .stateSync(currRoom!))
            }
            
        case .notConnected:
            print("🔴 \(peerID.displayName) disconnected.")
            // TODO: Remove this player or trigger the graceful exit
            
            // Remove the player from the room array
            currRoom?.players.removeAll(where: { $0.name == peerID.displayName })
            
            // If the person who disconnected was the host, we'd trigger the graceful exit here
            
        case .connecting:
            print("🟡 \(peerID.displayName) is connecting...")
            
        @unknown default:
            break
        }
    }
    
    private func handleIncomingMessage(_ message: GameMessage, from peerID: MCPeerID) {
        switch message {
        case .stateSync(let authoritativeRoom):
            print("📥 Received canonical room state from Host.")
            // Overwrite the client's nil state with the true game state
            self.currRoom = authoritativeRoom
            
        case .reactionSent(let emoji):
            // Push the incoming emoji directly to the UI's animation stream
            self.incomingReactions.send(emoji)
            
        default:
            print("Received unhandled message from \(peerID.displayName): \(message)")
        }
    }
    
    // MARK: - Network Triggers
    
    func hostGame() {
        // 1. Create a placeholder room so the UI has something to display
        let hostPlayer = Player(id: UUID(), name: UIDevice.current.name)
        currRoom = Room(
            id: UUID(),
            name: "Test Lobby",
            hostID: hostPlayer.id,
            players: [hostPlayer] // Add the host to the room immediately
        )
        
        // 2. Start broadcasting
        transport.startHosting()
        print("Started broadcasting as Host...")
    }
    
    func joinGame() {
        transport.startBrowsing()
        print("Scanning for Hosts...")
    }
    
    func leaveGame() {
        transport.stopNetworking()
        currRoom = nil
    }
    
    func sendReaction(_ emoji: String) {
        // We set 'reliably: false' (UDP mode) because missing a single dropped
        // confetti frame is perfectly fine, and it keeps network latency
        // insanely low so players can mash the button.
        transport.broadcast(message: .reactionSent(emoji), reliably: false)
    }
}
