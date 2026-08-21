//
//  TransitionScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 14/08/26.
//

import SwiftUI

struct TransitionScreen: View {
    @EnvironmentObject var store: GameStore
    
    let instructions: Dictionary<GamePhase, [(String, CGFloat, String)]> = [
        .none: [],
        .askHuman: [("**You are an alien.**", HTHSize.body, HTHFont.slackey),
                    ("You and your team have just discovered Earth.\n\n", HTHSize.body, HTHFont.slackey),
                    ("\n\n", HTHSize.body, HTHFont.slackey),
                    ("Curious, you want to experience human life for yourselves.", HTHSize.body, HTHFont.slackey),
                    ("First, you need to know how humans do things.", HTHSize.body, HTHFont.slackey),
                    ("\n\n", HTHSize.body, HTHFont.slackey),
                    ("Ask a human:", HTHSize.body, HTHFont.slackey),
                    ("**\"How do you...?\"**", HTHSize.title, HTHFont.slackey),
                    ("\n", HTHSize.title, HTHFont.slackey),
                    ("_The simpler, the better_", HTHSize.body, HTHFont.slackey),
                    ("\n\n", HTHSize.body, HTHFont.slackey)
                   ],
        
        
        .answerAlien: [("**Now, it's your turn, human.**", HTHSize.body, HTHFont.slackey),
                       ("\n\n", HTHSize.body, HTHFont.slackey),
                       ("An alien needs your help understanding how to be humans", HTHSize.body, HTHFont.slackey),
                       ("\n\n", HTHSize.body, HTHFont.slackey),
                       ("**Answer their question as clearly as you can.**", HTHSize.body, HTHFont.slackey),
                       ("\n\n", HTHSize.body, HTHFont.slackey),
                       ("Beware: alien knows nothing about humans and might take everything you say literally.", HTHSize.body, HTHFont.slackey),
                       ("\n\n", HTHSize.body, HTHFont.slackey)
                       //                           ("_What could possibly go wrong?_", HTHSize.body)
                      ],

        .narrateExperience: [("**Aliens, the humans have answered.**", HTHSize.body, HTHFont.slackey),
                             ("\n\n", HTHSize.body, HTHFont.slackey),
                             ("Go down to Earth with the guidance the humans provided.", HTHSize.body, HTHFont.slackey),
                             ("\n\n", HTHSize.body, HTHFont.slackey),
                             ("**Follow their instruction, write down your experience.**", HTHSize.body, HTHFont.slackey),
                             ("\n\n", HTHSize.body, HTHFont.slackey),
                             ("What happened?", HTHSize.body, HTHFont.slackey),
                             ("\n\n", HTHSize.body, HTHFont.slackey),
                             ("_Your fellow aliens will want to know._", HTHSize.body, HTHFont.slackey),
                             ("\n\n", HTHSize.body, HTHFont.slackey)
                            ],


        .shareExperience: [("**Welcome back to the spaceship, aliens.**", HTHSize.body, HTHFont.slackey),
                            ("\n\n", HTHSize.body, HTHFont.slackey),
                            ("Time to share our experience", HTHSize.body, HTHFont.slackey),
                            ("\n\n", HTHSize.body, HTHFont.slackey),
                            ("Let's see who goes first.", HTHSize.body, HTHFont.slackey),
                            ("\n\n", HTHSize.body, HTHFont.slackey)
                           ],

        .voting: [("Now that everyone's shared their experiences, answer this:", HTHSize.body, HTHFont.slackey),
                  ("\n\n", HTHSize.body, HTHFont.slackey),
                  ("Would you revisit Earth?", HTHSize.title, HTHFont.slackey),
                  ("\n\n", HTHSize.body, HTHFont.slackey),
                  ("**Cast your vote.**", HTHSize.body, HTHFont.slackey),
                  ("\n\n", HTHSize.body, HTHFont.slackey),
                 ]
    ]
    
    @State private var visibleRows: [Bool] = [false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]
    @State private var animationWorkItems: [DispatchWorkItem] = []
//    @State private var assignmentList: [UUID: UUID] = [:]
    var body: some View {
        ZStack{
            Color.clear.ignoresSafeArea()
            VStack{
                HStack{
                    ExitRoomButton()
                    Spacer()
                }
                Spacer()
                VStack{
                    let instruction = instructions[store.phase]!
                    
                    ForEach(instruction.indices, id:\.self){ index in
                        if instruction[index].0 == "\n\n"{
                            Color.clear.frame(width: 40, height: 40)
                        } else if instruction[index].0 == "\n"{
                            Color.clear.frame(width: 40, height: 10)
                        } else {
                            let attributedString = try? AttributedString(
                                markdown: instruction[index].0
                            )
                            HTHText(
                                markdowntitle: attributedString ?? "",
                                size: instruction[index].1,
                                font: HTHFont.space_grot
                            )
                            .opacity(visibleRows[index] ? 1.0 : 0.0)
                            .multilineTextAlignment(.center)
                            .animation(.easeIn(duration: 0.6), value: visibleRows[index])
                            .tracking(1.5)
                        }
                    }
                    
                }.padding(.horizontal, 40)
                Spacer()
                
                if store.currRoom?.hostID == store.myPlayerData.id {
                    PrimaryButton(title: "CONTINUE"){
                        store.next()
                    }
                }else{
                    HTHText(title: "Wait for host to continue", font: HTHFont.space_grot)
                }
                
            }.padding()
            .onAppear{
//                print(store.phase)
//                print("Submitted game data: ", store.submittedGameData)
//                print("Player count: ", store.currRoom?.players.count ?? 0)
//                print("Host id: ", store.currRoom?.hostID ?? "")
//                print("Player id: ", store.myPlayerData.id)
//                if (store.phase == .answerAlien && store.currRoom?.hostID == store.myPlayerData.id && store.submittedGameData == store.currRoom?.players.count){
//                    assignmentList = store.assignQuestions()
//                    print(assignmentList)
//                }
                startSequencedAnimation()
            }
//            .onChange(of: store.submittedGameData){
//                print("Submitted game data: ", store.submittedGameData)
//                if store.phase == .answerAlien && store.currRoom?.hostID == store.myPlayerData.id && store.submittedGameData == store.currRoom?.players.count && assignmentList.isEmpty{
//                    assignmentList = store.assignQuestions()
//                    print(assignmentList)
//                }
//            }
            .onTapGesture {
                skipAnimation()
            }
            
            if store.showExitRoomPopUp == true{
                ExitRoomPopUp(isPresented: $store.showExitRoomPopUp)
            }
        }
        .frame(maxWidth: .infinity)
        .background {
            HTHGameBackground()
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
