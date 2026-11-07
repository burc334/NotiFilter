#import "NFDecision.h"

@implementation NFDecision

+ (instancetype)decisionWithAction:(NFFilterAction)action
                      matchedFilter:(NFFilter *)matchedFilter {
    NFDecision *decision = [[self alloc] init];
    decision->_action = action;
    decision->_matchedFilter = [matchedFilter copy];
    return decision;
}

- (BOOL)isAllow {
    return self.action == NFFilterActionAllow;
}

- (BOOL)isMute {
    return self.action == NFFilterActionMute;
}

- (BOOL)isBlock {
    return self.action == NFFilterActionBlock;
}

@end
