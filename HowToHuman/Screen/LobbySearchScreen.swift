//
//  LobbySearchScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//

import SwiftUI

struct orbitView: View {
    var body: some View {
        Image("earth-perimeter").resizable().scaledToFit().frame(height: 300)
        Image("earth").resizable().scaledToFit().frame(height: 150)
    }
}



struct LobbySearchScreen: View {
    @EnvironmentObject var store: GameStore
    @State var joinRoomPopUp: Bool = false
    
    var body: some View {
        ZStack{
            Color.clear.ignoresSafeArea()
             
            orbitView()
            VStack{
                HStack{
                    BackButton(toState: .home)
                    Spacer()
                    HTHText(title: "JOIN A ROOM", size: HTHSize.title, color: HTHColor.yellow)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                
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
                
                PrimaryButton(title: "CREATE ROOM", btnHeight: 72){
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
        .frame(maxWidth: .infinity)
        .background {
            HTHOnboardingBackground()
        }
    }
}

#Preview {
    LobbySearchScreen().environmentObject(GameStore()).preferredColorScheme(.dark)
}
