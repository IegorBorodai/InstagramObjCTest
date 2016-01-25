//
//  SGPostCollectionViewCell.h
//  TestApp
//
//  Created by Iegor Borodai on 9/30/15.
//  Copyright © 2015 Iegor Borodai. All rights reserved.
//


@interface SGPostCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic, nullable) IBOutlet UIImageView              *imageView;
@property (weak, nonatomic, nullable) IBOutlet UIActivityIndicatorView  *activityIndicator;

@property (weak, nonatomic, nullable) NSString                          *postId;
@property (weak, nonatomic, nullable) NSBlockOperation                  *imageLoadingOperation;

@end
