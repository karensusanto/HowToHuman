//
//  Game.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 17/08/26.
//

import SwiftUI
import Foundation
import Network

// bcs each room can have multiple games
//struct Game: Identifiable{
//    let id: UUID
//    var dataList: [GameData]
//    
//    init(id: UUID, dataList: [GameData]) {
//        self.id = id
//        self.dataList = dataList
//    }
//}

enum MessageType: Codable{
    case none
    case joinRequest
    case joinResponse
    case playerGameData
    case sharedGameData
    case leaveNotice
    case reaction
    case readiness
    case vote
}

struct MessageEnvelope: Codable{
    let type: MessageType
    let data: Data
}

struct PlayerGameData: Codable, Sendable{
    let id: UUID
    var question: String?
    var answer: [String]?
    var experience: String?
    var vote: Float?
}

struct SharedGameData: Codable, Sendable {
    var gamePhase: GamePhase
    var gameState: AppState
    let room: Room
    var voteResult: Float?
    var playerGameDataList: [PlayerGameData]
    var migrateHost: Bool
    var connectToNewHost: Bool
    var assignedQuestionPlayerId: UUID?
    var currentExperienceIndex: Int = 0
    var experienceRevealed: Bool = false
}

struct JoinRequest: Codable, Sendable {
    let player: Player
}


enum JoinResponse: String, Codable, Sendable {
    case accepted
    case roomFull
    case readmitted
    case kicked
}
