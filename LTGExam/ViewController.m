//
//  ViewController.m
//  LTGExam
//
//  Created by Yaniv Marshaly on 2/5/15.
//  Copyright (c) 2015 Yaniv Marshaly. All rights reserved.
//

#import "ViewController.h"
#import "FBSession+Extentions.h"
#import "LoginViewController.h"

typedef NS_ENUM(NSUInteger, kFBInvitationType) {
    kFBInvitationTypeRequest        = 0,
    kFBInvitationTypeDialog         = 1,
};

@interface ViewController () <LoginViewControllerDelegate,FBFriendPickerDelegate>

//UI
@property (weak, nonatomic) IBOutlet FBProfilePictureView *profilePictureView;

//Local
@property (strong, nonatomic) id<FBGraphUser> currentUser;

@property (strong, nonatomic) FBCacheDescriptor * friendsCacheDescriptor;

@end

@implementation ViewController{
    
    NSArray * _friendsSelection;
    
    kFBInvitationType _invitationType;
}

#pragma mark - UIViewController methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //Check if user already logged in
    if ([FBSession isSessionOpen] == NO) {
        [self presentLoginViewController];
    }else{
        [self requestUserDetails];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.profilePictureView.layer.cornerRadius = CGRectGetWidth(self.profilePictureView.bounds)/2.0f;
}
#pragma mark - Properties
- (void)setCurrentUser:(id<FBGraphUser>)currentUser
{
    if ([_currentUser.objectID isEqualToString:currentUser.objectID] == NO) {
        
        _currentUser = currentUser;
        
        //release the old cache
        //because we have new user
        _friendsCacheDescriptor = nil;
        
        self.profilePictureView.profileID = currentUser.objectID;
        
    }
}

#pragma mark - Private methods
- (void)requestUserDetails
{
    __weak ViewController * weakSelf = self;
    
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        if (result && error == nil) {
            
            weakSelf.currentUser = result;
            
        }
        
    }];
}
- (void)presentLoginViewController
{
    LoginViewController * controller = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    
    controller.delegate = self;
    
    [self presentViewController:controller animated:YES completion:NULL];
    

    
}

- (void)presentFriendsPickerViewController
{
    FBFriendPickerViewController * controller = [FBFriendPickerViewController new];
    
    [self setupCacheDescriptorIfNeeded];
    
    //release the old friends selection list
    _friendsSelection = nil;
    
    [controller configureUsingCachedDescriptor:self.friendsCacheDescriptor];
    
    controller.title = @"Invite Friends";
    controller.delegate = self;
    
    [controller loadData];
    [controller clearSelection];
    
    [self presentViewController:controller animated:YES completion:NULL];

}

- (void)setupCacheDescriptorIfNeeded
{
    if (_friendsCacheDescriptor == nil) {
        
        _friendsCacheDescriptor = [FBFriendPickerViewController cacheDescriptor];
        
    }
}



- (void)showInviteDialog
{
    
     __weak ViewController * weakSelf = self;
    
    [FBWebDialogs presentRequestsDialogModallyWithSession:nil
                                                  message:@"This is an invitation test"
                                                    title:@"LTGExam" parameters:nil
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
        if (error) {
            // Case A: Error launching the dialog or sending request.
                [weakSelf showAlertWithTitle:@"Facebook" andMessage:error.localizedDescription];
        } else {
            if (result == FBWebDialogResultDialogNotCompleted) {
                // Case B: User clicked the "x" icon
                NSLog(@"User canceled request.");
            } else {
                 [weakSelf showAlertWithTitle:@"Invitation sent!" andMessage:nil];
            }
        }

    }];
    
}

- (void)sendInviteRquestWithFriendsIDs:(NSArray*)friendsIDs
{
    if (friendsIDs.count) {
        NSString * friendsIDsString = [friendsIDs componentsJoinedByString:@","];
        
        NSDictionary *params = @{
                                 @"message" : @"This is an invitation test" ,
                                 @"to" : friendsIDsString
                                 };
        
        __weak ViewController * weakSelf = self;
        
        /* make the API call */
        [FBRequestConnection startWithGraphPath:@"/me/apprequests"
                                     parameters:params
                                     HTTPMethod:@"POST"
                              completionHandler:^(
                                                  FBRequestConnection *connection,
                                                  id result,
                                                  NSError *error
                                                  ) {
                                  /* handle the result */
                                  if (error) {
                                      // Case A: Error launching the dialog or sending request.
                                      NSLog(@"Error sending request.");
                                      
                                      [weakSelf showAlertWithTitle:@"Facebook" andMessage:error.localizedDescription];
                                      
                                  } else {
                                      
                                      [weakSelf showAlertWithTitle:@"Invitation sent!" andMessage:nil];
                                      
                                  }
                              }];
    }

}
#pragma mark - Utilities
- (void)showAlertWithTitle:(NSString*)title andMessage:(NSString*)message
{
    UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alertView show];
}

#pragma mark - IBActions
- (IBAction)didPressInviteFriends:(UIButton*)sender {
    
    _invitationType = sender.tag;
    switch (_invitationType) {
        case kFBInvitationTypeDialog:
            [self showInviteDialog];
            break;
        case kFBInvitationTypeRequest:
            [self presentFriendsPickerViewController];
            break;
    }
   
    
}


#pragma mark - <LoginViewControllerDelegate>
- (void)loginViewController:(LoginViewController *)controller didFinishLoginWithUser:(id<FBGraphUser>)user
{
    self.currentUser = user;
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)loginViewControllerUserDidCancelLogin:(LoginViewController *)controller
{
    NSString * message = @"Login cancelled, to continue you must login with facebook";
    
    UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:@"Facebook Login" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alertView show];
}

#pragma mark - <FBFriendPickerDelegate>
- (void)friendPickerViewControllerSelectionDidChange:(FBFriendPickerViewController *)friendPicker
{
    _friendsSelection = friendPicker.selection;
}

- (void)friendPickerViewController:(FBFriendPickerViewController *)friendPicker
                       handleError:(NSError *)error
{
    NSString * message = error.localizedDescription;
    
    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"Facebook" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    
    [alert show];
    
}
#pragma mark - <FBViewController>
/*!
 @abstract
 Called when the Cancel button is pressed on a modally-presented <FBViewController>.
 
 @param sender          The view controller sending the message.
 */
- (void)facebookViewControllerCancelWasPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

/*!
 @abstract
 Called when the Done button is pressed on a modally-presented <FBViewController>.
 
 @param sender          The view controller sending the message.
 */
- (void)facebookViewControllerDoneWasPressed:(id)sender
{
    if (_friendsSelection.count == 0) {
        
        NSString * message = @"Use must choose at least 1 friend";
        
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"Alert" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        
        [alert show];
        
    }else{
        
        NSArray * friendsIDs = [_friendsSelection valueForKey:@"objectID"];
        
        __weak ViewController * weakSelf = self;
        
        [self dismissViewControllerAnimated:YES completion:^{
            
               [weakSelf sendInviteRquestWithFriendsIDs:friendsIDs];
            
        }];
    }
}
@end
