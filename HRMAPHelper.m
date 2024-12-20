//
//  HRMAPHelper.m
//  HeartMonitor
//
//  Created by Erlend Thune on 29.06.15.
//  Copyright (c) 2015 Razeware LLC. All rights reserved.
//

#import "HRMAPHelper.h"

@implementation HRMAPHelper

+ (HRMAPHelper *)sharedInstance {
    static dispatch_once_t once;
    static HRMAPHelper * sharedInstance;
    dispatch_once(&once, ^{
        NSSet * productIdentifiers = [NSSet setWithObjects:
                                      @"com.erlendthune.polpriser",
                                      nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}

@end
