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
