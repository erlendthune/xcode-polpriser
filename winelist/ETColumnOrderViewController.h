#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ETColumnOrderViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITableViewDragDelegate, UITableViewDropDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray<NSString *> *columns;  // Array to hold the column names
@property (nonatomic, copy) void (^completionHandler)(NSArray<NSString *> *updatedOrder); // Block to handle column reordering result

@end

NS_ASSUME_NONNULL_END
