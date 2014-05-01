//
//  Customer.h
//  Chanda
//
//  Created by Mohammad Azam on 10/25/11.
//  Copyright (c) 2011 HighOnCoding. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Wine : NSObject
{
    
}

@property (nonatomic,assign) int id;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *volume;
@property (nonatomic,strong) NSString *price;

@end
