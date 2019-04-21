//
//  ViewController.swift
//  DS4Prototype
//
//  Created by inket on 20/04/2019.
//  Copyright © 2019 Mahdi Bchatnia. All rights reserved.
//

import UIKit
import IOSDS4

class ViewController: UIViewController {
    let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        textView.text = "Ready."

        DS4Controller.listen()
        let controller = UnofficialController.controllers().first as? DS4Controller

        controller?.gamepad.valueChangedHandler = { gamepad, element in
            self.textView.text = self.textView.text.appending("\ngamepad")
        }

        controller?.extendedGamepad.valueChangedHandler = { gamepad, element in
            self.textView.text = self.textView.text.appending("\nextendedGamepad")
        }

        controller?.extendedGamepad.rightTrigger.valueChangedHandler = { input, value, pressed in
            self.textView.text = self.textView.text.appending("\nright trigger \(value) \(pressed)")
        }

        controller?.extendedGamepad.leftTrigger.valueChangedHandler = { input, value, pressed in
            self.textView.text = self.textView.text.appending("\nleft trigger \(value) \(pressed)")
        }
    }
}

