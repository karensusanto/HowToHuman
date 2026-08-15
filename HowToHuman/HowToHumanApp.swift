//
//  HowToHumanApp.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 14/08/26.
//

import SwiftUI

@main
struct HowToHumanApp: App {
    var body: some Scene {
        WindowGroup {
            //Proper RootView
            //RootView().preferredColorScheme(.dark)
            
            //Test RootView
            NetworkTestView().environmentObject(GameStore())
        }
    }
}
