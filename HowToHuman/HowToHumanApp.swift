//
//  HowToHumanApp.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 14/08/26.
//

import SwiftUI

@main
struct HowToHumanApp: App {
    
    @StateObject private var store = GameStore()
    @StateObject private var motion: MotionManager = MotionManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store).environmentObject(motion)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .inactive {
                        if store.currRoom != nil {
                            store.disconnectGracefully()
                        }
                    }
                }
        }
    }
}
