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

- (id)init:(int)imgWidth imgHeight:(int)imgHeight noOfTimesUsed:(int)noOfTimesUsed mvc:(ETViewController*) mvc
{
    CGRect rect = CGRectMake(0, 0, imgWidth, imgHeight);
    
    self = [super initWithFrame:rect];
    if (self) {
        self.mvc = mvc;
        
        self.noOfTimesUsed = noOfTimesUsed;
        self.counter = 0;
        self.mvc.nagscreenOnDisplay = true;

        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 10.0;
        self.layer.borderWidth = 1.0;
        self.backgroundColor = [UIColor whiteColor];
        self.layer.borderColor = [[UIColor blackColor] CGColor];
        
        int maxWidth = [[UIScreen mainScreen ]bounds].size.width;
        int fontSize = maxWidth/15;
        CGRect rect = CGRectMake(0, 0, imgWidth, imgHeight-fontSize*2);
        self.label =  [[UILabel alloc] initWithFrame: rect];
        self.label.layer.cornerRadius = 10.0;
        
        self.label.font = [UIFont systemFontOfSize:fontSize];
        
        self.label.backgroundColor = [UIColor clearColor];
        //        self.label.text = @"2+2="; //etc...
        self.label.textAlignment = NSTextAlignmentCenter;
        [self UpdateLabelText];

        self.label.numberOfLines = 5;
//        self.label.adjustsFontSizeToFitWidth = YES;
        [self addSubview:self.label];
        
        // Add gesture recognizers
//        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(isTapped:)]];
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval: 0.2 target:self selector:@selector(updateCountdown) userInfo:nil repeats: YES];

    }
    return self;
}

- (void)addOkButton
{
    int fontSize = self.frame.size.width/15;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.titleLabel.textColor = [UIColor whiteColor];
    button.titleLabel.font = [UIFont fontWithName: @"Helvetica" size: fontSize];

//    [button addTarget:self action:@selector(aMethod:) forControlEvents:UIControlEventTouchUpInside];
    [button addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(aMethod:)]];

    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
//    button.backgroundColor = [UIColor yellowColor];
    button.layer.borderColor = [UIColor blackColor].CGColor;
    [button setTitle:@"Ok" forState:UIControlStateNormal];
    float x = self.frame.size.width-self.frame.size.width/8-fontSize*2;
    float y = self.frame.size.height*3/4;
    button.frame = CGRectMake(x,y , fontSize*2, fontSize*1.5);
    [self addSubview:button];

    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button2 setTitleColor:[UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0] forState:UIControlStateNormal];
//    button2.backgroundColor = [UIColor yellowColor];
    button2.layer.borderColor = [UIColor blackColor].CGColor;
    button2.titleLabel.font = [UIFont fontWithName: @"Helvetica" size: fontSize];
    
//    [button2 addTarget:self action:@selector(buyMethod:) forControlEvents:UIControlEventTouchUpInside];
    [button2 addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buyMethod:)]];
    [button2 setTitle:@"Kjøp" forState:UIControlStateNormal];
    float x2 = self.frame.size.width/8;
    float y2 = self.frame.size.height-self.frame.size.height/4;
    button2.frame = CGRectMake(x2,y2 , fontSize*4, fontSize*1.5);
    [self addSubview:button2];

}

- (void)buyMethod:(UIButton*)button
{
    NSLog(@"Button  clicked.");
    self.mvc.nagscreenOnDisplay = false;
    [self removeFromSuperview];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms://itunes.apple.com/us/app/polpriser/id876819682"]];
}


- (void)aMethod:(UIButton*)button
{
    NSLog(@"Button  clicked.");
    self.mvc.nagscreenOnDisplay = false;
    [self removeFromSuperview];
    [self.mvc performSelectorOnMainThread:@selector(ShowStartupDialog) withObject:nil waitUntilDone:NO];
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
