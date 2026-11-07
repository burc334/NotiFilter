#import "NFNotificationContext.h"

@interface NCNotificationContent : NSObject
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;
@property (nonatomic, readonly, copy) NSString *message;
@end

@interface NCNotificationRequest : NSObject
@property (nonatomic, readonly, copy) NSString *sectionIdentifier;
@property (nonatomic, readonly) NCNotificationContent *content;
@property (nonatomic, readonly) BOOL criticalAlert;
- (BOOL)isCriticalAlert;
@end

@interface BBBulletin : NSObject
@property (nonatomic, readonly, copy) NSString *sectionID;
@property (nonatomic, readonly, copy) NSString *sectionDisplayName;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;
@property (nonatomic, readonly, copy) NSString *message;
@property (nonatomic, readonly) BOOL hasCriticalIcon;
@end

@implementation NFNotificationContext

+ (instancetype)contextWithRequest:(id)requestObject {
    NCNotificationRequest *request = (NCNotificationRequest *)requestObject;
    if (!request) {
        return nil;
    }

    NFNotificationContext *context = [[NFNotificationContext alloc] init];
    @try {
        context.sectionIdentifier = request.sectionIdentifier;
        NCNotificationContent *content = request.content;
        context.title = content.title;
        context.subtitle = content.subtitle;
        context.message = content.message;
        if ([request respondsToSelector:@selector(isCriticalAlert)]) {
            context.criticalAlert = [request isCriticalAlert];
        } else if ([request respondsToSelector:@selector(criticalAlert)]) {
            context.criticalAlert = request.criticalAlert;
        } else {
            // Never risk treating an unknown critical state as non-critical.
            context.criticalAlert = YES;
        }
    } @catch (NSException *exception) {
        (void)exception;
        return nil;
    }
    return context;
}

+ (instancetype)contextWithBulletin:(id)bulletinObject {
    BBBulletin *bulletin = (BBBulletin *)bulletinObject;
    if (!bulletin) {
        return nil;
    }

    NFNotificationContext *context = [[NFNotificationContext alloc] init];
    @try {
        context.sectionIdentifier = bulletin.sectionID;
        context.appName = bulletin.sectionDisplayName;
        context.title = bulletin.title;
        context.subtitle = bulletin.subtitle;
        context.message = bulletin.message;
        if ([bulletin respondsToSelector:@selector(hasCriticalIcon)]) {
            context.criticalAlert = bulletin.hasCriticalIcon;
        } else {
            // Never risk treating an unknown critical state as non-critical.
            context.criticalAlert = YES;
        }
    } @catch (NSException *exception) {
        (void)exception;
        return nil;
    }
    return context;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ section=%@ title=%lu subtitle=%lu message=%lu critical=%d>",
            NSStringFromClass([self class]),
            self.sectionIdentifier ?: @"(nil)",
            (unsigned long)self.title.length,
            (unsigned long)self.subtitle.length,
            (unsigned long)self.message.length,
            self.criticalAlert];
}

@end
