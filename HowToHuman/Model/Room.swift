//
//  Room.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//
import Foundation

nonisolated enum TimerMode: Int, CaseIterable, Identifiable, Codable, Sendable {
    case noTime, fast, normal, slow

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .noTime: return "NO TIME"
        case .fast: return "FAST"
        case .normal: return "NORMAL"
        case .slow: return "SLOW"
        }
    }

    enum PhaseKind {
        case question, steps, answer
    }

    func seconds(for kind: PhaseKind) -> Int? {
        switch self {
        case .noTime:
            return nil
        case .fast:
            switch kind {
            case .question: return 15
            case .steps: return 60
            case .answer: return 90
            }
        case .normal:
            switch kind {
            case .question: return 20
            case .steps: return 90
            case .answer: return 120
            }
        case .slow:
            switch kind {
            case .question: return 30
            case .steps: return 120
            case .answer: return 150
            }
        }
    }
}

struct Room: Identifiable, Codable, Sendable {
    let id: UUID
    var roomName: String
    var hostID: UUID
    var players: [Player]
    var timerMode: TimerMode
    var maxPlayers: Int = 8

    init(id: UUID = UUID(), name: String, hostID: UUID, players: [Player], timerMode: TimerMode = .normal) {
        self.id = id
        self.roomName = name
        self.hostID = hostID
        self.players = players
        self.timerMode = timerMode
    }

    var isFull: Bool { players.count >= maxPlayers }
}
