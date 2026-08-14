//
//  AlienQuestionCreen.swift
//  HowToHuman
//
//  Created by Baeni on 14/8/26.
//

import SwiftUI
struct AlienQuestionScreen: View {
    @State private var answer = ""
    private let stars: [StarDot] = (0..<25).map { _ in
            StarDot(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 2...5)
            )
        }
    private struct StarDot {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
    }
    var body: some View {
        ZStack {
            LinearGradient(
                           colors: [Color(red: 0.1, green: 0.15, blue: 0.35), .black],
                           startPoint: .top,
                           endPoint: .bottom
                       )
            .ignoresSafeArea()
            
            GeometryReader { geo in
                ForEach(0..<stars.count, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .foregroundColor(.white.opacity(Double.random(in: 0.5...1)))
                        .font(.system(size: stars[i].size))
                        .position(
                            x: stars[i].x * geo.size.width,
                            y: stars[i].y * geo.size.height
                        )
                }
            }
            
            VStack (alignment: .center) {
                Text("ASK A HUMAN")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                Text("🛸")
                    .font(.system(size: 72))
                VStack(alignment: .leading, spacing: 15) { Text("HOW DO YOU...?")
                    .font(.headline) .bold() .foregroundColor(.white); TextField("...", text: $answer) .font(.title3) .foregroundColor(.white) }
                    .padding(.horizontal, 20)
                        .frame(height: 70)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                .white.opacity(0.3),
                                lineWidth: 1
                            )
                        )
                        .padding(.horizontal, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            VStack {
                    Spacer()

                Button { } label: {
                    Text("Ask Human")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                        RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial))
                    }
                }
            
        }
    }
}
#Preview {
    AlienQuestionScreen().environmentObject(GameStore()).preferredColorScheme(.dark)
}
