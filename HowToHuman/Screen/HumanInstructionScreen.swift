//
//  HumanInstructionScreen.swift
//  HowToHuman
//
//  Created by Baeni on 17/8/26.
//

import SwiftUI
import Combine

struct HumanInstructionScreen: View {

    @EnvironmentObject var store: GameStore

    @State private var steps: [String] = []
    @State private var timeRemaining: Int = 0

    private let maxSteps = 5
    private let yellowAccent = Color(red: 0.94, green: 0.76, blue: 0.29)
    private let purpleGlow = Color(red: 0.70, green: 0.60, blue: 0.90)

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var filledStepsCount: Int {
        steps.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    @State var isReady: Bool = false

    private var canAddStep: Bool {
        steps.count < maxSteps
    }
    
    @State private var readyMsgSubmitted: Bool = false

    @State private var assignmentList: [UUID: UUID] = [:]
    @State private var listHeight: CGFloat = 0
    private let human = HumanAvatar.allCases.randomElement() ?? "human-girl"
    
    var body: some View {
        ZStack {
            VStack {

                HStack {
                    ExitRoomButton()
                    Spacer()
                    HTHText(title: "Guide The Alien", size: HTHSize.largeTitle, color: HTHColor.yellow)
                    Spacer()
                    timerBadge
                }

                questionPill
                
                Image(human)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130)
                    .padding()

                VStack(alignment: .trailing, spacing: 8) {
                    stepCounter
                    VStack(spacing: 12) {
                        ForEach(steps.indices, id: \.self) { index in
                            HStack{
                                stepField(index: index)
                                Button{
                                    deleteStep(index)
                                }label:{
                                    Image(systemName: "trash")
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        .onTapGesture {
                            if readyMsgSubmitted{
                                store.sendReadyStatus(false)
                                readyMsgSubmitted = false
                            }
                        }
                        
                        if canAddStep {
                            addStepButton
                                .onTapGesture {
                                    if readyMsgSubmitted{
                                        store.sendReadyStatus(false)
                                        readyMsgSubmitted = false
                                    }
                                }
                                .listRowBackground(Color.clear)
                        }
                            
                    }
                    
                }

                Spacer()
                if readyMsgSubmitted{
                    HTHText(title: "Waiting for other players...", size: HTHSize.caption, font: HTHFont.space_grot)
                }
                ReadyButton(readyMsgSubmitted: $readyMsgSubmitted, isReady: $isReady)
            }
            .padding()
            
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
            timeRemaining = (store.currRoom?.timerMode.seconds(for: .steps)) ?? 0
        }
        .onDisappear{
            let validSteps = steps.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty}
            
            if var receivedGameData = store.receivedGameData{
                if validSteps.count > 0{
                    receivedGameData.answer = validSteps
                }
                
                store.submitGameData(data: receivedGameData)
            }
            store.vibrate()
        }
        .onChange(of: filledStepsCount){
            isReady = filledStepsCount > 0
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
        HTHText(title: store.receivedGameData?.question ?? "No question", font: HTHFont.space_grot, weight: .medium)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.7)
            .lineLimit(3)
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


    private var stepCounter: some View {
        Text("\(steps.count)/\(maxSteps)")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
            .animation(.easeInOut(duration: 0.2), value: filledStepsCount)
    }

    private func stepField(index: Int) -> some View {
        HStack(spacing: 12) {
            HTHText(title: "\(index + 1)", font: HTHFont.space_grot, weight: .medium)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.black))

            ZStack(alignment: .topLeading) {
                if steps[index] == "" {
                    HTHText(title: "Write the instructions here...", font: HTHFont.space_grot, color: .black.opacity(0.5))
                }

                TextField("", text: $steps[index], axis: .vertical)
                    .font(.custom(HTHFont.space_grot, size: 16))
                    .foregroundStyle(.black)
                    .lineLimit(1...4)
            }
                
            
            
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 56)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
        )
    }
    
    private func deleteStep(_ index: Int){
        steps.remove(at: index)
    }

    private var addStepButton: some View {
        Button {
            guard canAddStep else { return }
            steps.append("")
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                Text("add step")
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
    let motionManager = MotionManager()
    let store = GameStore(
        motionManager: motionManager
    )
    HumanInstructionScreen()
    .environmentObject(store)
    .environmentObject(motionManager)
}
