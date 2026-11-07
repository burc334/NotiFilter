#import "NotiFilterFilterEditorController.h"
#import "NotiFilterAppPickerController.h"
#import "NotiFilterChoiceController.h"
#import "NotiFilterInlineTextFieldCell.h"
#import "NotiFilterTimePickerController.h"
#import "NotiFilterWeekdayController.h"

typedef NS_ENUM(NSInteger, NotiFilterEditorSection) {
    NotiFilterEditorSectionFilter = 0,
    NotiFilterEditorSectionRule = 1,
    NotiFilterEditorSectionSchedule = 2,
    NotiFilterEditorSectionStatus = 3,
    NotiFilterEditorSectionDelete = 4,
    NotiFilterEditorSectionCount = 5
};

typedef NS_ENUM(NSInteger, NotiFilterFilterRow) {
    NotiFilterFilterRowName = 0,
    NotiFilterFilterRowApp = 1
};

typedef NS_ENUM(NSInteger, NotiFilterRuleRow) {
    NotiFilterRuleRowAction = 0,
    NotiFilterRuleRowMatch = 1,
    NotiFilterRuleRowField = 2,
    NotiFilterRuleRowText = 3
};

typedef NS_ENUM(NSInteger, NotiFilterScheduleRow) {
    NotiFilterScheduleRowSwitch = 0,
    NotiFilterScheduleRowDays = 1,
    NotiFilterScheduleRowStart = 2,
    NotiFilterScheduleRowEnd = 3
};

@interface NotiFilterFilterEditorController ()
@property (nonatomic, strong) NFFilter *draft;
@property (nonatomic, assign) BOOL editingExistingFilter;
@property (nonatomic, strong) UISwitch *enabledSwitch;
@property (nonatomic, strong) UISwitch *scheduleSwitch;
@end

@implementation NotiFilterFilterEditorController

- (instancetype)initWithFilter:(NFFilter *)filter {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _editingExistingFilter = filter != nil;
        _draft = filter ? [filter copy] : [NFFilter defaultFilter];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.editingExistingFilter ? @"Edit Filter" : @"New Filter";
    self.tableView.rowHeight = 44.0;

    self.enabledSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    [self.enabledSwitch addTarget:self
                           action:@selector(enabledChanged:)
                 forControlEvents:UIControlEventValueChanged];

    self.scheduleSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    [self.scheduleSwitch addTarget:self
                            action:@selector(scheduleChanged:)
                  forControlEvents:UIControlEventValueChanged];

    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                      target:self
                                                      action:@selector(save)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NotiFilterEditorSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case NotiFilterEditorSectionFilter:
            return 2;
        case NotiFilterEditorSectionRule:
            return self.draft.matchType == NFFilterMatchAlways ? 3 : 4;
        case NotiFilterEditorSectionSchedule:
            return 4;
        case NotiFilterEditorSectionStatus:
            return 1;
        case NotiFilterEditorSectionDelete:
            return self.editingExistingFilter ? 1 : 0;
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case NotiFilterEditorSectionFilter:
            return @"Filter";
        case NotiFilterEditorSectionRule:
            return @"Rule";
        case NotiFilterEditorSectionSchedule:
            return @"Schedule";
        case NotiFilterEditorSectionStatus:
            return @"Status";
        default:
            return nil;
    }
}

- (UITableViewCell *)valueCellWithTitle:(NSString *)title value:(NSString *)value {
    static NSString *identifier = @"NotiFilterValueRow";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                     reuseIdentifier:identifier];
    }
    cell.userInteractionEnabled = YES;
    cell.textLabel.enabled = YES;
    cell.detailTextLabel.enabled = YES;
    cell.textLabel.text = title;
    cell.detailTextLabel.text = value;
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (NotiFilterInlineTextFieldCell *)textCell {
    static NSString *identifier = @"NotiFilterInlineTextRow";
    NotiFilterInlineTextFieldCell *cell =
        [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[NotiFilterInlineTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:identifier];
    }
    return cell;
}

- (UITableViewCell *)switchCellWithTitle:(NSString *)title
                                  toggle:(UISwitch *)toggle
                                      on:(BOOL)on
                        reuseIdentifier:(NSString *)identifier {
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];
    }
    cell.textLabel.text = title;
    cell.accessoryView = toggle;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    toggle.on = on;
    return cell;
}

