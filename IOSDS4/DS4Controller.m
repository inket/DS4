//
//  DS4Controller.m
//  DS4Prototype
//
//  Created by inket on 21/04/2019.
//  Copyright © 2019 Mahdi Bchatnia. All rights reserved.
//

#import "DS4Controller.h"
#import "IOKit/hid/IOHIDLib.h"

const float DeadZonePercent = 0.2f;
static IOHIDManagerRef HIDManager = nil;
static NSMutableArray *ps4Controllers = nil;

@implementation DS4Controller {
    GCExtendedGamepadSnapShotDataV100 _snapshot;

    // Gamepad ivars are lazy and are only created when requested.
    GCGamepadSnapshot *_gamepad;
    GCExtendedGamepadSnapshot *_extendedGamepad;

    CFIndex _lThumbXUsageID;
    CFIndex _lThumbYUsageID;
    CFIndex _rThumbXUsageID;
    CFIndex _rThumbYUsageID;
    CFIndex _lTriggerUsageID;
    CFIndex _rTriggerUsageID;

    BOOL _usesHatSwitch;
    CFIndex _dpadLUsageID;
    CFIndex _dpadRUsageID;
    CFIndex _dpadDUsageID;
    CFIndex _dpadUUsageID;

    CFIndex _buttonPauseUsageID;
    CFIndex _buttonAUsageID;
    CFIndex _buttonBUsageID;
    CFIndex _buttonXUsageID;
    CFIndex _buttonYUsageID;
    CFIndex _lShoulderUsageID;
    CFIndex _rShoulderUsageID;
}

@synthesize controllerPausedHandler = _controllerPausedHandler;
@synthesize vendorName = _vendorName;
@synthesize playerIndex = _playerIndex;

+ (void)listen {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setupListener];
    });
}

+ (void)setupListener {
    HIDManager = IOHIDManagerCreate(kCFAllocatorDefault, 0);
    ps4Controllers = [NSMutableArray array];

    if (IOHIDManagerOpen(HIDManager, kIOHIDOptionsTypeNone) != kIOReturnSuccess) {
        NSLog(@"Error opening IOHIDManager");
        return;
    }

    IOHIDManagerRegisterDeviceMatchingCallback(HIDManager, deviceRegister, NULL);
    IOHIDManagerSetDeviceMatchingMultiple(HIDManager, (__bridge CFArrayRef)@[
      @{@(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop),
        @(kIOHIDDeviceUsageKey): @(kHIDUsage_GD_GamePad)},
      @{@(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop),
        @(kIOHIDDeviceUsageKey): @(kHIDUsage_GD_MultiAxisController)},
    ]);

    // Pump the event loop to initially fill the ps4Controllers list.
    // Otherwise the list would be empty, immediately followed by didConnect events.
    // Not really a problem, but quite how the iOS API works.
    NSString *mode = @"DS4Controller";
    IOHIDManagerScheduleWithRunLoop(HIDManager, CFRunLoopGetCurrent(), (__bridge CFStringRef)mode);

    while(CFRunLoopRunInMode((CFStringRef)mode, 0, TRUE) == kCFRunLoopRunHandledSource) {}

    IOHIDManagerUnscheduleFromRunLoop(HIDManager, CFRunLoopGetCurrent(), (__bridge CFStringRef)mode);

    // Schedule the HID manager normally to get callbacks during runtime.
    IOHIDManagerScheduleWithRunLoop(HIDManager, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
}

- (instancetype)initWithDevice:(IOHIDDeviceRef)device {
    if (self = [super init]) {
        NSString *manufacturer = (__bridge NSString *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDManufacturerKey));
        NSString *product = (__bridge NSString *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey));
        _vendorName = [NSString stringWithFormat:@"%@ %@", manufacturer, product];

        _snapshot.version = 0x0100;
        _snapshot.size = sizeof(_snapshot);
    }

    return self;
}

