//
//  DisplayScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 14/08/26.
//

import SwiftUI

struct DisplayScreen: View {
    @EnvironmentObject var store: GameStore

    @State private var transcriptRevealed: Bool
    // local-only: lets anyone swipe back to re-check the steps after the narration's revealed,
    // without touching store.experienceRevealed (that stays host-controlled/synced)
    @State private var showingStepsPeek: Bool = false

    // previewTranscriptRevealed exists only so #Preview can seed the listener's local reveal toggle
    init(previewTranscriptRevealed: Bool = false) {
        _transcriptRevealed = State(initialValue: previewTranscriptRevealed)
    }

    private let purpleGlow = Color(red: 0.70, green: 0.60, blue: 0.90)

    private var isHost: Bool {
        store.currRoom?.hostID == store.myPlayerData.id
    }

    private var currentGameData: PlayerGameData? {
        guard store.playerGameDataList.indices.contains(store.currentExperienceIndex) else { return nil }
        return store.playerGameDataList[store.currentExperienceIndex]
    }

    private var currentPlayerName: String {
        guard let data = currentGameData,
              let player = store.currRoom?.inGamePlayers.first(where: { $0.id == data.id }) else {
            return "A Fellow Alien"
        }
        return player.name
    }
    
    private let human = HumanAvatar.allCases.randomElement() ?? "human-girl"

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    ExitRoomButton()
                    Spacer()
                }

                HTHText(title: "\(currentPlayerName)'s Experience", size: HTHSize.largeTitle, color: HTHColor.yellow)
                    .multilineTextAlignment(.center)

                questionPill

                stage

                pageIndicator

                Spacer()

                if store.experienceRevealed {
                    reactionRow
                }

                footer
            }
            .padding()

            VStack {
                if store.showExitRoomPopUp {
                    ExitRoomPopUp(isPresented: $store.showExitRoomPopUp)
                }
            }.padding()

            reactionBubbleOverlay
        }
        .frame(maxWidth: .infinity)
        .background {
            HTHGameBackground()
        }
        .onAppear {
            store.playChime()
        }
        .onChange(of: store.currentExperienceIndex) {
            transcriptRevealed = false
            showingStepsPeek = false
            store.playChime()
        }
        .onChange(of: store.experienceRevealed) {
            store.vibrate()
        }
    }
}

// MARK: - Sections
private extension DisplayScreen {
    var questionPill: some View {
        HTHText(title: LocalizedStringKey(currentGameData?.question ?? "No question"), size: HTHSize.caption, font: HTHFont.space_grot, weight: .medium)
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

    var stage: some View {
        ZStack {
            if !store.experienceRevealed || showingStepsPeek {
                stepsStage
                    .transition(.move(edge: .leading).combined(with: .opacity))
            } else {
                narrationStage
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.8), value: store.experienceRevealed)
        .animation(.spring(response: 0.55, dampingFraction: 0.8), value: showingStepsPeek)
        .gesture(
            // once revealed, anyone can swipe to peek back at the steps and back again;
            // the actual reveal itself stays host-only via the Continue/Next Experience buttons
            DragGesture(minimumDistance: 20).onEnded { value in
                guard store.experienceRevealed else { return }
                showingStepsPeek = value.translation.width > 0
            }
        )
    }

    var stepsStage: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array((currentGameData?.answer ?? []).enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        HTHText(title: "\(index + 1).", font: HTHFont.space_grot, weight: .medium, color: .black)
                        HTHText(title: LocalizedStringKey(step), font: HTHFont.space_grot, color: .black)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if currentGameData?.answer?.isEmpty ?? true {
                    HTHText(title: "The human did not respond", font: HTHFont.space_grot, color: .black)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(20)
            .padding(.bottom, 10) // extra room so text doesn't crowd the tail wedge baked into the shape below
            .frame(maxWidth: .infinity)
            .speechBubbleStyle(purpleGlow)

            Image(human)
                .resizable()
                .scaledToFit()
                .frame(width: 130)
                .padding()
        }
    }

    var narrationStage: some View {
        VStack(spacing: 0) {
            VStack(alignment: .trailing, spacing: 8) {
                if isHost || transcriptRevealed {
                    HTHText(title: LocalizedStringKey(currentGameData?.experience ?? "No experience shared"), font: HTHFont.space_grot, color: .black)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HTHText(title: "Listen to your friends' experience.", font: HTHFont.space_grot, weight: .medium, color: .black)
                        .multilineTextAlignment(.center)
                }

                HTHText(
                    title: isHost ? "[Read it out loud]" : (transcriptRevealed ? "[tap to hide transcript]" : "[tap to reveal transcript]"),
                    size: HTHSize.caption,
                    font: HTHFont.space_grot,
                    color: .black.opacity(0.6)
                )
            }
            .padding(20)
            .padding(.bottom, 10) // extra room so text doesn't crowd the tail wedge baked into the shape below
            .frame(maxWidth: .infinity)
            .speechBubbleStyle(purpleGlow)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isHost else { return }
                withAnimation { transcriptRevealed.toggle() }
            }

            // TEMP placeholder until custom art for the alien-in-UFO graphic is provided
            Image("spaceship-purple")
                .resizable()                        // 1. Allows the image to stretch/shrink
                .scaledToFit()                      // 2. Scales proportionally to fit the container
                .frame(width: 200, height: 200)

        }
    }
    
