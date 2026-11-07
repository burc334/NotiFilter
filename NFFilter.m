#import "NFFilter.h"

@implementation NFFilter

+ (instancetype)defaultFilter {
    NFFilter *filter = [[NFFilter alloc] init];
    filter.uuid = [[NSUUID UUID] UUIDString];
    filter.enabled = YES;
    filter.name = @"New Filter";
    filter.action = NFFilterActionBlock;
    filter.matchType = NFFilterMatchContains;
    filter.field = NFFilterFieldAny;
    filter.text = @"";
    filter.scheduleEnabled = NO;
    filter.weekdays = @[@YES, @YES, @YES, @YES, @YES, @NO, @NO];
    filter.startMinutes = 0;
    filter.endMinutes = 23 * 60 + 59;
    return filter;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _uuid = [[NSUUID UUID] UUIDString];
        _enabled = YES;
        _name = @"New Filter";
        _action = NFFilterActionBlock;
        _matchType = NFFilterMatchContains;
        _field = NFFilterFieldAny;
        _text = @"";
        _scheduleEnabled = NO;
        _weekdays = @[@YES, @YES, @YES, @YES, @YES, @NO, @NO];
        _startMinutes = 0;
        _endMinutes = 23 * 60 + 59;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [self init];
    if (!self || ![dictionary isKindOfClass:[NSDictionary class]]) {
        return self;
    }

    id value = dictionary[@"uuid"];
    if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
        _uuid = value;
    }

    value = dictionary[@"enabled"];
    if ([value isKindOfClass:[NSNumber class]]) {
        _enabled = [value boolValue];
    }

    value = dictionary[@"name"];
    if ([value isKindOfClass:[NSString class]]) {
        _name = value;
    }

    value = dictionary[@"bundleIdentifier"];
    if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
        _bundleIdentifier = value;
    }

    value = dictionary[@"appName"];
    if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
        _appName = value;
    }

    value = dictionary[@"action"];
    if ([value isKindOfClass:[NSNumber class]]) {
        _action = (NFFilterAction)[value integerValue];
    }

    value = dictionary[@"matchType"];
    if ([value isKindOfClass:[NSNumber class]]) {
        _matchType = (NFFilterMatchType)[value integerValue];
    }

    value = dictionary[@"field"];
    if ([value isKindOfClass:[NSNumber class]]) {
        _field = (NFFilterField)[value integerValue];
    }

    value = dictionary[@"text"];
    if ([value isKindOfClass:[NSString class]]) {
        _text = value;
    }

    value = dictionary[@"scheduleEnabled"];
    if ([value isKindOfClass:[NSNumber class]]) {
        _scheduleEnabled = [value boolValue];
    }

    value = dictionary[@"weekdays"];
    if ([value isKindOfClass:[NSArray class]]) {
        BOOL valid = [value count] == 7;
        if (valid) {
            for (id day in value) {
                if (![day isKindOfClass:[NSNumber class]]) {
                    valid = NO;
                    break;
                }
            }
        }
        _weekdays = valid ? [value copy] : nil;
    }

    value = dictionary[@"startMinutes"];
    if ([value isKindOfClass:[NSNumber class]]) {
        _startMinutes = [value integerValue];
    }

    value = dictionary[@"endMinutes"];
    if ([value isKindOfClass:[NSNumber class]]) {
        _endMinutes = [value integerValue];
    }

    if (_action < NFFilterActionBlock || _action > NFFilterActionAllow) {
        _action = NFFilterActionBlock;
    }
    if (_matchType < NFFilterMatchContains || _matchType > NFFilterMatchAlways) {
        _matchType = NFFilterMatchContains;
    }
    if (_field < NFFilterFieldAny || _field > NFFilterFieldMessage) {
        _field = NFFilterFieldAny;
    }
    if (_startMinutes < 0 || _startMinutes > 23 * 60 + 59) {
        _startMinutes = 0;
    }
    if (_endMinutes < 0 || _endMinutes > 23 * 60 + 59) {
        _endMinutes = 23 * 60 + 59;
    }

    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
        @"uuid": self.uuid ?: [[NSUUID UUID] UUIDString],
        @"enabled": @(self.enabled),
        @"name": self.name ?: @"New Filter",
        @"bundleIdentifier": self.bundleIdentifier ?: @"",
        @"appName": self.appName ?: @"",
        @"action": @(self.action),
        @"matchType": @(self.matchType),
        @"field": @(self.field),
        @"text": self.text ?: @"",
        @"scheduleEnabled": @(self.scheduleEnabled),
        @"weekdays": self.weekdays ?: @[@YES, @YES, @YES, @YES, @YES, @NO, @NO],
        @"startMinutes": @(self.startMinutes),
        @"endMinutes": @(self.endMinutes)
    };
}

- (id)copyWithZone:(NSZone *)zone {
    NFFilter *copy = [[NFFilter allocWithZone:zone] initWithDictionary:[self dictionaryRepresentation]];
    return copy;
}

+ (NSString *)titleForAction:(NFFilterAction)action {
    NSArray<NSString *> *titles = [self actionTitles];
    if (action < 0 || action >= (NSInteger)titles.count) {
        return titles.firstObject;
    }
    return titles[(NSUInteger)action];
}

+ (NSString *)titleForMatchType:(NFFilterMatchType)matchType {
    NSArray<NSString *> *titles = [self matchTypeTitles];
    if (matchType < 0 || matchType >= (NSInteger)titles.count) {
        return titles.firstObject;
    }
    return titles[(NSUInteger)matchType];
}

+ (NSString *)titleForField:(NFFilterField)field {
    NSArray<NSString *> *titles = [self fieldTitles];
    if (field < 0 || field >= (NSInteger)titles.count) {
        return titles.firstObject;
    }
    return titles[(NSUInteger)field];
}

+ (NSArray<NSString *> *)actionTitles {
    return @[@"Block", @"Mute", @"Allow"];
}

+ (NSArray<NSString *> *)matchTypeTitles {
    return @[@"Contains", @"Starts With", @"Ends With", @"Exact", @"Regex", @"Always"];
}

+ (NSArray<NSString *> *)fieldTitles {
    return @[@"Any", @"Title", @"Subtitle", @"Message"];
}

@end
