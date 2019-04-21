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

@interface DS4Controller : GCController

- (instancetype)init NS_UNAVAILABLE;
+ (void)listen;

@end

NS_ASSUME_NONNULL_END
