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
        HTHText(title: currentGameData?.question ?? "No question", size: HTHSize.caption, font: HTHFont.space_grot, weight: .medium)
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
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                ForEach(Array((currentGameData?.answer ?? []).enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        HTHText(title: "\(index + 1).", font: HTHFont.space_grot, weight: .medium, color: .black)
                        HTHText(title: step, font: HTHFont.space_grot, color: .black)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    )
                }

                if currentGameData?.answer?.isEmpty ?? true {
                    HTHText(title: "The human did not respond", font: HTHFont.space_grot, color: .black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Image("human")
                .resizable()
                .scaledToFit()
                .frame(width: 130)
        }
    }

    var narrationStage: some View {
        VStack(spacing: 5) {
            VStack(alignment: .trailing, spacing: 8) {
                if isHost || transcriptRevealed {
                    HTHText(title: currentGameData?.experience ?? "No experience shared", font: HTHFont.space_grot, color: .black)
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
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white, lineWidth: 2)
                    .shadow(color: Color.white.opacity(0.8), radius: 10)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isHost else { return }
                withAnimation { transcriptRevealed.toggle() }
            }

            Triangle()
                .fill(Color.white)
                .frame(width: 18, height: 10)

            // TEMP placeholder until custom art for the alien-in-UFO graphic is provided
            Text("🛸")
                .font(.system(size: 90))
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
