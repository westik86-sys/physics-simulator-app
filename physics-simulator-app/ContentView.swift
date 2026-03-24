//
//  ContentView.swift
//  physics-simulator-app
//
//  Created by Павел Коростелев on 24.03.2026.
//

import Combine
import SpriteKit
import SwiftUI

struct ContentView: View {
    @StateObject private var motionManager = MotionManager()

    private let scene: PhysicsScene = {
        let scene = PhysicsScene()
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .background(.black)

            VStack(spacing: 12) {
                controlsBar
                debugPanel
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
        }
        .onAppear {
            motionManager.startUpdates()
        }
        .onDisappear {
            motionManager.stopUpdates()
        }
        .onReceive(motionManager.$gravityVector) { gravityVector in
            scene.updateGravity(gravityVector)
        }
        .onReceive(motionManager.$shakeImpulse.compactMap { $0 }) { impulse in
            scene.applyImpulse(impulse)
        }
    }

    private var controlsBar: some View {
        HStack(spacing: 12) {
            controlButton(title: "Reset") {
                scene.resetDemoBodies()
            }

            controlButton(title: "Spawn") {
                scene.spawnRandomBody()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var debugPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            debugRow(title: "Gravity X", value: motionManager.gravityVector.dx)
            debugRow(title: "Gravity Y", value: motionManager.gravityVector.dy)
            debugRow(title: "Accel", value: motionManager.accelerationMagnitude)
            debugRow(title: "Last Shake", value: motionManager.lastShakeMagnitude)
        }
        .font(.system(size: 13, weight: .medium, design: .monospaced))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func controlButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.white.opacity(0.12), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            )
    }

    private func debugRow(title: String, value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value.formatted(.number.precision(.fractionLength(2))))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
