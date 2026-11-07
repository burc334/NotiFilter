#import "NotiFilterTimePickerController.h"

@interface NotiFilterTimePickerController ()
@property (nonatomic, copy) NSString *screenTitle;
@property (nonatomic, assign) NSInteger initialMinutes;
@property (nonatomic, strong) UIDatePicker *datePicker;
@end

@implementation NotiFilterTimePickerController

- (instancetype)initWithTitle:(NSString *)title minutes:(NSInteger)minutes {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _screenTitle = [title copy];
        _initialMinutes = minutes;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.screenTitle;
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self
                                                      action:@selector(save)];

    self.datePicker = [[UIDatePicker alloc] initWithFrame:CGRectZero];
    self.datePicker.datePickerMode = UIDatePickerModeTime;
    self.datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    self.datePicker.minuteInterval = 1;
    self.datePicker.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.datePicker];

    UILayoutGuide *margins = self.view.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.datePicker.centerXAnchor constraintEqualToAnchor:margins.centerXAnchor],
        [self.datePicker.centerYAnchor constraintEqualToAnchor:margins.centerYAnchor],
        [self.datePicker.leadingAnchor constraintGreaterThanOrEqualToAnchor:margins.leadingAnchor],
        [self.datePicker.trailingAnchor constraintLessThanOrEqualToAnchor:margins.trailingAnchor]
    ]];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components =
        [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
                    fromDate:[NSDate date]];
    components.hour = self.initialMinutes / 60;
    components.minute = self.initialMinutes % 60;
    components.second = 0;
    NSDate *date = [calendar dateFromComponents:components];
    if (date) {
        self.datePicker.date = date;
    }
}

- (void)save {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components =
        [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute)
                    fromDate:self.datePicker.date];
    NSInteger minutes = components.hour * 60 + components.minute;
    if (self.onSave) {
        self.onSave(minutes);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
