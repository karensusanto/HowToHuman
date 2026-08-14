//
//  LobbySearchScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//

import SwiftUI

struct orbitView: View {
    var body: some View {
        Text("orbitView")
    }
}



struct LobbySearchScreen: View {
    @EnvironmentObject var store: GameStore
    var body: some View {
        VStack{
            HStack{
                BackButton(toState: .home)
                Spacer()
                Text("JOIN A ROOM")
                    .font(.system(size: 13, weight: .bold))
                                            .tracking(1.5)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            
            orbitView()
            ScrollView{
                
            }
            
            PrimaryButton(title: "CREATE ROOM"){
                store.state = .customizeAlien
            }
        }.padding()
    }
}

#Preview {
    LobbySearchScreen().environmentObject(GameStore()).preferredColorScheme(.dark)
}
