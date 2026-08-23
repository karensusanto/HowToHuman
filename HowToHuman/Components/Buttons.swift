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
                .foregroundStyle(Color.white).bold()
                .font(.system(size: HTHSize.smallerTitle))
                .padding()
        }
        .clipShape(Circle())
        .background(
            Circle()
                .fill(HTHColor.purple)
        )
    }
}
struct ExitRoomButton: View {
    @EnvironmentObject var store: GameStore
    
    var body: some View {
        Button{ store.showExitRoomPopUp = true }label:{
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .scaleEffect(x: -1, y: 1)
                .foregroundStyle(Color.white).bold()
                .font(.system(size: HTHSize.smallerTitle))
                .padding()
        }
        .clipShape(Circle())
        .background(
            Circle()
                .fill(HTHColor.purple)
        )
    }
}

struct ReadyButton: View {
    @EnvironmentObject var store: GameStore
    @Binding var readyMsgSubmitted: Bool
    @Binding var isReady: Bool
    
    var body: some View {
        PrimaryButton(title: "Ready", isDisabled: !isReady || readyMsgSubmitted) {
            if readyMsgSubmitted {
                store.sendReadyStatus(false)
            }
            else{
                store.sendReadyStatus(true)
            }
            readyMsgSubmitted.toggle()
        }
    }
}

struct PrimaryButton: View {
    let title: String
    @State var size: CGFloat = 32
    @State var btnHeight: CGFloat = 56
    var isDisabled: Bool = false
    var btnColor: Color = HTHColor.purple
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
                        .fill(isDisabled ? Color.white.opacity(0.3) : btnColor)
                    HStack{
                        Spacer()
                        Image("button-reflection").resizable().frame(width: geometry.size.width * 0.5, height: btnHeight)
                    }
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
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
            color: btnColor.opacity(0.3),
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

//struct SecondaryButton: View {
//    let title: String
//    @State var size: CGFloat = 25
//    @State var btnHeight: CGFloat = 56
//    var isDisabled: Bool = false
//    var action: () -> Void
//
//    @State private var isPressed = false
//
//    var body: some View {
//        Button {
//            action()
//        } label: {
//            HTHText(title: title, size: size)
//            
//        }
//        .frame(maxWidth: .infinity)
//        .frame(height: btnHeight)
//        .foregroundStyle(Color.white)
//        .background(
//            RoundedRectangle(cornerRadius: 16, style: .continuous)
//                .fill(Color.white.opacity(0.3))
//        )
//        .scaleEffect(isPressed ? 0.97 : 1.0)
//        .opacity(isDisabled ? 0.6 : 1.0)
//        .disabled(isDisabled)
//        .simultaneousGesture(
//            DragGesture(minimumDistance: 0)
//                .onChanged { _ in isPressed = true }
//                .onEnded { _ in isPressed = false }
//        )
//        .animation(.easeOut(duration: 0.15), value: isPressed)
//    }
//}


struct OpenSettingButton: View {
    var action: () -> Void
    
    @State private var isPressed = false
    let btnWidth: CGFloat = 72
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "timer").font(.custom(HTHFont.slackey, size: 32))
        }
        .frame(maxWidth: btnWidth)
        .frame(height: btnWidth)
        .foregroundStyle(Color.white)
        .background(
            ZStack{
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(HTHColor.purple)
                HStack{
                    Spacer()
                    Image("button-reflection").resizable().frame(width: btnWidth * 0.5, height: btnWidth)
                }
            }
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