- (UITableViewCell *)deleteCell {
    static NSString *identifier = @"NotiFilterDeleteRow";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];
    }
    cell.textLabel.text = @"Delete Filter";
    cell.textLabel.textColor = [UIColor systemRedColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)configureScheduleCellState:(UITableViewCell *)cell {
    BOOL enabled = self.draft.scheduleEnabled;
    cell.userInteractionEnabled = enabled;
    cell.textLabel.enabled = enabled;
    cell.detailTextLabel.enabled = enabled;
    cell.accessoryType = enabled
        ? UITableViewCellAccessoryDisclosureIndicator
        : UITableViewCellAccessoryNone;
    cell.selectionStyle = enabled
        ? UITableViewCellSelectionStyleDefault
        : UITableViewCellSelectionStyleNone;
}

- (void)updateScheduleRows {
    for (NSInteger row = NotiFilterScheduleRowDays;
         row <= NotiFilterScheduleRowEnd;
         row++) {
        NSIndexPath *indexPath =
            [NSIndexPath indexPathForRow:row inSection:NotiFilterEditorSectionSchedule];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (cell) {
            [self configureScheduleCellState:cell];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == NotiFilterEditorSectionFilter) {
        if (indexPath.row == NotiFilterFilterRowName) {
            NotiFilterInlineTextFieldCell *cell = [self textCell];
            [cell configureWithTitle:@"Name" text:self.draft.name placeholder:@"Filter Name"];
            cell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
            cell.textField.autocorrectionType = UITextAutocorrectionTypeDefault;
            __weak typeof(self) weakSelf = self;
            cell.onTextChanged = ^(NSString *text) {
                weakSelf.draft.name = text;
            };
            return cell;
        }

        NSString *app = self.draft.appName.length > 0 ? self.draft.appName : @"All Apps";
        return [self valueCellWithTitle:@"App" value:app];
    }

    if (indexPath.section == NotiFilterEditorSectionRule) {
        switch (indexPath.row) {
            case NotiFilterRuleRowAction:
                return [self valueCellWithTitle:@"Action"
                                          value:[NFFilter titleForAction:self.draft.action]];
            case NotiFilterRuleRowMatch:
                return [self valueCellWithTitle:@"Match"
                                          value:[NFFilter titleForMatchType:self.draft.matchType]];
            case NotiFilterRuleRowField:
                return [self valueCellWithTitle:@"Field"
                                          value:[NFFilter titleForField:self.draft.field]];
            case NotiFilterRuleRowText: {
                NotiFilterInlineTextFieldCell *cell = [self textCell];
                [cell configureWithTitle:@"Text"
                                    text:self.draft.text
                             placeholder:@"Text to match"];
                cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
                __weak typeof(self) weakSelf = self;
                cell.onTextChanged = ^(NSString *text) {
                    weakSelf.draft.text = text;
                };
                return cell;
            }
            default:
                break;
        }
    }

    if (indexPath.section == NotiFilterEditorSectionSchedule) {
        switch (indexPath.row) {
            case NotiFilterScheduleRowSwitch:
                return [self switchCellWithTitle:@"Schedule"
                                          toggle:self.scheduleSwitch
                                              on:self.draft.scheduleEnabled
                                 reuseIdentifier:@"NotiFilterScheduleSwitchRow"];
            case NotiFilterScheduleRowDays: {
                UITableViewCell *cell = [self valueCellWithTitle:@"Days" value:[self weekdaySummary]];
                [self configureScheduleCellState:cell];
                return cell;
            }
            case NotiFilterScheduleRowStart: {
                UITableViewCell *cell =
                    [self valueCellWithTitle:@"Start"
                                       value:[self timeStringForMinutes:self.draft.startMinutes]];
                [self configureScheduleCellState:cell];
                return cell;
            }
            case NotiFilterScheduleRowEnd: {
                UITableViewCell *cell =
                    [self valueCellWithTitle:@"End"
                                       value:[self timeStringForMinutes:self.draft.endMinutes]];
                [self configureScheduleCellState:cell];
                return cell;
            }
            default:
                break;
        }
    }

    if (indexPath.section == NotiFilterEditorSectionStatus) {
        return [self switchCellWithTitle:@"Enabled"
                                  toggle:self.enabledSwitch
                                      on:self.draft.enabled
                         reuseIdentifier:@"NotiFilterEnabledSwitchRow"];
    }

    return [self deleteCell];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == NotiFilterEditorSectionFilter) {
        if (indexPath.row == NotiFilterFilterRowName) {
            NotiFilterInlineTextFieldCell *cell =
                (NotiFilterInlineTextFieldCell *)[tableView cellForRowAtIndexPath:indexPath];
            [cell beginEditing];
            return;
        }

        if (indexPath.row == NotiFilterFilterRowApp) {
            NotiFilterAppPickerController *picker =
                [[NotiFilterAppPickerController alloc] initWithStyle:UITableViewStyleInsetGrouped];
            picker.selectedBundleIdentifier = self.draft.bundleIdentifier;
            picker.onSelect = ^(NSString *bundleIdentifier, NSString *appName) {
                self.draft.bundleIdentifier = bundleIdentifier;
                self.draft.appName = appName;
                [self.tableView reloadRowsAtIndexPaths:
                    @[[NSIndexPath indexPathForRow:NotiFilterFilterRowApp
                                         inSection:NotiFilterEditorSectionFilter]]
                                      withRowAnimation:UITableViewRowAnimationNone];
            };
            [self.navigationController pushViewController:picker animated:YES];
        }
        return;
    }

    if (indexPath.section == NotiFilterEditorSectionRule) {
        if (indexPath.row == NotiFilterRuleRowText) {
            NotiFilterInlineTextFieldCell *cell =
                (NotiFilterInlineTextFieldCell *)[tableView cellForRowAtIndexPath:indexPath];
            [cell beginEditing];
            return;
        }

        if (indexPath.row == NotiFilterRuleRowAction) {
            NotiFilterChoiceController *choice =
                [[NotiFilterChoiceController alloc] initWithTitle:@"Action"
                                                           titles:[NFFilter actionTitles]
                                                    selectedIndex:self.draft.action];
            choice.onSelect = ^(NSInteger index) {
                self.draft.action = (NFFilterAction)index;
                [self.tableView reloadRowsAtIndexPaths:
                    @[[NSIndexPath indexPathForRow:NotiFilterRuleRowAction
                                         inSection:NotiFilterEditorSectionRule]]
                                      withRowAnimation:UITableViewRowAnimationNone];
            };
            [self.navigationController pushViewController:choice animated:YES];
            return;
        }

        if (indexPath.row == NotiFilterRuleRowMatch) {
            NotiFilterChoiceController *choice =
                [[NotiFilterChoiceController alloc] initWithTitle:@"Match"
                                                           titles:[NFFilter matchTypeTitles]
                                                    selectedIndex:self.draft.matchType];
            choice.onSelect = ^(NSInteger index) {
                self.draft.matchType = (NFFilterMatchType)index;
                [self.tableView reloadData];
            };
            [self.navigationController pushViewController:choice animated:YES];
            return;
        }

        if (indexPath.row == NotiFilterRuleRowField) {
            NotiFilterChoiceController *choice =
                [[NotiFilterChoiceController alloc] initWithTitle:@"Field"
                                                           titles:[NFFilter fieldTitles]
                                                    selectedIndex:self.draft.field];
            choice.onSelect = ^(NSInteger index) {
                self.draft.field = (NFFilterField)index;
                [self.tableView reloadRowsAtIndexPaths:
                    @[[NSIndexPath indexPathForRow:NotiFilterRuleRowField
                                         inSection:NotiFilterEditorSectionRule]]
                                      withRowAnimation:UITableViewRowAnimationNone];
            };
            [self.navigationController pushViewController:choice animated:YES];
        }
        return;
    }

    if (indexPath.section == NotiFilterEditorSectionSchedule) {
        if (!self.draft.scheduleEnabled) {
            return;
        }
        if (indexPath.row == NotiFilterScheduleRowDays) {
            NotiFilterWeekdayController *picker =
                [[NotiFilterWeekdayController alloc] initWithWeekdays:self.draft.weekdays];
            picker.onSave = ^(NSArray<NSNumber *> *weekdays) {
                self.draft.weekdays = weekdays;
                [self.tableView reloadRowsAtIndexPaths:
                    @[[NSIndexPath indexPathForRow:NotiFilterScheduleRowDays
                                         inSection:NotiFilterEditorSectionSchedule]]
                                      withRowAnimation:UITableViewRowAnimationNone];
            };
            [self.navigationController pushViewController:picker animated:YES];
            return;
        }

        if (indexPath.row == NotiFilterScheduleRowStart ||
            indexPath.row == NotiFilterScheduleRowEnd) {
            BOOL isStart = indexPath.row == NotiFilterScheduleRowStart;
            NSInteger minutes = isStart ? self.draft.startMinutes : self.draft.endMinutes;
            NotiFilterTimePickerController *picker =
                [[NotiFilterTimePickerController alloc] initWithTitle:isStart ? @"Start" : @"End"
                                                              minutes:minutes];
            picker.onSave = ^(NSInteger selectedMinutes) {
                if (isStart) {
                    self.draft.startMinutes = selectedMinutes;
                } else {
                    self.draft.endMinutes = selectedMinutes;
                }
                [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                      withRowAnimation:UITableViewRowAnimationNone];
            };
            [self.navigationController pushViewController:picker animated:YES];
        }
        return;
    }

    if (indexPath.section == NotiFilterEditorSectionDelete) {
        [self confirmDelete];
    }
}

