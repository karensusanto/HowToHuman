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
            Color.clear.ignoresSafeArea()
            VStack{
                HStack{
                    ExitRoomButton()
                    Spacer()
                    VStack{
                        HTHText(title: store.currRoom?.roomName ?? "Lobby", size: HTHSize.title, color: HTHColor.yellow)
                        HTHText(title: "\(store.currRoom?.players.count ?? 0) / \(store.currRoom?.maxPlayers ?? 8)")
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
                            AvatarLobbyView(player: player)
                        }
                    }
                }
                Spacer()
                
                if store.currRoom?.hostID == store.networkManager.myPeerId{
                    
                    HStack{
                        OpenSettingButton(){
                            store.showSettingPopUp = true
                        }
                        
                        PrimaryButton(title: "START", btnHeight: 72, isDisabled: store.currRoom!.players.count < 2){
                            store.phase = .askHuman
                            store.state = .transition
                            store.sendDataToPlayers()
                        }
                    }
                }
                else{
                    HStack{
                        ProgressView()
                        HTHText(title: "Waiting for host to start the game...", size: HTHSize.caption, font: HTHFont.space_grot)
                    }
                }
                
            }
            .padding()
            
            if store.showExitRoomPopUp{
                ExitRoomPopUp(isPresented: $store.showExitRoomPopUp)
            }
            
            let currTimeModeIdx = switch store.currRoom?.timerMode{
            case .fast: 0
            case .normal: 1
            case .slow: 2
            default:
                1
            }
            if store.showSettingPopUp{
                RoomSettingPopUp(isPresented: $store.showSettingPopUp, value: Float(currTimeModeIdx))
            }
        }
        .frame(maxWidth: .infinity)
        .background {
            HTHOnboardingBackground()
        }
    }
}

#Preview {
    LobbyScreen().environmentObject(GameStore()).preferredColorScheme(.dark)
}
