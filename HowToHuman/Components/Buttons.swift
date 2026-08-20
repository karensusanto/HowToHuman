//
//  Buttons.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//

import SwiftUI

struct BackButton: View {
    @EnvironmentObject var store: GameStore
    @State var toState: AppState
    
    var body: some View {
        Button{ store.state = toState }label:{
            Image(systemName: "chevron.left")
                .foregroundStyle(Color.white)
                .padding()
        }
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
    }
}
struct ExitRoomButton: View {
    @EnvironmentObject var store: GameStore
    
    var body: some View {
        Button{ store.showExitRoomPopUp = true }label:{
            Image(systemName: "door.left.hand.open")
                .foregroundStyle(Color.white)
                .padding()
        }
        .clipShape(Circle())
//        .overlay(
//            Circle()
//                .stroke(Color.white.opacity(0.6), lineWidth: 1)
//        )
    }
}

struct PrimaryButton: View {
    let title: String
    @State var size: CGFloat = 32
    @State var btnHeight: CGFloat = 56
    var isDisabled: Bool = false
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            HTHText(title: title, size: size)
            
        }
        .frame(maxWidth: .infinity)
        .frame(height: btnHeight)
        .foregroundStyle(Color.white)
        .background(
            GeometryReader { geometry in
                ZStack{
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isDisabled ? Color.white.opacity(0.3) : HTHColor.purple)
                    HStack{
                        Spacer()
                        let rotation = -65.78
                        let bigShadowHeight = 46.43
                        let smallShadowHeight = 7.75
                        let shadowWidth = btnHeight + 30
                        let shadowAreaWidth = geometry.size.width * 0.5
                        let spacing = CGFloat((btnHeight - 30) * -1)
                        
                        HStack(spacing: spacing){
                            Rectangle().fill(Color.white.opacity(0.3)).rotationEffect(.degrees(rotation)).frame(width: shadowWidth, height: bigShadowHeight)
                            Rectangle().fill(Color.white.opacity(0.3)).rotationEffect(.degrees(rotation)).frame(width: shadowWidth, height: smallShadowHeight)
                            Rectangle().fill(Color.white.opacity(0.3)).rotationEffect(.degrees(rotation)).frame(width: shadowWidth, height: bigShadowHeight)
                        }.frame(width: shadowAreaWidth, height: btnHeight)
                    }.clipped()
                }
            }
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .opacity(isDisabled ? 0.6 : 1.0)
        .disabled(isDisabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.easeOut(duration: 0.15), value: isPressed)
        .shadow(
            color: HTHColor.purple.opacity(0.3),
            radius: 30
        )
    }
}

#Preview {
    VStack{
        PrimaryButton(title: "Create a Room"){
            
        }
    }.padding()
}

struct SecondaryButton: View {
    let title: String
    @State var size: CGFloat = 25
    @State var btnHeight: CGFloat = 56
    var isDisabled: Bool = false
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            HTHText(title: title, size: size)
            
        }
        .frame(maxWidth: .infinity)
        .frame(height: btnHeight)
        .foregroundStyle(Color.white)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.3))
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .opacity(isDisabled ? 0.6 : 1.0)
        .disabled(isDisabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.easeOut(duration: 0.15), value: isPressed)
    }
}


struct OpenSettingButton: View {
    var action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "gear")
            
        }
        .frame(maxWidth: 72)
        .frame(height: 72)
        .foregroundStyle(Color.white)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AnyShapeStyle(HTHColor.purple))
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.easeOut(duration: 0.15), value: isPressed)
    }
}
