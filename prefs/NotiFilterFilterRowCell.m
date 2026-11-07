#import "NotiFilterFilterRowCell.h"

@interface NotiFilterFilterRowCell ()
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UISwitch *toggle;
@property (nonatomic, strong) UIImageView *chevronView;
@property (nonatomic, strong) UIStackView *textStack;
@property (nonatomic, strong) UIStackView *horizontalStack;
@end

@implementation NotiFilterFilterRowCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
               reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        self.contentView.layoutMargins = UIEdgeInsetsMake(10.0, 16.0, 10.0, 16.0);

        _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _nameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _nameLabel.adjustsFontForContentSizeCategory = YES;
        _nameLabel.numberOfLines = 1;
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        _detailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _detailLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        _detailLabel.textColor = [UIColor secondaryLabelColor];
        _detailLabel.adjustsFontForContentSizeCategory = YES;
        _detailLabel.numberOfLines = 1;
        _detailLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        _textStack = [[UIStackView alloc] initWithArrangedSubviews:@[_nameLabel, _detailLabel]];
        _textStack.axis = UILayoutConstraintAxisVertical;
        _textStack.spacing = 2.0;
        _textStack.alignment = UIStackViewAlignmentFill;
        [_textStack setContentHuggingPriority:UILayoutPriorityDefaultLow
                                     forAxis:UILayoutConstraintAxisHorizontal];
        [_textStack setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                    forAxis:UILayoutConstraintAxisHorizontal];

        _toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
        [_toggle addTarget:self
                    action:@selector(toggleChanged:)
          forControlEvents:UIControlEventValueChanged];
        [_toggle setContentHuggingPriority:UILayoutPriorityRequired
                                  forAxis:UILayoutConstraintAxisHorizontal];

        _chevronView = [[UIImageView alloc] initWithImage:
            [UIImage systemImageNamed:@"chevron.right"]];
        _chevronView.tintColor = [UIColor tertiaryLabelColor];
        _chevronView.contentMode = UIViewContentModeScaleAspectFit;
        _chevronView.translatesAutoresizingMaskIntoConstraints = NO;
        [_chevronView.widthAnchor constraintEqualToConstant:10.0].active = YES;
        [_chevronView.heightAnchor constraintEqualToConstant:20.0].active = YES;

        _horizontalStack = [[UIStackView alloc] initWithArrangedSubviews:
            @[_textStack, _toggle, _chevronView]];
        _horizontalStack.axis = UILayoutConstraintAxisHorizontal;
        _horizontalStack.alignment = UIStackViewAlignmentCenter;
        _horizontalStack.spacing = 10.0;
        _horizontalStack.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_horizontalStack];

        UILayoutGuide *margins = self.contentView.layoutMarginsGuide;
        [NSLayoutConstraint activateConstraints:@[
            [_horizontalStack.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
            [_horizontalStack.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
            [_horizontalStack.topAnchor constraintEqualToAnchor:margins.topAnchor],
            [_horizontalStack.bottomAnchor constraintEqualToAnchor:margins.bottomAnchor]
        ]];
    }
    return self;
}

- (void)configureWithFilter:(NFFilter *)filter subtitle:(NSString *)subtitle {
    self.nameLabel.text = filter.name;
    self.detailLabel.text = subtitle;

    self.toggle.on = filter.enabled;
}

- (void)toggleChanged:(UISwitch *)toggle {
    (void)toggle;
    if (self.onToggle) {
        self.onToggle(self.toggle.on);
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.onToggle = nil;
    self.nameLabel.text = nil;
    self.detailLabel.text = nil;
}

@end
