//
//  PhysicsScene.swift
//  physics-simulator-app
//
//  Created by Codex on 24.03.2026.
//

import SpriteKit
import UIKit

final class PhysicsScene: SKScene {
    struct Settings: Equatable {
        var bodyMass: CGFloat = 0.8
        var bodyFriction: CGFloat = 0.55
        var bodyRestitution: CGFloat = 0.35
        var linearDamping: CGFloat = 0.25
        var angularDamping: CGFloat = 0.35
        var emojiScale: CGFloat = 1
        var collisionScale: CGFloat = 0.64
    }

    private enum NodeMetricsKey {
        static let baseSize = "baseSize"
        static let baseRadius = "baseRadius"
    }

    private struct DragState {
        let node: SKNode
        let anchor: SKNode
        let joint: SKPhysicsJointSpring
        let startLocation: CGPoint
        let startTimestamp: TimeInterval
        var previousLocation: CGPoint
        var previousTimestamp: TimeInterval
    }

    private var hasConfiguredScene = false
    private var activeDrags: [ObjectIdentifier: DragState] = [:]
    private let maximumLinearVelocity: CGFloat = 900
    private let maximumAngularVelocity: CGFloat = 8
    private let releaseImpulseMultiplier: CGFloat = 0.018
    private let tapDistanceThreshold: CGFloat = 14
    private let tapDurationThreshold: TimeInterval = 0.22
    private let emojiPalette = ["😀", "😎", "🤖", "🐥", "🍎", "🌈", "⚽️", "🪐", "🍕", "🎈", "🧩", "🚀"]
    private(set) var settings = Settings()

    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        configureSceneIfNeeded()
    }

    func updateGravity(_ gravity: CGVector) {
        physicsWorld.gravity = gravity
    }

    func applySettings(_ settings: Settings) {
        self.settings = settings

        for node in children where node.name == "dynamicBody" {
            guard let sprite = node as? SKSpriteNode else { continue }
            applyDisplaySettings(to: sprite)
            applyPhysicsSettings(to: sprite)
        }
    }

    func applyImpulse(_ impulse: CGVector) {
        for node in children where node.name == "dynamicBody" {
            guard let body = node.physicsBody else { continue }

            body.applyImpulse(impulse)
            clampVelocity(for: body)
        }
    }

    func resetDemoBodies() {
        children.forEach { $0.removeFromParent() }
        addDemoBodies()
    }

    func spawnRandomBody() {
        guard size.width > 120, size.height > 180 else { return }

        let position = CGPoint(
            x: CGFloat.random(in: 60...(size.width - 60)),
            y: size.height - 90
        )

        let node: SKSpriteNode
        if Bool.random() {
            let radius = CGFloat.random(in: 22...38)
            node = makeCircle(radius: radius, position: position)
        } else {
            let bodySize = CGSize(
                width: CGFloat.random(in: 44...108),
                height: CGFloat.random(in: 44...108)
            )
            node = makeRectangle(size: bodySize, position: position)
        }

        addChild(node)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        updatePhysicsFrame()
        configureSceneIfNeeded()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            beginDragging(with: touch)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            updateDragging(with: touch)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            endDragging(with: touch)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            endDragging(with: touch)
        }
    }

    private func configureSceneIfNeeded() {
        guard size.width > 0, size.height > 0 else { return }

        updatePhysicsFrame()

        guard !hasConfiguredScene else { return }

        addDemoBodies()
        hasConfiguredScene = true
    }

    private func updatePhysicsFrame() {
        let frame = CGRect(origin: .zero, size: size)
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0.4
        physicsBody?.restitution = 0.6
    }

    private func addDemoBodies() {
        let bodies: [SKSpriteNode] = [
            makeCircle(radius: 26, position: CGPoint(x: size.width * 0.25, y: size.height * 0.78)),
            makeCircle(radius: 34, position: CGPoint(x: size.width * 0.72, y: size.height * 0.82)),
            makeRectangle(size: CGSize(width: 68, height: 68), position: CGPoint(x: size.width * 0.5, y: size.height * 0.72)),
            makeRectangle(size: CGSize(width: 110, height: 48), position: CGPoint(x: size.width * 0.34, y: size.height * 0.58)),
            makeRectangle(size: CGSize(width: 54, height: 120), position: CGPoint(x: size.width * 0.68, y: size.height * 0.62))
        ]

        for body in bodies {
            addChild(body)
        }
    }

    private func makeCircle(radius: CGFloat, position: CGPoint) -> SKSpriteNode {
        let node = makeEmojiNode(targetSize: CGSize(width: radius * 2, height: radius * 2))
        node.position = position
        applyPhysicsSettings(to: node)
        node.name = "dynamicBody"
        return node
    }

    private func makeRectangle(size: CGSize, position: CGPoint) -> SKSpriteNode {
        let node = makeEmojiNode(targetSize: size)
        node.position = position
        applyPhysicsSettings(to: node)
        node.name = "dynamicBody"
        return node
    }

    private func makeEmojiNode(targetSize: CGSize) -> SKSpriteNode {
        let emoji = emojiPalette.randomElement() ?? "🙂"
        let fontSize = max(targetSize.width, targetSize.height) * 0.95
        let texture = makeEmojiTexture(emoji: emoji, fontSize: fontSize)
        let node = SKSpriteNode(texture: texture)
        let textureSize = texture.size()
        node.size = textureSize
        node.userData = NSMutableDictionary()
        node.userData?[NodeMetricsKey.baseSize] = NSCoder.string(for: textureSize)
        node.userData?[NodeMetricsKey.baseRadius] = max(textureSize.width, textureSize.height) / 2
        applyDisplaySettings(to: node)
        return node
    }

    private func makeEmojiTexture(emoji: String, fontSize: CGFloat) -> SKTexture {
        let font = UIFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = (emoji as NSString).size(withAttributes: attributes)
        let canvasSize = CGSize(width: ceil(textSize.width + fontSize * 0.2), height: ceil(textSize.height + fontSize * 0.2))
        let origin = CGPoint(
            x: (canvasSize.width - textSize.width) / 2,
            y: (canvasSize.height - textSize.height) / 2
        )

        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        let image = renderer.image { _ in
            (emoji as NSString).draw(at: origin, withAttributes: attributes)
        }

        return SKTexture(image: image)
    }

    private func configurePhysics(for physicsBody: SKPhysicsBody?, allowsRotation: Bool) {
        physicsBody?.affectedByGravity = true
        physicsBody?.allowsRotation = allowsRotation
        physicsBody?.mass = settings.bodyMass
        physicsBody?.friction = settings.bodyFriction
        physicsBody?.restitution = settings.bodyRestitution
        physicsBody?.linearDamping = settings.linearDamping
        physicsBody?.angularDamping = settings.angularDamping
    }

    private func applyDisplaySettings(to node: SKSpriteNode) {
        guard
            let baseSizeString = node.userData?[NodeMetricsKey.baseSize] as? String
        else {
            return
        }

        let baseSize = NSCoder.cgSize(for: baseSizeString)
        node.size = CGSize(
            width: baseSize.width * settings.emojiScale,
            height: baseSize.height * settings.emojiScale
        )
    }

    private func applyPhysicsSettings(to node: SKSpriteNode) {
        let baseRadius = (node.userData?[NodeMetricsKey.baseRadius] as? CGFloat) ?? (max(node.size.width, node.size.height) / 2)
        let radius = max(8, baseRadius * settings.emojiScale * settings.collisionScale)
        let currentVelocity = node.physicsBody?.velocity
        let currentAngularVelocity = node.physicsBody?.angularVelocity ?? 0

        node.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        configurePhysics(for: node.physicsBody, allowsRotation: true)
        node.physicsBody?.velocity = currentVelocity ?? .zero
        node.physicsBody?.angularVelocity = currentAngularVelocity
    }

    private func clampVelocity(for physicsBody: SKPhysicsBody) {
        let velocity = physicsBody.velocity
        let speed = sqrt((velocity.dx * velocity.dx) + (velocity.dy * velocity.dy))

        guard speed > maximumLinearVelocity else { return }

        let scale = maximumLinearVelocity / speed
        physicsBody.velocity = CGVector(
            dx: velocity.dx * scale,
            dy: velocity.dy * scale
        )
        physicsBody.angularVelocity = min(
            max(physicsBody.angularVelocity, -maximumAngularVelocity),
            maximumAngularVelocity
        )
    }

    private func beginDragging(with touch: UITouch) {
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        let node = touchedNode.name == "dynamicBody" ? touchedNode : touchedNode.parent
        guard let node else { return }
        guard node.name == "dynamicBody", let body = node.physicsBody else { return }

        let anchor = SKNode()
        anchor.position = location
        anchor.physicsBody = SKPhysicsBody(circleOfRadius: 1)
        anchor.physicsBody?.isDynamic = false
        anchor.physicsBody?.affectedByGravity = false
        addChild(anchor)

        let joint = SKPhysicsJointSpring.joint(
            withBodyA: body,
            bodyB: anchor.physicsBody!,
            anchorA: location,
            anchorB: location
        )
        joint.damping = 9
        joint.frequency = 8
        physicsWorld.add(joint)

        body.angularVelocity = 0

        activeDrags[ObjectIdentifier(touch)] = DragState(
            node: node,
            anchor: anchor,
            joint: joint,
            startLocation: location,
            startTimestamp: touch.timestamp,
            previousLocation: location,
            previousTimestamp: touch.timestamp
        )
    }

    private func updateDragging(with touch: UITouch) {
        let touchID = ObjectIdentifier(touch)
        guard var dragState = activeDrags[touchID] else { return }

        let location = touch.location(in: self)
        dragState.anchor.position = location
        dragState.previousLocation = location
        dragState.previousTimestamp = touch.timestamp
        activeDrags[touchID] = dragState
    }

    private func endDragging(with touch: UITouch) {
        let touchID = ObjectIdentifier(touch)
        guard let dragState = activeDrags.removeValue(forKey: touchID) else { return }

        let currentLocation = touch.location(in: self)
        let totalDistance = hypot(
            currentLocation.x - dragState.startLocation.x,
            currentLocation.y - dragState.startLocation.y
        )
        let totalDuration = touch.timestamp - dragState.startTimestamp
        let previousLocation = touch.previousLocation(in: self)
        let timeDelta = max(touch.timestamp - dragState.previousTimestamp, 1.0 / 120.0)
        let velocity = CGVector(
            dx: (currentLocation.x - previousLocation.x) / timeDelta,
            dy: (currentLocation.y - previousLocation.y) / timeDelta
        )

        physicsWorld.remove(dragState.joint)
        dragState.anchor.removeFromParent()

        if totalDistance <= tapDistanceThreshold, totalDuration <= tapDurationThreshold {
            pop(node: dragState.node)
            return
        }

        if let body = dragState.node.physicsBody {
            body.applyImpulse(
                CGVector(
                    dx: velocity.dx * releaseImpulseMultiplier,
                    dy: velocity.dy * releaseImpulseMultiplier
                )
            )
            clampVelocity(for: body)
        }
    }

    private func pop(node: SKNode) {
        node.physicsBody = nil

        let group = SKAction.group([
            .scale(to: 1.35, duration: 0.12),
            .fadeOut(withDuration: 0.12)
        ])
        let remove = SKAction.removeFromParent()
        node.run(.sequence([group, remove]))
    }
}
