//
//  SGLandingViewController.h
//  TestApp
//
//  Created by Iegor Borodai on 9/29/15.
//  Copyright © 2015 Iegor Borodai. All rights reserved.
//

#import "User.h"

@protocol SGSearchViewControllerDelegate <NSObject>

- (void)searchControllerDidFinishSearchWithResult:(User  * _Nonnull )resultUser;

@end

@interface SGSearchViewController : UIViewController

@property (weak, nonatomic, nullable) id<SGSearchViewControllerDelegate> delegate;

- (void)updateSearchResultsForText:(NSString * _Nonnull )text;

@end
