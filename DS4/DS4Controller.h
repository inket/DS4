//
//  DS4Controller.h
//  DS4Prototype
//
//  Created by inket on 21/04/2019.
//  Copyright © 2019 Mahdi Bchatnia. All rights reserved.
//

@import Foundation;
@import GameController;

#import "UnofficialController.h"

NS_ASSUME_NONNULL_BEGIN

@interface GCControllerElement (Additions)

- (void)_setValue:(float)newValue;
- (BOOL)ds4_setValue:(float)newValue;

@end

@interface GCControllerAxisInput (Additions)

- (BOOL)ds4_setValue:(float)newValue;

@end

@interface GCControllerButtonInput (Additions)

- (BOOL)ds4_setValue:(float)newValue;

@end

@interface GCExtendedGamepad (Additions)

- (void)applyValues:(GCExtendedGamepadSnapShotDataV100)snapshotData;

@end

@interface DS4Controller : GCController

@property (nonatomic, retain, readonly) GCGamepad *gamepad;
@property (nonatomic, retain, readonly) GCExtendedGamepad *extendedGamepad;

- (instancetype)init NS_UNAVAILABLE;
+ (void)listen;

@end

NS_ASSUME_NONNULL_END
