//
//  AlienNarrationScreen.swift
//  HowToHuman
//
//  Created by Baeni on 17/8/26.
//

import SwiftUI

struct AlienNarrationScreen: View {
    let steps: [String]

    @State private var currentIndex: Int = 0
    @State private var narrations: [String]
    @State private var expandedIndices: Set<Int> = []

    private let stars: [StarDot] = (0..<25).map { _ in
        StarDot(
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 2...5),
            phase: Double.random(in: 0...(2 * .pi)),
            speed: Double.random(in: 0.3...0.9)
        )
    }

    private struct StarDot {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let phase: Double
        let speed: Double
    }

    init(steps: [String] = [
        "Find a bathroom",
        "Turn on the water",
        "Get undressed",
        "Step into the shower",
        "Wash with soap",
        "Dry off"
    ]) {
        self.steps = steps
        _narrations = State(initialValue: Array(repeating: "", count: steps.count))
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            starField
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    roleBadge
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Text("How to shower?")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.top, 16)

                stepCarousel

                pageDots

                Text("How did it go?")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 28)

                narrationField
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                Spacer()

                Button {
                } label: {
                    Text("DONE")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color(white: 0.9))
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    private var roleBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.white)
                .frame(width: 14, height: 14)
            Text("You are the alien")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.black))
    }

    private var stepCarousel: some View {
        TabView(selection: $currentIndex) {
            ForEach(steps.indices, id: \.self) { index in
                stepCard(index: index)
                    .padding(.horizontal, 20)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 150)
    }

    private func stepCard(index: Int) -> some View {
        let isExpanded = expandedIndices.contains(index)

        return VStack(spacing: 10) {
            Text("Step \(index + 1)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.black)

            Text(steps[index])
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(isExpanded ? nil : 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.black, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if isExpanded {
                expandedIndices.remove(index)
            } else {
                expandedIndices.insert(index)
            }
        }
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(steps.indices, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.black : Color.black.opacity(0.2))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var narrationField: some View {
        TextField("Describe what happened...", text: narrationBinding, axis: .vertical)
            .font(.system(size: 16))
            .lineLimit(3...6)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 90, alignment: .topLeading)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.black, lineWidth: 1.5)
            )
    }

    private var narrationBinding: Binding<String> {
        Binding(
            get: {
                narrations.indices.contains(currentIndex) ? narrations[currentIndex] : ""
            },
            set: { newValue in
                if narrations.indices.contains(currentIndex) {
                    narrations[currentIndex] = newValue
                }
            }
        )
    }

    private var starField: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(0..<stars.count, id: \.self) { i in
                        let star = stars[i]
                        let dx = sin(t * star.speed + star.phase) * 10
                        let dy = cos(t * star.speed * 0.8 + star.phase) * 10
                        Image(systemName: "star.fill")
                            .foregroundColor(.black.opacity(Double.random(in: 0.15...0.35)))
                            .font(.system(size: star.size))
                            .position(
                                x: star.x * geo.size.width + dx,
                                y: star.y * geo.size.height + dy
                            )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    AlienNarrationScreen()
}
