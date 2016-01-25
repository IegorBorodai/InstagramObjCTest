//
//  SGNetworkManager.m
//  TestApp
//
//  Created by Iegor Borodai on 9/29/15.
//  Copyright © 2015 Iegor Borodai. All rights reserved.
//

#import "SGNetworkManager.h"

static NSString *kClientID = @"9af54ad6da004994867f4274c348b146";
static NSString *kGetUserNamesURL = @"https://api.instagram.com/v1/users/search?q=%@&count=20&client_id=%@";
static NSString *kGetUserPostsURL = @"https://api.instagram.com/v1/users/%@/media/recent?count=30&client_id=%@";
static NSString *kGetMoreUserPostsURL = @"https://api.instagram.com/v1/users/%@/media/recent?max_id=%@&count=30&client_id=%@";


@implementation SGNetworkManager

#pragma mark - Requests

+ (nonnull NSURLSessionDataTask *)getAllUsersForShortUserName:(nonnull NSString *)shortUserName
                                                      success:(nullable SuccessUserSearchBlock)successBlock
                                                      failure:(nullable FailureBlock)failureBlock;
{
    NSURLRequest *requset = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:kGetUserNamesURL, shortUserName, kClientID]]];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:requset completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDictionary *JSON = [SGNetworkManager validateResponseAndSerializeJSON:(NSHTTPURLResponse*)response data:data error:error failureBlock:failureBlock];
        if (JSON) {
            NSMutableArray *results = [NSMutableArray new];
            for (NSDictionary *object in JSON[@"data"]) {
                if ([SGNetworkManager checkParameterWithKeyForDictionary:object parameterKey:@"id" class:[NSString class]]) {
                    User *newUser = [User new];
                    newUser.id = object[@"id"];
                    
                    if ([SGNetworkManager checkParameterWithKeyForDictionary:object parameterKey:@"full_name" class:[NSString class]]) {
                        newUser.name = object[@"full_name"];
                    }
                    
                    if ([SGNetworkManager checkParameterWithKeyForDictionary:object parameterKey:@"username" class:[NSString class]]) {
                        newUser.nickName = object[@"username"];
                    }
                    
                    if ([SGNetworkManager checkParameterWithKeyForDictionary:object parameterKey:@"profile_picture" class:[NSString class]]) {
                        newUser.imageURL = object[@"profile_picture"];
                    }
                    
                    [results addObject:newUser];
                }
            }
            
            if (successBlock) {
                successBlock(results);
            }
        }
    }];
    [task resume];
    
    return task;
}


