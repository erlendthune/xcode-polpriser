//
//  ETHelpViewController.m
//  Polet prisliste
//
//  Created by Erlend Thune on 09.05.14.
//  Copyright (c) 2014 Erlend Thune. All rights reserved.
//

#import "ETHelpViewController.h"

@interface ETHelpViewController ()

@end

@implementation ETHelpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (IBAction)helpDone:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *thePath = [[NSBundle mainBundle] pathForResource:@"PolpriserUserGuide" ofType:@"html"];
    
    if (thePath) {
        
        [self.helpView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:thePath isDirectory:NO]]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
