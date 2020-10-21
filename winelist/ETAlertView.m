//
//  ETAlertView.m
//  winelist
//
//  Created by Erlend Thune on 01.05.14.
//  Copyright (c) 2014 Erlend Thune. All rights reserved.
//

#import "ETAlertView.h"
#import <CoreText/CoreText.h>
#define NAG_SCALE_HEADLINE_FACTOR 20
#define NAG_SCALE_TEXT_FACTOR 25
#define BUTTON_Y_POS 5
@implementation ETAlertView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)init:(int)imgWidth imgHeight:(int)imgHeight noOfTimesUsed:(int)noOfTimesUsed mvc:(ETViewController*) mvc nag:(bool)nag
{
    CGRect rect = CGRectMake(0, 0, imgWidth, imgHeight);
    
    self = [super initWithFrame:rect];
    if (self) {
        self.mvc = mvc;
        self.nag = nag;
        
        self.noOfTimesUsed = noOfTimesUsed;
        self.counter = 0;
        self.mvc.nagscreenOnDisplay = true;
        
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 10.0;
        self.layer.borderWidth = 1.0;
        self.backgroundColor = [UIColor whiteColor];
        self.layer.borderColor = [[UIColor blackColor] CGColor];
        
        //        int maxWidth = [[UIScreen mainScreen ]bounds].size.width;
        int fontSize = self.frame.size.height/NAG_SCALE_TEXT_FACTOR;

        CGRect rect = CGRectMake(fontSize, 40, imgWidth-fontSize*2, imgHeight);
        self.label =  [[UILabel alloc] initWithFrame: rect];
        self.label.layer.cornerRadius = 10.0;
        
        self.label.backgroundColor = [UIColor clearColor];
        //        self.label.text = @"2+2="; //etc...
//        self.label.textAlignment = NSTextAlignmentCenter;
        [self UpdateLabelText];
        self.label.numberOfLines = 0;
        self.label.lineBreakMode = NSLineBreakByWordWrapping;
        [self.label sizeToFit];
        //        self.label.adjustsFontSizeToFitWidth = YES;
        [self addSubview:self.label];
        
        // Add gesture recognizers
        //        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(isTapped:)]];
        
        [self addBuyButtons];
        [self addOkButton];
        if(nag)
        {
            self.timer = [NSTimer scheduledTimerWithTimeInterval: 0.5 target:self selector:@selector(updateCountdown) userInfo:nil repeats: YES];
        }
        else
        {
            _counter = _noOfTimesUsed;
            [self enableOkButton];
            [self UpdateLabelText];
        }
    }
    return self;
}

- (void)enableOkButton
{
    _okButton.enabled = YES;
    [_okButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
}
- (void)addOkButton
{
    int fontSize = self.frame.size.height/NAG_SCALE_TEXT_FACTOR;
    _okButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _okButton.layer.cornerRadius = 10.0;
    _okButton.layer.borderWidth = 1.0;
    _okButton.titleLabel.textColor = [UIColor whiteColor];
    _okButton.titleLabel.font = [UIFont fontWithName: @"Helvetica" size: fontSize];
    
    //    [button addTarget:self action:@selector(aMethod:) forControlEvents:UIControlEventTouchUpInside];
    [_okButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(aMethod:)]];
    
    [[_okButton layer] setBorderWidth:2.0f];
    _okButton.layer.borderColor = [UIColor blackColor].CGColor;
    [_okButton setTitle:@"Senere" forState:UIControlStateNormal];
    float x = self.frame.size.width-fontSize*6;
    float y = self.label.frame.size.height+fontSize*BUTTON_Y_POS;
    _okButton.frame = CGRectMake(x,y , fontSize*5, fontSize*1.5);
    _okButton.enabled = NO;
    [self addSubview:_okButton];
}

