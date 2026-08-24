//
//  Game.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 23/08/26.
//

enum AppState: Codable {
    case home
    case howToPlay
    case lobbySearch
    case customizeAlien
    case lobby
    case transitionToAskHuman
    case transitionToGuideAliens
    case transitionToNarrateExperience
    case transitionToShareExperience
    case transitionToVoting
    case askHuman
    case guideAlien
    case narrateExperience
    case shareExperience
    case voting
    case result
    
    static func transitions() -> [AppState] {
        return [.transitionToVoting, .transitionToAskHuman, .transitionToGuideAliens, .transitionToNarrateExperience, .transitionToShareExperience]
    }
    
    var next: AppState {
        switch self{
        case .lobby:
                .transitionToAskHuman
        case .transitionToAskHuman:
                .askHuman
        case .transitionToGuideAliens:
                .guideAlien
        case .transitionToNarrateExperience:
                .narrateExperience
        case .transitionToShareExperience:
                .shareExperience
        case .transitionToVoting:
                .voting
        case .askHuman:
                .transitionToGuideAliens
        case .guideAlien:
                .transitionToNarrateExperience
        case .narrateExperience:
                .transitionToShareExperience
        case .shareExperience:
                .transitionToVoting
        case .voting:
                .result
        case .result:
                .lobby
        default:
            self
        }
    }
}

enum GamePhase: Codable {
    case none
    case askHuman
    case answerAlien
    case narrateExperience
    case shareExperience
    case voting
    
    var next: GamePhase {
        switch self {
        case .none:
            return .askHuman
        case .askHuman:
            return .answerAlien
        case .answerAlien:
            return .narrateExperience
        case .narrateExperience:
            return .shareExperience
        case .shareExperience:
            return .voting
        case .voting:
            return .none
        }
    }
}
