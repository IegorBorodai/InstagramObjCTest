//
//  SGKeyStorageManger.h
//  TestApp
//
//  Created by Iegor Borodai on 9/30/15.
//  Copyright © 2015 Iegor Borodai. All rights reserved.
//

@interface SGKeyStorageManger : NSObject

+ (nonnull SGKeyStorageManger *)sharedManager;

- (void)saveKeyToStorage:(NSString  * _Nonnull )key;
- (nonnull NSArray<UIImage *> *)getLastPhotos;
- (void)saveToDisk;

@end
