//
//  ContentView.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 11/08/26.
//

import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var store: GameStore
    @State private var floating: Bool = false
    
    var body: some View {
        ZStack{
            Color.clear.ignoresSafeArea()
            VStack(spacing: 100) {
                
                ZStack{
                    HStack{
                        Spacer()
                        Image("HTHTitleAlien").resizable().scaledToFit()
                            .frame(width: 203)
                    }.offset(x: 35, y: floating ? -50 : -30)
                    .onAppear {
                        withAnimation(.easeInOut(duration: Double.random(in: 1.8...2.6)).repeatForever(autoreverses: true)) {
                            floating = true
                        }
                    }
                    Image("HTHTitleText").resizable().scaledToFit()
                    
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
    let motionManager = MotionManager()
    let store = GameStore(
        motionManager: motionManager
    )
    HomeScreen()
    .environmentObject(store)
    .environmentObject(motionManager)
}
