import SwiftUI

// MARK: - Primary View Shell
struct DisplayScreen: View {
    // Injects your friend's global state manager
    @EnvironmentObject var store: GameStore
    
    // TEMPORARY: A mock ID representing the local device's user for UI testing.
    // In production, this would be stored locally upon joining the room.
    @State private var localPlayerID: UUID = UUID()
    
    // Dynamically checks if the current user is the host to swap the footer UI
    var isLocalPlayerHost: Bool {
        // NOTE: This assumes Player.id gets refactored to UUID to match Room.hostID
        store.currRoom?.hostID == localPlayerID
    }
    
    var body: some View {
        VStack(spacing: 24) {
            headerSection
            
            Text("How do you ... ?")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 20) {
                    StoryCardView(
                        title: "Human's Instructions",
                        content: "Step 1: Find a bathroom\nStep 2: Take off your clothes\nStep 3: Turn the water on",
                        iconName: "person.circle"
                    )
                    
                    StoryCardView(
                        title: "Narration",
                        content: "I found the place human called bathroom I have no clothes to take off, and I accidentally flooded the bathroom",
                        iconName: "face.smiling"
                    )
                }
                .padding(.horizontal)
            }
            
            reactionRow
            
            footerSection
        }
        .padding(.vertical)
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
        HStack(spacing: 16) {
            // Hardcoded 1 to 4 matching the placeholder wireframe
            ForEach(1...4, id: \.self) { index in
                Button(action: {
                    print("Emoji \(index) tapped")
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 60, height: 60)
                        
                        Text("Emoji\(index)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
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
                print("Host advances to Next Story")
                // Future logic: store.state = .voting (or advance story index)
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

#Preview {
    let motionManager = MotionManager()
    let store = GameStore(
        motionManager: motionManager
    )
    DisplayScreen()
    .environmentObject(store)
    .environmentObject(motionManager)
}
