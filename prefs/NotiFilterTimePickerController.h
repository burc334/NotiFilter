#import <UIKit/UIKit.h>

@interface NotiFilterTimePickerController : UIViewController

@property (nonatomic, copy) void (^onSave)(NSInteger minutes);

- (instancetype)initWithTitle:(NSString *)title minutes:(NSInteger)minutes;

@end
