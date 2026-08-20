//
//  AlienNarrationScreen.swift
//  HowToHuman
//
//  Created by Baeni on 17/8/26.
//

import SwiftUI

struct AlienNarrationScreen: View {
    let question: String
    let steps: [String]

    @EnvironmentObject var store: GameStore

    @State private var currentIndex: Int = 0
    @State private var narrations: [String]
    @State private var showAllSteps: Bool = false

    private let purpleGlow = Color(red: 0.70, green: 0.60, blue: 0.90)
    private let maxStepsShown = 5

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
                HTHText(title: "Respond to Instructions", size: HTHSize.largeTitle, color: HTHColor.yellow)
                    .padding(.top, 20)

                questionPill
                    .padding(.horizontal, 40)
                    .padding(.top, 16)

                stepCarousel

                stepCounter

                Text("How did it go?")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                narrationField
                    .padding(.horizontal, 20)
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

            if showAllSteps {
                allStepsPopup
            }
        }
        .frame(maxWidth: .infinity)
        .background {
            HTHGameBackground()
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
        HStack(spacing: 8) {
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
            .onTapGesture {
                showAllSteps = true
            }

            navArrowButton(systemName: "chevron.right", isEnabled: currentIndex < steps.count - 1) {
                withAnimation { currentIndex += 1 }
            }
        }
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private func navArrowButton(systemName: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        if isEnabled {
            Button(action: action) {
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(purpleGlow))
            }
        } else {
            Color.clear.frame(width: 36, height: 36)
        }
    }

    private func stepCard(index: Int) -> some View {
        VStack(spacing: 10) {
            Text("Step \(index + 1)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.black)

            Text(steps[index])
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
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
    }


    private var allStepsPopup: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    showAllSteps = false
                }

            VStack(spacing: 0) {
                HStack {
                    Text("All steps")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    Spacer()
                    Button {
                        showAllSteps = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.black)
                    }
                }
                .padding(20)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(steps.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(purpleGlow))

                                Text(steps[index])
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(index == currentIndex ? purpleGlow.opacity(0.15) : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
                            )
                            .onTapGesture {
                                currentIndex = index
                                showAllSteps = false
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(purpleGlow, lineWidth: 1.5)
            )
            .frame(maxWidth: 340, maxHeight: 420)
            .contentShape(Rectangle())
            .onTapGesture { } 
        }
        .transition(.opacity)
        .zIndex(1)
    }

    private var stepCounter: some View {
        Text("Step \(currentIndex + 1)/\(steps.count)")
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(purpleGlow)
            )
            .animation(.easeInOut(duration: 0.2), value: currentIndex)
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
}
