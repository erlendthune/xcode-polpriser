//
//  ETInternetconnection.h
//  winelist
//
//  Created by Erlend Thune on 03.05.14.
//  Copyright (c) 2014 Erlend Thune. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ETViewController;

@interface ETInternetconnection : UIView
- (id)init:(int)imgWidth imgHeight:(int)imgHeight;
-(void)UpdateLabelText:(NSString*)text;
@property (strong, nonatomic) UILabel *label;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@end