- (void)enabledChanged:(UISwitch *)toggle {
    self.draft.enabled = toggle.on;
}

- (void)scheduleChanged:(UISwitch *)toggle {
    self.draft.scheduleEnabled = toggle.on;
    [self updateScheduleRows];
}

- (NSArray<NSString *> *)weekdayNamesShort {
    NSArray<NSString *> *symbols = [NSDateFormatter new].shortWeekdaySymbols;
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (NSInteger index = 1; index < 7 && index < (NSInteger)symbols.count; index++) {
        [names addObject:symbols[(NSUInteger)index]];
    }
    if (symbols.count > 0) {
        [names addObject:symbols[0]];
    }
    return names;
}

- (BOOL)hasValidWeekdays {
    NSArray<NSNumber *> *weekdays = self.draft.weekdays;
    if (![weekdays isKindOfClass:[NSArray class]] || weekdays.count != 7) {
        return NO;
    }
    for (id day in weekdays) {
        if (![day isKindOfClass:[NSNumber class]]) {
            return NO;
        }
    }
    return YES;
}

- (NSString *)weekdaySummary {
    if (![self hasValidWeekdays]) {
        return @"Not Set";
    }

    BOOL selected[7] = {NO, NO, NO, NO, NO, NO, NO};
    NSUInteger selectedCount = 0;
    for (NSUInteger index = 0; index < 7; index++) {
        selected[index] = self.draft.weekdays[index].boolValue;
        if (selected[index]) {
            selectedCount++;
        }
    }

    if (selectedCount == 7) {
        return @"Every Day";
    }
    if (selectedCount == 5 && selected[0] && selected[1] && selected[2] &&
        selected[3] && selected[4] && !selected[5] && !selected[6]) {
        return @"Weekdays";
    }
    if (selectedCount == 2 && !selected[0] && !selected[1] && !selected[2] &&
        !selected[3] && !selected[4] && selected[5] && selected[6]) {
        return @"Weekends";
    }
    if (selectedCount == 0) {
        return @"None";
    }

    NSArray<NSString *> *names = [self weekdayNamesShort];
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    for (NSUInteger index = 0; index < 7 && index < names.count; index++) {
        if (selected[index]) {
            [parts addObject:names[index]];
        }
    }
    return [parts componentsJoinedByString:@", "];
}

