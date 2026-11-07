#import <UIKit/UIKit.h>
#import "NFFilter.h"

@class NotiFilterFilterEditorController;

@protocol NotiFilterFilterEditorDelegate <NSObject>
- (void)filterEditor:(NotiFilterFilterEditorController *)editor didSaveFilter:(NFFilter *)filter;
- (void)filterEditor:(NotiFilterFilterEditorController *)editor didDeleteFilter:(NFFilter *)filter;
@end

@interface NotiFilterFilterEditorController : UITableViewController

@property (nonatomic, weak) id<NotiFilterFilterEditorDelegate> delegate;

- (instancetype)initWithFilter:(NFFilter *)filter;

@end
