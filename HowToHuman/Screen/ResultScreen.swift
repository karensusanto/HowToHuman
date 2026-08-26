//
//  ResultScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 14/08/26.
//

import SwiftUI
import AVFoundation

struct ResultScreen: View {
    @EnvironmentObject var store: GameStore

    @State private var player: AVPlayer?
    // gates the tap-to-continue reveal - true once the result video plays through to the end
    @State private var videoFinished: Bool
    // debounce only - tapping sends the whole room back immediately, there's no one else to wait on
    @State private var hasTapped: Bool
    // flips false->true on appear; KeyframeAnimator's trigger needs an actual value change to
    // guarantee it fires, rather than relying on "plays automatically on appear" alone
    @State private var flightStarted = false

    // preview-only: skips starting real video playback/observers, showing a stable end-state instead
    private let skipIntroAnimation: Bool

    private let purpleGlow = Color(red: 0.70, green: 0.60, blue: 0.90)

    init(previewVideoFinished: Bool? = nil, previewHasTapped: Bool? = nil) {
        _videoFinished = State(initialValue: previewVideoFinished ?? false)
        _hasTapped = State(initialValue: previewHasTapped ?? false)
        skipIntroAnimation = previewVideoFinished != nil
    }

    // TEMP: flight paths below are a first-pass placeholder tuned by eye against exported video
    // frames, not measured live against the running video - expect to nudge the destination
    // offsets once this is actually seen playing on device.
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

    private var videoResourceName: String {
        switch outcome {
        case .slime: "result-slime"
        case .leave: "result-leave"
        case .visit: "result-visit"
        }
    }

    private var headline: String {
        switch outcome {
        case .slime: "The Aliens hated Earth so much, they covered it in slime!"
        case .leave: "The Aliens decided to just leave..."
        case .visit: "The Aliens decided that they would visit Earth again!"
        }
    }

    // where each UFO ends up relative to its VotingScreen starting position, and how it looks once there.
    // The cluster now starts high on screen, above where the video's Earth settles - visit descends
    // onto it, leave/slime both flee further up into space (slime doesn't linger after souring on Earth).
    private var flightDestination: (dx: CGFloat, dy: CGFloat, scale: CGFloat, opacity: Double) {
        switch outcome {
        case .visit: (0, 260, 0.45, 0.95)  // descend down onto Earth, stay mostly visible
        case .leave: (0, -220, 0.3, 0.1)   // flee further up into space, fade almost away
        case .slime: (0, -220, 0.35, 0.2)  // same - flee upward after souring on Earth
        }
    }

