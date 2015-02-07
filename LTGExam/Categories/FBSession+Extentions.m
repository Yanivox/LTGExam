//
//  FBSession+Extentions.m
//  LTGExam
//
//  Created by Yaniv Marshaly on 2/5/15.
//  Copyright (c) 2015 Yaniv Marshaly. All rights reserved.
//

#import "FBSession+Extentions.h"

@implementation FBSession (Extentions)

+(BOOL)isSessionOpen
{
    if (!FBSession.activeSession.isOpen && FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        // even though we had a cached token, we need to login to make the session usable
        [FBSession.activeSession openWithCompletionHandler:^(FBSession *session,
                                                             FBSessionState status,
                                                             NSError *error) {
            // we recurse here, in order to update buttons and labels
            [FBSession setActiveSession:session];
            
            
        }];
    }
    
    return FBSession.activeSession.isOpen;
}

@end
