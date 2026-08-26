//
//  AlienQuestionScreen.swift
//  HowToHuman
//
//  Created by Baeni on 14/8/26.
//

import SwiftUI
import Combine

struct AlienQuestionScreen: View {
    @EnvironmentObject var store: GameStore
    
    @State private var answerText: String = ""
    @FocusState private var isAnswerFocused: Bool
    @State private var timeRemaining: Int = 0
    @State private var readyMsgSubmitted: Bool = false
    
    private let maxCharacters = 30
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State var isReady: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
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
            
            VStack(spacing: 20){
                
                HStack {
                    ExitRoomButton()
                    Spacer()
                    HTHText(title: "Ask a Human", size: HTHSize.largeTitle, color: HTHColor.yellow)
                    Spacer()
                    timerBadge
                }
                
                ZStack(alignment: .top) {
                    Image(store.myPlayerData.avatar)
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
                    HTHText(title: "How do you", font: HTHFont.space_grot)
                        .foregroundColor(.white)
                    
                    Text("\(placeholderText)?")
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .overlay(
                    TextField("", text: $answerText)
                        .font(.custom(HTHFont.space_grot, size: HTHSize.body))
                        .focused($isAnswerFocused)
                        .opacity(0.02)
                        .focused($isTextFieldFocused)
                )
                .onChange(of: answerText) {
                    if answerText.count > maxCharacters {
                        answerText = String(answerText.prefix(maxCharacters))
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
                    if readyMsgSubmitted{
                        store.sendReadyStatus(false)
                        readyMsgSubmitted = false
                    }
                }
                
                HTHText(title: "Keep it simple, ask about things they'd probably do everyday.", size: HTHSize.caption, font: HTHFont.space_grot)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                
                if readyMsgSubmitted{
                    HTHText(title: "Waiting for other players...", size: HTHSize.caption, font: HTHFont.space_grot)
                }
                ReadyButton(readyMsgSubmitted: $readyMsgSubmitted, isReady: $isReady)
            }
            .padding()
            .onTapGesture {
                isTextFieldFocused = false
            }
            
            VStack{
                if store.showExitRoomPopUp{
                    ExitRoomPopUp(isPresented: $store.showExitRoomPopUp)
                }
            }.padding()
        }
        .frame(maxWidth: .infinity)
        .background {
            HTHGameBackground()
        }
        .onAppear{
            store.playChime()
            store.submittedQuestions = 0
            timeRemaining = (store.currRoom?.timerMode.seconds(for: .question)) ?? 0
        }
        .onDisappear{
            if answerText != "" {
                store.myGameData.question = answerText
            }
            store.submitGameData(data: store.myGameData)
            store.vibrate()
        }
        .onChange(of: answerText){
            isReady = !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if readyMsgSubmitted{
                store.sendReadyStatus(false)
                readyMsgSubmitted = false
            }
        }
        .onReceive(timer) { _ in
            guard timeRemaining > 0 else {
                if store.currRoom?.hostID == store.myPlayerData.id {
                    return store.next()
                }
                else{
                    store.state = store.state.next
                }
                return
            }
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
    let motionManager = MotionManager()
    let store = GameStore(
        motionManager: motionManager
    )
    AlienQuestionScreen()
    .environmentObject(store)
    .environmentObject(motionManager)
}
