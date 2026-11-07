#import "NFFilterEngine.h"

@interface NFFilterRule : NSObject
@property (nonatomic, strong) NFFilter *filter;
@property (nonatomic, strong) NSRegularExpression *regex;
@end

@implementation NFFilterRule
@end

@interface NFFilterEngine ()
@property (nonatomic, copy) NSArray<NFFilterRule *> *rules;
@end

@implementation NFFilterEngine

- (instancetype)initWithFilters:(NSArray<NFFilter *> *)filters {
    self = [super init];
    if (!self) {
        return nil;
    }

    if (![filters isKindOfClass:[NSArray class]]) {
        filters = @[];
    }

    NSMutableArray<NFFilterRule *> *rules = [NSMutableArray array];
    for (id object in filters) {
        if (![object isKindOfClass:[NFFilter class]]) {
            continue;
        }

        NFFilter *filter = object;
        if (!filter.enabled) {
            continue;
        }
        if (filter.action < NFFilterActionBlock || filter.action > NFFilterActionAllow) {
            continue;
        }
        if (filter.matchType < NFFilterMatchContains || filter.matchType > NFFilterMatchAlways) {
            continue;
        }
        if (filter.field < NFFilterFieldAny || filter.field > NFFilterFieldMessage) {
            continue;
        }

        BOOL usesText = filter.matchType != NFFilterMatchAlways;
        if (usesText && filter.text.length == 0) {
            continue;
        }

        NFFilterRule *rule = [[NFFilterRule alloc] init];
        rule.filter = filter;

        if (filter.matchType == NFFilterMatchRegex) {
            NSError *error = nil;
            rule.regex = [NSRegularExpression regularExpressionWithPattern:filter.text
                                                                    options:NSRegularExpressionCaseInsensitive
                                                                      error:&error];
            if (!rule.regex) {
                continue;
            }
        }

        [rules addObject:rule];
    }

    _rules = [rules copy];
    return self;
}

- (NFDecision *)decisionForContext:(NFNotificationContext *)context {
    return [self decisionForContext:context atDate:[NSDate date] calendar:[NSCalendar currentCalendar]];
}

- (NFDecision *)decisionForContext:(NFNotificationContext *)context
                            atDate:(NSDate *)date
                          calendar:(NSCalendar *)calendar {
    if (!context) {
        return [NFDecision decisionWithAction:NFFilterActionAllow matchedFilter:nil];
    }

    // Critical alerts are never filtered.
    if (context.criticalAlert) {
        return [NFDecision decisionWithAction:NFFilterActionAllow matchedFilter:nil];
    }

    if (!date) {
        date = [NSDate date];
    }
    if (!calendar) {
        calendar = [NSCalendar currentCalendar];
    }

    NFDecision *allowDecision = nil;
    NFDecision *blockDecision = nil;
    NFDecision *muteDecision = nil;

    for (NFFilterRule *rule in self.rules) {
        NFFilter *filter = rule.filter;

        if (filter.bundleIdentifier.length > 0 &&
            ![context.sectionIdentifier isEqualToString:filter.bundleIdentifier]) {
            continue;
        }

        if (filter.scheduleEnabled &&
            ![self scheduleIsActiveForFilter:filter date:date calendar:calendar]) {
            continue;
        }

        if (![self contentMatchesFilter:filter rule:rule context:context]) {
            continue;
        }

        NFDecision *decision = [NFDecision decisionWithAction:filter.action matchedFilter:filter];
        if (filter.action == NFFilterActionAllow) {
            allowDecision = decision;
            break;
        }
        if (filter.action == NFFilterActionBlock && !blockDecision) {
            blockDecision = decision;
        } else if (filter.action == NFFilterActionMute && !muteDecision) {
            muteDecision = decision;
        }
    }

    if (allowDecision) {
        return allowDecision;
    }
    if (blockDecision) {
        return blockDecision;
    }
    if (muteDecision) {
        return muteDecision;
    }
    return [NFDecision decisionWithAction:NFFilterActionAllow matchedFilter:nil];
}

