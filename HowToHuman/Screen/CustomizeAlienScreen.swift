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
    @State var playerName : String = ""
    
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
                
                TextField("Enter your name", text: $playerName)
                    .padding(.vertical, 10)
            }
            
            PrimaryButton(title: "DONE", isDisabled: playerName.isEmpty){
                if store.joiningRoom == nil {
                    let host = Player(id: store.networkManager.myPeerId, name: playerName, avatar: selectedAvatar)
                    let room = Room(name: "\(host.name)'s Room", hostID: host.id, players: [host])
                    
                    store.networkManager.startAdvertising(room: room)
                    store.currRoom = room
                    store.state = .lobby
                }
                else{//joining room
                    let player = Player(id: store.networkManager.myPeerId, name: playerName, avatar: selectedAvatar)
                    store.networkManager.join(room: store.joiningRoom!, player: player)
                }
                
                
            }
            
        }.padding()
        
    }
}

#Preview {
    CustomizeAlienScreen().environmentObject(GameStore()).preferredColorScheme(.dark)
}
