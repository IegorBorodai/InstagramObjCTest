//
//  SGPostsViewController.m
//  TestApp
//
//  Created by Iegor Borodai on 9/30/15.
//  Copyright © 2015 Iegor Borodai. All rights reserved.
//

#import "SGPostsViewController.h"
#import "SGNetworkManager.h"
#import "SGPostCollectionViewCell.h"
#import "SGPostViewController.h"
#import "SGSearchViewController.h"
#import <SDWebimage/SDImageCache.h>
#import "SGPostsFooterCollectionReusableView.h"
#import "SGKeyStorageManger.h"
#import "SGParallaxCollectionViewLayout.h"

#define ITEMS_BEFORE_LAZY_LOAD        10
#define TABLE_VIEW_ANIMATION_TIME     0.25
#define COLLECTION_ITEM_IN_LINE_COUNT 3
#define COLLECTION_ITEM_OFFSET        20
#define PARALLAX_INTENSITY            20
#define COLLECTION_VIEW_LAYOUT_OFFSET 20
#define PARALLAX_IMAGE_MIN_SIZE       50
#define PARALLAX_IMAGE_MAX_SIZE       70

static NSString *kPostCellId =                @"SGPostCollectionViewCell";
static NSString *kFooterSupplementaryViewId = @"SGPostsFooterCollectionReusableView";


typedef NS_ENUM(NSUInteger, CollectionViewLayoutState){
    CollectionViewLayoutStateLastImages = 0,
    CollectionViewLayoutStateInternetSearch = 1
};


@interface SGPostsViewController () <UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SGSearchViewControllerDelegate>

@property (weak, nonatomic) IBOutlet    UICollectionView        *collectionView;
@property (weak, nonatomic) IBOutlet    UISearchBar             *searchBar;
@property (weak, nonatomic) IBOutlet    UIView                  *containerView;
@property (weak, nonatomic) IBOutlet    UIView                  *loadingView;

@property (strong, nonatomic, nonnull)  NSArray<Post *>         *userPosts;
@property (strong, nonatomic, nonnull)  NSArray                 *imagesFromPreviousSearch;
@property (strong, nonatomic, nonnull)  NSString                *nextPageId;
@property (strong, nonatomic, nonnull)  NSOperationQueue        *imageLoadingQueue;
@property (strong, nonatomic, nullable) NSURLSessionDataTask    *postsRequest;

@property (strong, nonatomic, nullable) User                    *currentUser;
@property (weak, nonatomic, nullable)   SGSearchViewController  *searchViewController;

@property (assign, nonatomic)           CollectionViewLayoutState collectionViewLayoutState;

@end

@implementation SGPostsViewController


#pragma mark - Lifecycle


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(updatePosts:) forControlEvents:UIControlEventValueChanged];
    refreshControl.tintColor = [UIColor colorWithRed:48.0/255.0 green:131.0/255.0 blue:251.0/255.0 alpha:1.0];
    [self.collectionView addSubview:refreshControl];
    
    self.imageLoadingQueue = [NSOperationQueue new];
    self.imageLoadingQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    self.imageLoadingQueue.maxConcurrentOperationCount = 5;
    
    self.userPosts = @[];
    
    self.imagesFromPreviousSearch = [[SGKeyStorageManger sharedManager] getLastPhotos];
    
    self.collectionViewLayoutState = self.imagesFromPreviousSearch.count > 0 ? CollectionViewLayoutStateLastImages : CollectionViewLayoutStateInternetSearch;
    
    [self addParallaxToView:self.collectionView];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[SGSearchViewController class]]) {
        self.searchViewController = segue.destinationViewController;
        self.searchViewController.delegate = self;
    }
}

#pragma mark - Private

- (void)addParallaxToView:(UIView *)viewForParallax
{
    UIInterpolatingMotionEffect *verticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalMotionEffect.minimumRelativeValue = @(-PARALLAX_INTENSITY);
    verticalMotionEffect.maximumRelativeValue = @(PARALLAX_INTENSITY);
    
    UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = @(-PARALLAX_INTENSITY);
    horizontalMotionEffect.maximumRelativeValue = @(PARALLAX_INTENSITY);
    
    UIMotionEffectGroup *group = [UIMotionEffectGroup new];
    group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
    
    [viewForParallax addMotionEffect:group];
}

