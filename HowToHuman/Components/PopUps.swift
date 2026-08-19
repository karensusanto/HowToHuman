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
                Text("Exit \(roomName)?")
            }else{
                Text("Exit Room?")
            }
            
            if store.currRoom?.players.count == 1{
                Text("The room will be deleted")
            }
            else if store.currRoom?.hostID.uuidString == store.networkManager.myPeerId.uuidString{
                Text("Your hostship will be transferred to the next player")
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
            Text("Join \(room.roomName)?")
            
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
            Text("Sorry, \(room.roomName) is full")
            
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
        VStack(spacing: 20){
            Text("Room Settings")
            Slider(value: $value, in: 0...3, step: 1){
                Text("Room Settings")
            }
            HStack{
                Text("No Timer")
                Spacer()
                Text("Fast")
                Spacer()
                Text("Normal")
                Spacer()
                Text("Slow")
            }
            
            SecondaryButton(title: "DONE"){
                switch value{
                case 0:
                    store.currRoom?.timerMode =  .noTime
                case 1:
                    store.currRoom?.timerMode =  .fast
                case 2:
                    store.currRoom?.timerMode =  .normal
                case 3:
                    store.currRoom?.timerMode =  .slow
                default:
                    store.currRoom?.timerMode = .normal
                }
                isPresented = false
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black))
    }
}

#Preview {
    @Previewable @State var isPresented: Bool = true
    ExitRoomPopUp(isPresented:$isPresented).environmentObject(GameStore()).preferredColorScheme(.dark)
}
