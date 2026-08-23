//
//  RootView.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: GameStore
    // shared between VotingScreen and ResultScreen so the alien cluster morphs continuously across that switch
    @Namespace private var alienNamespace

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
                DisplayScreen()
            case .voting:
                VotingScreen(alienNamespace: alienNamespace)
            case .result:
                ResultScreen(alienNamespace: alienNamespace)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.35), value: store.state)
        .transition(.opacity)
        .onAppear{
            store.initChimeAudioPlayer()
        }
    }
}

#Preview {
    let motionManager = MotionManager()
    let store = GameStore(
        motionManager: motionManager
    )
    RootView()
    .environmentObject(store)
    .environmentObject(motionManager)
}