- (void)updatePosts:(UIRefreshControl *)refreshControl
{
    if (self.postsRequest) {
        [self.postsRequest cancel];
        self.postsRequest = nil;
    }
    
    __weak typeof(self)weakSelf = self;
    self.loadingView.hidden = NO;
    self.loadingView.alpha = 1.0;
    
    if (self.userPosts.count > 0) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
    }
    
    if (refreshControl) {
        [refreshControl endRefreshing];
    }
    
    self.postsRequest = [SGNetworkManager getAllPostForUserId:self.currentUser.id nextPageId:nil success:^(NSArray<Post *> * _Nonnull userPosts, NSString * _Nullable nextPageId) {
        weakSelf.nextPageId = [nextPageId copy];
        weakSelf.userPosts = [userPosts copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.postsRequest = nil;
            [weakSelf.collectionView reloadData];
            [UIView animateWithDuration:TABLE_VIEW_ANIMATION_TIME animations:^{
                weakSelf.loadingView.alpha = 0.0;
            } completion:^(BOOL finished) {
                weakSelf.loadingView.hidden = YES;
            }];
        });
    } failure:^(NSError * _Nullable error, BOOL isCanceled) {
        if (!isCanceled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:error.localizedDescription message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                self.loadingView.hidden = NO;
                [UIView animateWithDuration:TABLE_VIEW_ANIMATION_TIME animations:^{
                    weakSelf.loadingView.alpha = 0.0;
                } completion:^(BOOL finished) {
                    weakSelf.loadingView.hidden = YES;
                }];
            });
        }
    }];
}

#pragma mark - CollectionView layout state changes

-(void)setCollectionViewLayoutState:(CollectionViewLayoutState)collectionViewLayoutState
{
    _collectionViewLayoutState = collectionViewLayoutState;
    
    switch (collectionViewLayoutState) {
        case CollectionViewLayoutStateLastImages: {
            self.loadingView.hidden = YES;
            self.loadingView.alpha = 0.0;
            
            NSMutableArray *frames = [NSMutableArray arrayWithCapacity:self.imagesFromPreviousSearch.count];
            
            for (NSInteger i = 0; i < self.imagesFromPreviousSearch.count; i++) {
                CGRect randomRect = [self generateRandomRectWithPreviousFrames:frames];
                [frames addObject:[NSValue valueWithCGRect:randomRect]];
            }
            
            SGParallaxCollectionViewLayout *collectionLayout = [[SGParallaxCollectionViewLayout alloc] initWithFramesArray:frames];
            [collectionLayout prepareLayout];
            [self.collectionView setCollectionViewLayout:collectionLayout animated:NO];
            
            break;
        }
        case CollectionViewLayoutStateInternetSearch: {
            
            [self.searchBar becomeFirstResponder];
            
            if ([self.collectionView.collectionViewLayout isKindOfClass:[SGParallaxCollectionViewLayout class]]) {
                
                UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
                flowLayout.minimumLineSpacing = COLLECTION_VIEW_LAYOUT_OFFSET;
                flowLayout.minimumInteritemSpacing = COLLECTION_VIEW_LAYOUT_OFFSET;
                flowLayout.sectionInset = UIEdgeInsetsMake(COLLECTION_VIEW_LAYOUT_OFFSET, COLLECTION_VIEW_LAYOUT_OFFSET, COLLECTION_VIEW_LAYOUT_OFFSET, COLLECTION_VIEW_LAYOUT_OFFSET);
                [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
                [flowLayout prepareLayout];
                
                [self.collectionView reloadData];
                
                [self.collectionView performBatchUpdates:^{
                    [self.collectionView.collectionViewLayout invalidateLayout];
                    [self.collectionView setCollectionViewLayout:flowLayout animated:NO];
                } completion:^(BOOL finished) {
                }];
            }
            
            break;
        }
        default: {
            break;
        }
    }
}

- (CGRect)generateRandomRectWithPreviousFrames:(NSArray *)frames
{
    NSInteger size = arc4random() % PARALLAX_IMAGE_MAX_SIZE + PARALLAX_IMAGE_MIN_SIZE;
    CGRect randomRect = CGRectMake(arc4random() % (((NSInteger)self.view.bounds.size.width) - COLLECTION_VIEW_LAYOUT_OFFSET*2 - size), arc4random() % (((NSInteger)self.view.bounds.size.height) - COLLECTION_VIEW_LAYOUT_OFFSET*2 - ((NSInteger)self.searchBar.frame.size.height) - ((NSInteger)[UIApplication sharedApplication].statusBarFrame.size.height) - size), size, size);
    
    BOOL canUseFrame = YES;
    for (NSValue *value in frames) {
        if (CGRectIntersectsRect([value CGRectValue],randomRect)){
            canUseFrame = NO;
            break;
        }
    }
    
    if (canUseFrame) {
        return randomRect;
    } else {
        return [self generateRandomRectWithPreviousFrames:frames];
    }
}


#pragma mark - CollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return CollectionViewLayoutStateInternetSearch == self.collectionViewLayoutState ? self.userPosts.count : self.imagesFromPreviousSearch.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPostCellId forIndexPath:indexPath];
    
    if (CollectionViewLayoutStateInternetSearch == self.collectionViewLayoutState && !self.postsRequest && (indexPath.row + ITEMS_BEFORE_LAZY_LOAD) > self.userPosts.count) {
        __weak typeof(self)weakSelf = self;
        self.postsRequest = [SGNetworkManager getAllPostForUserId:self.currentUser.id nextPageId:self.nextPageId success:^(NSArray<Post *> * _Nonnull userPosts, NSString * _Nullable nextPageId) {
            weakSelf.nextPageId = [nextPageId copy];
            weakSelf.userPosts = [weakSelf.userPosts arrayByAddingObjectsFromArray:[userPosts copy]];
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.postsRequest = nil;
                [weakSelf.collectionView reloadData];
            });
        } failure:^(NSError * _Nullable error, BOOL isCanceled) {
            if (!isCanceled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:error.localizedDescription message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                });
            }
        }];
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (CollectionViewLayoutStateInternetSearch == self.collectionViewLayoutState) {
        SGPostsFooterCollectionReusableView *view = (SGPostsFooterCollectionReusableView *)[collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kFooterSupplementaryViewId forIndexPath:indexPath];
        if (self.postsRequest) {
            [view.activityIndicator startAnimating];
        } else {
            [view.activityIndicator stopAnimating];
        }
        return view;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger size = (self.view.bounds.size.width - (COLLECTION_ITEM_IN_LINE_COUNT + 1) * COLLECTION_ITEM_OFFSET) / COLLECTION_ITEM_IN_LINE_COUNT;
    return CGSizeMake(size, size);
}