    var body: some View {
        ZStack {
            if let player {
                VideoBackground(player: player)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    guard videoFinished, !hasTapped, !store.showExitRoomPopUp else { return }
                    store.requestReturnToLobby()
                    hasTapped = true
                }

            VStack(spacing: 20) {
                HStack {
                    ExitRoomButton()
                    Spacer()
                }

                HTHText(title: LocalizedStringKey(headline), font: HTHFont.space_grot)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // no Spacer here on purpose: matches VotingScreen's layout (cluster right after the
                // header, no spacer before it) so the starting position sits high on screen, above
                // where the video's Earth settles, and lines up with where the player saw it on vote
                alienCluster

                Spacer()

                if videoFinished {
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
        .onAppear {
            store.playChime()
            let players = store.currRoom?.inGamePlayers ?? []
            print("ResultScreen appeared - inGamePlayers:", players.map { "\($0.name)/\($0.avatar)/\($0.id)" }, "myPeerId:", store.networkManager.myPeerId, "hostID:", store.currRoom?.hostID as Any)
            guard !skipIntroAnimation else { return }
            startVideo()
            flightStarted = true
            store.initAudioPlayer(sound: "(ONBOARDING)")
        }
        .onDisappear {
            player?.pause()
            store.playSong()
        }
    }
}

private extension ResultScreen {
    func startVideo() {
        guard let url = Bundle.main.url(forResource: videoResourceName, withExtension: "mov") else { return }
        let newPlayer = AVPlayer(url: url)
        player = newPlayer
        newPlayer.play()
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { _ in
            withAnimation { videoFinished = true }
        }
    }

    var alienCluster: some View {
        GeometryReader { geo in
            let players = store.currRoom?.inGamePlayers ?? []
            ZStack {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    // same formula VotingScreen uses, so a player's starting position here lines up
                    // exactly with where they were on the vote screen
                    let base = clusterPosition(index: index, count: players.count, size: geo.size)
                    flyingAvatar(for: player, index: index)
                        .position(x: base.x, y: base.y)
                }
            }
        }
        .frame(height: 280)
    }

    // A two-loop-de-loop flourish (so the path reads as alive, not a straight slide) followed by a
    // long swoop to flightDestination, with scale/opacity easing in over the same span. Each index
    // gets a staggered start and alternating loop direction so the cluster doesn't move in lockstep.
    // Deliberately spans ~7-8s so the motion is the dominant thing on screen for most of the
    // 10s video, rather than snapping to its resting spot in the first couple seconds.
    @ViewBuilder
    func flyingAvatar(for player: Player, index: Int) -> some View {
        if skipIntroAnimation {
            // preview: show the settled end-state directly, no animation to wait on
            let dest = flightDestination
            AvatarLobbyView(player: player, inGame: false) {}
                .offset(x: dest.dx, y: dest.dy)
                .scaleEffect(dest.scale)
                .opacity(dest.opacity)
        } else {
            let loopSign: CGFloat = index.isMultiple(of: 2) ? 1 : -1
            let loopRadius: CGFloat = 40
            // index 0's stagger lands on exactly 0.0, and a zero-duration first keyframe on
            // offsetX/offsetY (unlike scale/opacity, which always add +3.2/+4.0) makes
            // KeyframeAnimator fail to render that instance at all - keep it just above zero
            let stagger = max(Double(index) * 0.15, 0.01)
            let dest = flightDestination

            KeyframeAnimator(initialValue: UFOFlight(), trigger: flightStarted) { value in
                AvatarLobbyView(player: player, inGame: false) {}
                    .offset(x: value.offsetX, y: value.offsetY)
                    .scaleEffect(value.scale)
                    .opacity(value.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.offsetX) {
                    LinearKeyframe(0, duration: stagger)
                    // loop 1
                    LinearKeyframe(loopRadius * loopSign, duration: 0.4)
                    LinearKeyframe(0, duration: 0.4)
                    LinearKeyframe(-loopRadius * loopSign, duration: 0.4)
                    LinearKeyframe(0, duration: 0.4)
                    // loop 2, wider, opposite starting direction
                    LinearKeyframe(-loopRadius * 1.4 * loopSign, duration: 0.4)
                    LinearKeyframe(0, duration: 0.4)
                    LinearKeyframe(loopRadius * 1.4 * loopSign, duration: 0.4)
                    LinearKeyframe(0, duration: 0.4)
                    CubicKeyframe(dest.dx, duration: 3.5)
                }
                KeyframeTrack(\.offsetY) {
                    LinearKeyframe(0, duration: stagger)
                    LinearKeyframe(-loopRadius, duration: 0.4)
                    LinearKeyframe(-loopRadius * 2, duration: 0.4)
                    LinearKeyframe(-loopRadius, duration: 0.4)
                    LinearKeyframe(0, duration: 0.4)
                    LinearKeyframe(loopRadius * 1.4, duration: 0.4)
                    LinearKeyframe(loopRadius * 2.8, duration: 0.4)
                    LinearKeyframe(loopRadius * 1.4, duration: 0.4)
                    LinearKeyframe(0, duration: 0.4)
                    CubicKeyframe(dest.dy, duration: 3.5)
                }
                KeyframeTrack(\.scale) {
                    LinearKeyframe(1, duration: stagger + 3.2)
                    CubicKeyframe(dest.scale, duration: 3.5)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(1, duration: stagger + 4.0)
                    CubicKeyframe(dest.opacity, duration: 2.5)
                }
            }
        }
    }
}

private struct UFOFlight: Equatable {
    var offsetX: CGFloat = 0
    var offsetY: CGFloat = 0
    var scale: CGFloat = 1
    var opacity: Double = 1
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

#Preview("Visit (90%) · Tap to Continue") {
    let store = previewResultStore(voteResult: 0.9)
    ResultScreen(previewVideoFinished: true)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Leave (50%) · Tap to Continue") {
    let store = previewResultStore(voteResult: 0.5)
    ResultScreen(previewVideoFinished: true)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Slime (10%) · Tap to Continue") {
    let store = previewResultStore(voteResult: 0.1)
    ResultScreen(previewVideoFinished: true)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Just Arrived · Video Playing") {
    let store = previewResultStore(voteResult: 0.9)
    ResultScreen(previewVideoFinished: false)
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
    return ResultScreen(previewVideoFinished: true)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}
