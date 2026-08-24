//
//  Room.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//
import Foundation
import Network

nonisolated enum TimerMode: Int, CaseIterable, Identifiable, Codable, Sendable {
    case slow, normal, fast

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .fast: return "FAST"
        case .normal: return "NORMAL"
        case .slow: return "SLOW"
        }
    }

    enum PhaseKind {
        case question, steps, experience
    }

    func seconds(for kind: PhaseKind) -> Int? {
        switch self {
        case .fast:
            switch kind {
            case .question: return 15
            case .steps: return 60
            case .experience: return 120
            }
        case .normal:
            switch kind {
            case .question: return 30
            case .steps: return 120
            case .experience: return 180
            }
        case .slow:
            switch kind {
            case .question: return 45
            case .steps: return 180
            case .experience: return 240
            }
        }
    }
    
    func estimatedDuration() -> String? {
        switch self {
        case .fast: return "5-10"
        case .normal: return "7-12"
        case .slow: return "10-15"
        }
    }
}

struct Room: Identifiable, Codable, Sendable {
    let id: UUID
    var roomName: String
    var hostID: UUID
    var inGamePlayers: [Player]
    var joinedPlayers: [Player]
    var timerMode: TimerMode
    var maxPlayers: Int = 8
    var isPlaying: Bool = false

    init(id: UUID = UUID(), name: String, hostID: UUID, joinedPlayers: [Player], timerMode: TimerMode = .normal) {
        self.id = id
        self.roomName = name
        self.hostID = hostID
        self.joinedPlayers = joinedPlayers
        self.timerMode = timerMode
        self.inGamePlayers = []
    }

    var isFull: Bool { joinedPlayers.count >= maxPlayers }
    
    mutating func changeHost(){
        removePlayer(id: hostID)
        let newHost = isPlaying ? inGamePlayers.first! : joinedPlayers.first!
        self.hostID = newHost.id
        self.roomName = "\(newHost.name)'s Satellite"
    }
    
    mutating func removePlayer(id: UUID){
        inGamePlayers.removeAll(where: { $0.id == id })
        joinedPlayers.removeAll(where: { $0.id == id })
    }
}


struct DiscoveredRoom: Identifiable{
    let id: UUID
    let roomName: String
    let roomEndpoint: NWEndpoint
    let hostID: UUID
    let hostAvatar: String
    let playerCount: String
    let maxPlayers: String
    
    init(id: UUID, roomName: String, roomEndpoint: NWEndpoint, hostID: UUID, hostAvatar: String, playerCount: String, maxPlayers: String) {
        self.id = id
        self.roomName = roomName
        self.roomEndpoint = roomEndpoint
        self.hostID = hostID
        self.hostAvatar = hostAvatar
        self.playerCount = playerCount
        self.maxPlayers = maxPlayers
    }
}
