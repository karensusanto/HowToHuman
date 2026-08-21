//
//  Background.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 19/08/26.
//

import SwiftUI

struct HTHOnboardingBackground: View {
    @EnvironmentObject var motion: MotionManager
    var bgImage: String = "stars-bg"
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    HTHColor.darkBackground,
                    HTHColor.lightBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            Image(bgImage)
                .resizable()
                .scaledToFill()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .ignoresSafeArea()
                .scaleEffect(1.15)
                .offset(x: CGFloat(motion.roll), y: CGFloat(motion.pitch))
                .onAppear{
                    motion.startUpdates()
                }
//                .onDisappear {
//                    motion.stopUpdates()
//                }
        }
        .ignoresSafeArea()
    }
}

struct HTHGameBackground: View {
    @EnvironmentObject var motion: MotionManager
    var bgImage: String = "stars-bg-2"
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    HTHColor.darkBackground,
                    HTHColor.lightBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            Image(bgImage)
                .resizable()
                .scaledToFill()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .ignoresSafeArea()
                .scaleEffect(1.15)
                .offset(x: CGFloat(motion.roll), y: CGFloat(motion.pitch))
                .onAppear{
                    motion.startUpdates()
                }
//                .onDisappear {
//                    motion.stopUpdates()
//                }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    HTHOnboardingBackground()
}
