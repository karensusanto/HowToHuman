//
//  RootView.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//

import SwiftUI

struct RootView: View {
    @StateObject private var store = GameStore()

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
            case .transition:
                TransitionScreen()
            case .askHuman:
                AlienQuestionScreen()
            case .answerAlien:
                EmptyView()
            case .narrateExperience:
                EmptyView()
            case .reviewExperience:
                EmptyView()
            case .voting:
                EmptyView()
            }
        }
        .environmentObject(store)
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.35), value: store.state)
        .transition(.opacity)
//        .overlay {
//            if store.isMigratingHost {
//                ReconnectingOverlay()
//            }
//        }
//        .animation(.easeInOut(duration: 0.25), value: store.isMigratingHost)
    }
}

#Preview {
    RootView()
}
