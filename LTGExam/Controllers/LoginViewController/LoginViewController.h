//
//  LoginViewController.h
//  LTGExam
//
//  Created by Yaniv Marshaly on 2/5/15.
//  Copyright (c) 2015 Yaniv Marshaly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@class LoginViewController;

@protocol  LoginViewControllerDelegate<NSObject>

- (void)loginViewController:(LoginViewController*)controller didFinishLoginWithUser:(id<FBGraphUser>)user;

- (void)loginViewControllerUserDidCancelLogin:(LoginViewController *)controller;

@end



@interface LoginViewController : UIViewController

@property (weak, nonatomic) id<LoginViewControllerDelegate> delegate;

@end
