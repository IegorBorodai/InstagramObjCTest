//
//  Post.h
//  TestApp
//
//  Created by Iegor Borodai on 9/30/15.
//  Copyright © 2015 Iegor Borodai. All rights reserved.
//

#import "Comment.h"

@interface Post : NSObject

@property (strong, nonatomic, nonnull) NSString *id;
@property (strong, nonatomic, nullable) NSString *lowResolutionImage;
@property (strong, nonatomic, nullable) NSString *fullResolutionImage;
@property (strong, nonatomic, nullable) NSMutableArray<Comment *> *comments;

@end
