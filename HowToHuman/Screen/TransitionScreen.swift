//
//  TransitionScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 14/08/26.
//

import SwiftUI

class HTHFontSize{
    static var body: CGFloat = 16
    static var subtext: CGFloat = 11
    static var title: CGFloat = 24
}

struct TransitionScreen: View {
    @EnvironmentObject var store: GameStore
    
    let instructions: Dictionary<GamePhase, [(String, CGFloat)]> = [
        .askHuman: [("**You are an alien.**", HTHFontSize.body),
                    ("You and your team have just discovered Earth.\n\n", HTHFontSize.body),
                    ("\n\n", HTHFontSize.body),
                    ("Curious, you want to experience human life for yourself.", HTHFontSize.body),
                    ("But first, you need to know how humans do things.", HTHFontSize.body),
                    ("\n\n", HTHFontSize.body),
                    ("Ask a human:", HTHFontSize.body),
                    ("**\"How do you...?\"**", HTHFontSize.title),
                    ("_The simpler, the better_", HTHFontSize.body)],
        
            .answerAlien: [("**Now, it's your turn, human.**", HTHFontSize.body),
                           ("An alien needs your help understanding how humans work.", HTHFontSize.body),
                           ("Beware: alien knows nothing about humans and might take everything you say literally.", HTHFontSize.body),
                           ("**Answer their question as clearly as you can.**", HTHFontSize.body),
                           ("_What could possibly go wrong?_", HTHFontSize.body)],
        
            .narrateExperience: [("**Aliens, the humans have answered.**", HTHFontSize.body),
                                 ("You may go down to Earth with the guidance they provided.", HTHFontSize.body),
                                 ("**Follow their instruction, write down your experience.**", HTHFontSize.body),
                                 ("_Your fellow aliens will want to know._", HTHFontSize.body)],
        
        
            .reviewExperience: [("**Welcome back to the spaceship, aliens.**", HTHFontSize.body),
                                ("Time to review our experiences.", HTHFontSize.body),
                                ("Let's compare and see how everyone's visit turned out.", HTHFontSize.body)],
        
            .voting: [("You've heard everyone's experiences on Earth.", HTHFontSize.body),
                      ("Now, would you visit Earth again?", HTHFontSize.body),
                      ("**Cast your vote.**", HTHFontSize.body)]
    ]
    
    @State private var visibleRows: [Bool] = [false, false, false, false, false, false, false, false, false, false]
    @State private var animationWorkItems: [DispatchWorkItem] = []
    var body: some View {
        VStack{
            Spacer()
            let instruction = instructions[store.phase]!
            ForEach(0..<instruction.count, id: \.self){ index in
                let attributedString = try? AttributedString(markdown: instruction[index].0)
                Text(attributedString ?? "")
                    .font(.system(size: instruction[index].1))
                    .opacity(visibleRows[index] ? 1.0 : 0.0)
                    .multilineTextAlignment(.center)
                    .animation(.easeIn(duration: 0.6), value: visibleRows[index])
                    .tracking(1.5)
                
            }
            Spacer()
            PrimaryButton(title: "CONTINUE"){
                switch store.phase {
                case .askHuman:
                    store.state = .askHuman
                case .answerAlien:
                    store.state = .answerAlien
                case .narrateExperience:
                    store.state = .narrateExperience
                case .reviewExperience:
                    store.state = .reviewExperience
                case .voting:
                    store.state = .voting
                }
            }
        }.padding()
            .onAppear{
                startSequencedAnimation()
            }
            .onTapGesture {
                skipAnimation()
            }
    }
    
    private func startSequencedAnimation() {
        for index in instructions[store.phase]!.indices {
            let item = DispatchWorkItem {
                visibleRows[index] = true
            }
            animationWorkItems.append(item)
            
            // Schedule each row with a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.4, execute: item)
        }
    }
    
    private func skipAnimation() {
        // 1. Cancel all remaining delayed tasks
        animationWorkItems.forEach { $0.cancel() }
        animationWorkItems.removeAll()
        
        // 2. Instantly force all rows to be visible without any animation
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            visibleRows = Array(repeating: true, count: instructions[store.phase]!.count)
        }
    }
}

#Preview {
    TransitionScreen().environmentObject(GameStore()).preferredColorScheme(.dark)
}
