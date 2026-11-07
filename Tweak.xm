#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <os/lock.h>
#import "NFConstants.h"
#import "NFSettings.h"
#import "NFNotificationContext.h"
#import "NFDecision.h"
#import "NFFilterEngine.h"
#import "NFHistoryStore.h"

@interface BBServer : NSObject
- (void)publishBulletin:(id)bulletin destinations:(unsigned long long)destinations;
@end

@interface NCNotificationDispatcher : NSObject
- (void)postNotificationWithRequest:(id)request;
- (void)_clearUnsafeNotification:(id)notification;
@end

@interface NCNotificationAlertQueue : NSObject
- (void)postNotificationRequest:(id)request;
@end

@interface NCMutableNotificationOptions : NSObject
- (void)setCanPlaySound:(BOOL)enabled;
- (void)setCanTurnOnDisplay:(BOOL)enabled;
- (void)setAlertsWhenLocked:(BOOL)enabled;
@end

@interface NCMutableNotificationRequest : NSObject
- (id)options;
- (void)setOptions:(id)options;
@end

static os_unfair_lock NFStateLock = OS_UNFAIR_LOCK_INIT;
static NFFilterEngine *NFEngine = nil;
static BOOL NFEnabled = NO;

static NFDecision *NFAllowDecision(void) {
    return [NFDecision decisionWithAction:NFFilterActionAllow matchedFilter:nil];
}

static void NFReloadSettings(void) {
    BOOL enabled = NFSettingsEnabled();
    NSArray<NFFilter *> *filters = NFSettingsFilters();
    NFFilterEngine *engine = [[NFFilterEngine alloc] initWithFilters:filters];

    os_unfair_lock_lock(&NFStateLock);
    NFEnabled = enabled;
    NFEngine = engine;
    os_unfair_lock_unlock(&NFStateLock);
}

static NFDecision *NFDecisionForContext(NFNotificationContext *context) {
    if (!context) {
        return NFAllowDecision();
    }

    BOOL enabled = NO;
    NFFilterEngine *engine = nil;
    os_unfair_lock_lock(&NFStateLock);
    enabled = NFEnabled;
    engine = NFEngine;
    os_unfair_lock_unlock(&NFStateLock);

    if (!enabled || !engine) {
        return NFAllowDecision();
    }

    return [engine decisionForContext:context];
}

static void NFPreferencesChanged(CFNotificationCenterRef center,
                                 void *observer,
                                 CFNotificationName name,
                                 const void *object,
                                 CFDictionaryRef userInfo) {
    (void)center;
    (void)observer;
    (void)name;
    (void)object;
    (void)userInfo;
    NFReloadSettings();
}

%ctor {
    NFReloadSettings();

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    NFPreferencesChanged,
                                    (__bridge CFStringRef)NFPreferencesChangedNotification,
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
}

%hook BBServer

- (void)publishBulletin:(id)bulletin destinations:(unsigned long long)destinations {
    @try {
        NFNotificationContext *context = [NFNotificationContext contextWithBulletin:bulletin];
        if (context && !context.criticalAlert) {
            NFDecision *decision = NFDecisionForContext(context);
            if (decision.isBlock) {
                [NFHistoryStore recordBlockedContext:context filter:decision.matchedFilter];
                // Hard block before the bulletin is stored or sent to any feed.
                return;
            }
        }
    } @catch (NSException *exception) {
        (void)exception;
        // Fail open.
    }
    %orig;
}

%end

%hook NCNotificationDispatcher

- (void)postNotificationWithRequest:(id)request {
    @try {
        NFNotificationContext *context = [NFNotificationContext contextWithRequest:request];
        if (context && !context.criticalAlert) {
            NFDecision *decision = NFDecisionForContext(context);

            if (decision.isBlock) {
                if ([self respondsToSelector:@selector(_clearUnsafeNotification:)]) {
                    [NFHistoryStore recordBlockedContext:context filter:decision.matchedFilter];
                    [self _clearUnsafeNotification:request];
                    return;
                }
                // If the clear path is unavailable, fail open.
            } else if (decision.isMute) {
                NCMutableNotificationRequest *mutableRequest = [request mutableCopy];
                id options = [mutableRequest options];
                NCMutableNotificationOptions *mutableOptions = [options mutableCopy];

                if (mutableRequest && mutableOptions &&
                    [mutableOptions respondsToSelector:@selector(setCanPlaySound:)] &&
                    [mutableOptions respondsToSelector:@selector(setCanTurnOnDisplay:)] &&
                    [mutableOptions respondsToSelector:@selector(setAlertsWhenLocked:)] &&
                    [mutableRequest respondsToSelector:@selector(setOptions:)]) {
                    [mutableOptions setCanPlaySound:NO];
                    [mutableOptions setCanTurnOnDisplay:NO];
                    [mutableOptions setAlertsWhenLocked:NO];
                    [mutableRequest setOptions:mutableOptions];
                    %orig(mutableRequest);
                    return;
                }
                // If the mute copy cannot be built, fail open.
            }
        }
    } @catch (NSException *exception) {
        (void)exception;
        // Fail open.
    }
    %orig;
}

%end

%hook NCNotificationAlertQueue

- (void)postNotificationRequest:(id)request {
    @try {
        NFNotificationContext *context = [NFNotificationContext contextWithRequest:request];
        if (context && !context.criticalAlert) {
            NFDecision *decision = NFDecisionForContext(context);
            if (decision.isMute || decision.isBlock) {
                // Keep the Notification Center path, but never present an alert.
                return;
            }
        }
    } @catch (NSException *exception) {
        (void)exception;
        // Fail open.
    }
    %orig;
}

%end
