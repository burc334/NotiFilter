#import <UIKit/UIKit.h>

@interface NotiFilterChoiceController : UITableViewController

@property (nonatomic, copy) void (^onSelect)(NSInteger index);

- (instancetype)initWithTitle:(NSString *)title
                       titles:(NSArray<NSString *> *)titles
                selectedIndex:(NSInteger)selectedIndex;

@end
