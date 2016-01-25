//
//  SGLandingViewController.m
//  TestApp
//
//  Created by Iegor Borodai on 9/29/15.
//  Copyright © 2015 Iegor Borodai. All rights reserved.
//

#import "SGSearchViewController.h"
#import "SGNetworkManager.h"
#import "SGUserTableViewCell.h"
#import <SDWebimage/SDImageCache.h>
#import "SGKeyStorageManger.h"

static NSString *kUserCellId = @"SGUserTableViewCell";
static NSString *kPlaceholderImageMan = @"MissingMale";
static NSString *kPlaceholderImageWoman = @"MissingFemale";

@interface SGSearchViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic, nullable)   IBOutlet UITableView *tableView;

@property (strong, nonatomic, nullable) NSArray<User *>      *searchResults;
@property (strong, nonatomic, nullable) NSURLSessionDataTask *currentSearchTask;

@property (strong, nonatomic, nonnull)  NSOperationQueue     *imageLoadingQueue;

@end

@implementation SGSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.imageLoadingQueue = [NSOperationQueue new];
    self.imageLoadingQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    self.imageLoadingQueue.maxConcurrentOperationCount = 5;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - SearchBar delegate

- (void)updateSearchResultsForText:(NSString *)text
{
    if (self.currentSearchTask) {
        [self.currentSearchTask cancel];
        self.currentSearchTask = nil;
    }
    
    __weak typeof(self)weakSelf = self;
    self.currentSearchTask = [SGNetworkManager getAllUsersForShortUserName:text success:^(NSArray<User *> * _Nonnull userArary) {
        weakSelf.searchResults = [userArary copy];
        weakSelf.tableView.dataSource = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    } failure:^(NSError * _Nullable error, BOOL isCanceled) {
        if (!isCanceled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:error.localizedDescription message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            });
        }
    }];
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    User *user = self.searchResults[indexPath.row];
    if ([self.delegate respondsToSelector:@selector(searchControllerDidFinishSearchWithResult:)]) {
        [self.delegate searchControllerDidFinishSearchWithResult:user];
    }
}

#pragma mark - TableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResults.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SGUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kUserCellId forIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(SGUserTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{    
    User *user = self.searchResults[indexPath.row];
    cell.userName.text = user.name;
    cell.userNickName.text = user.nickName;
    cell.userImageView.image = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:user.imageURL];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (!image) {
                if (0 == indexPath.row % 2) {
                    cell.userImageView.image = [UIImage imageNamed:kPlaceholderImageMan];
                } else {
                    cell.userImageView.image = [UIImage imageNamed:kPlaceholderImageWoman];
                }
                
                NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:user.imageURL]]];
                    if ([cell.userNickName.text isEqualToString:user.nickName]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[SGKeyStorageManger sharedManager] saveKeyToStorage:user.imageURL];
                            [[SDImageCache sharedImageCache] storeImage:image forKey:user.imageURL];
                            cell.userImageView.image = image;
                            cell.imageLoadingOperation = nil;
                        });
                    }
                }];
                operation.queuePriority = NSOperationQueuePriorityHigh;
                [self.imageLoadingQueue addOperation:operation];
                cell.imageLoadingOperation = operation;
            } else {
                cell.userImageView.image = image;
            }
        });
    });
}


- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(SGUserTableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (cell.imageLoadingOperation) {
        if (cell.imageLoadingOperation.finished) {
            cell.imageLoadingOperation = nil;
        } else {
            cell.imageLoadingOperation.queuePriority = NSOperationQueuePriorityLow;
        }
    }
}


@end
