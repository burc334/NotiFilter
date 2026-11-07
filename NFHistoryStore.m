#import "NFHistoryStore.h"
#import "NFConstants.h"
#import "NFSettings.h"

static NSString *const NFHistoryKey = @"History";

static NSArray<NSDictionary *> *NFHistoryRawEntries(void) {
    CFPropertyListRef value = CFPreferencesCopyAppValue(
        (__bridge CFStringRef)NFHistoryKey,
        (__bridge CFStringRef)NF_DOMAIN);
    if (!value) {
        return @[];
    }

    NSArray *entries = CFBridgingRelease(value);
    if (![entries isKindOfClass:[NSArray class]]) {
        return @[];
    }
    return entries;
}

static NSArray<NSDictionary *> *NFHistoryPrunedEntries(NSArray<NSDictionary *> *entries) {
    NSInteger limit = NFSettingsHistoryLimit();
    NSInteger days = NFSettingsHistoryRetentionDays();
    NSTimeInterval cutoff = [[NSDate date] timeIntervalSince1970] - (days * 24 * 60 * 60);

    NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
    for (id object in entries) {
        if (![object isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSDictionary *entry = object;
        NSNumber *timestamp = entry[@"timestamp"];
        if (![timestamp isKindOfClass:[NSNumber class]]) {
            continue;
        }
        if (days > 0 && timestamp.doubleValue < cutoff) {
            continue;
        }
        [result addObject:entry];
        if ((NSInteger)result.count >= limit) {
            break;
        }
    }
    return result;
}

@implementation NFHistoryStore

+ (void)recordBlockedContext:(NFNotificationContext *)context
                      filter:(NFFilter *)filter {
    if (!context) {
        return;
    }

    NSDictionary *entry = @{
        @"timestamp": @([[NSDate date] timeIntervalSince1970]),
        @"bundleIdentifier": context.sectionIdentifier ?: @"",
        @"appName": context.appName ?: @"",
        @"title": context.title ?: @"",
        @"subtitle": context.subtitle ?: @"",
        @"message": context.message ?: @"",
        @"filterName": filter.name ?: @"",
        @"filterUUID": filter.uuid ?: @""
    };

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        @synchronized ([NFHistoryStore class]) {
            NSMutableArray<NSDictionary *> *entries =
                [NFHistoryRawEntries() mutableCopy] ?: [NSMutableArray array];
            [entries insertObject:entry atIndex:0];

            NSArray<NSDictionary *> *pruned = NFHistoryPrunedEntries(entries);
            CFPreferencesSetAppValue((__bridge CFStringRef)NFHistoryKey,
                                     (__bridge CFArrayRef)pruned,
                                     (__bridge CFStringRef)NF_DOMAIN);
            CFPreferencesAppSynchronize((__bridge CFStringRef)NF_DOMAIN);
        }
    });
}

+ (NSArray<NSDictionary *> *)entries {
    @synchronized ([NFHistoryStore class]) {
        return NFHistoryPrunedEntries(NFHistoryRawEntries());
    }
}

+ (void)clear {
    @synchronized ([NFHistoryStore class]) {
        CFPreferencesSetAppValue((__bridge CFStringRef)NFHistoryKey,
                                 NULL,
                                 (__bridge CFStringRef)NF_DOMAIN);
        CFPreferencesAppSynchronize((__bridge CFStringRef)NF_DOMAIN);
    }
}

@end
