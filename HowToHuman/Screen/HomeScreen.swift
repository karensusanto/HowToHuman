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
        NavigationStack{
            VStack(spacing: 100) {
                
                VStack{
                    Image("alien-placeholder").resizable().scaledToFit()
                        .frame( height: 100)
                    Text("HOW TO HUMAN")
                }
                
                VStack(spacing: 20){
                    
                    PrimaryButton(title: "PLAY"){
                        store.state = .lobbySearch
                    }
                    
                    SecondaryButton(title: "HOW TO PLAY"){
                        store.state = .howToPlay
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(50)
        }
    }
}

#Preview {
    HomeScreen().environmentObject(GameStore()).preferredColorScheme(.dark)
}
