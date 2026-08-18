//
//  LobbyScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 14/08/26.
//

import SwiftUI

struct LobbyScreen: View {
    @EnvironmentObject var store: GameStore
    @State var listOfPlayersAvatars: [String] = []
    
    var body: some View {
        ZStack{
            VStack{
                HStack{
                    ExitRoomButton()
                    Spacer()
                    VStack{
                        Text(store.currRoom?.roomName ?? "Lobby").font(.largeTitle)
                        Text("\(store.currRoom?.players.count ?? 0) / \(store.currRoom?.maxPlayers ?? 8)")
                    }
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                
                let columns = [
                    GridItem(.adaptive(minimum: 65))
                ]
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(store.currRoom?.players ?? [], id: \.id){player in
                        VStack{
                            if player.id == store.currRoom?.hostID{
                                Text("Host").foregroundStyle(Color.blue)
                            }
                            else{
                                Text("Player")
                            }
                            Button{
                                
                            }label:{
                                Avatar(avatar: player.avatar, selected: true)
                            }
                            if player.id == store.currRoom?.hostID && store.currRoom?.hostID == store.networkManager.myPeerId{
                                Text("You").foregroundStyle(Color.blue)
                            }
                            else{
                                Text(player.name)
                            }
                        }
                    }
                }
                Spacer()
                
                if store.currRoom?.hostID == store.networkManager.myPeerId{
                    
                    HStack{
                        OpenSettingButton(){
                            store.showSettingPopUp = true
                        }
                        
                        PrimaryButton(title: "START", isDisabled: store.currRoom!.players.count < 2){
                            store.phase = .askHuman
                            store.state = .transition
                            store.sendDataToPlayers()
                        }
                    }
                }
                else{
                    HStack{
                        ProgressView()
                        Text("Waiting for host to start the game...")
                    }
                }
                
            }
            .padding()
            
            if store.showExitRoomPopUp{
                ExitRoomPopUp(isPresented: $store.showExitRoomPopUp)
            }
            
            let currTimeModeIdx = switch store.currRoom?.timerMode{
            case .noTime: 0
            case .fast: 1
            case .normal: 2
            case .slow: 3
            case .none:
                2
            }
            if store.showSettingPopUp{
                RoomSettingPopUp(isPresented: $store.showSettingPopUp, value: Float(currTimeModeIdx))
            }
        }
    }
}

#Preview {
    LobbyScreen().environmentObject(GameStore()).preferredColorScheme(.dark)
}
