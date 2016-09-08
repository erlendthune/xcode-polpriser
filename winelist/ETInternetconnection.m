//
//  ETInternetconnection.m
//  winelist
//
//  Created by Erlend Thune on 03.05.14.
//  Copyright (c) 2014 Erlend Thune. All rights reserved.
//
//  From http://codewithchris.com/tutorial-how-to-use-ios-nsurlconnection-by-example/

#import "ETInternetconnection.h"

@implementation ETInternetconnection

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
- (id)init:(int)imgWidth imgHeight:(int)imgHeight
{
    CGRect rect = CGRectMake(0, 0, imgWidth, imgHeight);
    
    self = [super initWithFrame:rect];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 10.0;
        self.layer.borderWidth = 1.0;
        self.backgroundColor = [UIColor whiteColor];
        self.layer.borderColor = [[UIColor blackColor] CGColor];
        
        CGRect rect = CGRectMake(0, 0, imgWidth, imgHeight/2);
        self.label =  [[UILabel alloc] initWithFrame: rect];
        self.label.layer.cornerRadius = 10.0;
        
        int maxWidth = [[UIScreen mainScreen ]bounds].size.width;
        int fontSize = maxWidth/10;
        self.label.font = [UIFont systemFontOfSize:fontSize];
        
        self.label.backgroundColor = [UIColor clearColor];
        //        self.label.text = @"2+2="; //etc...
        self.label.textAlignment = NSTextAlignmentCenter;
        
        self.label.numberOfLines = 5;
        //        self.label.adjustsFontSizeToFitWidth = YES;
        [self addSubview:self.label];

    
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:self.activityIndicator];
        self.activityIndicator.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
        [self.activityIndicator startAnimating];
    }
    return self;
}
-(void)UpdateLabelText:(NSString*)text
{
    self.label.text = text;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
