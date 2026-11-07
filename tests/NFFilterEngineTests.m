#import <Foundation/Foundation.h>
#import "NFFilterEngine.h"
#import "NFTransfer.h"

static NSUInteger gPassed = 0;
static NSUInteger gFailed = 0;

static void Check(BOOL condition, NSString *name) {
    if (condition) {
        gPassed++;
        printf("PASS  %s\n", name.UTF8String);
    } else {
        gFailed++;
        printf("FAIL  %s\n", name.UTF8String);
    }
}

static NSCalendar *UTCCalendar(void) {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    return calendar;
}

static NSDate *DateAt(NSCalendar *calendar,
                      NSInteger year,
                      NSInteger month,
                      NSInteger day,
                      NSInteger hour,
                      NSInteger minute) {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = month;
    components.day = day;
    components.hour = hour;
    components.minute = minute;
    return [calendar dateFromComponents:components];
}

static NSArray<NSNumber *> *Weekdays(BOOL monday, BOOL tuesday, BOOL wednesday,
                                     BOOL thursday, BOOL friday, BOOL saturday,
                                     BOOL sunday) {
    return @[@(monday), @(tuesday), @(wednesday), @(thursday),
             @(friday), @(saturday), @(sunday)];
}

static NFFilter *MakeFilter(NFFilterAction action,
                            NFFilterMatchType matchType,
                            NFFilterField field,
                            NSString *text) {
    NFFilter *filter = [[NFFilter alloc] init];
    filter.name = text.length > 0 ? text : @"Always Filter";
    filter.action = action;
    filter.matchType = matchType;
    filter.field = field;
    filter.text = text ?: @"";
    filter.enabled = YES;
    filter.scheduleEnabled = NO;
    return filter;
}

static NFNotificationContext *MakeContext(NSString *section,
                                           NSString *title,
                                           NSString *subtitle,
                                           NSString *message,
                                           BOOL critical) {
    NFNotificationContext *context = [[NFNotificationContext alloc] init];
    context.sectionIdentifier = section;
    context.title = title;
    context.subtitle = subtitle;
    context.message = message;
    context.criticalAlert = critical;
    return context;
}

static NFDecision *Evaluate(NSArray<NFFilter *> *filters,
                            NFNotificationContext *context,
                            NSCalendar *calendar,
                            NSDate *date) {
    NFFilterEngine *engine = [[NFFilterEngine alloc] initWithFilters:filters];
    return [engine decisionForContext:context atDate:date calendar:calendar];
}

