//
//  HumanInstructionScreen.swift
//  HowToHuman
//
//  Created by Baeni on 17/8/26.
//

import SwiftUI

struct HumanInstructionScreen: View {
    
    let question: String

    @State private var steps: [String] = [""]

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

    init(question: String = "How do you shower?") {
        self.question = question
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

                outlineTitle
                    .padding(.top, 20)

                questionPill
                    .padding(.horizontal, 40)
                    .padding(.top, 16)

                stepIllustration
                    .padding(.top, 70)

                VStack(spacing: 12) {
                    ForEach(steps.indices, id: \.self) { index in
                        stepField(index: index)
                    }
                    addStepButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)

                Spacer()

                Button {
                    // TODO: submit the steps
                } label: {
                    Text("READY")
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

    // MARK: - Status "You are the human"
    private var roleBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.white)
                .frame(width: 14, height: 14)
            Text("You are the human")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.black))
    }

    // MARK: - GUIDE THE HUMAN
    private var outlineTitle: some View {
        let text = "GUIDE THE HUMAN"
        let font: Font = .system(size: 28, weight: .heavy, design: .rounded)
        let strokeWidth: CGFloat = 1.6

        return ZStack {
            ForEach(Array(stride(from: 0.0, to: 360.0, by: 30.0)), id: \.self) { angle in
                Text(text)
                    .font(font)
                    .foregroundColor(.black)
                    .offset(
                        x: strokeWidth * cos(angle * .pi / 180),
                        y: strokeWidth * sin(angle * .pi / 180)
                    )
            }
            Text(text)
                .font(font)
                .foregroundColor(.white)
        }
    }

    // MARK: - Question pill
    private var questionPill: some View {
        Text(question)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.7)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.black, lineWidth: 2)
            )
    }

    // MARK: - Step text field
    private func stepField(index: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color(white: 0.9)))

            TextField("Describe this step...", text: $steps[index], axis: .vertical)
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
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.black, lineWidth: 1.5)
        )
    }

    // MARK: - Add Step Button
    private var addStepButton: some View {
        Button {
            steps.append("")
        } label: {
            Text("+ Add step")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                        .foregroundColor(.gray.opacity(0.5))
                )
        }
    }

    // MARK: - Placeholder illustration
    private var stepIllustration: some View {
        ZStack {
            Rectangle()
                .fill(Color(white: 0.85))
                .frame(width: 160, height: 110)
                .overlay(Rectangle().stroke(Color.black, lineWidth: 1.5))
            HStack{
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                    .overlay(Rectangle().stroke(Color.black, lineWidth: 1.5))
                    .offset(y: -30)
                    .padding(10)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                    .overlay(Rectangle().stroke(Color.black, lineWidth: 1.5))
                    .offset(y: -30)

            }
            Rectangle()
                .fill(Color(white: 0.85))
                .frame(width: 220, height: 70)
                .overlay(Rectangle().stroke(Color.black, lineWidth: 1.5))
                .rotationEffect(.degrees(-12))
                .offset(x: -10, y: -55)
        }
    }

    // MARK: - Animated black star background
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
    HumanInstructionScreen()
}
