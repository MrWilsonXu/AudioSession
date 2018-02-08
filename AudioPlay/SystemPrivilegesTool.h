//
//  SystemPrivilegesTool.h
//  NewGS
//
//  Created by Wilson on 2017/3/29.
//  Copyright © 2017年 cnmobi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^AuthorizationSuccess) (NSString *successMsg);
typedef void (^AuthorizationFailure) (NSString *failureMsg, NSURL *url);

@interface SystemPrivilegesTool : NSObject

/**
 *  Microphone
 */
+ (void)getMicrophoneAuthorizationSuccess:(AuthorizationSuccess)success failure:(AuthorizationFailure)failure;

/**
 *  Camera
 */
+ (void)getCameraAuthorizationSuccess:(AuthorizationSuccess)success failure:(AuthorizationFailure)failure;

/**
 *  Photograph album
 */
+ (void)getPhotoAlbumAuthorizationSuccess:(AuthorizationSuccess)success failure:(AuthorizationFailure)failure;

@end
