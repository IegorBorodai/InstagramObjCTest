//
//  SGNetworkManager.h
//  TestApp
//
//  Created by Iegor Borodai on 9/29/15.
//  Copyright © 2015 Iegor Borodai. All rights reserved.
//

@import Foundation;

#import "User.h"
#import "Post.h"
#import "Comment.h"

typedef void (^FailureBlock)(NSError* __nullable error, BOOL isCanceled);
typedef void (^SuccessUserSearchBlock)(NSArray<User *> * _Nonnull userArary);
typedef void (^SuccessPostsBlock)(NSArray<Post *> * _Nonnull userPosts, NSString * _Nullable nextPageId);

@interface SGNetworkManager : NSObject

+ (nonnull NSURLSessionDataTask *)getAllUsersForShortUserName:(nonnull NSString *)shortUserName
                                              success:(nullable SuccessUserSearchBlock)successBlock
                                              failure:(nullable FailureBlock)failureBlock;

+ (nonnull NSURLSessionDataTask *)getAllPostForUserId:(nonnull NSString *)userId
                                           nextPageId:(nullable NSString *)nextPageId
                                                      success:(nullable SuccessPostsBlock)successBlock
                                                      failure:(nullable FailureBlock)failureBlock;

@end
