//
//  NetworkTestView.swift
//  HowToHuman
//
//  Created by Syauqi Auliya M on 15/08/26.
//

import SwiftUI

struct NetworkTestView: View {
    @EnvironmentObject var store: GameStore
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Network Test")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button("Host Game") {
                store.hostGame()
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            
            Button("Join Game") {
                store.joinGame()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            
            // Show who is currently in the room
            if let room = store.currRoom {
                VStack(alignment: .leading) {
                    Text("Players in Room:")
                        .font(.headline)
                    ForEach(room.players) { player in
                        Text("- \(player.name)")
                    }
                }
            } else {
                Text("Not in a room.")
                    .foregroundColor(.gray)
            }
        }
    }
}
