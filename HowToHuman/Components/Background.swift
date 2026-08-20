//
//  Background.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 19/08/26.
//

import SwiftUI

struct HTHOnboardingBackground: View {
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
//                .offset(x: -200)
        }
        .ignoresSafeArea()
    }
}

struct HTHGameBackground: View {
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
        }
        .ignoresSafeArea()
    }
}

#Preview {
    HTHOnboardingBackground()
}
