#import <UIKit/UIKit.h>

@interface NotiFilterInlineTextFieldCell : UITableViewCell <UITextFieldDelegate>

@property (nonatomic, readonly) UITextField *textField;
@property (nonatomic, copy) void (^onTextChanged)(NSString *text);

- (void)configureWithTitle:(NSString *)title
                      text:(NSString *)text
               placeholder:(NSString *)placeholder;

- (void)beginEditing;

@end
