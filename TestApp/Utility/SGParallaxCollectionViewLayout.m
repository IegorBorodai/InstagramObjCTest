//
//  SGParallaxCollectionViewLayout.m
//  TestApp
//
//  Created by Iegor Borodai on 10/1/15.
//  Copyright © 2015 Iegor Borodai. All rights reserved.
//

#import "SGParallaxCollectionViewLayout.h"
#import "SGPostsViewController.h"

@interface SGParallaxCollectionViewLayout ()

@property (strong, nonatomic, nonnull) NSArray *frames;

@end

@implementation SGParallaxCollectionViewLayout

-(instancetype)initWithFramesArray:(NSArray *)frames
{
    self = [super init];
    if (self) {
        self.frames = frames;
    }
    return self;
}

#pragma mark - UICollectionViewLayout overridden methods

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    
    NSMutableArray *layoutAttributes = [NSMutableArray array];
    
    NSMutableArray *visibleIndexArray = [NSMutableArray new];
    for (NSInteger i = 0; i < [self.collectionView numberOfItemsInSection:0]; i++) {
        [visibleIndexArray addObject:[NSIndexPath indexPathForItem:i inSection:0]];
    }
    
    for (NSIndexPath *indexPath in visibleIndexArray) {
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        attributes.frame = [self.frames[indexPath.row] CGRectValue];
        [layoutAttributes addObject:attributes];
    }
    
    return layoutAttributes;
}


#pragma mark - UICollectionViewLayout Implementation


- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}


@end
