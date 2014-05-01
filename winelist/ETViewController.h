//
//  ETViewController.h
//  winelist
//
//  Created by Erlend Thune on 26.04.14.
//  Copyright (c) 2014 Erlend Thune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FMDataBaseQueue.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "Utility.h"
#import "Wine.h"

@class ETAlertView;

@interface ETViewController : UIViewController
@property (nonatomic,strong) NSMutableArray *fullWineList;
@property (atomic,strong) NSMutableArray *filteredWineList;
//@property (strong, nonatomic) FMDBDataAccess *db;
@property (copy, nonatomic) NSString *currentSearchString;
@property (weak, nonatomic) IBOutlet UITableView *wineTableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *wineSegment;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) FMDatabaseQueue *queue;
@property (nonatomic) bool orderByName;
@property (nonatomic) long activeSegment;

@property (strong, nonatomic) IBOutlet ETAlertView *alertView;
@end
