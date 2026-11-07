#import <Foundation/Foundation.h>
#import "NFFilter.h"

@interface NFDecision : NSObject

@property (nonatomic, assign, readonly) NFFilterAction action;
@property (nonatomic, strong, readonly) NFFilter *matchedFilter;

+ (instancetype)decisionWithAction:(NFFilterAction)action
                      matchedFilter:(NFFilter *)matchedFilter;

- (BOOL)isAllow;
- (BOOL)isMute;
- (BOOL)isBlock;

@end
