//
//  TransitionScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 14/08/26.
//

import SwiftUI

struct TransitionScreen: View {
    @EnvironmentObject var store: GameStore
    
    let instructions: Dictionary<GamePhase, [(LocalizedStringResource, CGFloat, String)]> = [
        .none: [],
        .askHuman: [("**You are an alien.**", HTHSize.title, HTHFont.space_grot),
                    ("You and your team have just discovered Earth.", HTHSize.title, HTHFont.space_grot),
                    ("\n", HTHSize.title, HTHFont.space_grot),
                    ("Curious, you want to experience human life for yourselves.", HTHSize.title, HTHFont.space_grot),
                    ("But first, you need to know how humans do things.", HTHSize.title, HTHFont.space_grot),
                    ("\n", HTHSize.title, HTHFont.space_grot),
                    ("Ask a human:", HTHSize.title, HTHFont.space_grot),
                    ("**\"How do you...?\"**", HTHSize.title, HTHFont.space_grot),
                    ("The simpler, the better", HTHSize.title, HTHFont.space_grot),
                    ("\n", HTHSize.title, HTHFont.space_grot)
                   ],
        
        
        .answerAlien: [("**Now, it's your turn, human.**", HTHSize.smallTitle, HTHFont.space_grot),
                       ("\n", HTHSize.smallTitle, HTHFont.space_grot),
                       ("An alien needs your help understanding how to be humans", HTHSize.smallTitle, HTHFont.space_grot),
                       ("\n", HTHSize.smallTitle, HTHFont.space_grot),
                       ("Answer their question as clearly as you can.", HTHSize.smallTitle, HTHFont.space_grot),
                       ("\n", HTHSize.smallTitle, HTHFont.space_grot),
                       ("Beware: alien knows nothing about humans and might take everything you say literally.", HTHSize.smallTitle, HTHFont.space_grot),
                       ("\n", HTHSize.smallTitle, HTHFont.space_grot),
                       ("_What could possibly go wrong?_", HTHSize.smallTitle, HTHFont.space_grot),
                       ("\n", HTHSize.smallTitle, HTHFont.space_grot)
                      ],

        .narrateExperience: [("**Aliens, the humans have answered.**", HTHSize.title, HTHFont.space_grot),
                             ("\n", HTHSize.title, HTHFont.space_grot),
                             ("Go down to Earth with the guidance the humans provided.", HTHSize.title, HTHFont.space_grot),
                             ("\n", HTHSize.title, HTHFont.space_grot),
                             ("Follow their instruction, write down your experience.", HTHSize.title, HTHFont.space_grot),
                             ("What happened?", HTHSize.title, HTHFont.space_grot),
                             ("\n", HTHSize.title, HTHFont.space_grot),
                             ("_Your fellow aliens will want to know._", HTHSize.title, HTHFont.space_grot),
                             ("\n", HTHSize.title, HTHFont.space_grot)
                            ],


        .shareExperience: [("**Welcome back to the spaceship, aliens.**", HTHSize.title, HTHFont.space_grot),
                            ("\n", HTHSize.title, HTHFont.space_grot),
                            ("Time to share our experience", HTHSize.title, HTHFont.space_grot),
                            ("\n", HTHSize.title, HTHFont.space_grot),
                            ("Let's see who goes first.", HTHSize.title, HTHFont.space_grot),
                            ("\n", HTHSize.title, HTHFont.space_grot)
                           ],

        .voting: [("Now that everyone's shared their experiences, answer this:", HTHSize.title, HTHFont.space_grot),
                  ("\n", HTHSize.title, HTHFont.space_grot),
                  ("**Would you revisit Earth?**", HTHSize.title, HTHFont.space_grot),
                  ("\n", HTHSize.title, HTHFont.space_grot),
                  ("Cast your vote.", HTHSize.title, HTHFont.space_grot),
                  ("\n", HTHSize.title, HTHFont.space_grot),
                 ]
    ]
    
    @State private var visibleRows: [Bool] = [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]
    @State private var animationWorkItems: [DispatchWorkItem] = []
    private var showFootnote : Bool {
        visibleRows.filter{$0}.count == instructions[store.phase]!.count
    }
    @State private var showDelayedContent = false

    var body: some View {
        ZStack{
            Color.clear.ignoresSafeArea()
            VStack{
                HStack{
                    ExitRoomButton()
                    Spacer()
                }
                Spacer()
                
                let instruction = instructions[store.phase] ?? []
                VStack{
                    
                    ForEach(instruction.indices, id:\.self){ index in
                            let attributedString = AttributedString(
                                localized: instruction[index].0
                            )
                            HTHText(
                                markdowntitle: attributedString,
                                size: instruction[index].1,
                                font: HTHFont.space_grot
                            )
                            .opacity(visibleRows[index] ? 1.0 : 0.0)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .animation(.easeIn(duration: 0.6), value: visibleRows[index])
                            .tracking(1.5)
                    }
                    
                }.padding(.horizontal, 30)
                Spacer()
                
                if showFootnote {
                    if showDelayedContent{
                        if store.currRoom?.hostID == store.myPlayerData.id {
                            PrimaryButton(title: "CONTINUE"){
                                store.next()
                            }
                        }else{
                            HTHText(title: "Wait for host to continue", font: HTHFont.space_grot)
                        }
                    }
                }
                
            }.padding()
            .onAppear{
                print("TransitionScreen appeared - state:", store.state, "phase:", store.phase, "instructions found:", instructions[store.phase] != nil)
                startSequencedAnimation()
                switch store.phase {
                case .none:
                    store.stopOnboardingSong()
                case .askHuman:
                    store.initAudioPlayer(sound: "(ASK)")
                case .answerAlien:
                    store.initAudioPlayer(sound: "(GUIDE)")
                case .narrateExperience:
                    store.initAudioPlayer(sound: "(FOLLOW)")
                case .shareExperience:
                    store.initAudioPlayer(sound: "(READING)")
                case .voting:
                    store.initAudioPlayer(sound: "(VOTE)")
                }
                
            }
            .onTapGesture {
                skipAnimation()
            }
            .onChange(of: showFootnote) {
                if showFootnote {
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        withAnimation {
                            showDelayedContent = true
                        }
                    }
                } else {
                    showDelayedContent = false
                }
            }
            
            VStack{
                if store.showExitRoomPopUp == true{
                    ExitRoomPopUp(isPresented: $store.showExitRoomPopUp)
                }
            }.padding()
        }
        .frame(maxWidth: .infinity)
        .background {
            HTHGameBackground()
        }
    }
    
    private func startSequencedAnimation() {
        for index in (instructions[store.phase] ?? []).indices {
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
            visibleRows = Array(repeating: true, count: (instructions[store.phase] ?? []).count)
        }
    }
}

#Preview {
    let motionManager = MotionManager()
    let store = GameStore(
        motionManager: motionManager
    )
    TransitionScreen()
    .environmentObject(store)
    .environmentObject(motionManager)
}
