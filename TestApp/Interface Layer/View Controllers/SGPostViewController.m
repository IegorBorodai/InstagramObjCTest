//
//  SGPostViewController.m
//  TestApp
//
//  Created by Iegor Borodai on 9/30/15.
//  Copyright © 2015 Iegor Borodai. All rights reserved.
//

#import "SGPostViewController.h"
#import <SDWebimage/SDImageCache.h>
#import "SGKeyStorageManger.h"

static NSString *kCommentCellId = @"CommentCellId";

@interface SGPostViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SGPostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:self.post.fullResolutionImage];
    if (image) {
         self.imageView.image = image;
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.post.fullResolutionImage]]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[SGKeyStorageManger sharedManager] saveKeyToStorage:self.post.fullResolutionImage];
                [[SDImageCache sharedImageCache] storeImage:image forKey:self.post.fullResolutionImage];
                self.imageView.image = image;
            });
        });
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark - TableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.post.comments.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCommentCellId forIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Comment *comment = self.post.comments[indexPath.row];

    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", comment.name] attributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:254.0/255.0 green:110.0/255.0 blue:110.0/255.0 alpha:1.0]}];
    
    [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:comment.text attributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:84.0/255.0 green:83.0/255.0 blue:101.0/255.0 alpha:1.0]}]];

    cell.textLabel.attributedText = attrString;
}

@end
