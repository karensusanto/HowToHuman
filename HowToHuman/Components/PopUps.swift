//
//  PopUps.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 16/08/26.
//

import SwiftUI

struct PopUpBuilder: View {
    @Binding var isPresented: Bool
    var title: String
    var subtitle: String
    var leftBtnText: String
    var rightBtnText: String
    var leftBtnColor: Color
    var rightBtnColor: Color
    var action: () -> Void

    var body: some View {
        VStack(spacing: 20){
            VStack(spacing: 10){
                HTHText(title: title, font: HTHFont.space_grot)
                HTHText(title: subtitle, size: HTHSize.caption, font: HTHFont.space_grot)
                    .multilineTextAlignment(.center)
            }

            HStack{
                PrimaryButton(title:leftBtnText, btnColor: leftBtnColor){
                    isPresented = false
                }
                
                PrimaryButton(title:rightBtnText, btnColor: rightBtnColor){
                    action()
                }
            }
        }
        .padding()
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black).stroke(HTHColor.purple, lineWidth: 1)
                .shadow(color: HTHColor.purple.opacity(0.5), radius: 16)
                .shadow(color: HTHColor.purple.opacity(0.3), radius: 30)
        )
    }
}

//#Preview {
//    @Previewable @State var isPresented: Bool = true
//    PopUpBuilder(isPresented: $isPresented, title: "Title", subtitle: "subtitle", leftBtnText: "No", rightBtnText: "Yes", leftBtnColor: .white.opacity(0.3), rightBtnColor: HTHColor.green){
//        
//    }
//}

struct ExitRoomPopUp: View {
    @EnvironmentObject var store: GameStore
    @Binding var isPresented: Bool
    @State var roomName: String = ""
    @State var subTitle: String = ""
    
    var body: some View {
        PopUpBuilder(isPresented: $isPresented, title: "Exit \(roomName)?", subtitle: subTitle, leftBtnText: "No", rightBtnText: "Yes", leftBtnColor: HTHColor.green, rightBtnColor: .white.opacity(0.3)){
                
                //host is the only one in the room and want to leave the room (game hasn't started)
                if store.currRoom?.joinedPlayers.count == 1{
                    store.clearGame()
                    store.networkManager.stop()
                }
                //check if he's the host
                else if store.currRoom?.hostID.uuidString == store.networkManager.myPeerId.uuidString{
                    store.leaveRoomAsHost(){
                        store.clearGame() // clear all connections, hopefully all transfer to new host messages have been sent to the players
                    }
                }
                
                else{
                    store.leaveRoomAsParticipant(on: store.connectionToHost!){
                        store.clearGame()
                    }
                }
                
                isPresented = false
            }.onAppear{
                roomName = store.currRoom?.roomName ?? "Room"
                let hostID = store.currRoom?.hostID.uuidString
                let playerID = store.networkManager.myPeerId.uuidString
                let inGamePlayerIDs = Set(store.currRoom!.inGamePlayers.map(\.id))
                if inGamePlayerIDs.contains(store.myPlayerData.id) && store.currRoom?.inGamePlayers.count == 2 { // a player in the game wants to leave, leaving one player left in the game
                    
                    if hostID == playerID {
                        subTitle = "Leaving will end the game — only 1 player would remain, and your hostship will be transferred to the next player"
                    }
                    else{
                        subTitle = "Leaving will end the game - only 1 player would remain."
                    }
                }
                else if store.currRoom?.joinedPlayers.count == 1 {
                    subTitle = "The room will be deleted"
                }
                else if hostID == playerID {
                    subTitle = "Your hostship will be transferred to the next player"
                }
            }
        
    }
}

struct JoinRoomPopUp: View {
    @EnvironmentObject var store: GameStore
    @Binding var isPresented: Bool
    @State var room: DiscoveredRoom
    
    var body: some View {
        PopUpBuilder(isPresented: $isPresented, title: "Join \(room.roomName)?", subtitle: "", leftBtnText: "No", rightBtnText: "Join", leftBtnColor: .white.opacity(0.3), rightBtnColor: HTHColor.green){
                isPresented = false
                store.state = .customizeAlien
        }
    }
}

struct RoomFullPopUp: View {
    @Binding var isPresented: Bool
    @State var room: DiscoveredRoom
    
    var body: some View {
        VStack{
            HTHText(title: "Sorry, \(room.roomName) is full")
            
            PrimaryButton(title:"OK"){
                isPresented = false
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black))
    }
}

struct KickPlayerPopUp: View {
    @EnvironmentObject var store: GameStore
    @Binding var isPresented: Bool
    @State var player: Player
    
    var body: some View {
        PopUpBuilder(isPresented: $isPresented, title: "Kick \(player.name)?", subtitle: "", leftBtnText: "No", rightBtnText: "Kick", leftBtnColor: HTHColor.green, rightBtnColor: .white.opacity(0.3)){
            store.kickPlayer(player)
            isPresented = false
        }
    }
}

