#import "NotiFilterChoiceController.h"

@interface NotiFilterChoiceController ()
@property (nonatomic, copy) NSString *screenTitle;
@property (nonatomic, copy) NSArray<NSString *> *titles;
@property (nonatomic, assign) NSInteger selectedIndex;
@end

@implementation NotiFilterChoiceController

- (instancetype)initWithTitle:(NSString *)title
                       titles:(NSArray<NSString *> *)titles
                selectedIndex:(NSInteger)selectedIndex {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _screenTitle = [title copy];
        _titles = [titles copy];
        _selectedIndex = selectedIndex;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.screenTitle;
    self.tableView.rowHeight = 44.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.titles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"NotiFilterChoiceCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];
    }
    cell.textLabel.text = self.titles[(NSUInteger)indexPath.row];
    cell.accessoryType = indexPath.row == self.selectedIndex
        ? UITableViewCellAccessoryCheckmark
        : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedIndex = indexPath.row;
    if (self.onSelect) {
        self.onSelect(indexPath.row);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
