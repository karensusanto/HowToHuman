//
//  Text.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 19/08/26.
//

import SwiftUI

struct HTHSize{
    static let largestTitle : CGFloat = 40
    static let extraLargeTitle : CGFloat = 32
    static let largeTitle : CGFloat = 25
    static let title : CGFloat = 24
    static let smallTitle : CGFloat = 22
    static let smallerTitle : CGFloat = 20
    static let body : CGFloat = 16
    static let caption : CGFloat = 12
}

struct HTHFont{
    static let slackey : String = "Slackey-Regular"
    static let space_grot : String = "SpaceGrotesk-Light"
}

struct HTHText: View {
    var title: String = ""
    @State var markdowntitle: AttributedString = AttributedString("")
    @State var size: CGFloat = HTHSize.body
    @State var font: String = HTHFont.slackey
    @State var weight: Font.Weight = .regular
    var color: Color = Color.white
    
    var body: some View {
        
        if title == ""{
            Text(markdowntitle)
                .font(.custom(font, size: size))
                .fontWeight(weight)
                .foregroundStyle(color)
        }
        else{
            Text(title)
                .font(.custom(font, size: size))
                .fontWeight(weight)
                .foregroundStyle(color)
        }
        
    }
}
