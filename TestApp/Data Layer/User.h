//
//  User.h
//  TestApp
//
//  Created by Iegor Borodai on 9/29/15.
//  Copyright © 2015 Iegor Borodai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

@property (strong, nonatomic, nonnull)  NSString *id;
@property (strong, nonatomic, nullable) NSString *name;
@property (strong, nonatomic, nullable) NSString *nickName;
@property (strong, nonatomic, nullable) NSString *imageURL;

@end
