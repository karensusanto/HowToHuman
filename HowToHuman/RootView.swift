//
//  RootView.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: GameStore
    var body: some View {
        Group {
            switch store.state {
            case .home:
                HomeScreen()
            case .howToPlay:
                HowToPlayScreen()
            case .lobbySearch:
                LobbySearchScreen()
            case .customizeAlien:
                CustomizeAlienScreen()
            case .lobby:
                LobbyScreen()
            case .transitionToVoting,
                    .transitionToAskHuman,
                    .transitionToGuideAliens,
                    .transitionToShareExperience,
                    .transitionToNarrateExperience:
                TransitionScreen()
            case .askHuman:
                AlienQuestionScreen()
            case .guideAlien:
                HumanInstructionScreen()
            case .narrateExperience:
                AlienNarrationScreen()
            case .shareExperience:
                EmptyView()
            case .voting:
                EmptyView()
            case .result:
                EmptyView()
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.35), value: store.state)
        .transition(.opacity)
    }
}

#Preview {
    RootView().environmentObject(GameStore()).environmentObject(MotionManager())
}
