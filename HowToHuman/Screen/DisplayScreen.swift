//
//  DisplaySCreen.swift
//  HowToHuman
//
//  Created by Syauqi Auliya on 13/08/26.
//

import SwiftUI

// MARK: - Ephemeral Animation Model
/// Represents a single emoji instance floating up the screen.
struct FloatingReaction: Identifiable {
    let id = UUID()
    let symbol: String
    let xOffset: CGFloat
}

// MARK: - Primary View Shell
struct DisplayScreen: View {
    @EnvironmentObject var store: GameStore
    
    // TEMPORARY: Identifiers for UI testing.
    var localPlayerID: UUID = UUID()
    
    // MARK: Animation State
    // Maintains the active array of flying emojis
    @State private var activeReactions: [FloatingReaction] = []
    
    var isLocalPlayerHost: Bool {
        store.currRoom?.hostID == localPlayerID
    }
    
    // Hardcoded placeholder fallback for the MVP testing phase
    let fallbackQuestion = "How do you make a sandwich?"
    let fallbackInstruction = "Step 1: Get bread.\nStep 2: Panic."
    let fallbackNarration = "I stared at the bread until it intimidated me."
    
    var body: some View {
        ZStack {
            // Main Content Layer
            VStack(spacing: 24) {
                headerSection
                
                // DATA CONTAINER 1: The Alien's Original Question
                // In production, this reads from store.currentActiveStory?.question.text
                Text(fallbackQuestion)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // DATA CONTAINER 2: The Human's Step-by-Step Guide
                        StoryCardView(
                            title: "Human's Instructions",
                            content: fallbackInstruction,
                            iconName: "person.circle"
                        )
                        
                        // DATA CONTAINER 3: The Alien's Disastrous Attempt
                        StoryCardView(
                            title: "Narration",
                            content: fallbackNarration,
                            iconName: "face.smiling"
                        )
                    }
                    .padding(.horizontal)
                }
                
                reactionRow
                
                footerSection
            }
            .padding(.vertical)
            
            // Animation Overlay Layer
            reactionParticlesOverlay
        }
        .onReceive(store.incomingReactions) { networkEmoji in
            fireReaction(symbol: networkEmoji)
        }
    }
    
}

// MARK: - View Components
private extension DisplayScreen {
    var headerSection: some View {
        HStack {
            HStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                Text("Display")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.black))
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    var reactionRow: some View {
        // Utilizing the finalized emoji array defined in your GDD
        let reactionOptions = ["😂", "💩", "🚀", "👽"]
        
        return HStack(spacing: 16) {
            ForEach(reactionOptions, id: \.self) { emoji in
                Button(action: {
                    // 1. Fire the animation locally right now
                    fireReaction(symbol: emoji)
                    // 2. Beam it across the network to everyone else
                    store.sendReaction(emoji)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 60, height: 60)
                        
                        Text(emoji)
                            .font(.title)
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    var footerSection: some View {
        if isLocalPlayerHost {
            Button(action: {
                print("Host commands transition to the next triplet.")
                // Future integration: store.advanceToNextStory()
            }) {
                Text("NEXT STORY")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Color(UIColor.systemGray4)))
            }
            .padding(.horizontal)
        } else {
            HStack(spacing: 12) {
                ProgressView()
                Text("Waiting for host to continue...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
    
    
    // MARK: - Particle Engine Method
    /// Generates a visual emoji and dispatches the network payload simultaneously.
    func fireReaction(symbol: String) {
        // 1. Dispatch the network payload (to be implemented via MultipeerTransport)
        print("Network transmission: Sending \(symbol) payload.")
        
        // 2. Generate a randomized visual instance
        let randomX = CGFloat.random(in: -120...120)
        let newReaction = FloatingReaction(symbol: symbol, xOffset: randomX)
        activeReactions.append(newReaction)
        
        // 3. Purge the instance from memory after the animation concludes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            activeReactions.removeAll { $0.id == newReaction.id }
        }
    }
    
    // MARK: - Particle Overlay Layer
    var reactionParticlesOverlay: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(activeReactions) { reaction in
                    AnimatedBubbleView(symbol: reaction.symbol)
                    // Anchor the origin point roughly above the reaction buttons
                        .position(x: geo.size.width / 2 + reaction.xOffset, y: geo.size.height - 150)
                }
            }
        }
        // Prevents the invisible overlay from blocking scroll gestures
        .allowsHitTesting(false)
    }
}

// MARK: - Isolated Bubble Animation View
/// Encapsulates the specific movement physics for a single emoji.
struct AnimatedBubbleView: View {
    let symbol: String
    
    @State private var verticalOffset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        Text(symbol)
            .font(.system(size: 40))
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(y: verticalOffset)
            .onAppear {
                // Execute a spring-loaded ascent paired with a gradual fade
                withAnimation(.easeOut(duration: 2.0)) {
                    verticalOffset = -400 // Float upward distance
                    opacity = 0.0
                    scale = 1.5
                }
            }
    }
}

// MARK: - Extracted Card Subview
struct StoryCardView: View {
    let title: String
    let content: String
    let iconName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Image(systemName: iconName)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(8)
                    .background(Circle().stroke(Color.black, lineWidth: 1))
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 1)
        )
    }
}

// MARK: - Previews
#Preview("Host View") {
    // 1. Create a specific ID for the Host
    let mockHostID = UUID()
    
    // 2. Set up a mock GameStore with a Room where the hostID matches
    let mockStore = GameStore()
    mockStore.currRoom = Room(
        id: UUID(),
        name: "Test Room",
        hostID: mockHostID,
        players: [Player(id: mockHostID, name: "Host")]
    )
    
    // 3. Inject the matching ID into the View
    return DisplayScreen(localPlayerID: mockHostID)
        .environmentObject(mockStore)
}

#Preview("Player View") {
    // 1. Create separate IDs for the Host and the Client
    let mockHostID = UUID()
    let mockClientID = UUID()
    
    // 2. Set up the GameStore where the hostID belongs to someone else
    let mockStore = GameStore()
    mockStore.currRoom = Room(
        id: UUID(),
        name: "Test Room",
        hostID: mockHostID,
        players: [
            Player(id: mockHostID, name: "Host"),
            Player(id: mockClientID, name: "Client")
        ]
    )
    
    // 3. Inject the Client's ID into the View (It won't match the hostID!)
    return DisplayScreen(localPlayerID: mockClientID)
        .environmentObject(mockStore)
}
