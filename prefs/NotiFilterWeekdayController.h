#import <UIKit/UIKit.h>

@interface NotiFilterWeekdayController : UITableViewController

@property (nonatomic, copy) void (^onSave)(NSArray<NSNumber *> *weekdays);

- (instancetype)initWithWeekdays:(NSArray<NSNumber *> *)weekdays;

@end
