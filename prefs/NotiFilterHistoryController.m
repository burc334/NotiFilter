#import "NotiFilterHistoryController.h"
#import "NFHistoryStore.h"
#import "NFSettings.h"
#import "NotiFilterChoiceController.h"

typedef NS_ENUM(NSInteger, NotiFilterHistorySection) {
    NotiFilterHistorySectionEntries = 0,
    NotiFilterHistorySectionOptions = 1,
    NotiFilterHistorySectionClear = 2,
    NotiFilterHistorySectionCount = 3
};

@interface NotiFilterHistoryController ()
@property (nonatomic, copy) NSArray<NSDictionary *> *entries;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation NotiFilterHistoryController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Blocked";
    self.tableView.rowHeight = 44.0;

    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;

    [self loadHistory];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadHistory];
}

- (void)loadHistory {
    self.entries = [NFHistoryStore entries];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NotiFilterHistorySectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case NotiFilterHistorySectionEntries:
            return self.entries.count > 0 ? (NSInteger)self.entries.count : 1;
        case NotiFilterHistorySectionOptions:
            return 2;
        case NotiFilterHistorySectionClear:
            return self.entries.count > 0 ? 1 : 0;
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case NotiFilterHistorySectionEntries:
            return @"Blocked Notifications";
        case NotiFilterHistorySectionOptions:
            return @"History Settings";
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == NotiFilterHistorySectionEntries) {
        return @"Only hard Block decisions are recorded.";
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == NotiFilterHistorySectionEntries) {
        return 64.0;
    }
    return 44.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == NotiFilterHistorySectionEntries) {
        static NSString *identifier = @"NotiFilterHistoryEntryCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:identifier];
        }
        cell.imageView.image = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        if (self.entries.count == 0) {
            cell.textLabel.text = @"No blocked notifications yet.";
            cell.detailTextLabel.text = @"Only hard Block decisions are recorded.";
        } else {
            NSDictionary *entry = self.entries[(NSUInteger)indexPath.row];
            NSString *title = entry[@"title"];
            if (![title isKindOfClass:[NSString class]] || title.length == 0) {
                title = @"(No title)";
            }
            NSString *app = entry[@"appName"];
            if (![app isKindOfClass:[NSString class]] || app.length == 0) {
                app = entry[@"bundleIdentifier"];
            }
            if (![app isKindOfClass:[NSString class]] || app.length == 0) {
                app = @"Unknown App";
            }
            NSNumber *timestamp = entry[@"timestamp"];
            NSString *date = @"";
            if ([timestamp isKindOfClass:[NSNumber class]]) {
                date = [self.dateFormatter stringFromDate:
                        [NSDate dateWithTimeIntervalSince1970:timestamp.doubleValue]] ?: @"";
            }
            NSString *filterName = entry[@"filterName"];
            NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithObject:app];
            if (date.length > 0) {
                [parts addObject:date];
            }
            if ([filterName isKindOfClass:[NSString class]] && filterName.length > 0) {
                [parts addObject:filterName];
            }
            cell.textLabel.text = title;
            cell.detailTextLabel.text = [parts componentsJoinedByString:@" · "];
            cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
        }
        return cell;
    }

    if (indexPath.section == NotiFilterHistorySectionOptions) {
        static NSString *identifier = @"NotiFilterHistoryOptionCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                          reuseIdentifier:identifier];
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;

        if (indexPath.row == 0) {
            cell.textLabel.text = @"History Limit";
            cell.detailTextLabel.text =
                [NSString stringWithFormat:@"%ld", (long)NFSettingsHistoryLimit()];
        } else {
            cell.textLabel.text = @"Keep For";
            NSInteger days = NFSettingsHistoryRetentionDays();
            cell.detailTextLabel.text =
                [NSString stringWithFormat:@"%ld %@", (long)days, days == 1 ? @"day" : @"days"];
        }
        cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
        return cell;
    }

    static NSString *identifier = @"NotiFilterHistoryClearCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];
    }
    cell.textLabel.text = @"Clear History";
    cell.textLabel.textColor = [UIColor systemRedColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == NotiFilterHistorySectionOptions) {
        if (indexPath.row == 0) {
            NSArray<NSNumber *> *values = @[@25, @50, @100, @250, @500];
            NSArray<NSString *> *titles = @[@"25", @"50", @"100", @"250", @"500"];
            NSInteger current = NFSettingsHistoryLimit();
            NSInteger selected = 2;
            for (NSUInteger index = 0; index < values.count; index++) {
                if (values[index].integerValue == current) {
                    selected = (NSInteger)index;
                    break;
                }
            }
            NotiFilterChoiceController *choice =
                [[NotiFilterChoiceController alloc] initWithTitle:@"History Limit"
                                                           titles:titles
                                                    selectedIndex:selected];
            choice.onSelect = ^(NSInteger index) {
                NFSettingsSetHistoryLimit(values[(NSUInteger)index].integerValue);
                [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                      withRowAnimation:UITableViewRowAnimationNone];
            };
            [self.navigationController pushViewController:choice animated:YES];
            return;
        }

        NSArray<NSNumber *> *values = @[@1, @3, @7, @14, @30];
        NSArray<NSString *> *titles = @[@"1 day", @"3 days", @"7 days", @"14 days", @"30 days"];
        NSInteger current = NFSettingsHistoryRetentionDays();
        NSInteger selected = 4;
        for (NSUInteger index = 0; index < values.count; index++) {
            if (values[index].integerValue == current) {
                selected = (NSInteger)index;
                break;
            }
        }
        NotiFilterChoiceController *choice =
            [[NotiFilterChoiceController alloc] initWithTitle:@"Keep For"
                                                       titles:titles
                                                selectedIndex:selected];
        choice.onSelect = ^(NSInteger index) {
            NFSettingsSetHistoryRetentionDays(values[(NSUInteger)index].integerValue);
            [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
        };
        [self.navigationController pushViewController:choice animated:YES];
        return;
    }

    if (indexPath.section == NotiFilterHistorySectionClear) {
        UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:@"Clear History?"
                                                message:@"This cannot be undone."
                                         preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Clear"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *action) {
            (void)action;
            [NFHistoryStore clear];
            [self loadHistory];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
