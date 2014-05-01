//
//  ETAlertView.m
//  winelist
//
//  Created by Erlend Thune on 01.05.14.
//  Copyright (c) 2014 Erlend Thune. All rights reserved.
//

#import "ETAlertView.h"

@implementation ETAlertView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)init:(int)imgWidth imgHeight:(int)imgHeight noOfTimesUsed:(int)noOfTimesUsed
{
    CGRect rect = CGRectMake(0, 0, imgWidth, imgHeight);
    
    self = [super initWithFrame:rect];
    if (self) {
        
        self.noOfTimesUsed = noOfTimesUsed;
        self.counter = 0;

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
        [self UpdateLabelText];

        self.label.numberOfLines = 5;
//        self.label.adjustsFontSizeToFitWidth = YES;
        [self addSubview:self.label];
        
        // Add gesture recognizers
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(isTapped:)]];
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target:self selector:@selector(updateCountdown) userInfo:nil repeats: YES];

    }
    return self;
}

- (void)addOkButton
{
    int fontSize = self.frame.size.width/10;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.titleLabel.textColor = [UIColor whiteColor];
    button.titleLabel.font = [UIFont fontWithName: @"Helvetica" size: fontSize];

    [button addTarget:self action:@selector(aMethod:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Ok" forState:UIControlStateNormal];
    float x = self.frame.size.width/2.0-20.0;
    float y = self.frame.size.height-80.0;
    button.frame = CGRectMake(x,y , 40.0, 40.0);
    [self addSubview:button];
    
    
}
- (void)aMethod:(UIButton*)button
{
    NSLog(@"Button  clicked.");
    [self removeFromSuperview];
}

#pragma mark - Gesture recognizer handlers
- (void)isTapped:(UITapGestureRecognizer *)recognizer
{
//    [self.mvc answerQuestion:self];
}


-(void)UpdateLabelText
{
    NSString *s = [NSString stringWithFormat:@"Du har brukt appen gratis %d ganger.", self.counter];
    
    self.label.text = s;
}

-(void) updateCountdown
{
    self.counter++;
    [self UpdateLabelText];
   
    if(self.noOfTimesUsed == self.counter)
    {
        [self.timer invalidate];
        self.timer = nil;
        [self addOkButton];
    }
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
