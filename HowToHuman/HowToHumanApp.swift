//
//  HowToHumanApp.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 14/08/26.
//

import SwiftUI

@main
struct HowToHumanApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var motionManager: MotionManager
        @StateObject private var store: GameStore

        init() {
            let motionManager = MotionManager()

            _motionManager = StateObject(
                wrappedValue: motionManager
            )

            _store = StateObject(
                wrappedValue: GameStore(
                    motionManager: motionManager
                )
            )
        }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store).environmentObject(motionManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    print("App is being removed from running apps! Saving data...")
                    if store.currRoom != nil {
                        store.disconnectGracefully()
                    }
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .background {
                        if store.currRoom != nil {
                            store.disconnectGracefully()
                        }
                    }
                }
        }
    }
}