static void deviceRegister(void *context, IOReturn result, void *sender, IOHIDDeviceRef device) {
    if (result != kIOReturnSuccess) return;

    DS4Controller *controller = [[DS4Controller alloc] initWithDevice:device];

    CFIndex axisMin = 0;
    CFIndex axisMax = 256;

    controller->_lThumbXUsageID = kHIDUsage_GD_X;
    controller->_lThumbYUsageID = kHIDUsage_GD_Y;
    controller->_rThumbXUsageID = kHIDUsage_GD_Z;
    controller->_rThumbYUsageID = kHIDUsage_GD_Rz;
    controller->_lTriggerUsageID = kHIDUsage_GD_Rx;
    controller->_rTriggerUsageID = kHIDUsage_GD_Ry;

    controller->_usesHatSwitch = YES;

    controller->_buttonPauseUsageID = 0x0A;
    controller->_buttonAUsageID = 0x02;
    controller->_buttonBUsageID = 0x03;
    controller->_buttonXUsageID = 0x01;
    controller->_buttonYUsageID = 0x04;
    controller->_lShoulderUsageID = 0x05;
    controller->_rShoulderUsageID = 0x06;

    setupAxis(device, getAxis(device, controller->_lThumbXUsageID), -1.0,  1.0, axisMin, axisMax, DeadZonePercent);
    setupAxis(device, getAxis(device, controller->_lThumbYUsageID),  1.0, -1.0, axisMin, axisMax, DeadZonePercent);
    setupAxis(device, getAxis(device, controller->_rThumbXUsageID), -1.0,  1.0, axisMin, axisMax, DeadZonePercent);
    setupAxis(device, getAxis(device, controller->_rThumbYUsageID),  1.0, -1.0, axisMin, axisMax, DeadZonePercent);

    setupAxis(device, getAxis(device, controller->_lTriggerUsageID), 0.0,  1.0, 0, 256, 0.0f);
    setupAxis(device, getAxis(device, controller->_rTriggerUsageID), 0.0,  1.0, 0, 256, 0.0f);

    IOHIDDeviceRegisterInputValueCallback(device, input, (__bridge void *)controller);
    IOHIDDeviceSetInputValueMatchingMultiple(device, (__bridge CFArrayRef)@[
                                                                            @{@(kIOHIDElementUsagePageKey): @(kHIDPage_GenericDesktop)},
                                                                            @{@(kIOHIDElementUsagePageKey): @(kHIDPage_Button)},
                                                                            ]);

    IOHIDDeviceRegisterRemovalCallback(device, deviceDisconnected, (void *)CFBridgingRetain(controller));

    [ps4Controllers addObject:controller];
    [UnofficialController registerController:(GCController *)controller];
}

static IOHIDElementRef getAxis(IOHIDDeviceRef device, CFIndex axis) {
    NSDictionary *match = @{
                            @(kIOHIDElementUsagePageKey): @(kHIDPage_GenericDesktop),
                            @(kIOHIDElementUsageKey): @(axis)
                            };

    NSArray *elements = CFBridgingRelease(IOHIDDeviceCopyMatchingElements(device, (__bridge CFDictionaryRef)match, 0));
    if (elements.count != 1) NSLog(@"Warning. Oops, didn't find exactly one axis?");

    return (__bridge IOHIDElementRef)elements[0];
}

static void setupAxis(IOHIDDeviceRef device, IOHIDElementRef element, CFIndex dmin, CFIndex dmax, CFIndex rmin, CFIndex rmax, float deadZonePercent) {
    IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationMinKey), (__bridge CFTypeRef)@(dmin));
    IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationMaxKey), (__bridge CFTypeRef)@(dmax));

    IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationSaturationMinKey), (__bridge CFTypeRef)@(rmin));
    IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationSaturationMaxKey), (__bridge CFTypeRef)@(rmax));

    if (deadZonePercent > 0.0f) {
        CFIndex mid = (rmin + rmax)/2;
        CFIndex deadZone = (rmax - rmin)*(deadZonePercent/2.0f);

        IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationDeadZoneMinKey), (__bridge CFTypeRef)@(mid - deadZone));
        IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationDeadZoneMaxKey), (__bridge CFTypeRef)@(mid + deadZone));
    }
}

static void deviceDisconnected(void *context, IOReturn result, void *sender) {
    if (result != kIOReturnSuccess) return;

    DS4Controller *controller = CFBridgingRelease((CFTypeRef)context);

    if ([controller isKindOfClass:[DS4Controller class]]) {
        [ps4Controllers removeObject:controller];
        [UnofficialController unregisterController:(GCController *)controller];
    }
}

static float clamp(float value) {
    return MAX(-1.0f, MIN(value, 1.0f));
}

