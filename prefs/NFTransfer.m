#import "NFTransfer.h"

static NSString *const NFTransferErrorDomain = @"com.burc334.notifilter.transfer";

static NSError *NFTransferError(NSString *message) {
    return [NSError errorWithDomain:NFTransferErrorDomain
                               code:1
                           userInfo:@{ NSLocalizedDescriptionKey: message }];
}

static BOOL NFIsNumberInRange(id value, NSInteger minimum, NSInteger maximum) {
    if (![value isKindOfClass:[NSNumber class]]) {
        return NO;
    }
    NSInteger integer = [value integerValue];
    return integer >= minimum && integer <= maximum;
}

static BOOL NFValidWeekdays(id value) {
    if (![value isKindOfClass:[NSArray class]] || [value count] != 7) {
        return NO;
    }
    for (id day in value) {
        if (![day isKindOfClass:[NSNumber class]]) {
            return NO;
        }
    }
    return YES;
}

static BOOL NFValidateFilterDictionary(NSDictionary *dictionary, NSError **error) {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        if (error) *error = NFTransferError(@"The file contains an invalid filter entry.");
        return NO;
    }

    id uuid = dictionary[@"uuid"];
    if (![uuid isKindOfClass:[NSString class]] || [uuid length] == 0) {
        if (error) *error = NFTransferError(@"A filter is missing its UUID.");
        return NO;
    }

    NSString *name = dictionary[@"name"];
    if (![name isKindOfClass:[NSString class]]) {
        if (error) *error = NFTransferError(@"A filter is missing its name.");
        return NO;
    }
    NSString *trimmedName = [name stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedName.length == 0) {
        if (error) *error = NFTransferError(@"A filter is missing its name.");
        return NO;
    }

    NSNumber *matchType = dictionary[@"matchType"];
    if (![dictionary[@"enabled"] isKindOfClass:[NSNumber class]] ||
        !NFIsNumberInRange(dictionary[@"action"], 0, 2) ||
        !NFIsNumberInRange(matchType, 0, 5) ||
        !NFIsNumberInRange(dictionary[@"field"], 0, 3) ||
        ![dictionary[@"text"] isKindOfClass:[NSString class]] ||
        ![dictionary[@"scheduleEnabled"] isKindOfClass:[NSNumber class]] ||
        !NFValidWeekdays(dictionary[@"weekdays"]) ||
        !NFIsNumberInRange(dictionary[@"startMinutes"], 0, 1439) ||
        !NFIsNumberInRange(dictionary[@"endMinutes"], 0, 1439)) {
        if (error) *error = NFTransferError(@"A filter has invalid or missing fields.");
        return NO;
    }

    NSString *text = dictionary[@"text"];
    NSString *trimmedText = [text stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (matchType.integerValue != NFFilterMatchAlways && trimmedText.length == 0) {
        if (error) *error = NFTransferError(@"A filter has empty match text.");
        return NO;
    }

    if (matchType.integerValue == NFFilterMatchRegex) {
        NSError *regexError = nil;
        NSRegularExpression *regex =
            [NSRegularExpression regularExpressionWithPattern:text
                                                      options:NSRegularExpressionCaseInsensitive
                                                        error:&regexError];
        if (!regex) {
            if (error) *error = NFTransferError(@"A filter has an invalid regular expression.");
            return NO;
        }
    }

    NSNumber *scheduleEnabled = dictionary[@"scheduleEnabled"];
    if (scheduleEnabled.boolValue) {
        BOOL anyDay = NO;
        for (id day in dictionary[@"weekdays"]) {
            if ([day boolValue]) {
                anyDay = YES;
                break;
            }
        }
        if (!anyDay) {
            if (error) *error = NFTransferError(@"A filter schedule has no selected days.");
            return NO;
        }
        if ([dictionary[@"startMinutes"] integerValue] ==
            [dictionary[@"endMinutes"] integerValue]) {
            if (error) *error = NFTransferError(@"A filter schedule has equal start and end times.");
            return NO;
        }
    }

    for (NSString *key in @[@"bundleIdentifier", @"appName"]) {
        id value = dictionary[key];
        if (value && ![value isKindOfClass:[NSString class]]) {
            if (error) *error = NFTransferError(@"A filter has an invalid app field.");
            return NO;
        }
    }

    return YES;
}

@implementation NFTransfer

+ (NSData *)exportDataWithFilters:(NSArray<NFFilter *> *)filters
                            error:(NSError **)error {
    if (![filters isKindOfClass:[NSArray class]] || filters.count == 0) {
        if (error) *error = NFTransferError(@"There are no filters to export.");
        return nil;
    }

    NSMutableArray<NSDictionary *> *rawFilters = [NSMutableArray array];
    for (id object in filters) {
        if (![object isKindOfClass:[NFFilter class]]) {
            continue;
        }
        NFFilter *filter = object;
        [rawFilters addObject:[filter dictionaryRepresentation]];
    }

    if (rawFilters.count == 0) {
        if (error) *error = NFTransferError(@"There are no filters to export.");
        return nil;
    }

    NSDictionary *document = @{
        @"schemaVersion": @1,
        @"filters": rawFilters
    };

    return [NSJSONSerialization dataWithJSONObject:document
                                            options:(NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys)
                                              error:error];
}

+ (NSArray<NFFilter *> *)filtersFromData:(NSData *)data
                                  error:(NSError **)error {
    if (![data isKindOfClass:[NSData class]] || data.length == 0) {
        if (error) *error = NFTransferError(@"The selected file is empty.");
        return nil;
    }

    NSError *jsonError = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (![object isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = jsonError ?: NFTransferError(@"The selected file is not valid JSON.");
        }
        return nil;
    }

    NSDictionary *document = object;
    NSNumber *schemaVersion = document[@"schemaVersion"];
    if (![schemaVersion isKindOfClass:[NSNumber class]] || schemaVersion.integerValue != 1) {
        if (error) *error = NFTransferError(@"Unsupported filter file version.");
        return nil;
    }

    NSArray *rawFilters = document[@"filters"];
    if (![rawFilters isKindOfClass:[NSArray class]] || rawFilters.count == 0) {
        if (error) *error = NFTransferError(@"The file does not contain any filters.");
        return nil;
    }

    NSMutableArray<NFFilter *> *filters = [NSMutableArray array];
    for (id entry in rawFilters) {
        if (!NFValidateFilterDictionary(entry, error)) {
            return nil;
        }
        NFFilter *filter = [[NFFilter alloc] initWithDictionary:entry];
        [filters addObject:filter];
    }
    return filters;
}

+ (NSArray<NFFilter *> *)mergeExistingFilters:(NSArray<NFFilter *> *)existing
                           withImportedFilters:(NSArray<NFFilter *> *)imported {
    NSMutableArray<NFFilter *> *result =
        [existing isKindOfClass:[NSArray class]] ? [existing mutableCopy] : [NSMutableArray array];

    for (NFFilter *importedFilter in imported) {
        if (![importedFilter isKindOfClass:[NFFilter class]]) {
            continue;
        }

        NSUInteger existingIndex = NSNotFound;
        for (NSUInteger index = 0; index < result.count; index++) {
            if ([result[index].uuid isEqualToString:importedFilter.uuid]) {
                existingIndex = index;
                break;
            }
        }

        if (existingIndex == NSNotFound) {
            [result addObject:importedFilter];
        } else {
            result[existingIndex] = importedFilter;
        }
    }
    return result;
}

@end
