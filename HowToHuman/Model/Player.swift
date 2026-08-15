//
//  Player.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 13/08/26.
//
import Foundation
import SwiftUI

struct Player: Codable {
    let id: Int
    let name: String
    let avatar: String
}

extension Player {
    var avatarImage: Image {
        Image(avatar)
    }
}
