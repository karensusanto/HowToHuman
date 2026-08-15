//
//  CustomizeAlienScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//

import SwiftUI

struct CustomizeAlienScreen: View {
    @EnvironmentObject var store: GameStore
    @State private var selectedAvatar: String = AlienAvatar.allCases.randomElement()!
    
    var body: some View {
        VStack {
            HStack {
                BackButton(toState: .lobbySearch)
                Spacer()
            }
            
            ScrollView {
                Text(store.currRoom?.roomName ?? "Room").font(.system(.footnote))
                Text("CUSTOMIZE YOUR ALIEN").font(.system(.title))
                
                Avatar(avatar: selectedAvatar, size: 100, selected: true)
                
                AvatarGridView(selectedAvatar: $selectedAvatar)
            }
            
            PrimaryButton(title: "DONE"){
                store.state = .lobby
            }
            
        }.padding()
        
    }
}

#Preview {
    CustomizeAlienScreen().environmentObject(GameStore()).preferredColorScheme(.dark)
}
