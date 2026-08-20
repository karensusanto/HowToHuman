//
//  PopUps.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 16/08/26.
//

import SwiftUI

struct ExitRoomPopUp: View {
    @EnvironmentObject var store: GameStore
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack{
            if let roomName = store.currRoom?.roomName{
                HTHText(title: "Exit \(roomName)?")
            }else{
                HTHText(title: "Exit Room?")
            }
            
            if store.currRoom?.players.count == 1{
                HTHText(title: "The room will be deleted")
            }
            else if store.currRoom?.hostID.uuidString == store.networkManager.myPeerId.uuidString{
                HTHText(title: "Your hostship will be transferred to the next player")
            }
            
            HStack{
                SecondaryButton(title:"No"){
                    isPresented = false
                }
                
                PrimaryButton(title:"Yes"){
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
                        store.leaveRoomAsParticipant(on: store.connectionToHost!)
                    }
                    
                    isPresented = false
                }
            }
        }.padding()
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black))
        
    }
}

struct JoinRoomPopUp: View {
    @EnvironmentObject var store: GameStore
    @Binding var isPresented: Bool
    @State var room: DiscoveredRoom
    
    var body: some View {
        VStack{
            HTHText(title: "Join \(room.roomName)?")
            
            HStack{
                SecondaryButton(title:"No"){
                    isPresented = false
                }
                
                PrimaryButton(title:"Yes"){
                    isPresented = false
                    store.state = .customizeAlien
                }
            }
        }.padding()
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black))
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

#Preview {
    @Previewable @State var isPresented: Bool = true
    RoomSettingPopUp(isPresented:$isPresented, value: 0).environmentObject(GameStore()).preferredColorScheme(.dark)
}
