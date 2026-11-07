#import <UIKit/UIKit.h>

@interface NotiFilterAppPickerController : UITableViewController

@property (nonatomic, copy) NSString *selectedBundleIdentifier;
@property (nonatomic, copy) void (^onSelect)(NSString *bundleIdentifier, NSString *appName);

@end
