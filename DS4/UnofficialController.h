//
//  UnofficialController.h
//  IOSDS4
//
//  Created by inket on 21/04/2019.
//  Copyright © 2019 Mahdi Bchatnia. All rights reserved.
//

#import <GameController/GameController.h>

NS_ASSUME_NONNULL_BEGIN

@interface UnofficialController : GCController

- (instancetype)init NS_UNAVAILABLE;
+ (void)registerController:(GCController *)controller;
+ (void)unregisterController:(GCController *)controller;

@end

NS_ASSUME_NONNULL_END
