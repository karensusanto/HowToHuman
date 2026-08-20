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
                
                
                Image("HTHTitleText").resizable().scaledToFit()
                
                VStack(spacing: 20){
                    
                    PrimaryButton(title: "Play", size: HTHSize.largestTitle, btnHeight: 102){
                        store.state = .lobbySearch
                    }
                    
                    SecondaryButton(title: "How To Play"){
                        store.state = .howToPlay
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
