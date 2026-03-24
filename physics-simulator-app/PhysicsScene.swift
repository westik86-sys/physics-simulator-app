//
//  PhysicsScene.swift
//  physics-simulator-app
//
//  Created by Codex on 24.03.2026.
//

import SpriteKit
import UIKit

final class PhysicsScene: SKScene {
    private struct DragState {
        let node: SKNode
        let anchor: SKNode
        let joint: SKPhysicsJointSpring
        var previousLocation: CGPoint
        var previousTimestamp: TimeInterval
    }

    private var hasConfiguredScene = false
    private var activeDrags: [ObjectIdentifier: DragState] = [:]
    private let maximumLinearVelocity: CGFloat = 900
    private let maximumAngularVelocity: CGFloat = 8
    private let releaseImpulseMultiplier: CGFloat = 0.018
    private let emojiPalette = ["😀", "😎", "🤖", "🐥", "🍎", "🌈", "⚽️", "🪐", "🍕", "🎈", "🧩", "🚀"]

    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        configureSceneIfNeeded()
    }

    func updateGravity(_ gravity: CGVector) {
        physicsWorld.gravity = gravity
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
        node.physicsBody = SKPhysicsBody(circleOfRadius: max(node.size.width, node.size.height) * 0.32)
        configurePhysics(for: node.physicsBody, allowsRotation: true)
        node.name = "dynamicBody"
        return node
    }

    private func makeRectangle(size: CGSize, position: CGPoint) -> SKSpriteNode {
        let node = makeEmojiNode(targetSize: size)
        node.position = position
        node.physicsBody = SKPhysicsBody(circleOfRadius: max(node.size.width, node.size.height) * 0.32)
        configurePhysics(for: node.physicsBody, allowsRotation: true)
        node.name = "dynamicBody"
        return node
    }

    private func makeEmojiNode(targetSize: CGSize) -> SKSpriteNode {
        let emoji = emojiPalette.randomElement() ?? "🙂"
        let fontSize = max(targetSize.width, targetSize.height) * 0.95
        let texture = makeEmojiTexture(emoji: emoji, fontSize: fontSize)
        let node = SKSpriteNode(texture: texture)
        node.size = texture.size()
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
        physicsBody?.mass = 0.8
        physicsBody?.friction = 0.55
        physicsBody?.restitution = 0.35
        physicsBody?.linearDamping = 0.25
        physicsBody?.angularDamping = 0.35
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
        guard let node = atPoint(location) as? SKNode ?? atPoint(location).parent else {
            return
        }
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
        let previousLocation = touch.previousLocation(in: self)
        let timeDelta = max(touch.timestamp - dragState.previousTimestamp, 1.0 / 120.0)
        let velocity = CGVector(
            dx: (currentLocation.x - previousLocation.x) / timeDelta,
            dy: (currentLocation.y - previousLocation.y) / timeDelta
        )

        physicsWorld.remove(dragState.joint)
        dragState.anchor.removeFromParent()

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
}
