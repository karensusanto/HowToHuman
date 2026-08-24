//
//  ResultScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 14/08/26.
//

import SwiftUI

struct ResultScreen: View {
    @EnvironmentObject var store: GameStore

    // gates the opacity fade-out (slime/leave) and the tap-to-continue reveal
    @State private var descended: Bool
    // debounce only - tapping sends the whole room back immediately, there's no one else to wait on
    @State private var hasTapped: Bool

    // preview-only: seeding skips the real reveal-timer animation, showing a stable end-state instead
    private let skipIntroAnimation: Bool

    private let purpleGlow = Color(red: 0.70, green: 0.60, blue: 0.90)

    init(previewDescended: Bool? = nil, previewHasTapped: Bool? = nil) {
        _descended = State(initialValue: previewDescended ?? false)
        _hasTapped = State(initialValue: previewHasTapped ?? false)
        skipIntroAnimation = previewDescended != nil
    }

    // TEMP: placeholder motion per tier until the real videos are wired in and these get replaced
    // by hand-authored keyframes matching each video's choreography
    private enum Outcome {
        case slime  // 0-33% yes: aliens hate Earth, cover it in slime
        case leave  // 34-66% yes: aliens just leave
        case visit  // 67-100% yes: aliens go down to Earth
    }

    // percentage of yes votes, rounded up, bucketed into thirds
    private var outcome: Outcome {
        let percentage = Int(((store.voteResult ?? 0.5) * 100).rounded(.up))
        switch percentage {
        case ...33: return .slime
        case 34...66: return .leave
        default: return .visit
        }
    }

    private var headline: String {
        switch outcome {
        case .slime: "The Aliens hated Earth so much, they covered it in slime!"
        case .leave: "The Aliens decided to just leave..."
        case .visit: "The Aliens decided that they would visit Earth again!"
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
                    .opacity(outcome == .leave ? 0.6 : 1)
            }
            .frame(width: geo.size.width)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    var alienCluster: some View {
        GeometryReader { geo in
            let players = store.currRoom?.inGamePlayers ?? []
            ZStack {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    // same formula VotingScreen uses, so a player's starting position here lines up
                    // exactly with where they were on the vote screen - see clusterPosition's doc comment
                    let base = clusterPosition(index: index, count: players.count, size: geo.size)
                    // inGame here means "playing a different ongoing round" (LobbyScreen's grayed-out
                    // treatment) - never true for players shown mid-round on this screen
                    AvatarLobbyView(player: player, inGame: false) {}
                        .scaleEffect(clusterScale)
                        .position(x: base.x, y: base.y + clusterYOffset)
                        .opacity(clusterOpacity)
                }
            }
        }
        .frame(height: 280)
        .animation(.easeInOut(duration: 2.5), value: descended)
    }

    // TEMP placeholder motion - onto Earth (visit), out into space fading (leave), or down but
    // holding tighter to Earth for now (slime). Real per-tier choreography lands once the actual
    // videos are wired in and this becomes hand-authored keyframes matching each video's timing.
    var clusterYOffset: CGFloat {
        guard descended else { return 0 }
        switch outcome {
        case .visit: return 140
        case .leave: return -160
        case .slime: return 100
        }
    }

    var clusterScale: CGFloat {
        guard descended else { return 1 }
        switch outcome {
        case .visit: return 0.5
        case .leave: return 0.3
        case .slime: return 0.6
        }
    }

    var clusterOpacity: Double {
        guard descended, outcome == .leave else { return 1 }
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

#Preview("Live · Watch It Animate (Visit)") {
    let store = previewResultStore(voteResult: 0.9)
    ResultScreen() // no preview overrides: runs the real onAppear animation, needs Xcode's Live Preview to actually play
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Visit (90%) · Tap to Continue") {
    let store = previewResultStore(voteResult: 0.9)
    ResultScreen(previewDescended: true)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Leave (50%) · Tap to Continue") {
    let store = previewResultStore(voteResult: 0.5)
    ResultScreen(previewDescended: true)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Slime (10%) · Tap to Continue") {
    let store = previewResultStore(voteResult: 0.1)
    ResultScreen(previewDescended: true)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Just Arrived · Pre-descend") {
    let store = previewResultStore(voteResult: 0.9)
    ResultScreen(previewDescended: false)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("6 Players · All Slots Fill") {
    let store = previewResultStore(voteResult: 0.9)
    let names = ["Cho", "Karen", "Baeni", "Satria", "Wais", "Barra"]
    let avatars = AlienAvatar.allCases
    let players = (0..<6).map { index in
        Player(id: UUID(), name: names[index], avatar: avatars[index % avatars.count])
    }
    store.currRoom?.joinedPlayers = players
    store.currRoom?.inGamePlayers = players
    return ResultScreen(previewDescended: true)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}