- (void)addBuyButtons
{
    int fontSize = self.frame.size.height/NAG_SCALE_TEXT_FACTOR;
    //Kjøp knapp
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button2.layer.cornerRadius = 10.0;
    button2.layer.borderWidth = 1.0;
    [button2 setTitleColor:[UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    [[button2 layer] setBorderWidth:2.0f];
    button2.layer.borderColor = [UIColor blackColor].CGColor;
    button2.titleLabel.font = [UIFont fontWithName: @"Helvetica" size: fontSize];
    
    //    [button2 addTarget:self action:@selector(buyMethod:) forControlEvents:UIControlEventTouchUpInside];
    [button2 addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buyMethod:)]];
    [button2 setTitle:@"Kjøp" forState:UIControlStateNormal];
    button2.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button2.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
    float x2 = fontSize;
    float y2 = self.label.frame.size.height+fontSize*BUTTON_Y_POS;
  
    button2.frame = CGRectMake(x2,y2 , fontSize*5, fontSize*1.5);
    [self addSubview:button2];
    
    //Gjenopprett kjøp knapp
    UIButton *button3 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button3.layer.cornerRadius = 10.0;
    button3.layer.borderWidth = 1.0;
    [button3 setTitleColor:[UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    //    button2.backgroundColor = [UIColor yellowColor];
    [[button3 layer] setBorderWidth:2.0f];
    button3.layer.borderColor = [UIColor blackColor].CGColor;
    button3.titleLabel.font = [UIFont fontWithName: @"Helvetica" size: fontSize];
    button3.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    button3.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
    
    //    [button2 addTarget:self action:@selector(buyMethod:) forControlEvents:UIControlEventTouchUpInside];
    [button3 addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(restorePurchaseMethod:)]];
    [button3 setTitle:@"Gjenopprett kjøp" forState:UIControlStateNormal];
    float x3 = fontSize;
    float y3 = self.label.frame.size.height+fontSize*(BUTTON_Y_POS+3);
    button3.frame = CGRectMake(x3,y3 , fontSize*9, fontSize*1.5);
    [self addSubview:button3];
    
}


- (void)buyMethod:(UIButton*)button
{
    NSLog(@"Button  clicked.");
    self.mvc.nagscreenOnDisplay = false;
    [self.mvc purchase];
    [self removeFromSuperview];
}
- (void)restorePurchaseMethod:(UIButton*)button
{
    NSLog(@"Restore purchase button clicked.");
    self.mvc.nagscreenOnDisplay = false;
    [self.mvc restorePurchase];
    [self removeFromSuperview];
}



- (void)aMethod:(UIButton*)button
{
    NSLog(@"Button  clicked.");
    self.mvc.nagscreenOnDisplay = false;
    [self removeFromSuperview];
}

#pragma mark - Gesture recognizer handlers
- (void)isTapped:(UITapGestureRecognizer *)recognizer
{
    //    [self.mvc answerQuestion:self];
}


-(void)setFont:(NSMutableAttributedString*)s fontSize:(int)fontSize
{
    NSRange selectedRange = NSMakeRange(0, [s length]);

    [s beginEditing];
    
    [s addAttribute:NSFontAttributeName
                      value:[UIFont fontWithName:@"Helvetica" size:fontSize]
                      range:selectedRange];
    
    [s endEditing];
}

-(void)UpdateLabelText
{
    NSMutableAttributedString *sHeadline = [[NSMutableAttributedString alloc] initWithString:@"Liker du Polpriser?"];
    NSRange selectedRange = NSMakeRange(0, [sHeadline length]);

    int fontSizeHeadline = self.frame.size.height/NAG_SCALE_HEADLINE_FACTOR;
    int fontSize = self.frame.size.height/NAG_SCALE_TEXT_FACTOR;
//    self.label.font = [UIFont systemFontOfSize:fontSize];

    [sHeadline beginEditing];
    
    [sHeadline addAttribute:NSFontAttributeName
                   value:[UIFont fontWithName:@"Helvetica-Bold" size:fontSizeHeadline]
                   range:selectedRange];
    
    [sHeadline endEditing];
    
    NSString *s = nil;
    if(self.mvc.price)
    {

        s = [NSString stringWithFormat:@"\n\nDu har brukt Polpriser gratis %d ganger.\n\nDu kan kjøpe Polpriser for %@.\n\nDenne beskjeden vises automatisk når du har brukt Polpriser gratis mer enn 10 ganger.", self.counter, self.mvc.price];
        
    }
    else
    {
        s = [NSString stringWithFormat:@"\n\nDu har brukt Polpriser gratis %d ganger.\n\nDenne beskjeden vises automatisk når du har brukt Polpriser gratis mer enn 10 ganger.", self.counter];
    }
    
    NSMutableAttributedString *sBody = [[NSMutableAttributedString alloc] initWithString:s];
    [self setFont:sBody fontSize:fontSize];
    NSMutableAttributedString *sCombined = [[NSMutableAttributedString alloc]initWithAttributedString:sHeadline];
    [sCombined appendAttributedString:sBody];
    self.label.attributedText = sCombined;
}

-(void) updateCountdown
{
    self.counter++;
    [self UpdateLabelText];
    
    if(self.noOfTimesUsed == self.counter)
    {
        [self.timer invalidate];
        self.timer = nil;
        [self enableOkButton];
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

