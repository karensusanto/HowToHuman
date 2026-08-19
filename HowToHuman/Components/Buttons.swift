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
//    var isLoading: Bool = false
    var isDisabled: Bool = false
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
            
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .foregroundStyle(Color.black)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isDisabled ? AnyShapeStyle(Color.gray) : AnyShapeStyle(Color.blue))
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


struct SecondaryButton: View {
    let title: String
//    var isLoading: Bool = false
    var isDisabled: Bool = false
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
            
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .foregroundStyle(Color.white)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.gray, lineWidth: 1.5)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.black.opacity(0.6)))
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
//    var isLoading: Bool = false
    var action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "gear")
            
        }
        .frame(maxWidth: 54)
        .frame(height: 54)
        .foregroundStyle(Color.white)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.gray, lineWidth: 1.5)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.black.opacity(0.6)))
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
