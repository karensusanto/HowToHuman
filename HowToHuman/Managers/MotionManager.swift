//
//  MotionManager.swift
//  HowToHuman
//
//  Created by Karen Regina Susanto on 21/08/26.
//

import SwiftUI
import CoreMotion
import Combine

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    
    // Publishes the continuous X and Y offset values to the view
    @Published var pitch: Double = 0.0 // Tilting forward/backward (Y-axis)
    @Published var roll: Double = 0.0  // Tilting left/right (X-axis)
    
    func startUpdates() {
        // Verify the device actually has an accelerometer/gyroscope
        guard motionManager.isDeviceMotionAvailable else { return }
        
        // Update 60 times per second for maximum smoothness
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            
            // Apply a multiplier to make the subtle tilt visible
            let sensitivity: Double = 30.0
            
            // Animate the transitions so the movement doesn't look jittery
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.6)) {
                self?.pitch = data.attitude.pitch * sensitivity
                self?.roll = data.attitude.roll * sensitivity
            }
        }
    }
    
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}
