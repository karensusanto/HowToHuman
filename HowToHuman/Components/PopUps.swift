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
    var action: () -> Void
    
    var body: some View {
        VStack{
            HTHText(title: title)
            HTHText(title: subtitle)
            
            HStack{
                SecondaryButton(title:"No"){
                    isPresented = false
                }
                
                PrimaryButton(title:"Yes"){
                    action()
                }
            }
        }.padding()
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black))
    }
}

#Preview {
    @Previewable @State var isPresented: Bool = true
    PopUpBuilder(isPresented: $isPresented, title: "Title", subtitle: "subtitle"){
        
    }
}

struct ExitRoomPopUp: View {
    @EnvironmentObject var store: GameStore
    @Binding var isPresented: Bool
    @State var roomName: String = ""
    @State var subTitle: String = ""
    
    var body: some View {
            PopUpBuilder(isPresented: $isPresented, title: "Exit \(roomName)?", subtitle: subTitle){
                
                //check if the room is gonna be empty, delete room
                if store.currRoom?.players.count == 1{
                    store.clearGame()
                    store.networkManager.stop()
                }
                //check if he's the host
                else if store.currRoom?.hostID.uuidString == store.networkManager.myPeerId.uuidString{
                    store.leaveRoomAsHost()
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
                
                if store.currRoom?.players.count == 1 {
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
        PopUpBuilder(isPresented: $isPresented, title: "Join \(room.roomName)?", subtitle: ""){
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
            
            SecondaryButton(title:"OK"){
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
        PopUpBuilder(isPresented: $isPresented, title: "Remove \(player.name) from this room?", subtitle: ""){
            store.kickPlayer(player)
            isPresented = false
        }
    }
}


struct RoomSettingPopUp: View {
    @EnvironmentObject var store: GameStore
    @Binding var isPresented: Bool
    @State var value: Float
    
    var body: some View {
        ZStack{
            Color.clear.ignoresSafeArea()
            VStack(spacing: 40){
                HTHText(title: "Room Settings", size: HTHSize.title, color: HTHColor.yellow)
                VStack(alignment: .leading, spacing: 20){
                    HTHText(title: "Timer")
                    Slider(value: $value, in: 0...2, step: 1){
                        HTHText(title: "Room Settings")
                    }
                    
                    HStack{
                        HTHText(title: "Fast")
                        Spacer()
                        HTHText(title: "Normal")
                        Spacer()
                        HTHText(title: "Slow")
                    }
                }
                let timerMode = switch value{
                case 0:
                    TimerMode.fast
                case 1:
                    TimerMode.normal
                case 2:
                    TimerMode.slow
                default:
                    TimerMode.normal
                }
                Spacer()
                let questionTime = timerMode.seconds(for: .question) ?? 0
                let answerTime = timerMode.seconds(for: .steps) ?? 0
                let experienceTime = timerMode.seconds(for: .experience) ?? 0
                HTHText(title: "Question time: \(questionTime) seconds")
                HTHText(title: "Answer time: \(answerTime) seconds")
                HTHText(title: "Write Experience time: \(experienceTime) seconds")
                Spacer()
                Color.clear
                PrimaryButton(title: "DONE"){
                    store.currRoom?.timerMode = timerMode
                    isPresented = false
                }
            }
            .padding()
        }
        .background(HTHOnboardingBackground())
//        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black))
    }
}

//#Preview {
//    @Previewable @State var isPresented: Bool = true
//    RoomSettingPopUp(isPresented:$isPresented, value: 0).environmentObject(GameStore()).preferredColorScheme(.dark)
//}
