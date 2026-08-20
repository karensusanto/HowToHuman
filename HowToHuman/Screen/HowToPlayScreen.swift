//
//  HowToPlayScreen.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//
import SwiftUI

struct HowToPlayScreen: View {
    @EnvironmentObject var store: GameStore
    
    private let story : [String] = [
        """
        What happens when someone with **absolutely no knowledge of humanity** tries to follow human instructions? Well, let's find out.
        """,
        """
        Aliens have discovered Earth and want to experience life as humans, **but they have no idea how humans do things.**
        """,
        """
        They send down some questions about basic human activities. Give them some guidance, but remember: **Aliens follow instructions literally.**
        """,
        """
        Your advice could lead to an amazing human experience… or a very confused alien.
        """,
        """
        **Help the aliens have a positive experience on Earth — or risk angering them.**
        """]
    
    private let steps: [(String, String)] = [
        ("Phase 1: Ask", "Everyone is an alien. Think of something simple you've always wondered about doing as a human - _the simpler, the better._ Ask a human: **_\"How do you...?\"_**"),
        ("Phase 2: Guide", "Everyone is a now human. You get one of the alien's questions and must create a step-by-step guide to answer it."),
        ("Phase 3: Follow", "Everyone is back to being an alien. Follow the human's instructions **_as literally as possible_**, then write down your experience. Look for gaps, misunderstandings, and opportunities for things to go hilariously wrong. Be creative!"),
        ("Phase 4: Share", "Review everyone's experience from Earth. Then vote: **Did the aliens have a positive experience with humanity?**")
    ]
    
    var body: some View {
        ZStack{
            Color.clear.ignoresSafeArea()
            VStack(spacing:0){
                HStack{
                    BackButton(toState: .home)
                    Spacer()
                    HTHText(title: "HOW TO PLAY", size: HTHSize.title, color: HTHColor.yellow)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                
                
                ScrollView(showsIndicators: false){
                    VStack(alignment: .center, spacing: 40){
                        
                        VStack(alignment: .center, spacing: 20){
                            ForEach(story, id: \.self){paragraph in
                                let attributedString = try? AttributedString(markdown: paragraph)
                                HTHText(markdowntitle: attributedString ?? "", font: HTHFont.space_grot)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        
                        ForEach(steps.indices, id: \.self){ i in
                            VStack(alignment: .center, spacing: 10){
                                HTHText(title: steps[i].0, size: HTHSize.title, color: HTHColor.yellow)
                                let attributedString = try? AttributedString(markdown: steps[i].1)
                                HTHText(markdowntitle: attributedString ?? "", font: HTHFont.space_grot)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }.padding(40)
                }
                
//                PrimaryButton(title: "GOT IT"){
//                    store.state = .home
//                }
                
            }.padding()
        }
        .frame(maxWidth: .infinity)
        .background {
            HTHOnboardingBackground()
        }
    }
}


#Preview {
    HowToPlayScreen().environmentObject(GameStore()).preferredColorScheme(.dark)
}
