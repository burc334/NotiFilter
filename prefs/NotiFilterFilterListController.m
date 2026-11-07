#import "NotiFilterFilterListController.h"
#import "NFFilter.h"
#import "NFSettings.h"
#import "NotiFilterFilterRowCell.h"

@interface NotiFilterFilterListController ()
@property (nonatomic, copy) NSArray<NFFilter *> *filters;
@property (nonatomic, strong) UIView *emptyStateView;
@end

@implementation NotiFilterFilterListController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Filters";
    self.tableView.rowHeight = 64.0;
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                      target:self
                                                      action:@selector(addFilter)];
    [self loadFilters];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadFilters];
}

- (void)loadFilters {
    self.filters = NFSettingsFilters();
    [self updateEmptyState];
    [self.tableView reloadData];
}

- (void)updateEmptyState {
    if (self.filters.count > 0) {
        self.tableView.backgroundView = nil;
        return;
    }

    if (!self.emptyStateView) {
        UIView *container = [[UIView alloc] initWithFrame:self.tableView.bounds];
        container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        UILabel *title = [[UILabel alloc] init];
        title.text = @"No filters yet";
        title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        title.textAlignment = NSTextAlignmentCenter;
        title.adjustsFontForContentSizeCategory = YES;

        UILabel *detail = [[UILabel alloc] init];
        detail.text = @"Add a filter to block, mute, or allow notifications.";
        detail.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        detail.textColor = [UIColor secondaryLabelColor];
        detail.textAlignment = NSTextAlignmentCenter;
        detail.numberOfLines = 0;
        detail.adjustsFontForContentSizeCategory = YES;

        UIButton *addButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [addButton setTitle:@"Add Filter" forState:UIControlStateNormal];
        addButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        [addButton addTarget:self
                      action:@selector(addFilter)
            forControlEvents:UIControlEventTouchUpInside];

        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[title, detail, addButton]];
        stack.axis = UILayoutConstraintAxisVertical;
        stack.alignment = UIStackViewAlignmentCenter;
        stack.spacing = 12.0;
        stack.translatesAutoresizingMaskIntoConstraints = NO;
        [container addSubview:stack];
        [NSLayoutConstraint activateConstraints:@[
            [stack.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
            [stack.centerYAnchor constraintEqualToAnchor:container.centerYAnchor],
            [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:container.leadingAnchor constant:32.0],
            [stack.trailingAnchor constraintLessThanOrEqualToAnchor:container.trailingAnchor constant:-32.0]
        ]];

        self.emptyStateView = container;
    }

    self.tableView.backgroundView = self.emptyStateView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.filters.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.filters.count > 0 ? @"Filters" : nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.filters.count > 0
        ? @"Swipe left to delete. Toggle the switch to enable or disable a filter."
        : nil;
}

- (NSString *)subtitleForFilter:(NFFilter *)filter {
    if (filter.matchType == NFFilterMatchContains) {
        return filter.text ?: @"";
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"NotiFilterFilterRow";
    NotiFilterFilterRowCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[NotiFilterFilterRowCell alloc] initWithStyle:UITableViewCellStyleDefault
                                              reuseIdentifier:identifier];
    }

    NFFilter *filter = self.filters[(NSUInteger)indexPath.row];
    [cell configureWithFilter:filter subtitle:[self subtitleForFilter:filter]];

    NSString *uuid = filter.uuid;
    __weak typeof(self) weakSelf = self;
    cell.onToggle = ^(BOOL enabled) {
        [weakSelf setFilterWithUUID:uuid enabled:enabled];
    };
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row >= (NSInteger)self.filters.count) {
        return;
    }

    NotiFilterFilterEditorController *editor =
        [[NotiFilterFilterEditorController alloc] initWithFilter:self.filters[(NSUInteger)indexPath.row]];
    editor.delegate = self;
    [self.navigationController pushViewController:editor animated:YES];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= (NSInteger)self.filters.count) {
        return nil;
    }

    UIContextualAction *deleteAction =
        [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                title:@"Delete"
                                              handler:^(UIContextualAction *action,
                                                        UIView *sourceView,
                                                        void (^completionHandler)(BOOL)) {
        (void)action;
        (void)sourceView;
        [self deleteFilterAtIndex:indexPath.row];
        completionHandler(YES);
    }];
    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
}

- (void)setFilterWithUUID:(NSString *)uuid enabled:(BOOL)enabled {
    for (NFFilter *filter in self.filters) {
        if ([filter.uuid isEqualToString:uuid]) {
            filter.enabled = enabled;
            [self saveFilters];
            return;
        }
    }
}

- (void)saveFilters {
    NFSettingsSetFilters(self.filters);
    NFSettingsPostChanged();
}

- (void)deleteFilterAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.filters.count) {
        return;
    }

    NSMutableArray<NFFilter *> *filters = [self.filters mutableCopy];
    [filters removeObjectAtIndex:(NSUInteger)index];
    self.filters = filters;
    [self saveFilters];
    [self updateEmptyState];
    [self.tableView reloadData];
}

- (void)addFilter {
    NotiFilterFilterEditorController *editor =
        [[NotiFilterFilterEditorController alloc] initWithFilter:nil];
    editor.delegate = self;
    [self.navigationController pushViewController:editor animated:YES];
}

- (void)filterEditor:(NotiFilterFilterEditorController *)editor didSaveFilter:(NFFilter *)filter {
    NSMutableArray<NFFilter *> *filters = [self.filters mutableCopy];
    NSUInteger existingIndex = NSNotFound;
    for (NSUInteger index = 0; index < filters.count; index++) {
        if ([filters[index].uuid isEqualToString:filter.uuid]) {
            existingIndex = index;
            break;
        }
    }

    if (existingIndex == NSNotFound) {
        [filters addObject:filter];
    } else {
        filters[existingIndex] = filter;
    }

    self.filters = filters;
    [self saveFilters];
    [self updateEmptyState];
    [self.tableView reloadData];
}

- (void)filterEditor:(NotiFilterFilterEditorController *)editor didDeleteFilter:(NFFilter *)filter {
    NSMutableArray<NFFilter *> *filters = [self.filters mutableCopy];
    NSUInteger existingIndex = NSNotFound;
    for (NSUInteger index = 0; index < filters.count; index++) {
        if ([filters[index].uuid isEqualToString:filter.uuid]) {
            existingIndex = index;
            break;
        }
    }

    if (existingIndex != NSNotFound) {
        [filters removeObjectAtIndex:existingIndex];
        self.filters = filters;
        [self saveFilters];
        [self updateEmptyState];
        [self.tableView reloadData];
    }
}

@end
