//
//  Sprite.swift
//  CHIPcade
//
//  Created by Markus Moenig on 7/10/24.
//

import Foundation

class Sprite {
    
    // The sprite index in the global array
    let index: Int
    
    // The associted layer (if any)
    var layer: Int? = nil
    
    var position: CGPoint = CGPoint(x: 0, y: 0)
    var size: CGSize = CGSize(width: 32, height: 32)
    var rotation: CGFloat = 0.0
    var scale: CGFloat = 1.0
    
    var isVisible: Bool = false
    var isWrapped: Bool = false
    
    var priority: Int = 0
    
    var velocity: CGVector = CGVector(dx: 0, dy: 0)
    
    var acceleration: CGFloat = 0.0
    
    var speed: CGFloat = 0.0
    var maxSpeed: CGFloat = 3.0

    var friction: CGFloat = 1.0

    var imageGroup: ImageGroup? = nil
    var currentImageIndex: Int = 0 // Current image index for display or animation

    // Collision
    var collisionGroupIndex: Int = 0
    var collisionFlag: Bool = false
    var collidedWithSpriteIndex: Int? = nil
    
    // Animation properties
    var isAnimating: Bool = false
    var animationSpeed: Float = 10.0
    var animationRange: ClosedRange<Int> = 0...1
    var timeSinceLastFrame: Float = 0.0

    // Initialization
    init(index: Int) {
        self.index = index
    }
    
    // Method to set the current image based on the index
    func setCurrentImage(index: Int) {
        if let imageGroup = imageGroup {
            guard index >= 0 && index < imageGroup.images.count else { return }
            currentImageIndex = index
        }
    }

    // setVisible
    func setVisibility(visible: Bool) {
        isVisible = visible
    }
    
    // Method to check for collision (placeholder for collision logic)
    func checkCollision(with otherSprite: Sprite) -> Bool {
        // Collision logic (simple bounding box for now)
        let rect1 = CGRect(origin: self.position, size: self.size)
        let rect2 = CGRect(origin: otherSprite.position, size: otherSprite.size)
        if rect1.intersects(rect2) {
            self.collisionFlag = true
            self.collidedWithSpriteIndex = otherSprite.index
            return true
        }
        self.collisionFlag = false
        self.collidedWithSpriteIndex = nil
        return false
    }
    
    func setRotation(_ rotation: Float) {
        self.rotation = CGFloat(rotation)
        if speed != 0.0 {
            updateVelocity()
        }
    }
    
    // Update position based on velocity and direction
    func updatePosition() {
        applyFriction()
        position.x += velocity.dx
        position.y += velocity.dy
    }
    
    // Update velocity based on speed and direction (rotation in degrees)
    func updateVelocity() {
        let radians = (rotation - 90) * .pi / 180 // Convert degrees to radians
        velocity.dx = cos(radians) * speed
        velocity.dy = sin(radians) * speed
    }
    
    // Apply friction
    func applyFriction() {
        velocity.dx *= friction
        velocity.dy *= friction
    }
    
    // Apply an acceleration impulse
    func applyAccelerationImpulse() {
        // Convert rotation to radians
        let radians = (rotation - 90) * .pi / 180

        // Calculate acceleration components based on current rotation
        let accelX = cos(radians) * acceleration
        let accelY = sin(radians) * acceleration

        // Add the acceleration to the current velocity
        velocity.dx += accelX
        velocity.dy += accelY

        // Cap the speed to maxSpeed
        let currentSpeed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        if currentSpeed > maxSpeed {
            velocity.dx = (velocity.dx / currentSpeed) * maxSpeed
            velocity.dy = (velocity.dy / currentSpeed) * maxSpeed
        }
    }
}
