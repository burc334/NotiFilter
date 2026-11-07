#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NFFilterAction) {
    NFFilterActionBlock = 0,
    NFFilterActionMute = 1,
    NFFilterActionAllow = 2
};

typedef NS_ENUM(NSInteger, NFFilterMatchType) {
    NFFilterMatchContains = 0,
    NFFilterMatchStartsWith = 1,
    NFFilterMatchEndsWith = 2,
    NFFilterMatchEquals = 3,
    NFFilterMatchRegex = 4,
    NFFilterMatchAlways = 5
};

typedef NS_ENUM(NSInteger, NFFilterField) {
    NFFilterFieldAny = 0,
    NFFilterFieldTitle = 1,
    NFFilterFieldSubtitle = 2,
    NFFilterFieldMessage = 3
};

@interface NFFilter : NSObject <NSCopying>

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *bundleIdentifier;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, assign) NFFilterAction action;
@property (nonatomic, assign) NFFilterMatchType matchType;
@property (nonatomic, assign) NFFilterField field;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) BOOL scheduleEnabled;
@property (nonatomic, copy) NSArray<NSNumber *> *weekdays;
@property (nonatomic, assign) NSInteger startMinutes;
@property (nonatomic, assign) NSInteger endMinutes;

+ (instancetype)defaultFilter;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;

+ (NSString *)titleForAction:(NFFilterAction)action;
+ (NSString *)titleForMatchType:(NFFilterMatchType)matchType;
+ (NSString *)titleForField:(NFFilterField)field;
+ (NSArray<NSString *> *)actionTitles;
+ (NSArray<NSString *> *)matchTypeTitles;
+ (NSArray<NSString *> *)fieldTitles;

@end
