//
//  ContentView.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 11/08/26.
//

import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var store: GameStore
    
    var body: some View {
        ZStack{
            Color.clear.ignoresSafeArea()
            VStack(spacing: 100) {
                
                ZStack{
                    Image("HTHTitleText").resizable().scaledToFit()
                    HStack{
                        Spacer()
                        Image("spaceship-pink").resizable().scaledToFit()
                            .frame(width: 115)
                            .rotationEffect(.degrees(24))
                    }.offset(x: 25, y: -110)
                }
                
                VStack(spacing: 20){
                    
                    PrimaryButton(title: "Play", size: HTHSize.largestTitle, btnHeight: 102){
                        store.state = .lobbySearch
                    }
                    
                    Button{
                        store.state = .howToPlay
                    }label: {
                        HTHText(title: "How to Play?", size: 20)
                            .underline(true, pattern: .solid, color: .white)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(50)
            
        }
        .frame(maxWidth: .infinity)
        .background {
            HTHOnboardingBackground()
        }
    }
}

#Preview {
    HomeScreen().environmentObject(GameStore()).preferredColorScheme(.dark)
}
