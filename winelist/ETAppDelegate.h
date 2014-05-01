//
//  ETAppDelegate.h
//  winelist
//
//  Created by Erlend Thune on 26.04.14.
//  Copyright (c) 2014 Erlend Thune. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic,strong) NSString *databaseName;
@property (nonatomic,strong) NSString *databasePath;

@end
