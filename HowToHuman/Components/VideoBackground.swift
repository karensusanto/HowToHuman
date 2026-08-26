//
//  VideoBackground.swift
//  HowToHuman
//
//  Created by Cho on 24/08/26.
//

import SwiftUI
import AVFoundation

final class PlayerContainerView: UIView {
    private let playerLayer = AVPlayerLayer()

    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

// Fills its frame with a silently-playing, control-less video (AVPlayerLayer, not AVKit's
// VideoPlayer, which shows playback controls we don't want here).
struct VideoBackground: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        PlayerContainerView(player: player)
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {}
}
