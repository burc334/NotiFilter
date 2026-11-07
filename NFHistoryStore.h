#import <Foundation/Foundation.h>
#import "NFNotificationContext.h"
#import "NFFilter.h"

@interface NFHistoryStore : NSObject

+ (void)recordBlockedContext:(NFNotificationContext *)context
                      filter:(NFFilter *)filter;
+ (NSArray<NSDictionary *> *)entries;
+ (void)clear;

@end
