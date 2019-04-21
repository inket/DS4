//
//  AppDelegate.swift
//  DS4PrototypeMac
//
//  Created by inket on 21/04/2019.
//  Copyright © 2019 Mahdi Bchatnia. All rights reserved.
//

import Cocoa
import MacDS4

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        DS4Controller.listen()
        let controller = UnofficialController.controllers().first as? DS4Controller

        controller?.gamepad.valueChangedHandler = { gamepad, element in
            debugPrint("gamepad")
        }

        controller?.extendedGamepad.valueChangedHandler = { gamepad, element in
            debugPrint("extendedGamepad")
        }

        controller?.extendedGamepad.rightTrigger.valueChangedHandler = { input, value, pressed in
            debugPrint("right trigger \(value) \(pressed)")
        }

        controller?.extendedGamepad.leftTrigger.valueChangedHandler = { input, value, pressed in
            debugPrint("left trigger \(value) \(pressed)")
        }
    }
}

