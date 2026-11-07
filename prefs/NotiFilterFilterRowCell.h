#import <UIKit/UIKit.h>
#import "NFFilter.h"

@interface NotiFilterFilterRowCell : UITableViewCell

@property (nonatomic, copy) void (^onToggle)(BOOL enabled);

- (void)configureWithFilter:(NFFilter *)filter subtitle:(NSString *)subtitle;

@end
