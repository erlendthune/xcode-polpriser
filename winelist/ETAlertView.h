//
//  ETAlertView.h
//  winelist
//
//  Created by Erlend Thune on 01.05.14.
//  Copyright (c) 2014 Erlend Thune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ETViewController.h"

@interface ETAlertView : UIView
- (id)init:(int)imgWidth imgHeight:(int)imgHeight noOfTimesUsed:(int)noOfTimesUsed mvc:(ETViewController*) mvc nag:(bool)nag;

@property (weak, nonatomic) NSTimer * timer;
@property (nonatomic) int noOfTimesUsed;
@property (nonatomic) bool nag;
@property (nonatomic) int counter;
@property (strong, nonatomic) UIButton *okButton;
@property (strong, nonatomic) UILabel *label;
@property (strong, nonatomic) UILabel *headLine;
@property (weak, nonatomic) ETViewController* mvc;
@end

