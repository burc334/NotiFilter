#import <Foundation/Foundation.h>
#import "NFDecision.h"
#import "NFFilter.h"
#import "NFNotificationContext.h"

@interface NFFilterEngine : NSObject

- (instancetype)initWithFilters:(NSArray<NFFilter *> *)filters;

- (NFDecision *)decisionForContext:(NFNotificationContext *)context;

- (NFDecision *)decisionForContext:(NFNotificationContext *)context
                            atDate:(NSDate *)date
                          calendar:(NSCalendar *)calendar;

@end
