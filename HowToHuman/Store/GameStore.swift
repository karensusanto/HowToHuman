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
//    private var netTransport: MultipeerTransport!
    
    @Published var state: AppState = .home
    @Published var phase: GamePhase = .askHuman
//    @Published var isMigratingHost: Bool = false
    @Published var currRoom: Room?
    
    init() {
//        let transport = MultipeerConnectivity(displayName: PlatformDevice.name)
//        netTransport = transport
        
    }
}
