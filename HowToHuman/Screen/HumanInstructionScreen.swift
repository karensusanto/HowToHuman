//
//  HumanInstructionScreen.swift
//  HowToHuman
//
//  Created by Baeni on 17/8/26.
//

import SwiftUI
import Combine

struct HumanInstructionScreen: View {

    let question: String
    @EnvironmentObject var store: GameStore

    @State private var steps: [String] = [""]
    @State private var timeRemaining: Int = 60

    private let maxSteps = 5
    private let yellowAccent = Color(red: 0.94, green: 0.76, blue: 0.29)
    private let purpleGlow = Color(red: 0.70, green: 0.60, blue: 0.90)

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var filledStepsCount: Int {
        steps.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    private var isReady: Bool {
        filledStepsCount > 0
    }

    private var canAddStep: Bool {
        steps.count < maxSteps
    }

    init(question: String = "How do you shower?") {
        self.question = question
    }

    var body: some View {
        ZStack {
            VStack {

                HStack {
                    Color.clear.frame(width: 40, height: 40)
                    Spacer()
                    HTHText(title: "Guide The Alien", size: HTHSize.largeTitle, color: HTHColor.yellow)
                    Spacer()
                    timerBadge
                }
                .padding(.horizontal, 20)

                questionPill
                    .padding(.horizontal, 40)
                    .padding(.top, 16)
                
                //Baeni need Human Image TT.TT
                Image("spaceship-blue")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130)
                    .padding()

                VStack(alignment: .trailing, spacing: 8) {
                    stepCounter

                    VStack(spacing: 12) {
                        ForEach(steps.indices, id: \.self) { index in
                            stepField(index: index)
                        }
                        if canAddStep {
                            addStepButton
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                PrimaryButton(title: "Ready", btnHeight: 56) {
                    store.joiningRoom = nil
                    store.state = .customizeAlien
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


    private var stepCounter: some View {
        Text("\(filledStepsCount)/\(maxSteps)")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
            .animation(.easeInOut(duration: 0.2), value: filledStepsCount)
    }

    private func stepField(index: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.black))

            TextField("Write the instructions here..", text: $steps[index], axis: .vertical)
                .font(.system(size: 16))
                .lineLimit(1...4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 56)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
        )
    }

    private var addStepButton: some View {
        Button {
            guard canAddStep else { return }
            steps.append("")
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                Text("add more steps..")
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .foregroundColor(.white.opacity(0.5))
            )
        }
    }
}

#Preview {
    HumanInstructionScreen()
        .environmentObject(GameStore()) .environmentObject(MotionManager())
}
