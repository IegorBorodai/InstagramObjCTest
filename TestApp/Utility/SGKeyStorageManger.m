//
//  SGKeyStorageManger.m
//  TestApp
//
//  Created by Iegor Borodai on 9/30/15.
//  Copyright © 2015 Iegor Borodai. All rights reserved.
//

#import "SGKeyStorageManger.h"
#import <SDWebimage/SDImageCache.h>

static NSString *kKeyStorageId = @"KeyStorage";

@interface SGKeyStorageManger ()

@property (strong, nonatomic, nonnull) NSMutableArray *keys;

@end

@implementation SGKeyStorageManger

#pragma mark - Lifecycle

+ (SGKeyStorageManger *)sharedManager
{
    static SGKeyStorageManger *globalDataManager = nil;
    static dispatch_once_t onceTokenGlobalDataManager;
    
    dispatch_once(&onceTokenGlobalDataManager, ^{
        if (!globalDataManager)
        {
            globalDataManager = [SGKeyStorageManger new];
        }
    });
    
    return globalDataManager;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.keys = [[[NSUserDefaults standardUserDefaults] arrayForKey:kKeyStorageId] mutableCopy];
        if (!self.keys) {
            self.keys = [NSMutableArray new];
        }
    }
    return self;
}

#pragma mark - Public methods


- (void)saveKeyToStorage:(NSString  * _Nonnull )key
{
    [self.keys addObject:key];
}

- (nonnull NSArray<UIImage *> *)getLastPhotos
{
    NSMutableArray *images = [NSMutableArray new];
    
    [self.keys enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString  * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if([[SDImageCache sharedImageCache] diskImageExistsWithKey:key]) {
            [images addObject:[[SDImageCache sharedImageCache] imageFromDiskCacheForKey:key]];
            if (images.count > 9)
            {
                *stop = YES;
                return;
            }
        }
    }];
    
    
    return images;
}

- (void)saveToDisk
{
    [[NSUserDefaults standardUserDefaults] setObject:self.keys forKey:kKeyStorageId];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