struct TimerCard: View {
    @State var timerMode: TimerMode
    @Binding var selectedTimerMode: TimerMode
    let selectedBorderColor = HTHColor.purple
    let unselectedBorderColor = Color.white.opacity(0.5)
    let selectedTextColor = Color.white
    let unselectedTextColor = Color.white.opacity(0.5)
    @State var isSelected: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20){
            let title = timerMode.label
            HStack(){
                if !isSelected{Spacer()}
                HTHText(title: title, color: isSelected ? selectedTextColor : unselectedTextColor)
                Spacer()
                if isSelected{
                    HTHText(title: "± \(timerMode.estimatedDuration() ?? "0") mins", font: HTHFont.space_grot, weight: .medium, color: isSelected ? selectedTextColor : unselectedTextColor)
                }
            }
            HStack(alignment: .center, spacing: 10){
                if isSelected{
                    VStack(alignment: .leading, spacing: 10){
                        HTHText(title: "Phase 1 - Ask", font: HTHFont.space_grot, weight: .medium, color: isSelected ? selectedTextColor : unselectedTextColor)
                        HTHText(title: "Phase 2 - Guide", font: HTHFont.space_grot, weight: .medium, color: isSelected ? selectedTextColor : unselectedTextColor)
                        HTHText(title: "Phase 3 - Follow", font: HTHFont.space_grot, weight: .medium, color: isSelected ? selectedTextColor : unselectedTextColor)
                    }
                    VStack(alignment: .leading, spacing: 10){
                        HTHText(title: ":", font: HTHFont.space_grot, weight: .medium, color: isSelected ? selectedTextColor : unselectedTextColor)
                        HTHText(title: ":", font: HTHFont.space_grot, weight: .medium, color: isSelected ? selectedTextColor : unselectedTextColor)
                        HTHText(title: ":", font: HTHFont.space_grot, weight: .medium, color: isSelected ? selectedTextColor : unselectedTextColor)
                    }
                    VStack(alignment: .leading, spacing: 10){
                        HTHText(title: "\(timerMode.seconds(for: .question) ?? 0) Seconds", font: HTHFont.space_grot, weight: .medium, color: isSelected ? selectedTextColor : unselectedTextColor)
                        HTHText(title: "\(timerMode.seconds(for: .steps) ?? 0) Seconds", font: HTHFont.space_grot, weight: .medium, color: isSelected ? selectedTextColor : unselectedTextColor)
                        HTHText(title: "\(timerMode.seconds(for: .experience) ?? 0) Seconds", font: HTHFont.space_grot, weight: .medium, color: isSelected ? selectedTextColor : unselectedTextColor)
                    }
                }
                else{
                    Spacer()
                    HTHText(title: "± \(timerMode.estimatedDuration() ?? "0") mins", font: HTHFont.space_grot, weight: .medium, color: isSelected ? selectedTextColor : unselectedTextColor)
                    Spacer()
                }
            }
        }
        .padding()
        .background(isSelected ? .black : .black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? selectedBorderColor : unselectedBorderColor, lineWidth: 2)
                .shadow(
                    color: selectedBorderColor.opacity(0.8),
                    radius: isSelected ? 18 : 0
                )
                .shadow(
                    color: selectedBorderColor.opacity(0.5),
                    radius: isSelected ? 30 : 0
                )
        )
        .onAppear{
            isSelected = selectedTimerMode.label == timerMode.label
        }
        .onChange(of: selectedTimerMode){
            withAnimation(.easeInOut(duration: 0.3)) {
                isSelected = selectedTimerMode.label == timerMode.label
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isSelected)
        
    }
}

struct TimerSettingPopUp: View {
    @EnvironmentObject var store: GameStore
    @Binding var isPresented: Bool
    @State var selectedTimerMode: TimerMode = .normal
    
    
    var body: some View {
        ZStack{
            Color.clear.ignoresSafeArea()
            VStack(spacing: 40){
                HTHText(title: "Timer Settings", size: HTHSize.title, color: HTHColor.yellow)
                Spacer()
                VStack(spacing: 20){
                    ForEach(TimerMode.allCases, id: \.id){mode in
                        Button{
                            selectedTimerMode = mode
                        }label:{
                            TimerCard(timerMode: mode, selectedTimerMode: $selectedTimerMode)
                        }
                        .scaleEffect(selectedTimerMode == mode ? 1 : 0.9)
                    }
                    Spacer()
                    HTHText(title:"The more players you have, the longer the game could go on.", font: HTHFont.space_grot, weight: .medium)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }.padding(.horizontal, 40)
                
                PrimaryButton(title: "DONE", btnHeight: 72){
                    store.currRoom?.timerMode = selectedTimerMode
                    isPresented = false
                }
            }
            .padding()
        }
        .background(HTHGameBackground())
    }
}

#Preview {
    @Previewable @State var isPresented: Bool = true
    let motionManager = MotionManager()
    let store = GameStore(
        motionManager: motionManager
    )
    TimerSettingPopUp(isPresented:$isPresented)
    .environmentObject(store)
    .environmentObject(motionManager)
    
}
