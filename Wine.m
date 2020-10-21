//
//  Customer.m
//  Chanda
//
//  Created by Mohammad Azam on 10/25/11.
//  Copyright (c) 2011 HighOnCoding. All rights reserved.
//

#import "Wine.h"

@implementation Wine

@synthesize id,type,name,volume,price;

-(NSString *) getName 
{
    return [NSString stringWithFormat:@"%d %@ %@ %d",self.id,self.name, self.volume, self.price];
}

@end
