//
//  CustomizeAlienScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//

import SwiftUI

struct CustomizeAlienScreen: View {
    @EnvironmentObject var store: GameStore
    @State private var selectedAvatar: String = AlienAvatar.allCases.first!
    @State var playerName : String = ""
    @State var playerNameLen: Int = 0
    
    var body: some View {
        VStack {
            HStack {
                BackButton(toState: .lobbySearch)
                Spacer()
            }
            
            ScrollView {
                VStack(spacing:20){
                    Text(store.currRoom?.roomName ?? "Room").font(.system(.footnote))
                    Text("CUSTOMIZE YOUR ALIEN").font(.system(.title))
                    
                    Avatar(avatar: selectedAvatar, size: 100, selected: true)
                    
                    AvatarGridView(selectedAvatar: $selectedAvatar)
                    
                    
                    TextField("Enter your name", text: $playerName)
                        .padding(.vertical, 10)
                        .onChange(of: playerName) { _, newValue in
                            if newValue.count > 20 {
                                playerName = String(newValue.prefix(20))
                            }
                            playerNameLen = playerName.count
                        }
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    HTHText(title: "\(playerNameLen)/20", size: HTHSize.caption, color: Color.gray)
                    
                }
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
