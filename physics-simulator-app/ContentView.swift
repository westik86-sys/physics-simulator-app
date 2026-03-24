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
    @State private var isShowingSettings = false
    @State private var sceneSettings = PhysicsScene.Settings()

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
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
        }
        .onAppear {
            motionManager.startUpdates()
            scene.applySettings(sceneSettings)
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
        .sheet(isPresented: $isShowingSettings) {
            SettingsSheet(settings: $sceneSettings)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: sceneSettings) { newValue in
            scene.applySettings(newValue)
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

            controlButton(title: "Settings") {
                isShowingSettings = true
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

}

private struct SettingsSheet: View {
    @Binding var settings: PhysicsScene.Settings

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    settingsGroup(
                        title: "Physics",
                        rows: [
                            sliderRow(title: "Mass", value: $settings.bodyMass, range: 0.2...2, step: 0.05),
                            sliderRow(title: "Friction", value: $settings.bodyFriction, range: 0...1, step: 0.01),
                            sliderRow(title: "Bounce", value: $settings.bodyRestitution, range: 0...1, step: 0.01),
                            sliderRow(title: "Linear Damping", value: $settings.linearDamping, range: 0...1.2, step: 0.01),
                            sliderRow(title: "Angular Damping", value: $settings.angularDamping, range: 0...1.2, step: 0.01)
                        ]
                    )

                    settingsGroup(
                        title: "Emoji",
                        rows: [
                            sliderRow(title: "Emoji Size", value: $settings.emojiScale, range: 0.6...1.6, step: 0.01),
                            sliderRow(title: "Collision Size", value: $settings.collisionScale, range: 0.36...0.9, step: 0.01)
                        ]
                    )
                }
                .padding(20)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }

    private func settingsGroup(title: String, rows: [AnyView]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            VStack(spacing: 14) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    row
                }
            }
            .padding(16)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private func sliderRow(title: String, value: Binding<CGFloat>, range: ClosedRange<CGFloat>, step: CGFloat) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(Double(value.wrappedValue).formatted(.number.precision(.fractionLength(2))))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Slider(
                    value: Binding(
                        get: { Double(value.wrappedValue) },
                        set: { value.wrappedValue = CGFloat($0) }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound),
                    step: Double(step)
                )
                .tint(.white)
            }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