#pragma mark - CollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(SGPostCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    cell.imageView.image = nil;
    
    switch (self.collectionViewLayoutState) {
        case CollectionViewLayoutStateLastImages: {
            cell.imageView.image = self.imagesFromPreviousSearch[indexPath.row];
            [cell.activityIndicator stopAnimating];
            
            break;
        }
        case CollectionViewLayoutStateInternetSearch: {
            Post *post = self.userPosts[indexPath.row];
            cell.postId = post.id;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:post.lowResolutionImage];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!image) {
                        [cell.activityIndicator startAnimating];
                        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:post.lowResolutionImage]]];
                            if ([cell.postId isEqualToString:post.id]) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [[SGKeyStorageManger sharedManager] saveKeyToStorage:post.lowResolutionImage];
                                    [[SDImageCache sharedImageCache] storeImage:image forKey:post.lowResolutionImage];
                                    [cell.activityIndicator stopAnimating];
                                    cell.imageView.image = image;
                                    cell.imageLoadingOperation = nil;
                                });
                            }
                        }];
                        operation.queuePriority = NSOperationQueuePriorityHigh;
                        [self.imageLoadingQueue addOperation:operation];
                        cell.imageLoadingOperation = operation;
                    } else {
                        [cell.activityIndicator stopAnimating];
                        cell.imageView.image = image;
                    }
                });
            });
            break;
        }
        default: {
            break;
        }
    }
}


- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(SGPostCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (CollectionViewLayoutStateInternetSearch == self.collectionViewLayoutState && cell.imageLoadingOperation) {
        if (cell.imageLoadingOperation.finished) {
            cell.imageLoadingOperation = nil;
        } else {
            cell.imageLoadingOperation.queuePriority = NSOperationQueuePriorityLow;
        }
    }
}


-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (CollectionViewLayoutStateInternetSearch == self.collectionViewLayoutState) {
        Post *post = self.userPosts[indexPath.row];
        SGPostViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass(SGPostViewController.class)];
        vc.title = self.currentUser.nickName;
        vc.post = post;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - SGSearchViewController Delegate

- (void)searchControllerDidFinishSearchWithResult:(User  * _Nonnull )resultUser
{
    [self.searchBar resignFirstResponder];
    
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:TABLE_VIEW_ANIMATION_TIME animations:^{
        weakSelf.containerView.alpha = 0.0;
    } completion:^(BOOL finished) {
        weakSelf.containerView.hidden = YES;
    }];
    
    self.currentUser = resultUser;
    [self updatePosts:nil];
}


#pragma mark - UISearchBar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (self.searchViewController && searchText && searchText.length > 0) {
        [self.searchViewController updateSearchResultsForText:searchText];
    }
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    __weak typeof(self)weakSelf = self;
    self.containerView.hidden = NO;
    [UIView animateWithDuration:TABLE_VIEW_ANIMATION_TIME animations:^{
        weakSelf.containerView.alpha = 1.0;
    } completion:^(BOOL finished) {
        weakSelf.collectionViewLayoutState = CollectionViewLayoutStateInternetSearch;
    }];
    return YES;
}

@end
