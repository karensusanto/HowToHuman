//
//  ResultScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 14/08/26.
//

import SwiftUI

struct ResultScreen: View {
    @EnvironmentObject var store: GameStore

    @State private var positions: [UUID: PlayerPosition] = [:]
    @State private var descended: Bool
    @State private var showPlayAgainPrompt: Bool

    // preview-only: seeding either skips the real descend/reveal animation timers, showing a stable end-state instead
    private let skipIntroAnimation: Bool

    init(previewDescended: Bool? = nil, previewShowPlayAgainPrompt: Bool? = nil) {
        _descended = State(initialValue: previewDescended ?? false)
        _showPlayAgainPrompt = State(initialValue: previewShowPlayAgainPrompt ?? false)
        skipIntroAnimation = previewDescended != nil || previewShowPlayAgainPrompt != nil
    }

    private enum Outcome {
        case visitAgain, wontVisit, tie
    }

    private var outcome: Outcome {
        guard let result = store.voteResult else { return .tie }
        if result > 0.5 { return .visitAgain }
        if result < 0.5 { return .wontVisit }
        return .tie
    }

    private var isHost: Bool {
        store.currRoom?.hostID == store.myPlayerData.id
    }

    private var headline: String {
        switch outcome {
        case .visitAgain: "The Aliens decided that they would visit Earth again!"
        case .wontVisit: "The Aliens decided that they won't visit Earth again."
        case .tie: "The Aliens couldn't come to a decision..."
        }
    }

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            earthGraphic

            VStack(spacing: 20) {
                HStack {
                    ExitRoomButton()
                    Spacer()
                }

                HTHText(title: headline, font: HTHFont.space_grot)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                alienCluster

                if !isHost {
                    HTHText(title: "Waiting for host to decide...", size: HTHSize.caption, font: HTHFont.space_grot)
                        .opacity(descended ? 1 : 0)
                }

                Spacer()
            }
            .padding()

            VStack {
                if isHost && showPlayAgainPrompt {
                    PopUpBuilder(
                        isPresented: $showPlayAgainPrompt,
                        title: "Play Again?",
                        subtitle: "",
                        leftBtnText: "Yes",
                        rightBtnText: "No",
                        leftBtnColor: HTHColor.green,
                        rightBtnColor: HTHColor.purple,
                        leftAction: { store.playAgain() }
                    ) {
                        showPlayAgainPrompt = false
                        store.showExitRoomPopUp = true
                    }
                }
            }.padding()

            VStack {
                if store.showExitRoomPopUp {
                    ExitRoomPopUp(isPresented: $store.showExitRoomPopUp)
                }
            }.padding()
        }
        .frame(maxWidth: .infinity)
        .background {
            HTHGameBackground()
        }
        .onAppear {
            store.playChime()
            guard !skipIntroAnimation else { return }
            withAnimation(.easeInOut(duration: 2.5)) {
                descended = true
            }
            Task {
                try? await Task.sleep(for: .seconds(3))
                store.vibrate()
                withAnimation { showPlayAgainPrompt = true }
            }
        }
    }
}

private extension ResultScreen {
    var earthGraphic: some View {
        VStack {
            Spacer()
            Image("earth")
                .resizable()
                .scaledToFit()
                .frame(width: 500)
                .offset(y: 250)
                .opacity(outcome == .wontVisit ? 0.6 : 1)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    var alienCluster: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(store.currRoom?.players ?? [], id: \.id) { player in
                    if let position = positions[player.id] {
                        AvatarLobbyView(player: player) {}
                            .scaleEffect(clusterScale)
                            .position(x: position.x, y: position.y + clusterYOffset)
                            .opacity(clusterOpacity)
                    }
                }
            }
            .onAppear {
                assignPositions(for: store.currRoom?.players ?? [], into: &positions, size: geo.size, radius: 60)
            }
        }
        .frame(height: 280)
        .animation(.easeInOut(duration: 2.5), value: descended)
    }

    // Yes: drift down and shrink onto Earth. No: drift up and shrink out into space. Tie: hold in place.
    var clusterYOffset: CGFloat {
        guard descended else { return 0 }
        switch outcome {
        case .visitAgain: return 140
        case .wontVisit: return -160
        case .tie: return 0
        }
    }

    var clusterScale: CGFloat {
        guard descended else { return 1 }
        switch outcome {
        case .visitAgain: return 0.5
        case .wontVisit: return 0.3
        case .tie: return 1
        }
    }

    var clusterOpacity: Double {
        guard descended, outcome == .wontVisit else { return 1 }
        return 0.15
    }
}

// MARK: - Previews
@MainActor
private func previewResultStore(voteResult: Float?, asHost: Bool) -> GameStore {
    let motionManager = MotionManager()
    let store = GameStore(motionManager: motionManager)

    let cho = Player(id: asHost ? store.networkManager.myPeerId : UUID(), name: "Cho", avatar: "spaceship-yellow")
    let karen = Player(id: asHost ? UUID() : store.networkManager.myPeerId, name: "Karen", avatar: "spaceship-blue")
    let baeni = Player(id: UUID(), name: "Baeni", avatar: "spaceship-pink")

    store.currRoom = Room(name: "Cho's Room", hostID: cho.id, players: [cho, karen, baeni])
    store.myPlayerData = asHost ? cho : karen
    store.playerGameDataList = [cho, karen, baeni].map { PlayerGameData(id: $0.id) }
    store.voteResult = voteResult

    return store
}

#Preview("Yes · Host") {
    let store = previewResultStore(voteResult: 1.0, asHost: true)
    ResultScreen(previewDescended: true, previewShowPlayAgainPrompt: true)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Yes · Listener") {
    let store = previewResultStore(voteResult: 1.0, asHost: false)
    ResultScreen(previewDescended: true, previewShowPlayAgainPrompt: false)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("No · Host") {
    let store = previewResultStore(voteResult: 0.0, asHost: true)
    ResultScreen(previewDescended: true, previewShowPlayAgainPrompt: true)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("No · Listener") {
    let store = previewResultStore(voteResult: 0.0, asHost: false)
    ResultScreen(previewDescended: true, previewShowPlayAgainPrompt: false)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Tie · Host") {
    let store = previewResultStore(voteResult: 0.5, asHost: true)
    ResultScreen(previewDescended: true, previewShowPlayAgainPrompt: true)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Tie · Listener") {
    let store = previewResultStore(voteResult: 0.5, asHost: false)
    ResultScreen(previewDescended: true, previewShowPlayAgainPrompt: false)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Just Arrived · Pre-descend") {
    let store = previewResultStore(voteResult: 1.0, asHost: true)
    ResultScreen(previewDescended: false, previewShowPlayAgainPrompt: false)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}
