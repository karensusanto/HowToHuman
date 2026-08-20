//
//  AlienQuestionScreen.swift
//  HowToHuman
//
//  Created by Baeni on 14/8/26.
//

import SwiftUI

struct AlienQuestionScreen: View {
    @EnvironmentObject var store: GameStore
    
    @State private var answerText: String = ""
    @FocusState private var isAnswerFocused: Bool
    
    private let maxCharacters = 30
    
    private var isReady: Bool {
         !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
     }
    
    private var placeholderText: String {
        let typedChars = Array(answerText)
        var result = ""
        for i in 0..<maxCharacters {
            if i < typedChars.count {
                result.append(typedChars[i])
            } else {
                result.append("_")
            }
        }
        return result
    }
    
    var body: some View {
        ZStack{
            Color.clear.ignoresSafeArea()
            
            VStack{
                
                    HTHText(title: "Ask a Human", size: HTHSize.extraLargeTitle, color: HTHColor.yellow)
                
                    ZStack(alignment: .top) {
                        Image("spaceship-purple")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 190, height: 120)
                            .padding(.top, 44)

                            SpeechBubbleDots()
                    }

                                  
                    HStack {
                        Spacer()
                        Text("\(answerText.count)/\(maxCharacters)")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    VStack {
                        Text("How do you ")
                            .foregroundColor(.white)
                        +
                        Text(placeholderText)
                            .foregroundColor(.white)
                        +
                        Text(" ?")
                            .foregroundColor(.white)
                    }
                    .font(.system(size: 17, weight: .medium))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .overlay(
                        
                    TextField("", text: $answerText)
                        .focused($isAnswerFocused)
                        .opacity(0.02))
                        .onChange(of: answerText) { newValue in
                            if newValue.count > maxCharacters {
                                answerText = String(newValue.prefix(maxCharacters))
                            }
                        }
                        .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black))
                            .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(HTHColor.purple, lineWidth: 2))
                            .shadow(color: HTHColor.purple.opacity(0.6), radius: 6)
                            .contentShape(Rectangle())
                            .onTapGesture {
                            isAnswerFocused = true
                            }
                            .padding(.horizontal)
                    
                    Text("Keep it simple, ask about things they'd probably do everyday.")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)

                    Spacer()
                
                PrimaryButton(title: "Ready", btnHeight: 56){
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
    }
}

struct SpeechBubbleDots: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color.black.opacity(0.75))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
            )

            Triangle()
                .fill(Color.white)
                .frame(width: 14, height: 8)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    AlienQuestionScreen().environmentObject(GameStore())
}