    var pageIndicator: some View {
        HStack(spacing: 6) {
            Circle().frame(width: 7, height: 7)
                .foregroundStyle(showingStepsPeek ? Color.white : Color.white.opacity(0.4))
            Circle().frame(width: 7, height: 7)
                .foregroundStyle(store.experienceRevealed && !showingStepsPeek ? Color.white : Color.white.opacity(0.4))
        }
        .opacity(store.experienceRevealed ? 1 : 0)
    }

    var reactionRow: some View {
        HStack(spacing: 24) {
            reactionButton("LOLAlienEmoji")
            reactionButton("LoveAlienEmoji")
            reactionButton("WowAlienEmoji")
            reactionButton("MadAlienEmoji")
        }
    }

    var reactionBubbleOverlay: some View {
        ZStack {
            ForEach(store.bubbles) { bubble in
                Image(bubble.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .offset(x: bubble.x, y: bubble.y)
                    .opacity(bubble.opacity)
                    .scaleEffect(bubble.scale)
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 90)
        .allowsHitTesting(false)
    }

    func reactionButton(_ assetName: String) -> some View {
        Button {
            createBubble(assetName: assetName, store: store)
        } label: {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
        }
    }

    @ViewBuilder
    var footer: some View {
        if !store.experienceRevealed {
            if isHost {
                PrimaryButton(title: "Continue") {
                    store.revealExperience()
                }
            } else {
                HTHText(title: "Wait for host to continue", font: HTHFont.space_grot)
            }
        } else {
            if isHost {
                PrimaryButton(title: store.currentExperienceIndex >= store.playerGameDataList.count - 1 ? "Finish" : "Next Experience") {
                    store.advanceExperience()
                }
            } else {
                HTHText(title: "Wait for host to continue", font: HTHFont.space_grot)
            }
        }
    }
}

// A rounded rect with a downward-pointing tail carved directly into the bottom edge, traced as
// one continuous outline - so a stroke/shadow applied to it wraps the body and tail seamlessly,
// unlike a separate RoundedRectangle + Triangle pair (which can show a gap or a mismatched border
// where the two shapes meet).
struct SpeechBubbleShape: Shape {
    var cornerRadius: CGFloat = 16
    var tailWidth: CGFloat = 22
    var tailHeight: CGFloat = 14
    // fraction of the width where the tail is centered
    var tailPosition: CGFloat = 0.5

    func path(in rect: CGRect) -> Path {
        let r = min(cornerRadius, min(rect.width, rect.height - tailHeight) / 2)
        let bodyMaxY = rect.maxY - tailHeight
        let tailCenterX = rect.minX + rect.width * tailPosition
        let tailLeftX = max(rect.minX + r, tailCenterX - tailWidth / 2)
        let tailRightX = min(rect.maxX - r, tailCenterX + tailWidth / 2)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: bodyMaxY - r))
        path.addArc(center: CGPoint(x: rect.maxX - r, y: bodyMaxY - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: tailRightX, y: bodyMaxY))
        path.addLine(to: CGPoint(x: tailCenterX, y: rect.maxY))
        path.addLine(to: CGPoint(x: tailLeftX, y: bodyMaxY))
        path.addLine(to: CGPoint(x: rect.minX + r, y: bodyMaxY))
        path.addArc(center: CGPoint(x: rect.minX + r, y: bodyMaxY - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}

private struct SpeechBubbleStyle: ViewModifier {
    let glow: Color

    func body(content: Content) -> some View {
        content
            .background(SpeechBubbleShape().fill(Color.white))
            .overlay(
                SpeechBubbleShape()
                    .stroke(glow, lineWidth: 2.5)
                    // stacked shadows (tight + wide) read as a punchier glow than one alone
                    .shadow(color: glow.opacity(0.9), radius: 8)
                    .shadow(color: glow.opacity(0.6), radius: 22)
            )
    }
}

private extension View {
    func speechBubbleStyle(_ glow: Color) -> some View {
        modifier(SpeechBubbleStyle(glow: glow))
    }
}

// MARK: - Previews
@MainActor
private func previewStore(asHost: Bool, showingLastExperience: Bool = false) -> GameStore {
    let motionManager = MotionManager()
    let store = GameStore(motionManager: motionManager)

    // "self" must share networkManager.myPeerId, same as the real GameStore.init does,
    // or identity checks like sendReaction's host/participant branch pick the wrong path.
    let cho = Player(id: asHost ? store.networkManager.myPeerId : UUID(), name: "Cho", avatar: "spaceship-yellow")
    let karen = Player(id: asHost ? UUID() : store.networkManager.myPeerId, name: "Karen", avatar: "spaceship-blue")

    var room = Room(name: "Cho's Room", hostID: cho.id, joinedPlayers: [cho, karen])
    room.isPlaying = true
    room.inGamePlayers = [cho, karen]
    store.currRoom = room

    store.playerGameDataList = [
        PlayerGameData(
            id: cho.id,
            question: "How do you clean up after a dump?",
            answer: [
                "Usually there will be a roll of tissue in the bathroom",
                "Tissue is a white thin paper usually rolled up to a tube, take some part of it",
                "Use the parts of the tissue that you took and wipe them against your butt"
            ],
            experience: "I had a hard time trying to find the roll of tissue, but I found a white paper like thingy behind a thing that is being fixed onto the wall so I used that instead."
        ),
        PlayerGameData(
            id: karen.id,
            question: "How do you greet a stranger?",
            answer: ["Smile", "Say \"hello\"", "Offer a handshake"],
            experience: "I bared all my teeth and grabbed their hand very firmly. They screamed."
        )
    ]

    store.myPlayerData = asHost ? cho : karen
    store.currentExperienceIndex = showingLastExperience ? store.playerGameDataList.count - 1 : 0

    return store
}

#Preview("Phase 4-1 · Steps (Host)") {
    let store = previewStore(asHost: true)
    DisplayScreen()
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Phase 4-1 · Steps (Waiting for host)") {
    let store = previewStore(asHost: false)
    DisplayScreen()
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Phase 4-2 · Reader (Host)") {
    let store = previewStore(asHost: true)
    store.experienceRevealed = true
    return DisplayScreen()
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Phase 4-2 · Listener (Hidden)") {
    let store = previewStore(asHost: false)
    store.experienceRevealed = true
    return DisplayScreen()
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Phase 4-2 · Listener (Shown)") {
    let store = previewStore(asHost: false)
    store.experienceRevealed = true
    return DisplayScreen(previewTranscriptRevealed: true)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Phase 4-2 · Reader, last experience") {
    let store = previewStore(asHost: true, showingLastExperience: true)
    store.experienceRevealed = true
    return DisplayScreen()
        .environmentObject(store)
        .environmentObject(store.motionManager)
}