+ (nonnull NSURLSessionDataTask *)getAllPostForUserId:(nonnull NSString *)userId
                                           nextPageId:(nullable NSString *)nextPageId
                                              success:(nullable SuccessPostsBlock)successBlock
                                              failure:(nullable FailureBlock)failureBlock;
{
    NSString *urlPath = nextPageId ? [NSString stringWithFormat:kGetMoreUserPostsURL, userId, nextPageId, kClientID] : [NSString stringWithFormat:kGetUserPostsURL, userId, kClientID];
    NSURLRequest *requset = [NSURLRequest requestWithURL:[NSURL URLWithString:urlPath]];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:requset completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDictionary *JSON = [SGNetworkManager validateResponseAndSerializeJSON:(NSHTTPURLResponse*)response data:data error:error failureBlock:failureBlock];
        if (JSON) {
            
            NSString *paginationId;
            if ([SGNetworkManager checkParameterWithKeyForDictionary:JSON parameterKey:@"pagination" class:[NSDictionary class]]) {
                NSDictionary *pagination = JSON[@"pagination"];
                if ([self checkParameterWithKeyForDictionary:pagination parameterKey:@"next_max_id" class:[NSString class]]) {
                    paginationId = pagination[@"next_max_id"];
                }
            }
            
            NSMutableArray *results = [NSMutableArray new];
            for (NSDictionary *object in JSON[@"data"]) {
                if ([SGNetworkManager checkParameterWithKeyForDictionary:object parameterKey:@"id" class:[NSString class]]) {
                    Post *newPost = [Post new];
                    newPost.id = object[@"id"];
                    
                    if ([SGNetworkManager checkParameterWithKeyForDictionary:object parameterKey:@"images" class:[NSDictionary class]]) {
                        NSDictionary *images = object[@"images"];
                        if ([SGNetworkManager checkParameterWithKeyForDictionary:images parameterKey:@"low_resolution" class:[NSDictionary class]]) {
                            
                            NSDictionary *image = images[@"low_resolution"];
                            if ([SGNetworkManager checkParameterWithKeyForDictionary:image parameterKey:@"url" class:[NSString class]]) {
                                newPost.lowResolutionImage = image[@"url"];
                            }
                        }
                        
                        if ([SGNetworkManager checkParameterWithKeyForDictionary:images parameterKey:@"standard_resolution" class:[NSDictionary class]]) {
                            
                            NSDictionary *image = images[@"standard_resolution"];
                            if ([SGNetworkManager checkParameterWithKeyForDictionary:image parameterKey:@"url" class:[NSString class]]) {
                                newPost.fullResolutionImage = image[@"url"];
                            }
                        }
                    }
                    
                    NSMutableArray *commentsResults = [NSMutableArray new];
                    if ([SGNetworkManager checkParameterWithKeyForDictionary:object parameterKey:@"comments" class:[NSDictionary class]]) {
                        NSDictionary *comments = object[@"comments"];
                        
                        if ([SGNetworkManager checkParameterWithKeyForDictionary:comments parameterKey:@"data" class:[NSArray class]]) {
                            NSArray *commentsData = comments[@"data"];
                            for (NSDictionary *dict in commentsData) {
                                Comment *newComment = [Comment new];
                                
                                if ([SGNetworkManager checkParameterWithKeyForDictionary:dict parameterKey:@"text" class:[NSString class]]) {
                                    newComment.text = dict[@"text"];
                                }
                                
                                if ([SGNetworkManager checkParameterWithKeyForDictionary:dict parameterKey:@"from" class:[NSDictionary class]]) {
                                    NSDictionary *fromUser = dict[@"from"];
                                    
                                    if ([SGNetworkManager checkParameterWithKeyForDictionary:fromUser parameterKey:@"username" class:[NSString class]]) {
                                        newComment.name = fromUser[@"username"];
                                    }
                                }
                                
                                [commentsResults addObject:newComment];
                            }
                        }
                    }
                    
                    newPost.comments = commentsResults;
                    
                    [results addObject:newPost];
                }
            }
            
            if (successBlock) {
                successBlock(results, paginationId);
            }
        }
    }];
    [task resume];
    
    return task;
}

+ (NSDictionary *)validateResponseAndSerializeJSON:(NSHTTPURLResponse * _Nullable)response data:(NSData * _Nullable)data error:(NSError * _Nullable)error failureBlock:(FailureBlock)failureBlock {
    
    NSError *localError = error;
    if (!error) {
        if (response.statusCode == 200) {
            
            NSError *jsonError;
            NSDictionary *filesJSON = [NSJSONSerialization
                                       JSONObjectWithData:data
                                       options:NSJSONReadingAllowFragments
                                       error:&jsonError];
            
            if (!jsonError && filesJSON && [SGNetworkManager checkParameterWithKeyForDictionary:filesJSON parameterKey:@"data" class:[NSArray class]]) {
                return filesJSON;
            } else {
                localError = [NSError errorWithDomain:[response.URL absoluteString] code:-1 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"request.error.instagram", @"Network error when instagram API not working or send corrupted data")}];
            }
        } else if (response.statusCode == 400) {
            localError = [NSError errorWithDomain:[response.URL absoluteString] code:-1 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"request.error.instagramPrivate", @"Network error when instagram API found private profile")}];
        } else {
            
        }
    } else {
        if (error.code == NSURLErrorCancelled) {
            localError = nil;
            failureBlock(error, YES);
        } else {
            localError = [NSError errorWithDomain:@"Cancel" code:-1 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"request.error.internet", @"Network error when user has problems with internet connection")}];
        }
    }
    
    if (localError) {
        failureBlock(localError, NO);
    }
    
    return nil;
}

#pragma mark - Private methods

+ (BOOL)checkParameterWithKeyForDictionary:(NSDictionary *)dict parameterKey:(NSString *)parameterKey class:(Class)class
{
    BOOL result = ([dict isKindOfClass:[NSDictionary class]] && dict[parameterKey] && [dict[parameterKey] isKindOfClass:class]);
    if (!result) {
        NSLog(@"WRONG PARAMETER TYPE FOR KEY: %@", parameterKey);
    }
    return result;
}

@end
