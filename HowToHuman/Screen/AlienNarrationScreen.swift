//
//  AlienNarrationScreen.swift
//  HowToHuman
//
//  Created by Baeni on 17/8/26.
//

import SwiftUI
import Combine

struct AlienNarrationScreen: View {
    let question: String
    let steps: [String]

    @EnvironmentObject var store: GameStore

    @State private var currentIndex: Int = 0
    @State private var narrations: [String]
    @State private var timeRemaining: Int = 90

    private let purpleGlow = Color(red: 0.70, green: 0.60, blue: 0.90)
    private let maxStepsShown = 5

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var isReady: Bool {
        narrations.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    init(question: String = "", steps: [String] = []) {
        self.question = question
        let filledSteps = steps.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let limitedSteps = Array(filledSteps.prefix(5))
        self.steps = limitedSteps.isEmpty ? ["No steps provided"] : limitedSteps
        _narrations = State(initialValue: Array(repeating: "", count: self.steps.count))
    }

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    HTHText(title: "Tell Your Experience", size: HTHSize.title, color: HTHColor.yellow)
                    Spacer()
                    timerBadge
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                questionPill
                    .padding(.horizontal, 40)
                    .padding(.top, 16)

                stepCarousel

                narrationField
                    .padding(.horizontal, 5)
                    .padding(.top, 10)

                Spacer()

                PrimaryButton(title: "Ready", btnHeight: 56) {
                }
                .disabled(!isReady)
                .grayscale(isReady ? 0 : 1)
                .opacity(isReady ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 0.2), value: isReady)
                .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .background {
            HTHGameBackground()
        }
        .onReceive(timer) { _ in
            guard timeRemaining > 0 else { return }
            timeRemaining -= 1
        }
    }

    private var timerBadge: some View {
        HStack(spacing: 4) {
            Text("\(timeRemaining)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Image(systemName: "clock.fill")
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
    }

    private var questionPill: some View {
        Text(question)
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.7)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(purpleGlow, lineWidth: 1.5)
                    .shadow(color: purpleGlow.opacity(0.6), radius: 6)
            )
    }

    private var stepCarousel: some View {
        HStack(spacing: 4) {
            navArrowButton(systemName: "chevron.left", isEnabled: currentIndex > 0) {
                withAnimation { currentIndex -= 1 }
            }

            TabView(selection: $currentIndex) {
                ForEach(steps.indices, id: \.self) { index in
                    stepCard(index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 150)

            navArrowButton(systemName: "chevron.right", isEnabled: currentIndex < steps.count - 1) {
                withAnimation { currentIndex += 1 }
            }
        }
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func navArrowButton(systemName: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(purpleGlow)
                .frame(width: 28, height: 28)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.3)
    }
    
    private func stepCard(index: Int) -> some View {
        VStack(alignment: .center, spacing: 0) {
    
            Text(steps[index])
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.bottom,5)
            
            Text("Step \(currentIndex + 1)/\(steps.count)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.gray)
                .animation(.easeInOut(duration: 0.2), value: currentIndex)
            
        }
        .padding(20)
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
    }


    private var narrationField: some View {
        ZStack(alignment: .topLeading) {
            if narrationBinding.wrappedValue.isEmpty {
                Text("Describe what happened...")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }

            TextField("", text: narrationBinding, axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .lineLimit(3...6)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
        }
        .frame(minHeight: 90, alignment: .topLeading)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(purpleGlow, lineWidth: 1.5)
                .shadow(color: purpleGlow.opacity(0.6), radius: 6)
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
}

#Preview {
    AlienNarrationScreen(
        question: "How do you clean up after a dump?",
        steps: [
            "Find a bathroom",
            "Turn on the water",
            "Get undressed"
        ]
    )
    .environmentObject(GameStore())
    .environmentObject(MotionManager())
}
