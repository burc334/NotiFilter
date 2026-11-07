#import "NotiFilterInlineTextFieldCell.h"

@interface NotiFilterInlineTextFieldCell ()
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation NotiFilterInlineTextFieldCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
               reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.layoutMargins = UIEdgeInsetsMake(0.0, 16.0, 0.0, 16.0);

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _titleLabel.textColor = [UIColor labelColor];
        _titleLabel.adjustsFontForContentSizeCategory = YES;
        _titleLabel.numberOfLines = 1;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_titleLabel setContentHuggingPriority:UILayoutPriorityRequired
                                      forAxis:UILayoutConstraintAxisHorizontal];
        [_titleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                    forAxis:UILayoutConstraintAxisHorizontal];
        [self.contentView addSubview:_titleLabel];

        _textField = [[UITextField alloc] initWithFrame:CGRectZero];
        _textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _textField.adjustsFontForContentSizeCategory = YES;
        _textField.textAlignment = NSTextAlignmentRight;
        _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _textField.returnKeyType = UIReturnKeyDone;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textField.smartQuotesType = UITextSmartQuotesTypeNo;
        _textField.smartDashesType = UITextSmartDashesTypeNo;
        _textField.delegate = self;
        _textField.translatesAutoresizingMaskIntoConstraints = NO;
        [_textField addTarget:self
                       action:@selector(textChanged:)
             forControlEvents:UIControlEventEditingChanged];
        [self.contentView addSubview:_textField];

        UILayoutGuide *margins = self.contentView.layoutMarginsGuide;
        [NSLayoutConstraint activateConstraints:@[
            [_titleLabel.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
            [_titleLabel.centerYAnchor constraintEqualToAnchor:margins.centerYAnchor],

            [_textField.leadingAnchor constraintEqualToAnchor:_titleLabel.trailingAnchor
                                                      constant:12.0],
            [_textField.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
            [_textField.centerYAnchor constraintEqualToAnchor:margins.centerYAnchor],
            [_textField.heightAnchor constraintEqualToConstant:32.0]
        ]];
    }
    return self;
}

- (void)configureWithTitle:(NSString *)title
                      text:(NSString *)text
               placeholder:(NSString *)placeholder {
    self.titleLabel.text = title;
    self.textField.text = text;
    self.textField.placeholder = placeholder;
    self.textField.accessibilityLabel = title;
}

- (void)beginEditing {
    [self.textField becomeFirstResponder];
}

- (void)textChanged:(UITextField *)textField {
    if (self.onTextChanged) {
        self.onTextChanged(textField.text ?: @"");
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.onTextChanged = nil;
    self.titleLabel.text = nil;
    self.textField.text = nil;
    self.textField.placeholder = nil;
}

@end
