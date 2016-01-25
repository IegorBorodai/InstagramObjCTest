//
//  SGUserTableViewCell.h
//  TestApp
//
//  Created by Iegor Borodai on 9/29/15.
//  Copyright © 2015 Iegor Borodai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SGUserTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UILabel *userNickName;

@property (weak, nonatomic) NSBlockOperation *imageLoadingOperation;

@end
