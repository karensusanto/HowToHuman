//
//  LobbyScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 14/08/26.
//

import SwiftUI

struct LobbyScreen: View {
    @EnvironmentObject var store: GameStore
    var body: some View {
        VStack{
            HStack{
                BackButton(toState: .customizeAlien)
                Spacer()
            }
            Text("Lobby")
            Spacer()
            PrimaryButton(title: "START"){
                store.phase = .askHuman
                store.state = .transition
            }
        }.padding()
    }
}

#Preview {
    LobbyScreen().environmentObject(GameStore()).preferredColorScheme(.dark)
}
