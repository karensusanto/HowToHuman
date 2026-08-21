//
//  LobbyScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 14/08/26.
//

import SwiftUI

struct PlayerPosition {
    let x: CGFloat
    let y: CGFloat
}


func findAvailablePosition(
    existing: [PlayerPosition],
    size: CGSize,
    radius: CGFloat
) -> PlayerPosition? {

    for _ in 0..<1000 {
        let radius = CGFloat(80)
        let x = CGFloat.random(
            in: radius...(size.width - radius)
        )

        let y = CGFloat.random(
            in: radius...(size.height - radius)
        )

        let candidate = PlayerPosition(
            x: x,
            y: y
        )

        let overlaps = existing.contains { circle in
            let dx = candidate.x - circle.x
            let dy = candidate.y - circle.y

            let distance = sqrt(dx * dx + dy * dy)

            return distance < radius + radius
        }

        if !overlaps {
            return candidate
        }
    }

    return nil
}

struct playersView: View {
    @EnvironmentObject var store: GameStore
    @Binding var positions: [UUID: PlayerPosition]
    @Binding var selectedPlayer: Player
    @Binding var showPopUp: Bool
    
    var body: some View {
        GeometryReader{geo in
            ZStack{
                let players: [Player] = store.currRoom?.players ?? []
                ForEach(players, id: \.id){player in
                    if let position = positions[player.id] {
                        AvatarLobbyView(player: player){
                            showPopUp = true
                            selectedPlayer = player
                        }
                        .position(x: position.x, y: position.y)
                    }
                }
            }
            .onAppear{
                updatePositions(
                    players: store.currRoom?.players ?? [],
                    size: geo.size
                )
            }
            .onChange(of: store.currRoom?.players.count) {
                    updatePositions(
                        players: store.currRoom?.players ?? [],
                        size: geo.size
                    )
                }
        }
    }
    
    func updatePositions(
        players: [Player],
        size: CGSize
    ) {
        for player in players {

            // Already has a position → DON'T MOVE IT
            if positions[player.id] != nil {
                continue
            }

            // New player → find a new position
            if let position = findAvailablePosition(
                existing: Array(positions.values),
                size: size,
                radius: 30
            ) {
                positions[player.id] = position
            }
        }

        // Remove players that no longer exist
        let playerIDs = Set(players.map(\.id))

        positions = positions.filter {
            playerIDs.contains($0.key)
        }
    }
}

struct LobbyScreen: View {
    @EnvironmentObject var store: GameStore
    @State var listOfPlayersAvatars: [String] = []
    @State private var positions: [UUID: PlayerPosition] = [:]
    @State var selectedPlayer: Player = Player(id: UUID(), name: "", avatar: "")
    
    var body: some View {
        ZStack{
            Color.clear.ignoresSafeArea()
            VStack{
                
                HStack{
                    ExitRoomButton()
                    Spacer()
                    VStack{
                        HTHText(title: store.currRoom?.roomName ?? "Lobby", size: HTHSize.title, color: HTHColor.yellow)
                        HTHText(title: "(\(store.currRoom?.players.count ?? 0) / \(store.currRoom?.maxPlayers ?? 8) Players)", font: HTHFont.space_grot, weight: .bold, color: HTHColor.yellow)
                    }
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                
                playersView(positions: $positions, selectedPlayer: $selectedPlayer, showPopUp: $store.showKickPlayerPopUp)
                
                if store.currRoom?.hostID == store.networkManager.myPeerId{
                    
                    HStack{
                        OpenSettingButton(){
                            store.showSettingPopUp = true
                        }
                        
                        PrimaryButton(title: "START", btnHeight: 72, isDisabled: store.currRoom!.players.count < 2){
                            store.next()
                        }
                    }
                }
                else{
                    HStack{
                        ProgressView()
                        HTHText(title: "Wait for host to start the game...", size: HTHSize.caption, font: HTHFont.space_grot)
                    }
                }
                
                
            }
            .padding()
            
            
            
            
            let currTimeModeIdx = switch store.currRoom?.timerMode{
            case .fast: 0
            case .normal: 1
            case .slow: 2
            default:
                1
            }
            
            VStack{
                if store.showExitRoomPopUp{
                    ExitRoomPopUp(isPresented: $store.showExitRoomPopUp)
                }
                if store.showSettingPopUp{
                    TimerSettingPopUp(isPresented: $store.showSettingPopUp, value: Float(currTimeModeIdx))
                }
                if store.showKickPlayerPopUp{
                    KickPlayerPopUp(isPresented: $store.showKickPlayerPopUp, player: selectedPlayer)
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
    LobbyScreen().environmentObject(GameStore()).environmentObject(MotionManager())
}