int main(void) {
    @autoreleasepool {
        NSCalendar *calendar = UTCCalendar();
        NSDate *mondayMorning = DateAt(calendar, 2026, 11, 2, 9, 0);
        NSDate *mondayLate = DateAt(calendar, 2026, 11, 2, 23, 0);
        NSDate *tuesdayEarly = DateAt(calendar, 2026, 11, 3, 2, 0);
        NSDate *tuesdayLate = DateAt(calendar, 2026, 11, 3, 23, 0);
        NSDate *tuesdaySeven = DateAt(calendar, 2026, 11, 3, 7, 0);
        NSDate *sundayLate = DateAt(calendar, 2026, 11, 1, 23, 0);
        NSDate *mondayEight = DateAt(calendar, 2026, 11, 2, 8, 59);
        NSDate *mondaySeventeen = DateAt(calendar, 2026, 11, 2, 17, 0);
        NSDate *mondaySixteenFiftyNine = DateAt(calendar, 2026, 11, 2, 16, 59);

        Check([[calendar components:NSCalendarUnitWeekday fromDate:mondayMorning] weekday] == 2,
              @"2026-11-02 is Monday");

        NFNotificationContext *saleContext = MakeContext(@"com.example.app", @"BIG SALE today", nil, nil, NO);
        NFDecision *decision = Evaluate(@[MakeFilter(NFFilterActionBlock, NFFilterMatchContains, NFFilterFieldAny, @"sale")],
                                        saleContext, calendar, mondayMorning);
        Check(decision.isBlock, @"contains is case-insensitive and matches any field");

        decision = Evaluate(@[MakeFilter(NFFilterActionBlock, NFFilterMatchStartsWith, NFFilterFieldTitle, @"big")],
                            saleContext, calendar, mondayMorning);
        Check(decision.isBlock, @"starts with matches the title");

        decision = Evaluate(@[MakeFilter(NFFilterActionBlock, NFFilterMatchEndsWith, NFFilterFieldTitle, @"today")],
                            saleContext, calendar, mondayMorning);
        Check(decision.isBlock, @"ends with matches the title");

        NFNotificationContext *exactContext = MakeContext(@"com.example.app", nil, @"Server Alert", nil, NO);
        decision = Evaluate(@[MakeFilter(NFFilterActionBlock, NFFilterMatchEquals, NFFilterFieldSubtitle, @"server alert")],
                            exactContext, calendar, mondayMorning);
        Check(decision.isBlock, @"exact match is case-insensitive and field-specific");

        NFNotificationContext *regexContext = MakeContext(@"com.example.app", @"foo42", nil, nil, NO);
        decision = Evaluate(@[MakeFilter(NFFilterActionBlock, NFFilterMatchRegex, NFFilterFieldTitle, @"^foo[0-9]+$")],
                            regexContext, calendar, mondayMorning);
        Check(decision.isBlock, @"regex matches case-insensitively");

        decision = Evaluate(@[MakeFilter(NFFilterActionBlock, NFFilterMatchRegex, NFFilterFieldTitle, @"[")],
                            regexContext, calendar, mondayMorning);
        Check(decision.isAllow, @"invalid regex is ignored");

        decision = Evaluate(@[MakeFilter(NFFilterActionBlock, NFFilterMatchAlways, NFFilterFieldAny, @"")],
                            MakeContext(@"com.example.app", @"anything", nil, nil, NO), calendar, mondayMorning);
        Check(decision.isBlock, @"always matches without text");

        decision = Evaluate(@[MakeFilter(NFFilterActionBlock, NFFilterMatchContains, NFFilterFieldAny, @"")],
                            saleContext, calendar, mondayMorning);
        Check(decision.isAllow, @"empty non-always text is ignored");

        NFFilter *appFilter = MakeFilter(NFFilterActionBlock, NFFilterMatchContains, NFFilterFieldAny, @"sale");
        appFilter.bundleIdentifier = @"com.example.app";
        decision = Evaluate(@[appFilter], saleContext, calendar, mondayMorning);
        Check(decision.isBlock, @"app-specific filter matches its bundle");

        decision = Evaluate(@[appFilter], MakeContext(@"com.other.app", @"BIG SALE", nil, nil, NO),
                            calendar, mondayMorning);
        Check(decision.isAllow, @"app-specific filter does not match another app");

        NFFilter *allApps = MakeFilter(NFFilterActionBlock, NFFilterMatchContains, NFFilterFieldAny, @"sale");
        decision = Evaluate(@[allApps], MakeContext(nil, @"BIG SALE", nil, nil, NO),
                            calendar, mondayMorning);
        Check(decision.isBlock, @"all-app filter matches a nil section");

        NFFilter *disabled = MakeFilter(NFFilterActionBlock, NFFilterMatchContains, NFFilterFieldAny, @"sale");
        disabled.enabled = NO;
        decision = Evaluate(@[disabled], saleContext, calendar, mondayMorning);
        Check(decision.isAllow, @"disabled filters are ignored");

        NFFilter *block = MakeFilter(NFFilterActionBlock, NFFilterMatchContains, NFFilterFieldAny, @"sale");
        NFFilter *allow = MakeFilter(NFFilterActionAllow, NFFilterMatchContains, NFFilterFieldAny, @"sale");
        decision = Evaluate(@[block, allow], saleContext, calendar, mondayMorning);
        Check(decision.isAllow, @"allow overrides block regardless of order (block first)");
        decision = Evaluate(@[allow, block], saleContext, calendar, mondayMorning);
        Check(decision.isAllow, @"allow overrides block regardless of order (allow first)");

        NFFilter *mute = MakeFilter(NFFilterActionMute, NFFilterMatchContains, NFFilterFieldAny, @"sale");
        decision = Evaluate(@[mute, block], saleContext, calendar, mondayMorning);
        Check(decision.isBlock, @"block overrides mute regardless of order (mute first)");
        decision = Evaluate(@[block, mute], saleContext, calendar, mondayMorning);
        Check(decision.isBlock, @"block overrides mute regardless of order (block first)");

        NFFilter *firstBlock = MakeFilter(NFFilterActionBlock, NFFilterMatchContains, NFFilterFieldAny, @"sale");
        firstBlock.name = @"First Block";
        NFFilter *secondBlock = MakeFilter(NFFilterActionBlock, NFFilterMatchContains, NFFilterFieldAny, @"sale");
        secondBlock.name = @"Second Block";
        decision = Evaluate(@[firstBlock, secondBlock], saleContext, calendar, mondayMorning);
        Check(decision.isBlock, @"multiple block filters produce block");
        Check([decision.matchedFilter.name isEqualToString:@"First Block"],
              @"first matching block filter is retained for history");

        NFFilter *sameDay = MakeFilter(NFFilterActionBlock, NFFilterMatchAlways, NFFilterFieldAny, @"");
        sameDay.scheduleEnabled = YES;
        sameDay.weekdays = Weekdays(YES, NO, NO, NO, NO, NO, NO);
        sameDay.startMinutes = 9 * 60;
        sameDay.endMinutes = 17 * 60;
        decision = Evaluate(@[sameDay], saleContext, calendar, mondayMorning);
        Check(decision.isBlock, @"same-day schedule is active at start");
        decision = Evaluate(@[sameDay], saleContext, calendar, mondaySixteenFiftyNine);
        Check(decision.isBlock, @"same-day schedule is active before end");
        decision = Evaluate(@[sameDay], saleContext, calendar, mondaySeventeen);
        Check(decision.isAllow, @"same-day schedule is inactive at end");
        decision = Evaluate(@[sameDay], saleContext, calendar, mondayEight);
        Check(decision.isAllow, @"same-day schedule is inactive before start");

        NFFilter *overnight = MakeFilter(NFFilterActionBlock, NFFilterMatchAlways, NFFilterFieldAny, @"");
        overnight.scheduleEnabled = YES;
        overnight.weekdays = Weekdays(YES, NO, NO, NO, NO, NO, NO);
        overnight.startMinutes = 22 * 60;
        overnight.endMinutes = 7 * 60;
        decision = Evaluate(@[overnight], saleContext, calendar, mondayLate);
        Check(decision.isBlock, @"overnight schedule is active on its start day");
        decision = Evaluate(@[overnight], saleContext, calendar, tuesdayEarly);
        Check(decision.isBlock, @"overnight schedule carries into the next day");
        decision = Evaluate(@[overnight], saleContext, calendar, tuesdayLate);
        Check(decision.isAllow, @"overnight schedule does not apply to an unselected next day");
        decision = Evaluate(@[overnight], saleContext, calendar, sundayLate);
        Check(decision.isAllow, @"overnight schedule does not apply to an unselected previous day");
        decision = Evaluate(@[overnight], saleContext, calendar, tuesdaySeven);
        Check(decision.isAllow, @"overnight schedule ends exclusively at end time");

        NFFilter *equalSchedule = MakeFilter(NFFilterActionBlock, NFFilterMatchAlways, NFFilterFieldAny, @"");
        equalSchedule.scheduleEnabled = YES;
        equalSchedule.weekdays = Weekdays(YES, YES, YES, YES, YES, YES, YES);
        equalSchedule.startMinutes = 9 * 60;
        equalSchedule.endMinutes = 9 * 60;
        decision = Evaluate(@[equalSchedule], saleContext, calendar, mondayMorning);
        Check(decision.isAllow, @"equal start and end times are inactive");

        NFFilter *invalidSchedule = MakeFilter(NFFilterActionBlock, NFFilterMatchAlways, NFFilterFieldAny, @"");
        invalidSchedule.scheduleEnabled = YES;
        invalidSchedule.weekdays = @[@YES, @NO];
        decision = Evaluate(@[invalidSchedule], saleContext, calendar, mondayMorning);
        Check(decision.isAllow, @"invalid weekday arrays are inactive");

        NFFilter *malformedWeekdays = [[NFFilter alloc] initWithDictionary:@{
            @"weekdays": @[@"Mon", @"Tue", @"Wed", @"Thu", @"Fri", @"Sat", @"Sun"],
            @"scheduleEnabled": @YES
        }];
        Check(malformedWeekdays.weekdays == nil,
              @"malformed weekday values are discarded");

        NFFilter *allDaysOff = MakeFilter(NFFilterActionBlock, NFFilterMatchAlways, NFFilterFieldAny, @"");
        allDaysOff.scheduleEnabled = YES;
        allDaysOff.weekdays = Weekdays(NO, NO, NO, NO, NO, NO, NO);
        decision = Evaluate(@[allDaysOff], saleContext, calendar, mondayMorning);
        Check(decision.isAllow, @"schedule with no selected weekdays is inactive");

        NFFilter *scheduleDisabled = MakeFilter(NFFilterActionBlock, NFFilterMatchAlways, NFFilterFieldAny, @"");
        scheduleDisabled.scheduleEnabled = NO;
        scheduleDisabled.weekdays = Weekdays(NO, NO, NO, NO, NO, NO, NO);
        decision = Evaluate(@[scheduleDisabled], saleContext, calendar, mondayMorning);
        Check(decision.isBlock, @"disabled schedule ignores weekday data");

        NFNotificationContext *critical = MakeContext(@"com.example.app", @"BIG SALE", nil, nil, YES);
        decision = Evaluate(@[block], critical, calendar, mondayMorning);
        Check(decision.isAllow, @"critical alerts always allow");
        Check(decision.matchedFilter == nil, @"critical allow has no matched filter");

        decision = Evaluate(@[block], nil, calendar, mondayMorning);
        Check(decision.isAllow, @"nil context allows");

        decision = Evaluate(@[], saleContext, calendar, mondayMorning);
        Check(decision.isAllow, @"empty filter list allows");

        NFNotificationContext *unicodeContext = MakeContext(@"com.example.app", @"CAFÉ", nil, nil, NO);
        decision = Evaluate(@[MakeFilter(NFFilterActionBlock, NFFilterMatchContains, NFFilterFieldTitle, @"café")],
                            unicodeContext, calendar, mondayMorning);
        Check(decision.isBlock, @"unicode letters match case-insensitively");

        NFNotificationContext *subtitleOnly = MakeContext(@"com.example.app", @"Title", @"SALE", nil, NO);
        decision = Evaluate(@[MakeFilter(NFFilterActionBlock, NFFilterMatchContains, NFFilterFieldSubtitle, @"sale")],
                            subtitleOnly, calendar, mondayMorning);
        Check(decision.isBlock, @"subtitle field matches independently");
        decision = Evaluate(@[MakeFilter(NFFilterActionBlock, NFFilterMatchContains, NFFilterFieldMessage, @"sale")],
                            subtitleOnly, calendar, mondayMorning);
        Check(decision.isAllow, @"message field does not match subtitle text");

        NFFilter *roundTrip = MakeFilter(NFFilterActionMute, NFFilterMatchEndsWith, NFFilterFieldMessage, @"done");
        roundTrip.name = @"Round Trip";
        roundTrip.bundleIdentifier = @"com.example.app";
        roundTrip.scheduleEnabled = YES;
        roundTrip.weekdays = Weekdays(YES, NO, YES, NO, YES, NO, NO);
        roundTrip.startMinutes = 8 * 60 + 15;
        roundTrip.endMinutes = 18 * 60 + 45;
        NSError *transferError = nil;
        NSData *exportedData = [NFTransfer exportDataWithFilters:@[roundTrip] error:&transferError];
        Check(exportedData.length > 0 && transferError == nil, @"export produces JSON data");
        NSArray<NFFilter *> *roundTripFilters = [NFTransfer filtersFromData:exportedData error:&transferError];
        Check(roundTripFilters.count == 1, @"import reads the exported filter");
        NFFilter *reloaded = roundTripFilters.firstObject;
        Check([reloaded.uuid isEqualToString:roundTrip.uuid], @"round trip preserves UUID");
        Check([reloaded.name isEqualToString:roundTrip.name], @"round trip preserves name");
        Check(reloaded.action == roundTrip.action, @"round trip preserves action");
        Check(reloaded.matchType == roundTrip.matchType, @"round trip preserves match type");
        Check(reloaded.field == roundTrip.field, @"round trip preserves field");
        Check(reloaded.scheduleEnabled && reloaded.startMinutes == roundTrip.startMinutes &&
              reloaded.endMinutes == roundTrip.endMinutes, @"round trip preserves schedule");

        NSData *invalidData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
        Check([NFTransfer filtersFromData:invalidData error:&transferError] == nil,
              @"invalid import data is rejected");

        NFFilter *validationBase = MakeFilter(NFFilterActionBlock,
                                              NFFilterMatchContains,
                                              NFFilterFieldAny,
                                              @"valid");
        NSMutableDictionary *baseDictionary =
            [[validationBase dictionaryRepresentation] mutableCopy];

        NSMutableDictionary *badName = [baseDictionary mutableCopy];
        badName[@"name"] = @"   ";
        NSMutableDictionary *badText = [baseDictionary mutableCopy];
        badText[@"text"] = @"   ";
        NSMutableDictionary *badRegex = [baseDictionary mutableCopy];
        badRegex[@"matchType"] = @(NFFilterMatchRegex);
        badRegex[@"text"] = @"[";
        NSMutableDictionary *badSchedule = [baseDictionary mutableCopy];
        badSchedule[@"scheduleEnabled"] = @YES;
        badSchedule[@"startMinutes"] = @60;
        badSchedule[@"endMinutes"] = @60;

        NSArray<NSDictionary *> *invalidFilters = @[badName, badText, badRegex, badSchedule];
        NSArray<NSString *> *invalidReasons = @[@"whitespace name",
                                               @"empty text",
                                               @"invalid regex",
                                               @"equal schedule times"];
        for (NSUInteger index = 0; index < invalidFilters.count; index++) {
            NSData *invalidFilterData =
                [NSJSONSerialization dataWithJSONObject:
                    @{ @"schemaVersion": @1, @"filters": @[invalidFilters[index]] }
                                                options:0
                                                  error:NULL];
            Check(invalidFilterData != nil &&
                  [NFTransfer filtersFromData:invalidFilterData error:&transferError] == nil,
                  [NSString stringWithFormat:@"invalid import rejected (%@)",
                      invalidReasons[index]]);
        }

        NFFilter *existingA = MakeFilter(NFFilterActionBlock, NFFilterMatchContains, NFFilterFieldAny, @"a");
        existingA.name = @"Existing A";
        NFFilter *existingB = MakeFilter(NFFilterActionMute, NFFilterMatchContains, NFFilterFieldAny, @"b");
        existingB.name = @"Existing B";
        NFFilter *importedB = [existingB copy];
        importedB.name = @"Imported B";
        NFFilter *importedC = MakeFilter(NFFilterActionAllow, NFFilterMatchContains, NFFilterFieldAny, @"c");
        importedC.name = @"Imported C";
        NSArray<NFFilter *> *merged = [NFTransfer mergeExistingFilters:@[existingA, existingB]
                                                   withImportedFilters:@[importedB, importedC]];
        Check(merged.count == 3, @"merge preserves existing filters and adds new ones");
        Check([merged[0].name isEqualToString:@"Existing A"], @"merge preserves unrelated existing filter");
        Check([merged[1].name isEqualToString:@"Imported B"], @"merge updates a matching UUID");
        Check([merged[2].name isEqualToString:@"Imported C"], @"merge appends a new filter");

        printf("\n%lu passed, %lu failed\n", (unsigned long)gPassed, (unsigned long)gFailed);
    }
    return gFailed == 0 ? 0 : 1;
}
