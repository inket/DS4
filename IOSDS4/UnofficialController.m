//
//  UnofficialController.m
//  IOSDS4
//
//  Created by inket on 21/04/2019.
//  Copyright © 2019 Mahdi Bchatnia. All rights reserved.
//

#import "UnofficialController.h"
#import "DS4Controller.h"

static NSMutableArray *additionalControllers = nil;

@implementation UnofficialController

static void
ActivateController(GCController *controller)
{
    NSLog(@"Activating controller: %@", controller);
    NSLog(@"    VendorName: %@", controller.vendorName);

//    controller.playerIndex = 0;

    controller.controllerPausedHandler = ^(GCController *controller){
        NSLog(@"Pause button.");
    };

//    controller.gamepad.valueChangedHandler = ^(GCGamepad *gamepad, GCControllerElement *element){
//        NSLog(@"DPad: (% .1f, % .1f), RS: %d, LS: %d, A: %d, B: %d, X: %d, Y: %d",
//              gamepad.dpad.xAxis.value, gamepad.dpad.yAxis.value,
//              gamepad.leftShoulder.pressed, gamepad.rightShoulder.pressed,
//              gamepad.buttonA.pressed, gamepad.buttonB.pressed, gamepad.buttonX.pressed, gamepad.buttonY.pressed
//              );
//    };
//
//    controller.extendedGamepad.valueChangedHandler = ^(GCExtendedGamepad *gamepad, GCControllerElement *element){
//        NSLog(@"test");
////        NSLog(@"L: (% .1f, % .1f), R: (% .1f, % .1f), DPad: (% .1f, % .1f), LT: %.1f, RT: %.1f, RS: %d, LS: %d, A: %d, B: %d, X: %d, Y: %d",
////              gamepad.leftThumbstick.xAxis.value, gamepad.leftThumbstick.yAxis.value,
////              gamepad.rightThumbstick.xAxis.value, gamepad.rightThumbstick.yAxis.value,
////              gamepad.dpad.xAxis.value, gamepad.dpad.yAxis.value,
////              gamepad.leftTrigger.value, gamepad.rightTrigger.value,
////              gamepad.leftShoulder.pressed, gamepad.rightShoulder.pressed,
////              gamepad.buttonA.pressed, gamepad.buttonB.pressed, gamepad.buttonX.pressed, gamepad.buttonY.pressed
////              );
//    };

    __block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidDisconnectNotification object:controller queue:nil usingBlock:^(NSNotification *notification){
        NSLog(@"Deactivating controller: %@", notification.object);
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }];
}

+ (void)registerController:(GCController *)controller {
    if (!additionalControllers) {
        additionalControllers = [NSMutableArray array];
    }

    [additionalControllers addObject:controller];
    [[NSNotificationCenter defaultCenter] postNotificationName:GCControllerDidConnectNotification object:controller];
}

+ (void)unregisterController:(GCController *)controller {
    [additionalControllers removeObject:controller];
    [[NSNotificationCenter defaultCenter] postNotificationName:GCControllerDidDisconnectNotification object:controller];
}

+ (NSArray<GCController *> *)controllers {
    if (additionalControllers) {
        return [[super controllers] arrayByAddingObjectsFromArray:additionalControllers];
    } else {
        return [super controllers];
    }
}

@end
