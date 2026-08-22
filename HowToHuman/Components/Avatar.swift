//
//  Avatar.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 14/08/26.
//

import SwiftUI

class AlienAvatar{
    static var allCases: [String] = [
        "spaceship-yellow",
        "spaceship-blue",
        "spaceship-neo",
        "spaceship-cyan",
        "spaceship-pink",
        "spaceship-purple",
    ]
}

struct Avatar: View {
    let avatar: String
    @State private var floating: Bool = false
    var size: CGFloat = 65
    var selected: Bool = false
    
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.5),
                              lineWidth: 0.5)
            
            Image(avatar)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.5)
                .offset(y: floating ? 1.5 : -1.5)
            
            Circle()
                .strokeBorder(Color.white,
                              lineWidth: selected ? 2.5 : 0)
//            Text(avatar)
//                .font(.system(size: size * 0.5))
//                .offset(y: floating ? -1.5 : 1.5)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: Double.random(in: 1.8...2.6)).repeatForever(autoreverses: true)) {
                floating = true
            }
        }
    }
}

struct AvatarGridView: View {
    @Binding var selectedAvatar: String
    @State var listOfAvatars: [String] = AlienAvatar.allCases
    let columns = [
        GridItem(.adaptive(minimum: 70))
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(listOfAvatars, id: \.self){avatar in
                Button{selectedAvatar = avatar}
                label:{
                    Avatar(avatar: avatar, selected: selectedAvatar == avatar)
                }
            }
        }
    }
}

struct AvatarLobbyView: View {
    let player: Player
    @EnvironmentObject var store: GameStore
    @State private var floating: Bool = false
    var action: () -> Void
    
    var playerDisplay: some View{
        VStack{
            
            let addition = player.id == store.currRoom?.hostID ? " [Host]" :""
            let color =
            player.id == store.networkManager.myPeerId ?
            HTHColor.yellow : Color.white
            
            HTHText(title: player.name, font: HTHFont.space_grot, color: color).frame(width: 100).multilineTextAlignment(.center)
            HTHText(title: addition, font: HTHFont.space_grot, color: color)
            
            Image(player.avatar).resizable().scaledToFit().frame(width:100)
            
            
        }
        .offset(y: floating ? 3.0 : -3.0)
        .onAppear {
            withAnimation(.easeInOut(duration: Double.random(in: 1.8...2.6)).repeatForever(autoreverses: true)) {
                floating = true
            }
        }
    }
    
    var body: some View {
        if store.networkManager.myPeerId == store.currRoom?.hostID{
            Button{
                action()
            }label:{
                playerDisplay
            }
        }
        else{
            playerDisplay
        }
        
    }
}

#Preview {
    Avatar(avatar: AlienAvatar.allCases.randomElement() ?? "")
}