- (BOOL)contentMatchesFilter:(NFFilter *)filter
                        rule:(NFFilterRule *)rule
                     context:(NFNotificationContext *)context {
    if (filter.matchType == NFFilterMatchAlways) {
        return YES;
    }

    NSString *text = filter.text ?: @"";
    if (text.length == 0) {
        return NO;
    }

    NSArray<NSString *> *candidates = nil;
    switch (filter.field) {
        case NFFilterFieldTitle:
            candidates = @[context.title ?: @""];
            break;
        case NFFilterFieldSubtitle:
            candidates = @[context.subtitle ?: @""];
            break;
        case NFFilterFieldMessage:
            candidates = @[context.message ?: @""];
            break;
        case NFFilterFieldAny:
        default:
            candidates = @[context.title ?: @"", context.subtitle ?: @"", context.message ?: @""];
            break;
    }

    for (NSString *candidate in candidates) {
        if ([self string:candidate matchesText:text matchType:filter.matchType regex:rule.regex]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)string:(NSString *)string
    matchesText:(NSString *)text
      matchType:(NFFilterMatchType)matchType
          regex:(NSRegularExpression *)regex {
    switch (matchType) {
        case NFFilterMatchContains:
            return [string rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound;
        case NFFilterMatchStartsWith:
            return [string rangeOfString:text
                                 options:(NSAnchoredSearch | NSCaseInsensitiveSearch)].location != NSNotFound;
        case NFFilterMatchEndsWith:
            return [string rangeOfString:text
                                 options:(NSAnchoredSearch | NSBackwardsSearch | NSCaseInsensitiveSearch)].location != NSNotFound;
        case NFFilterMatchEquals:
            return [string compare:text options:NSCaseInsensitiveSearch] == NSOrderedSame;
        case NFFilterMatchRegex:
            if (!regex) {
                return NO;
            }
            return [regex firstMatchInString:string
                                     options:0
                                       range:NSMakeRange(0, string.length)] != nil;
        case NFFilterMatchAlways:
            return YES;
        default:
            return NO;
    }
}

- (BOOL)scheduleIsActiveForFilter:(NFFilter *)filter
                             date:(NSDate *)date
                         calendar:(NSCalendar *)calendar {
    NSArray<NSNumber *> *weekdays = filter.weekdays;
    if (![weekdays isKindOfClass:[NSArray class]] || weekdays.count != 7) {
        return NO;
    }

    BOOL selected[7] = {NO, NO, NO, NO, NO, NO, NO};
    for (NSUInteger index = 0; index < 7; index++) {
        id value = weekdays[index];
        if (![value isKindOfClass:[NSNumber class]]) {
            return NO;
        }
        selected[index] = [(NSNumber *)value boolValue];
    }

    NSInteger start = filter.startMinutes;
    NSInteger end = filter.endMinutes;
    if (start < 0 || start >= 24 * 60 || end < 0 || end >= 24 * 60) {
        return NO;
    }
    if (start == end) {
        return NO;
    }

    NSDateComponents *components =
        [calendar components:(NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute)
                    fromDate:date];
    if (!components) {
        return NO;
    }

    NSInteger weekday = components.weekday; // Sunday = 1, Monday = 2, ..., Saturday = 7.
    NSInteger current = (weekday + 5) % 7;  // Monday = 0, Tuesday = 1, ..., Sunday = 6.
    NSInteger previous = (current + 6) % 7;
    NSInteger minute = components.hour * 60 + components.minute;

    if (start < end) {
        return selected[current] && minute >= start && minute < end;
    }

    // Overnight window: the selected weekday is the day the window starts.
    return (selected[current] && minute >= start) ||
           (selected[previous] && minute < end);
}

@end
