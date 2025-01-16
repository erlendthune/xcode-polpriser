#import "ETColumnOrderViewController.h"

@implementation ETColumnOrderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Reorder Columns";
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Example column names
    self.columns = [@[@"Name", @"Price", @"Alcohol", @"Volume", @"Type"] mutableCopy];
    
    // Table view setup
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsSelection = NO;
    self.tableView.dragInteractionEnabled = YES;
    self.tableView.dragDelegate = self;
    self.tableView.dropDelegate = self;
    [self.view addSubview:self.tableView];
    
    // Add save button
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(saveButtonTapped)];
    self.navigationItem.rightBarButtonItem = saveButton;
}

#pragma mark - TableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.columns.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = self.columns[indexPath.row];
    cell.showsReorderControl = YES;
    return cell;
}

#pragma mark - TableView Drag Delegate

- (NSArray<UIDragItem *> *)tableView:(UITableView *)tableView
         itemsForBeginningDragSession:(id<UIDragSession>)session
                          atIndexPath:(NSIndexPath *)indexPath {
    NSString *column = self.columns[indexPath.row];
    NSItemProvider *itemProvider = [[NSItemProvider alloc] initWithObject:column];
    UIDragItem *dragItem = [[UIDragItem alloc] initWithItemProvider:itemProvider];
    return @[dragItem];
}

#pragma mark - TableView Drop Delegate
// Called to check if the drop is allowed at the destination index path.
- (BOOL)tableView:(UITableView *)tableView canHandleDropAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Checking if drop is allowed at index: %@", indexPath);
    return YES;  // Allow drop anywhere in the table view
}

- (void)tableView:(UITableView *)tableView acceptDropWithCoordinator:(id<UITableViewDropCoordinator>)coordinator {
    // Handle the drop of the item(s)
    NSLog(@"acceptDropWithCoordinator");
    [self tableView:tableView performDropWithCoordinator:coordinator];
}

- (void)tableView:(UITableView *)tableView
        performDropWithCoordinator:(id<UITableViewDropCoordinator>)coordinator {
    NSLog(@"performDropWithCoordinator");
    NSIndexPath *destinationIndexPath = coordinator.destinationIndexPath;

    for (UIDragItem *dragItem in coordinator.items) {
        [dragItem.itemProvider loadItemForTypeIdentifier:@"public.text" options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Nullable error) {
            if (item) {
                NSString *column = (NSString *)item;
                [self.columns removeObject:column];
                [self.columns insertObject:column atIndex:destinationIndexPath.row];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [tableView reloadData];
                });
            }
        }];
    }
}

#pragma mark - Save Button Action

- (void)saveButtonTapped {
    NSLog(@"New column order: %@", self.columns);
    if (self.completionHandler) {
        self.completionHandler(self.columns);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
