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
    // gates the opacity fade-out (wontVisit) and the tap-to-continue reveal; cluster position/scale are
    // unconditional on outcome so matchedGeometryEffect can morph continuously from VotingScreen's layout
    @State private var descended: Bool
    // debounce only - tapping sends the whole room back immediately, there's no one else to wait on
    @State private var hasTapped: Bool

    // shared with VotingScreen (via RootView) so the alien cluster morphs continuously across the screen switch instead of cutting
    var alienNamespace: Namespace.ID?

    // preview-only: seeding skips the real reveal-timer animation, showing a stable end-state instead
    private let skipIntroAnimation: Bool

    private let purpleGlow = Color(red: 0.70, green: 0.60, blue: 0.90)

    init(alienNamespace: Namespace.ID? = nil, previewDescended: Bool? = nil, previewHasTapped: Bool? = nil) {
        self.alienNamespace = alienNamespace
        _descended = State(initialValue: previewDescended ?? false)
        _hasTapped = State(initialValue: previewHasTapped ?? false)
        skipIntroAnimation = previewDescended != nil
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
                .contentShape(Rectangle())
                .onTapGesture {
                    guard descended, !hasTapped, !store.showExitRoomPopUp else { return }
                    store.requestReturnToLobby()
                    hasTapped = true
                }

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

                Spacer()

                if descended {
                    HTHText(
                        title: "Tap anywhere to go back to the lobby",
                        size: HTHSize.caption,
                        font: HTHFont.space_grot
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule().fill(Color.black.opacity(0.6))
                    )
                    .overlay(
                        Capsule()
                            .stroke(purpleGlow, lineWidth: 1.5)
                            .shadow(color: purpleGlow.opacity(0.6), radius: 6)
                    )
                }
            }
            .padding()

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
        }
    }
}

private extension ResultScreen {
    var earthGraphic: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                Image("earth")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 1.3)
                    .offset(y: 250)
                    .opacity(outcome == .wontVisit ? 0.6 : 1)
            }
            .frame(width: geo.size.width)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    var alienCluster: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(store.currRoom?.inGamePlayers ?? [], id: \.id) { player in
                    if let position = positions[player.id] {
                        avatarView(for: player)
                            .scaleEffect(clusterScale)
                            .position(x: position.x, y: position.y + clusterYOffset)
                            .opacity(clusterOpacity)
                    }
                }
            }
            .onAppear {
                assignPositions(for: store.currRoom?.inGamePlayers ?? [], into: &positions, size: geo.size, radius: 60)
            }
        }
        .frame(height: 280)
        // decoupled from RootView's ambient 0.35s screen-switch crossfade, so the geometry morph gets a slower,
        // deliberate duration instead of a snappy blip
        .animation(.easeInOut(duration: 2.5), value: store.state)
    }

    @ViewBuilder
    func avatarView(for player: Player) -> some View {
        // inGame here means "playing a different ongoing round" (LobbyScreen's grayed-out treatment) -
        // never true for players shown mid-round on this screen
        if let alienNamespace {
            AvatarLobbyView(player: player, inGame: false) {}
                .matchedGeometryEffect(id: player.id, in: alienNamespace)
        } else {
            AvatarLobbyView(player: player, inGame: false) {}
        }
    }

    // Yes: onto Earth. No: out into space. Tie: hold in place. Unconditional on outcome (not time-gated) so
    // matchedGeometryEffect can morph continuously straight from VotingScreen's large centered layout into this one.
    var clusterYOffset: CGFloat {
        switch outcome {
        case .visitAgain: 140
        case .wontVisit: -160
        case .tie: 0
        }
    }

    var clusterScale: CGFloat {
        switch outcome {
        case .visitAgain: 0.5
        case .wontVisit: 0.3
        case .tie: 1
        }
    }

    var clusterOpacity: Double {
        guard descended, outcome == .wontVisit else { return 1 }
        return 0.15
    }
}

// MARK: - Previews
@MainActor
private func previewResultStore(voteResult: Float?) -> GameStore {
    let motionManager = MotionManager()
    let store = GameStore(motionManager: motionManager)

    let cho = Player(id: store.networkManager.myPeerId, name: "Cho", avatar: "spaceship-yellow")
    let karen = Player(id: UUID(), name: "Karen", avatar: "spaceship-blue")
    let baeni = Player(id: UUID(), name: "Baeni", avatar: "spaceship-pink")

    store.currRoom = Room(name: "Cho's Room", hostID: cho.id, joinedPlayers: [cho, karen, baeni])
    store.currRoom?.inGamePlayers = [cho, karen, baeni]
    store.myPlayerData = cho
    store.playerGameDataList = [cho, karen, baeni].map { PlayerGameData(id: $0.id) }
    store.voteResult = voteResult

    return store
}

#Preview("Live · Watch It Animate (Yes)") {
    let store = previewResultStore(voteResult: 1.0)
    ResultScreen() // no preview overrides: runs the real onAppear animation, needs Xcode's Live Preview to actually play
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Yes · Tap to Continue") {
    let store = previewResultStore(voteResult: 1.0)
    ResultScreen(previewDescended: true)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("No · Tap to Continue") {
    let store = previewResultStore(voteResult: 0.0)
    ResultScreen(previewDescended: true)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Tie · Tap to Continue") {
    let store = previewResultStore(voteResult: 0.5)
    ResultScreen(previewDescended: true)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Just Arrived · Pre-descend") {
    let store = previewResultStore(voteResult: 1.0)
    ResultScreen(previewDescended: false)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}
