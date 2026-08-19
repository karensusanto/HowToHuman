//
//  Avatar.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 14/08/26.
//

import SwiftUI

class AlienAvatar{
    static var allCases: [String] = ["alien-placeholder", "alien-placeholder-2"]
}

struct Avatar: View {
    let avatar: String
    @State private var floating: Bool = false
    var size: CGFloat = 56
    var selected: Bool = false
    
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white,
                              lineWidth: selected ? 2.5 : 0)
            
            Image(avatar)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.5)
                .offset(y: floating ? 1.5 : -1.5)
//            Text(avatar)
//                .font(.system(size: size * 0.5))
//                .offset(y: floating ? -1.5 : 1.5)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: Double.random(in: 1.8...2.6)).repeatForever(autoreverses: true)) {
                floating = true
            }
        }
    }
}

struct AvatarGridView: View {
    @Binding var selectedAvatar: String
    @State var listOfAvatars: [String] = AlienAvatar.allCases
    let columns = [
        GridItem(.adaptive(minimum: 65))
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(listOfAvatars, id: \.self){avatar in
                Button{selectedAvatar = avatar}
                label:{
                    Avatar(avatar: avatar, selected: selectedAvatar == avatar)
                }
            }
        }
    }
}

#Preview {
    Avatar(avatar: AlienAvatar.allCases.randomElement() ?? "")
}
