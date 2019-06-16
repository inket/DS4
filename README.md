# DS4

This library can be added to any app to support the DualShock 4 controller under iOS 12 (and earlier versions probably)

Note: You probably don't need this since DS4 support is official in iOS 13

Technical information: Library links with IOKit (which is private on iOS) and assumes whatever is connected is a DS4 (iOS doesn't let us see the vendor/model information)

Usage: Add into app and use UnofficialController.controllers instead of GCController.controllers

Note: Controller has to be connected via USB.

Working proof with [Provenance](https://github.com/Provenance-Emu/Provenance): https://youtu.be/YtmhrpnyNlE
