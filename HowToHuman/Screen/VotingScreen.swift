//
//  VotingScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 14/08/26.
//

import SwiftUI
import Combine

struct VotingScreen: View {
    @EnvironmentObject var store: GameStore

    @State private var positions: [UUID: PlayerPosition] = [:]
    @State private var timeRemaining: Int = 0
    // nil = haven't voted yet; votes stay changeable up until the timer runs out or everyone's voted
    @State private var myVote: Bool?

    // preview-only: lets #Preview seed a fixed countdown / current-vote state that's otherwise only reachable by interacting live
    private let previewTimeRemaining: Int?

    init(previewTimeRemaining: Int? = nil, previewMyVote: Bool? = nil) {
        self.previewTimeRemaining = previewTimeRemaining
        _myVote = State(initialValue: previewMyVote)
    }

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var votedCount: Int {
        store.playerGameDataList.filter { data in
            store.currRoom?.players.contains(where: { $0.id == data.id }) == true && data.vote != nil
        }.count
    }

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    ExitRoomButton()
                    Spacer()
                    timerBadge
                }

                VStack(spacing: 4) {
                    HTHText(title: "Now that everyone's shared their experiences, would you visit Earth again?", font: HTHFont.space_grot)
                        .multilineTextAlignment(.center)
                    HTHText(title: "Cast your vote.", font: HTHFont.space_grot)
                }
                .padding(.horizontal)

                alienCluster

                Spacer()

                HStack(spacing: 16) {
                    PrimaryButton(title: "Yes!", btnColor: HTHColor.green) {
                        store.submitVote(yes: true)
                        myVote = true
                    }
                    .opacity(myVote == false ? 0.5 : 1)

                    PrimaryButton(title: "No!", btnColor: HTHColor.purple) {
                        store.submitVote(yes: false)
                        myVote = false
                    }
                    .opacity(myVote == true ? 0.5 : 1)
                }

                if myVote != nil {
                    HTHText(title: "You can still change your vote", size: HTHSize.caption, font: HTHFont.space_grot)
                }

                HTHText(title: "\(votedCount)/\(store.currRoom?.players.count ?? 0) Aliens Voted", size: HTHSize.caption, color: HTHColor.yellow)
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
            timeRemaining = previewTimeRemaining ?? (store.currRoom?.timerMode.seconds(for: .question) ?? 0)
        }
        .onDisappear {
            store.vibrate()
        }
        .onReceive(timer) { _ in
            guard timeRemaining > 0 else {
                if store.currRoom?.hostID == store.myPlayerData.id {
                    store.resolveVote()
                } else {
                    store.state = store.state.next
                }
                return
            }
            timeRemaining -= 1
        }
    }
}

private extension VotingScreen {
    var timerBadge: some View {
        HStack(spacing: 4) {
            Text("\(timeRemaining)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Image(systemName: "clock.fill")
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
    }

    var alienCluster: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(store.currRoom?.players ?? [], id: \.id) { player in
                    if let position = positions[player.id] {
                        AvatarLobbyView(player: player) {}
                            .position(x: position.x, y: position.y)
                    }
                }
            }
            .onAppear {
                assignPositions(for: store.currRoom?.players ?? [], into: &positions, size: geo.size, radius: 60)
            }
            .onChange(of: store.currRoom?.players.count) {
                assignPositions(for: store.currRoom?.players ?? [], into: &positions, size: geo.size, radius: 60)
            }
        }
        .frame(height: 320)
    }
}

// MARK: - Previews
@MainActor
private func previewVotingStore(playerCount: Int, votedCount: Int) -> GameStore {
    let motionManager = MotionManager()
    let store = GameStore(motionManager: motionManager)

    let names = ["Cho", "Karen", "Baeni", "Satria", "Wais", "Barra"]
    let avatars = AlienAvatar.allCases
    let players = (0..<playerCount).map { index in
        Player(id: UUID(), name: names[index % names.count], avatar: avatars[index % avatars.count])
    }

    store.currRoom = Room(name: "Cho's Room", hostID: players[0].id, players: players)
    store.myPlayerData = players[0]
    store.playerGameDataList = players.enumerated().map { index, player in
        PlayerGameData(id: player.id, vote: index < votedCount ? (index.isMultiple(of: 2) ? 1.0 : 0.0) : nil)
    }

    return store
}

#Preview("Fresh · 2 Players (minimum)") {
    let store = previewVotingStore(playerCount: 2, votedCount: 0)
    VotingScreen()
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Fresh · 6 Players") {
    let store = previewVotingStore(playerCount: 6, votedCount: 0)
    VotingScreen()
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Mid-Vote · 3/6 Voted") {
    let store = previewVotingStore(playerCount: 6, votedCount: 3)
    VotingScreen()
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Almost Done · 5/6 Voted") {
    let store = previewVotingStore(playerCount: 6, votedCount: 5)
    VotingScreen()
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Voted Yes · Still Changeable") {
    let store = previewVotingStore(playerCount: 6, votedCount: 1)
    VotingScreen(previewMyVote: true)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Voted No · Still Changeable") {
    let store = previewVotingStore(playerCount: 6, votedCount: 1)
    VotingScreen(previewMyVote: false)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}

#Preview("Timer Almost Out") {
    let store = previewVotingStore(playerCount: 4, votedCount: 2)
    VotingScreen(previewTimeRemaining: 3)
        .environmentObject(store)
        .environmentObject(store.motionManager)
}
