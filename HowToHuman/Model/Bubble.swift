//
//  Bubble.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 18/08/26.
//
import SwiftUI

struct Bubble: Identifiable, Codable {
    let assetName: String
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
    var scale: CGFloat
    var sender: UUID
}

func createBubble(assetName: String, store: GameStore) {
    let id = UUID()

    let bubble = Bubble(
        assetName: assetName,
        id: id,
        x: CGFloat.random(in: -30...30),
        y: 0,
        opacity: 1, scale: 1.5,
        sender: store.networkManager.myPeerId
    )
    
    showReaction(bubble, store: store)
    store.sendReaction(bubble: bubble)
}

func showReaction(_ bubble: Bubble, store: GameStore) {
    let id = bubble.id

    store.bubbles.append(bubble)

    withAnimation(.easeOut(duration: 1.2)) {
        if let index = store.bubbles.firstIndex(where: { $0.id == id }) {
            store.bubbles[index].y = -150
            store.bubbles[index].opacity = 0
        }
    }

    DispatchQueue.main.asyncAfter(
        deadline: .now() + 1.2,
        execute: {
            store.bubbles.removeAll { $0.id == id }
        }
    )
}
