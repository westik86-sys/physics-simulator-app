//
//  MotionManager.swift
//  physics-simulator-app
//
//  Created by Codex on 24.03.2026.
//

import Combine
import CoreMotion
import Foundation

@MainActor
final class MotionManager: ObservableObject {
    @Published private(set) var gravityVector = CGVector(dx: 0, dy: -9.8)
    @Published private(set) var shakeImpulse: CGVector?
    @Published private(set) var accelerationMagnitude: Double = 0
    @Published private(set) var lastShakeMagnitude: Double = 0

    private let motionManager = CMMotionManager()
    private let updateInterval = 1.0 / 60.0
    private let gravityScale = 14.0
    private let smoothingFactor = 0.18
    private let shakeDetectionThreshold = 1.35
    private let shakeImpulseScale = 0.22
    private let minimumShakeInterval = 0.18

    private var lastShakeDate = Date.distantPast

    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        guard !motionManager.isDeviceMotionActive else { return }

        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }

            let gravity = motion.gravity

            let targetVector = CGVector(
                dx: gravity.x * self.gravityScale,
                dy: gravity.y * self.gravityScale
            )

            self.gravityVector = self.interpolate(
                from: self.gravityVector,
                to: targetVector
            )

            self.processShakeIfNeeded(from: motion.userAcceleration)
        }
    }

    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
        shakeImpulse = nil
        accelerationMagnitude = 0
    }

    private func interpolate(from current: CGVector, to target: CGVector) -> CGVector {
        CGVector(
            dx: current.dx + (target.dx - current.dx) * smoothingFactor,
            dy: current.dy + (target.dy - current.dy) * smoothingFactor
        )
    }

    private func processShakeIfNeeded(from acceleration: CMAcceleration) {
        let magnitude = sqrt(
            acceleration.x * acceleration.x +
            acceleration.y * acceleration.y +
            acceleration.z * acceleration.z
        )

        accelerationMagnitude = magnitude

        guard magnitude > shakeDetectionThreshold else { return }

        let now = Date()
        guard now.timeIntervalSince(lastShakeDate) > minimumShakeInterval else { return }

        lastShakeDate = now
        lastShakeMagnitude = magnitude
        shakeImpulse = CGVector(
            dx: acceleration.x * gravityScale * shakeImpulseScale,
            dy: acceleration.y * gravityScale * shakeImpulseScale
        )
    }
}