static void input(void *context, IOReturn result, void *sender, IOHIDValueRef value) {
    if (result != kIOReturnSuccess) return;

    @autoreleasepool {
        DS4Controller *controller = (__bridge DS4Controller *)context;
        GCExtendedGamepadSnapShotDataV100 *snapshot = &controller->_snapshot;

        IOHIDElementRef element = IOHIDValueGetElement(value);

        uint32_t usagePage = IOHIDElementGetUsagePage(element);
        uint32_t usage = IOHIDElementGetUsage(element);

        CFIndex state = (int)IOHIDValueGetIntegerValue(value);
        float analog = IOHIDValueGetScaledValue(value, kIOHIDValueScaleTypeCalibrated);

//        snapshot->version = 100;

        if (usagePage == kHIDPage_Button) {
            if (usage == controller->_buttonPauseUsageID) { if (state) controller.controllerPausedHandler(controller); }
            if (usage == controller->_buttonAUsageID) { snapshot->buttonA = state; }
            if (usage == controller->_buttonBUsageID) { snapshot->buttonB = state; }
            if (usage == controller->_buttonXUsageID) { snapshot->buttonX = state; }
            if (usage == controller->_buttonYUsageID) { snapshot->buttonY = state; }
            if (usage == controller->_lShoulderUsageID) { snapshot->leftShoulder = state; }
            if (usage == controller->_rShoulderUsageID) { snapshot->rightShoulder = state; }

            if (!controller->_usesHatSwitch) {
                if (usage == controller->_dpadLUsageID) { snapshot->dpadX = clamp(snapshot->dpadX - (state ? 1.0f : -1.0f)); }
                if (usage == controller->_dpadRUsageID) { snapshot->dpadX = clamp(snapshot->dpadX + (state ? 1.0f : -1.0f)); }
                if (usage == controller->_dpadDUsageID) { snapshot->dpadY = clamp(snapshot->dpadY - (state ? 1.0f : -1.0f)); }
                if (usage == controller->_dpadUUsageID) { snapshot->dpadY = clamp(snapshot->dpadY + (state ? 1.0f : -1.0f)); }
            }
        }

        if (usagePage == kHIDPage_GenericDesktop) {
            if (usage == controller->_lThumbXUsageID) { snapshot->leftThumbstickX  = analog; }
            if (usage == controller->_lThumbYUsageID) { snapshot->leftThumbstickY  = analog; }
            if (usage == controller->_rThumbXUsageID) { snapshot->rightThumbstickX = analog; }
            if (usage == controller->_rThumbYUsageID) { snapshot->rightThumbstickY = analog; }
            if (usage == controller->_lTriggerUsageID) { snapshot->leftTrigger     = analog; }
            if (usage == controller->_rTriggerUsageID) { snapshot->rightTrigger    = analog; }

            if (controller->_usesHatSwitch && usage == kHIDUsage_GD_Hatswitch) {
                switch(state) {
                    case  0: snapshot->dpadX =  0.0; snapshot->dpadY =  1.0; break;
                    case  1: snapshot->dpadX =  1.0; snapshot->dpadY =  1.0; break;
                    case  2: snapshot->dpadX =  1.0; snapshot->dpadY =  0.0; break;
                    case  3: snapshot->dpadX =  1.0; snapshot->dpadY = -1.0; break;
                    case  4: snapshot->dpadX =  0.0; snapshot->dpadY = -1.0; break;
                    case  5: snapshot->dpadX = -1.0; snapshot->dpadY = -1.0; break;
                    case  6: snapshot->dpadX = -1.0; snapshot->dpadY =  0.0; break;
                    case  7: snapshot->dpadX = -1.0; snapshot->dpadY =  1.0; break;
                    default: snapshot->dpadX =  0.0; snapshot->dpadY =  0.0; break;
                }
            }
        }

        updateSnapshot(controller);
    }
}

static void updateSnapshot(DS4Controller *controller) {
    GCExtendedGamepadSnapShotDataV100 *extendedSnapshot = &controller->_snapshot;

    // Update the gamepad snapshots if they currently exist.
    if (controller->_extendedGamepad) {
        NSData *data = NSDataFromGCExtendedGamepadSnapShotDataV100(extendedSnapshot);

        if (data) {
            controller->_extendedGamepad.snapshotData = data;
        }
    }

    if (controller->_gamepad) {
        GCGamepadSnapShotDataV100 snapshot = copySnapshotData(extendedSnapshot);
        NSData *data = NSDataFromGCGamepadSnapShotDataV100(&snapshot);

        if (data) {
            controller->_gamepad.snapshotData = data;
        }
    }
}

#pragma mark - Gamepad

static GCGamepadSnapShotDataV100 copySnapshotData(GCExtendedGamepadSnapShotDataV100 *snapshot) {
    return (GCGamepadSnapShotDataV100){
        .version = 0x0100,
        .size = sizeof(GCGamepadSnapShotDataV100),
        .dpadX = snapshot->dpadX,
        .dpadY = snapshot->dpadY,
        .buttonA = snapshot->buttonA,
        .buttonB = snapshot->buttonB,
        .buttonX = snapshot->buttonX,
        .buttonY = snapshot->buttonY,
        .leftShoulder = snapshot->leftShoulder,
        .rightShoulder = snapshot->rightShoulder,
    };
}

- (GCGamepad *)gamepad {
    if (_gamepad == nil) {
        _gamepad = [[GCGamepadSnapshot alloc] init];
        GCGamepadSnapShotDataV100 snapshot = copySnapshotData(&_snapshot);
        NSData *data = NSDataFromGCGamepadSnapShotDataV100(&snapshot);
        if(data) _gamepad.snapshotData = data;
    }

    return _gamepad;
}

- (GCExtendedGamepad *)extendedGamepad {
    if (_extendedGamepad == nil) {
        _extendedGamepad = [[GCExtendedGamepadSnapshot alloc] init];
        NSData *data = NSDataFromGCExtendedGamepadSnapShotDataV100(&_snapshot);
        _extendedGamepad.snapshotData = data;
    }

    return _extendedGamepad;
}

@end
