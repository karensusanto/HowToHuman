//
//  AlienNarrationScreen.swift
//  HowToHuman
//
//  Created by Baeni on 17/8/26.
//

import SwiftUI
import Combine

struct AlienNarrationScreen: View {
    @State private var steps: [String]?

    @EnvironmentObject var store: GameStore

    @State private var currentIndex: Int = 0
    @State var narrations: String = ""
    @State private var timeRemaining: Int = 0
    @State private var readyMsgSubmitted: Bool = false

    private let purpleGlow = Color(red: 0.70, green: 0.60, blue: 0.90)

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State var isReady: Bool = false
    
    @State private var narrationsLen : Int = 0
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    ExitRoomButton()
                    Spacer()
                    HTHText(title: "Tell Your Experience", size: HTHSize.title, color: HTHColor.yellow)
                        .multilineTextAlignment(.center)
                    Spacer()
                    timerBadge
                }

                questionPill

                stepCarousel

                VStack{
                    narrationField
                        .focused($isTextFieldFocused)
                    
                    HTHText(title: "\(narrationsLen)/700", size: HTHSize.caption, color: Color.gray)
                }

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
            steps = store.myGameData.answer
            timeRemaining = (store.currRoom?.timerMode.seconds(for: .question)) ?? 0
        }
        .onDisappear{
            if narrations != "" {
                store.myGameData.experience = narrations
            }
            store.submitGameData(data: store.myGameData)
            store.vibrate()
        }
        .onChange(of: narrations){
            isReady = !narrations.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
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

    private var questionPill: some View {
        
        HTHText(title: LocalizedStringKey(store.myGameData.question ?? "No question"), size: HTHSize.caption, font: HTHFont.space_grot, weight: .medium)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.7)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(purpleGlow, lineWidth: 1.5)
                    .shadow(color: purpleGlow.opacity(0.6), radius: 6)
            )
    }

    private var stepCarousel: some View {
        HStack(spacing: 4) {
            if steps != nil {
            
                navArrowButton(systemName: "chevron.left", isEnabled: currentIndex > 0) {
                    withAnimation { currentIndex -= 1 }
                }
                
                
                TabView(selection: $currentIndex) {
                    ForEach(steps!.indices, id: \.self) { index in
                        stepCard(index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 150)
                
                
                
                navArrowButton(systemName: "chevron.right", isEnabled: currentIndex < steps!.count - 1) {
                    withAnimation { currentIndex += 1 }
                }
                
            }
            else{
                HTHText(title: "The human did not respond", font: HTHFont.space_grot, color: .black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
            }
        }
    }

    @ViewBuilder
    private func navArrowButton(systemName: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(purpleGlow)
                .frame(width: 28, height: 28)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.3)
    }
    
    private func stepCard(index: Int) -> some View {
        VStack(alignment: .center, spacing: 5) {
    
            HTHText(title: LocalizedStringKey(steps![index]), font: HTHFont.space_grot, color: .black)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            HTHText(title: "Step \(currentIndex + 1)/\(steps!.count)", size: HTHSize.caption, font: HTHFont.space_grot, weight: .medium, color: .black.opacity(0.5))
                .animation(.easeInOut(duration: 0.2), value: currentIndex)
            
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }


    private var narrationField: some View {
        ZStack(alignment: .topLeading) {
            if narrations == "" {
                HTHText(title: "Describe what happened...", font: HTHFont.space_grot, color: .white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }

            TextField("", text: $narrations, axis: .vertical)
            .foregroundStyle(.white)
            .font(.custom(HTHFont.space_grot, size: 16))
            .lineLimit(3...6)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .onChange(of: narrations) { _, newValue in
                if newValue.count > 700 {
                    narrations = String(newValue.prefix(700))
                }
                narrationsLen = narrations.count
            }
        }
        .frame(minHeight: 90, alignment: .topLeading)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(purpleGlow, lineWidth: 1.5)
                .shadow(color: purpleGlow.opacity(0.6), radius: 6)
        )
    }

//    private var narrationBinding: Binding<String> {
//        Binding(
//            get: {
//                narrations.indices.contains(currentIndex) ? narrations[currentIndex] : ""
//            },
//            set: { newValue in
//                if narrations.indices.contains(currentIndex) {
//                    narrations[currentIndex] = newValue
//                }
//            }
//        )
//    }
}

#Preview {
    let motionManager = MotionManager()
    let store = GameStore(
        motionManager: motionManager
    )
    AlienNarrationScreen()
    .environmentObject(store)
    .environmentObject(motionManager)
}
