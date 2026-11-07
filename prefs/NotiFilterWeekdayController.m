#import "NotiFilterWeekdayController.h"

@interface NotiFilterWeekdayController ()
@property (nonatomic, copy) NSMutableArray<NSNumber *> *selected;
@property (nonatomic, copy) NSArray<NSString *> *weekdayNames;
@end

@implementation NotiFilterWeekdayController

- (instancetype)initWithWeekdays:(NSArray<NSNumber *> *)weekdays {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        if ([weekdays isKindOfClass:[NSArray class]] && weekdays.count == 7) {
            _selected = [weekdays mutableCopy];
        } else {
            _selected = [@[@YES, @YES, @YES, @YES, @YES, @NO, @NO] mutableCopy];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Days";
    self.tableView.rowHeight = 44.0;
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self
                                                      action:@selector(save)];

    NSArray<NSString *> *symbols = [NSDateFormatter new].weekdaySymbols;
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    for (NSInteger index = 1; index < 7; index++) {
        [names addObject:symbols[(NSUInteger)index]];
    }
    if (symbols.count > 0) {
        [names addObject:symbols[0]];
    }
    self.weekdayNames = names;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"At least one day is required.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"NotiFilterWeekdayCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];
    }
    cell.textLabel.text = self.weekdayNames[(NSUInteger)indexPath.row];
    cell.accessoryType = self.selected[(NSUInteger)indexPath.row].boolValue
        ? UITableViewCellAccessoryCheckmark
        : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSNumber *current = self.selected[(NSUInteger)indexPath.row];
    self.selected[(NSUInteger)indexPath.row] = @(!current.boolValue);
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)save {
    if (self.onSave) {
        self.onSave([self.selected copy]);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
