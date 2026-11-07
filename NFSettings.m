#import "NFSettings.h"
#import "NFConstants.h"

static CFStringRef NFPreferencesDomain(void) {
    return (__bridge CFStringRef)NF_DOMAIN;
}

static void NFPreferencesSynchronize(void) {
    CFPreferencesAppSynchronize(NFPreferencesDomain());
}

BOOL NFSettingsEnabled(void) {
    Boolean keyExists = false;
    Boolean value = CFPreferencesGetAppBooleanValue(CFSTR("Enabled"),
                                                    NFPreferencesDomain(),
                                                    &keyExists);
    if (!keyExists) {
        return NO;
    }
    return value ? YES : NO;
}

void NFSettingsSetEnabled(BOOL enabled) {
    CFPreferencesSetAppValue(CFSTR("Enabled"),
                             enabled ? kCFBooleanTrue : kCFBooleanFalse,
                             NFPreferencesDomain());
    NFPreferencesSynchronize();
}

NSArray<NFFilter *> *NFSettingsFilters(void) {
    CFPropertyListRef value = CFPreferencesCopyAppValue(CFSTR("Filters"),
                                                        NFPreferencesDomain());
    if (!value) {
        return @[];
    }

    NSArray *rawFilters = CFBridgingRelease(value);
    if (![rawFilters isKindOfClass:[NSArray class]]) {
        return @[];
    }

    NSMutableArray<NFFilter *> *filters = [NSMutableArray array];
    for (id entry in rawFilters) {
        if (![entry isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NFFilter *filter = [[NFFilter alloc] initWithDictionary:entry];
        if (filter) {
            [filters addObject:filter];
        }
    }
    return filters;
}

void NFSettingsSetFilters(NSArray<NFFilter *> *filters) {
    NSMutableArray<NSDictionary *> *rawFilters = [NSMutableArray array];
    for (NFFilter *filter in filters) {
        [rawFilters addObject:[filter dictionaryRepresentation]];
    }
    CFPreferencesSetAppValue(CFSTR("Filters"),
                             (__bridge CFArrayRef)rawFilters,
                             NFPreferencesDomain());
    NFPreferencesSynchronize();
}

NSInteger NFSettingsHistoryLimit(void) {
    Boolean keyExists = false;
    CFIndex value = CFPreferencesGetAppIntegerValue(CFSTR("HistoryLimit"),
                                                    NFPreferencesDomain(),
                                                    &keyExists);
    if (!keyExists) {
        return 100;
    }
    if (value < 25) {
        return 25;
    }
    if (value > 500) {
        return 500;
    }
    return (NSInteger)value;
}

void NFSettingsSetHistoryLimit(NSInteger limit) {
    if (limit < 25) {
        limit = 25;
    }
    if (limit > 500) {
        limit = 500;
    }
    CFPreferencesSetAppValue(CFSTR("HistoryLimit"),
                             (__bridge CFTypeRef)@(limit),
                             NFPreferencesDomain());
    NFPreferencesSynchronize();
}

NSInteger NFSettingsHistoryRetentionDays(void) {
    Boolean keyExists = false;
    CFIndex value = CFPreferencesGetAppIntegerValue(CFSTR("HistoryRetentionDays"),
                                                    NFPreferencesDomain(),
                                                    &keyExists);
    if (!keyExists) {
        return 30;
    }
    if (value < 1) {
        return 1;
    }
    if (value > 30) {
        return 30;
    }
    return (NSInteger)value;
}

void NFSettingsSetHistoryRetentionDays(NSInteger days) {
    if (days < 1) {
        days = 1;
    }
    if (days > 30) {
        days = 30;
    }
    CFPreferencesSetAppValue(CFSTR("HistoryRetentionDays"),
                             (__bridge CFTypeRef)@(days),
                             NFPreferencesDomain());
    NFPreferencesSynchronize();
}

void NFSettingsPostChanged(void) {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         (__bridge CFStringRef)NFPreferencesChangedNotification,
                                         NULL,
                                         NULL,
                                         YES);
}

void NFSettingsResetToDefaults(void) {
    CFPreferencesSetAppValue(CFSTR("Enabled"), NULL, NFPreferencesDomain());
    CFPreferencesSetAppValue(CFSTR("Filters"), NULL, NFPreferencesDomain());
    CFPreferencesSetAppValue(CFSTR("HistoryLimit"), NULL, NFPreferencesDomain());
    CFPreferencesSetAppValue(CFSTR("HistoryRetentionDays"), NULL, NFPreferencesDomain());
    NFPreferencesSynchronize();
    NFSettingsPostChanged();
}
