//
//  CustomizeAlienScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//

import SwiftUI

struct CustomizeAlienScreen: View {
    @EnvironmentObject var store: GameStore
    let size: CGFloat = 56
    @State private var floating = false
//    @State private var avatar: Alien.Avatar = .random()
    
    var body: some View {
        VStack {
            HStack {
                BackButton(toState: .lobbySearch)
                Spacer()
            }
            
            ScrollView {
                Text(store.currRoom?.roomName ?? "Room").font(.system(.footnote))
                Text("CUSTOMIZE YOUR ALIEN").font(.system(.title))
                
                ZStack {
                    Circle()
                        .strokeBorder(Color.white,
                            lineWidth: 2.5)
                            
                            Text("🙂")
                                .font(.system(size: size * 0.5))
                                .offset(y: floating ? -1.5 : 1.5)
                        }
                        .frame(width: size, height: size)
                        .onAppear {
                            withAnimation(.easeInOut(duration: Double.random(in: 1.8...2.6)).repeatForever(autoreverses: true)) {
                                floating = true
                            }
                        }
            }
            
            PrimaryButton(title: "DONE"){
                store.state = .lobby
            }
            
        }.padding()
        
    }
}

#Preview {
    CustomizeAlienScreen().environmentObject(GameStore()).preferredColorScheme(.dark)
}
