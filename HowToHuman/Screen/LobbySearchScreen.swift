//
//  LobbySearchScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//

import SwiftUI

struct orbitView: View {
    var body: some View {
        Text("🌏").font(.largeTitle)
    }
}



struct LobbySearchScreen: View {
    @EnvironmentObject var store: GameStore
    @State var joinRoomPopUp: Bool = false
    
    var body: some View {
        ZStack{
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
                    ForEach(store.availableRooms, id: \.id){room in
                        Button{
                            store.joiningRoom = room
                            store.joiningRoom = room
                            joinRoomPopUp.toggle()
                        }label:{
                            VStack{
                                Image("ufo-placeholder").resizable().scaledToFit().frame(width: 100)
                                Text(room.roomName)
                            }
                        }
                    }
                }
                
                PrimaryButton(title: "CREATE ROOM"){
                    store.joiningRoom = nil
                    store.state = .customizeAlien
                }
            }.padding()
                .onAppear {
                    store.networkManager.startBrowsing(){rooms in
                        store.availableRooms = rooms
                    }
                }
                .onDisappear {
                    store.networkManager.stopBrowsing()
                }
            
            if joinRoomPopUp{
                JoinRoomPopUp(isPresented: $joinRoomPopUp, room: store.joiningRoom!)
            }
            
            if store.showRoomFullPopUp{
                RoomFullPopUp(isPresented: $store.showRoomFullPopUp, room: store.joiningRoom!)
            }
        }
    }
}

#Preview {
    LobbySearchScreen().environmentObject(GameStore()).preferredColorScheme(.dark)
}
