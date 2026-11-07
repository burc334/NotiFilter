#import "NotiFilterAppPickerController.h"
#import "NFIconProvider.h"

@interface NotiFilterAppPickerController () <UISearchResultsUpdating>
@property (nonatomic, copy) NSArray<NSDictionary *> *allApps;
@property (nonatomic, copy) NSArray<NSDictionary *> *apps;
@property (nonatomic, strong) UISearchController *searchController;
@end

@implementation NotiFilterAppPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"App";
    self.tableView.rowHeight = 44.0;

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;

    [self loadApplications];
}

- (void)loadApplications {
    NSMutableArray<NSDictionary *> *apps = [NSMutableArray array];

    @try {
        Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
        if (workspaceClass && [workspaceClass respondsToSelector:@selector(defaultWorkspace)]) {
            id workspace = [workspaceClass performSelector:@selector(defaultWorkspace)];
            if (workspace && [workspace respondsToSelector:@selector(allInstalledApplications)]) {
                NSArray *proxies = [workspace performSelector:@selector(allInstalledApplications)];
                for (id proxy in proxies) {
                    NSString *bundleIdentifier = nil;
                    NSString *appName = nil;
                    @try {
                        bundleIdentifier = [proxy valueForKey:@"bundleIdentifier"];
                        appName = [proxy valueForKey:@"localizedName"];
                        if (![appName isKindOfClass:[NSString class]] || appName.length == 0) {
                            appName = [proxy valueForKey:@"itemName"];
                        }
                    } @catch (NSException *exception) {
                        continue;
                    }

                    if (![bundleIdentifier isKindOfClass:[NSString class]] ||
                        bundleIdentifier.length == 0) {
                        continue;
                    }
                    if (![appName isKindOfClass:[NSString class]] || appName.length == 0) {
                        appName = bundleIdentifier;
                    }

                    [apps addObject:@{ @"bundleIdentifier": bundleIdentifier,
                                       @"appName": appName }];
                }
            }
        }
    } @catch (NSException *exception) {
        apps = [NSMutableArray array];
    }

    [apps sortUsingComparator:^NSComparisonResult(NSDictionary *first, NSDictionary *second) {
        return [first[@"appName"] localizedCaseInsensitiveCompare:second[@"appName"]];
    }];
    self.allApps = apps;
    self.apps = apps;
    [self.tableView reloadData];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *query = searchController.searchBar.text ?: @"";
    if (query.length == 0) {
        self.apps = self.allApps;
    } else {
        NSMutableArray<NSDictionary *> *results = [NSMutableArray array];
        for (NSDictionary *app in self.allApps) {
            NSString *name = app[@"appName"];
            NSString *bundleIdentifier = app[@"bundleIdentifier"];
            if ([name localizedCaseInsensitiveContainsString:query] ||
                [bundleIdentifier localizedCaseInsensitiveContainsString:query]) {
                [results addObject:app];
            }
        }
        self.apps = results;
    }
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    return MAX((NSInteger)self.apps.count, 1);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"All Apps";
    }
    return self.searchController.isActive ? @"Results" : @"Installed Apps";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"NotiFilterAppCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:identifier];
    }

    if (indexPath.section == 0) {
        cell.textLabel.text = @"All Apps";
        cell.detailTextLabel.text = nil;
        cell.imageView.image = nil;
        cell.accessoryType = self.selectedBundleIdentifier.length == 0
            ? UITableViewCellAccessoryCheckmark
            : UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        return cell;
    }

    if (self.apps.count == 0) {
        cell.textLabel.text = self.searchController.isActive
            ? @"No apps found"
            : @"No installed apps found";
        cell.detailTextLabel.text = nil;
        cell.imageView.image = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }

    NSDictionary *app = self.apps[(NSUInteger)indexPath.row];
    NSString *bundleIdentifier = app[@"bundleIdentifier"];
    cell.textLabel.text = app[@"appName"];
    cell.detailTextLabel.text = bundleIdentifier;
    cell.imageView.image = [NFIconProvider iconForBundleIdentifier:bundleIdentifier];
    cell.accessoryType = [bundleIdentifier isEqualToString:self.selectedBundleIdentifier]
        ? UITableViewCellAccessoryCheckmark
        : UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0) {
        if (self.onSelect) {
            self.onSelect(nil, @"All Apps");
        }
        [self.searchController setActive:NO];
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }

    if (self.apps.count == 0 || indexPath.row >= (NSInteger)self.apps.count) {
        return;
    }

    NSDictionary *app = self.apps[(NSUInteger)indexPath.row];
    if (self.onSelect) {
        self.onSelect(app[@"bundleIdentifier"], app[@"appName"]);
    }
    [self.searchController setActive:NO];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
