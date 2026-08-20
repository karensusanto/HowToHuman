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
        What happens when someone with absolutely no knowledge of humanity tries to follow human instructions?
        """,
        """
        Aliens have discovered Earth and want to experience life as humans, but they have no idea how humans do things.
        """,
        """
        They send down some questions about basic human activities. Give them some guidance, but remember: **_Aliens follow instructions literally._**
        """,
        """
        Your advice could lead to an amazing human experience… or a very confused alien.
        """,
        """
        Help the aliens have a positive experience on Earth — or risk angering them.
        """]
    
    private let steps: [(String, String, String)] = [
        ("antenna.radiowaves.left.and.right", "ASK", "Everyone is an alien. Think of something simple you've always wondered about doing as a human - _the simpler, the better._ Ask a human: **_\"How do you...?\"_**"),
        ("person.fill.questionmark", "ANSWER", "Everyone is a now human. You get one of the alien's questions and must create a step-by-step guide to answer it."),
        ("figure.walk", "FOLLOW", "Everyone is back to being an alien. Follow the human's instructions **_as literally as possible_**, then write down your experience. Look for gaps, misunderstandings, and opportunities for things to go hilariously wrong. Be creative!"),
        ("scalemass", "JUDGE", "Review everyone's experience from Earth. Then vote: **Did the aliens have a positive experience with humanity?**")
    ]
    
    var body: some View {
        ZStack{
            Color.clear.ignoresSafeArea()
            VStack{
                HStack{
                    BackButton(toState: .home)
                    Spacer()
                    HTHText(title: "HOW TO PLAY", size: HTHSize.title, color: HTHColor.yellow)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                
                
                ScrollView{
                    VStack(alignment: .leading, spacing: 15){
                        
                        ForEach(story, id: \.self){paragraph in
                            let attributedString = try? AttributedString(markdown: paragraph)
                            HTHText(markdowntitle: attributedString ?? "", font: HTHFont.space_grot)
                                .multilineTextAlignment(.leading)
                        }
                        
                        
                        ForEach(steps.indices, id: \.self){ i in
                            HStack(alignment: .top, spacing: 15){
                                Image(systemName: steps[i].0)
                                    .foregroundStyle(Color.white)
                                    .frame(width: 44, height: 44)
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                
                                
                                VStack(alignment: .leading, spacing: 10){
                                    HTHText(title: steps[i].1, font: HTHFont.space_grot)
                                    let attributedString = try? AttributedString(markdown: steps[i].2)
                                    HTHText(markdowntitle: attributedString ?? "", font: HTHFont.space_grot)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(.black.opacity(0.6))
                                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.gray, lineWidth: 1))
                            )
                        }
                    }
                }
                
                PrimaryButton(title: "GOT IT"){
                    store.state = .home
                }
                
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
