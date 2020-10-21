//
//  ETViewController.h
//  winelist
//
//  Created by Erlend Thune on 26.04.14.
//  Copyright (c) 2014 Erlend Thune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "FMDataBaseQueue.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "Utility.h"
#import "Wine.h"

@class ETAlertView;
@class ETInternetconnection;

@interface ETViewController : UIViewController<UIActionSheetDelegate, NSURLConnectionDelegate,  SKRequestDelegate>
-(void)ShowStartupDialog;
- (void)purchase;
- (void)restorePurchase;
- (void) AppNotPurchased;
- (void) AppPurchased;

@property (nonatomic,strong) NSMutableArray *fullWineList;
//@property (strong, nonatomic) FMDBDataAccess *db;
@property (copy, nonatomic) NSString *currentSearchString;
@property (weak, nonatomic) IBOutlet UITableView *wineTableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *wineSegment;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *dbDateButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) FMDatabaseQueue *queue;
@property (nonatomic) bool orderAscending;
@property (nonatomic) bool nagscreenOnDisplay;
@property (nonatomic) bool filterMenuHasBeenDisplayed;
@property (nonatomic) int orderBy;
@property (nonatomic) long bytesReceived;
@property (nonatomic) long activeSegment;
@property (nonatomic) int filter;
@property (weak, nonatomic) IBOutlet UIView *nagView;
@property (nonatomic) int usageCounter;
@property (nonatomic) int downloadState;
@property (nonatomic) int dateRequestSource;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *menuButton;
@property (nonatomic) NSTimeInterval databasedate;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *filterButton;
@property (strong, nonatomic) UIColor *buttonTintColor;
@property (strong, nonatomic) NSMutableData *responseData;
@property (nonatomic, strong) NSString   *price;
@property bool purchased;
@property bool restorePurchaseStarted;

@property (strong, nonatomic) IBOutlet ETAlertView *alertView;
@property (strong, nonatomic) IBOutlet ETInternetconnection *internetView;
@end
