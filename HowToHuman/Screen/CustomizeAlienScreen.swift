//
//  CustomizeAlienScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//

import SwiftUI

struct CustomizeAlienScreen: View {
    @EnvironmentObject var store: GameStore
    @State private var selectedAvatar: String? = AlienAvatar.allCases.first!
    @State var playerName : String = ""
    @State var playerNameLen: Int = 0
    
    var alienScrollView: some View{
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .center, spacing: 80) {
                    ForEach(AlienAvatar.allCases, id: \.self) { avatar in
                        ZStack {
                            Image(avatar)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width / 3)
                                .shadow(color: .white.opacity(avatar == selectedAvatar ? 0.5 : 0.0), radius: 15)
                                .shadow(color: .white.opacity(avatar == selectedAvatar ? 0.25 : 0.0), radius: 30)
                                .scrollTransition(
                                    .interactive,
                                    axis: .horizontal
                                ) { view, phase in
                                    view
                                        .scaleEffect(
                                            1.4 - min(abs(phase.value), 1) * 0.5
                                        )
                                        .opacity(
                                            1.0 - min(abs(phase.value), 1) * 0.4
                                        )
                                }
                        }
                        .frame(
                            width: geo.size.width / 3,
                            height: 300
                        )
                        .id(avatar)
                    }
                }
                .frame(height: 300)
                .scrollTargetLayout()
            }
            .contentMargins(
                .horizontal,
                (geo.size.width - geo.size.width / 3) / 2
            )
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selectedAvatar)
        }
        .frame(height: 300)
    }
    
    var body: some View {
        ZStack{
            Color.clear.ignoresSafeArea()
            
            VStack {
                HStack {
                    BackButton(toState: .lobbySearch)
                    Spacer()
                    HTHText(title: "Set Your Profile", size: HTHSize.title, color: HTHColor.yellow)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                
                ZStack{
                    alienScrollView
                    HStack{
                        Spacer()
                        if selectedAvatar != AlienAvatar.allCases.first{
                            Button{
                                guard let selectedAvatar,
                                      let index = AlienAvatar.allCases.firstIndex(of: selectedAvatar),
                                      index > 0
                                else { return }
                                
                                withAnimation {
                                    self.selectedAvatar = AlienAvatar.allCases[index - 1]
                                }
                            }label:{
                                Image(systemName: "chevron.left").fontWeight(.bold).foregroundStyle(.white)
                            }
                        }
                        
                        Color.clear.frame(width: 230, height: 300)
                        
                        if selectedAvatar != AlienAvatar.allCases.last{
                            Button{
                                guard let selectedAvatar,
                                      let index = AlienAvatar.allCases.firstIndex(of: selectedAvatar),
                                      index < AlienAvatar.allCases.count - 1
                                else { return }
                                
                                withAnimation {
                                    self.selectedAvatar = AlienAvatar.allCases[index + 1]
                                }
                            }label:{
                                Image(systemName: "chevron.right").fontWeight(.bold).foregroundStyle(.white)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                TextField("Enter Nickname...", text: $playerName)
                    .padding(.vertical, 15)
                    .onChange(of: playerName) { _, newValue in
                        if newValue.count > 20 {
                            playerName = String(newValue.prefix(20))
                        }
                        playerNameLen = playerName.count
                    }
                    .font(.custom(HTHFont.space_grot, size: HTHSize.body)).fontWeight(.medium)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.center)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.clear)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(HTHColor.purple, lineWidth: 2)
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(HTHColor.purple, lineWidth: 2)
                                    .shadow(color: HTHColor.purple.opacity(0.8), radius: 3)
                                    .shadow(color: HTHColor.purple.opacity(0.5), radius: 8)
                                    .shadow(color: HTHColor.purple.opacity(0.25), radius: 15)
                            }
                        
                        
                    }
                HTHText(title: "\(playerNameLen)/20", size: HTHSize.caption, color: Color.gray)
                
                Spacer()
                PrimaryButton(title: "DONE", isDisabled: playerName.isEmpty){
                    if store.joiningRoom == nil {
                        let host = Player(id: store.networkManager.myPeerId, name: playerName, avatar: selectedAvatar!)
                        let room = Room(name: "\(host.name)'s Satellite", hostID: host.id, players: [host])
                        store.playerGameDataList.append(store.myGameData)
                        
                        store.networkManager.startAdvertising(room: room)
                        store.currRoom = room
                        store.state = .lobby
                    }
                    else{//joining room
                        store.myPlayerData.name = playerName
                        store.myPlayerData.avatar = selectedAvatar!
                        store.join()
                    }
                    
                    
                }
                
            }.padding()
        }
        .frame(maxWidth: .infinity)
        .background {
            HTHOnboardingBackground()
        }
    }
}

#Preview {
    CustomizeAlienScreen().environmentObject(GameStore()).environmentObject(MotionManager())
}