- (NSString *)timeStringForMinutes:(NSInteger)minutes {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components =
        [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
                    fromDate:[NSDate date]];
    components.hour = minutes / 60;
    components.minute = minutes % 60;
    components.second = 0;
    NSDate *date = [calendar dateFromComponents:components];
    if (!date) {
        return @"--";
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterNoStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    return [formatter stringFromDate:date] ?: @"--";
}

- (void)save {
    NSString *name = [self.draft.name stringByTrimmingCharactersInSet:
                      [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (name.length == 0) {
        [self showError:@"Filter name cannot be empty."];
        return;
    }
    self.draft.name = name;

    if (self.draft.matchType != NFFilterMatchAlways) {
        NSString *text = [self.draft.text stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (text.length == 0) {
            [self showError:@"Filter text cannot be empty unless Match is Always."];
            return;
        }
        self.draft.text = text;

        if (self.draft.matchType == NFFilterMatchRegex) {
            NSError *regexError = nil;
            NSRegularExpression *regex =
                [NSRegularExpression regularExpressionWithPattern:text
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:&regexError];
            if (!regex) {
                [self showError:@"Regex is invalid."];
                return;
            }
        }
    }

    if (self.draft.scheduleEnabled) {
        if (![self hasValidWeekdays]) {
            [self showError:@"Select at least one day for the schedule."];
            return;
        }

        BOOL anyDay = NO;
        for (NSNumber *day in self.draft.weekdays) {
            if (day.boolValue) {
                anyDay = YES;
                break;
            }
        }
        if (!anyDay) {
            [self showError:@"Select at least one day for the schedule."];
            return;
        }

        if (self.draft.startMinutes == self.draft.endMinutes) {
            [self showError:@"Start and end times must be different."];
            return;
        }
    }

    if ([self.delegate respondsToSelector:@selector(filterEditor:didSaveFilter:)]) {
        [self.delegate filterEditor:self didSaveFilter:[self.draft copy]];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)confirmDelete {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Delete Filter?"
                                            message:@"This filter will be removed."
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction *action) {
        (void)action;
        if ([self.delegate respondsToSelector:@selector(filterEditor:didDeleteFilter:)]) {
            [self.delegate filterEditor:self didDeleteFilter:self.draft];
        }
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showError:(NSString *)message {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Cannot Save"
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
