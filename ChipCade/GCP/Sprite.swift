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
    var priority: Int = 0
    
    var velocity: CGVector = CGVector(dx: 0, dy: 0)
    var speed: CGFloat = 0.0
    
    var imageGroup: ImageGroup? = nil
    var currentImageIndex: Int = 0 // Current image index for display or animation

    // Collision flag and data
    var collisionFlag: Bool = false
    var collidedWithSpriteIndex: Int? = nil
    
    // Animation properties
    var isAnimating: Bool = false
    var animationSpeed: Double = 1.0
    var animationRange: Range<Int>? = nil

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

    // Method to start or stop animation
    func startAnimation(range: Range<Int>, speed: Double) {
        self.animationRange = range
        self.animationSpeed = speed
        self.isAnimating = true
    }
    
    func stopAnimation() {
        self.isAnimating = false
        self.animationRange = nil
    }
    
    // Update position based on velocity and direction
    func updatePosition() {
        position.x += velocity.dx
        position.y += velocity.dy
    }
    
    // Update velocity based on speed and direction (rotation in degrees)
    func updateVelocity() {
        let radians = -rotation * .pi / 180 // Convert degrees to radians
        velocity.dx = cos(radians) * speed
        velocity.dy = sin(radians) * speed
    }
}
