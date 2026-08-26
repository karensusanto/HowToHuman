//
//  LobbySearchScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//

import SwiftUI

struct OrbitView: View {
    @EnvironmentObject var store: GameStore
    @Binding var joinRoomPopUp: Bool
    
    var body: some View {
        GeometryReader { geo in
            let diameter = geo.size.height * 0.8
            let padding = CGFloat(50)
            
            ZStack {
                // Your orbit/dashed-line image
                Image("earth-perimeter")
                    .resizable()
                    .frame(
                        width: diameter,
                        height: diameter
                    )
                
                // Earth
                Image("earth")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                
                // Ships
                if !store.availableRooms.isEmpty {
                    ForEach(
                        Array(store.availableRooms.enumerated()),
                        id: \.element.id
                    ) { index, room in
                        
                        let count = store.availableRooms.count
                        
                        // -90° -> +90°
                        let progress = count == 1
                        ? 0.5
                        : Double(index) / Double(count - 1)
                        
                        let angle =
                        -.pi / 2 + progress * .pi
                        
                        let radiusX = diameter / 2 - padding
                        let radiusY = diameter / 2
                        
                        let x =
                        radiusX * cos(angle)
                        
                        let y =
                        radiusY * sin(angle)
                        
                        Button {
                            store.joiningRoom = room
                            joinRoomPopUp = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(room.hostAvatar)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100)
                                
                                HTHText(
                                    title: LocalizedStringKey(room.roomName), size: HTHSize.caption, font: HTHFont.space_grot, weight: .medium
                                ).frame(width: 100).multilineTextAlignment(.center)
                                HTHText(
                                    title: "(\(room.playerCount) / \(room.maxPlayers) Players)", size: HTHSize.caption, font: HTHFont.space_grot, weight: .medium
                                ).frame(width: 100).multilineTextAlignment(.center)
                            }
                        }
                        .grayscale(room.playerCount >= room.maxPlayers ? 0.9 : 0)
                        .disabled(room.playerCount >= room.maxPlayers)
                        .position(
                            x: diameter / 2 + x + padding,
                            y: geo.size.height / 2 + y
                        )
                    }
                }
            }
            .frame(
                width: diameter, height: geo.size.height
            )
            .offset(
                x: -diameter / 2
            )
        }
    }
}



struct LobbySearchScreen: View {
    @EnvironmentObject var store: GameStore
    @State var joinRoomPopUp: Bool = false
    
    var body: some View {
        ZStack{
            Color.clear.ignoresSafeArea()
            
            VStack{
                HStack{
                    BackButton(toState: .home)
                    Spacer()
                }
                
                OrbitView(joinRoomPopUp: $joinRoomPopUp)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                
                PrimaryButton(title: "CREATE ROOM", btnHeight: 72){
                    store.joiningRoom = nil
                    store.state = .customizeAlien
                }
            }.padding()
                .onAppear {
                    store.startBrowsing()
                    store.playSong()
                }
                .onDisappear {
                    store.networkManager.stopBrowsing()
                }
            
            VStack{
                
                if joinRoomPopUp{
                    JoinRoomPopUp(isPresented: $joinRoomPopUp, room: store.joiningRoom!)
                }
                
                if store.showRoomFullPopUp{
                    RoomFullPopUp(isPresented: $store.showRoomFullPopUp, room: store.joiningRoom!)
                }
            }.padding()
        }
        .frame(maxWidth: .infinity)
        .background {
            HTHGameBackground()
        }
    }
}

#Preview {
    let motionManager = MotionManager()
    let store = GameStore(
        motionManager: motionManager
    )
    LobbySearchScreen()
    .environmentObject(store)
    .environmentObject(motionManager)
}
