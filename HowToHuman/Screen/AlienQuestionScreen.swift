//
//  AlienQuestionScreen.swift
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

    var body: some View {
        ZStack {
            
            Color.white
                .ignoresSafeArea()

            starField
                .ignoresSafeArea()

            VStack(spacing: 0) {

                HStack {
                    alienBadge
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)


                OutlineText(
                    text: "ASK HUMAN",
                    font: .system(size: 34, weight: .heavy, design: .rounded)
                )
                .padding(.top, 24)

                questionPill
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                alienCircle
                    .padding(.top, 24)

                TextField("Type something...", text: $answer, axis: .vertical)
                    .font(.system(size: 17))
                    .lineLimit(1...6)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(minHeight: 56)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 28)

                Spacer()

                Button {
          
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

    // MARK: - Alien Badge
    private var alienBadge: some View {
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
        .background(
            Capsule().fill(Color.black)
        )
    }

    // MARK: - Question Pill
    private var questionPill: some View {
        Text("How do you ____?")
            .font(.system(size: 24, weight: .heavy, design: .rounded))
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

    // MARK: - Alien Circle
    private var alienCircle: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 160, height: 160)
            Circle()
                .stroke(Color.black, lineWidth: 2)
                .frame(width: 160, height: 160)
            AlienFace()
                .frame(width: 90, height: 100)
        }
    }

    // MARK: - Stars Field
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

// MARK: - Outline text
private struct OutlineText: View {
    let text: String
    let font: Font
    var strokeColor: Color = .black
    var fillColor: Color = .white
    var strokeWidth: CGFloat = 1.6

    var body: some View {
        ZStack {
            ForEach(Array(stride(from: 0.0, to: 360.0, by: 30.0)), id: \.self) { angle in
                Text(text)
                    .font(font)
                    .foregroundColor(strokeColor)
                    .offset(
                        x: strokeWidth * cos(angle * .pi / 180),
                        y: strokeWidth * sin(angle * .pi / 180)
                    )
            }
            Text(text)
                .font(font)
                .foregroundColor(fillColor)
        }
    }
}

// MARK: - Alien Face
private struct AlienFace: View {
    var body: some View {
        ZStack {
            AlienHeadShape()
                .fill(Color(white: 0.85))
            AlienHeadShape()
                .stroke(Color.black, lineWidth: 2)

            HStack(spacing: 10) {
                eye
                eye
            }
            .offset(y: -8)
        }
    }

    private var eye: some View {
        Ellipse()
            .fill(Color.white)
            .overlay(Ellipse().stroke(Color.black, lineWidth: 1.5))
            .frame(width: 26, height: 18)
            .rotationEffect(.degrees(-10))
    }
}

private struct AlienHeadShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.5, y: h))
        path.addCurve(
            to: CGPoint(x: 0, y: h * 0.35),
            control1: CGPoint(x: w * 0.15, y: h * 0.85),
            control2: CGPoint(x: 0, y: h * 0.6)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control1: CGPoint(x: 0, y: h * 0.1),
            control2: CGPoint(x: w * 0.2, y: 0)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.35),
            control1: CGPoint(x: w * 0.8, y: 0),
            control2: CGPoint(x: w, y: h * 0.1)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: w, y: h * 0.6),
            control2: CGPoint(x: w * 0.85, y: h * 0.85)
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    AlienQuestionScreen().environmentObject(GameStore())
}
