//
//  VirtualController.swift
//  CHIPcade
//
//  Created by Markus Moenig on 28/10/24.
//

import SwiftUI
import GameController

/*
//#if os(iOS)

class GameControllerManager: ObservableObject {
    @Published var direction: String = "Center"
    @Published var isFiring: Bool = false

    init() {
        // Set up controller observers
        setupControllerObservers()
        
        // Connect existing controllers
        connectControllers()
    }

    // Set up observers for controller connection and disconnection
    private func setupControllerObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(controllerConnected),
                                               name: .GCControllerDidConnect,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(controllerDisconnected),
                                               name: .GCControllerDidDisconnect,
                                               object: nil)
    }

    // Connect to a newly connected controller
    @objc private func controllerConnected(notification: Notification) {
        connectControllers()
    }

    // Handle controller disconnection
    @objc private func controllerDisconnected(notification: Notification) {
        direction = "Center"
        isFiring = false
    }

    // Connect to available controllers and set up input handlers
    private func connectControllers() {
        for controller in GCController.controllers() {
            setupInputHandlers(for: controller)
        }
    }

    // Set up input handlers for the given controller
    private func setupInputHandlers(for controller: GCController) {
        guard let gamepad = controller.extendedGamepad else { return }

        // Handle thumbstick input
        gamepad.leftThumbstick.valueChangedHandler = { [weak self] thumbstick, xValue, yValue in
            guard let self = self else { return }
            
            if xValue < -0.5 {
                self.direction = "Left"
            } else if xValue > 0.5 {
                self.direction = "Right"
            } else if yValue > 0.5 {
                self.direction = "Up"
            } else if yValue < -0.5 {
                self.direction = "Down"
            } else {
                self.direction = "Center"
            }
        }

        // Handle D-pad input
        gamepad.dpad.valueChangedHandler = { [weak self] dpad, xValue, yValue in
            guard let self = self else { return }
            
            if dpad.left.isPressed {
                self.direction = "Left"
            } else if dpad.right.isPressed {
                self.direction = "Right"
            } else if dpad.up.isPressed {
                self.direction = "Up"
            } else if dpad.down.isPressed {
                self.direction = "Down"
            } else {
                self.direction = "Center"
            }
        }

        // Handle button A for "Fire"
        gamepad.buttonA.pressedChangedHandler = { [weak self] button, _, pressed in
            guard let self = self else { return }
            self.isFiring = pressed
        }
    }
}

//#endif
*/
