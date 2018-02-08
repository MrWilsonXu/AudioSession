//
//  SystemPrivilegesTool.m
//  NewGS
//
//  Created by Wilson on 2017/3/29.
//  Copyright © 2017年 cnmobi. All rights reserved.
//

#import "SystemPrivilegesTool.h"

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVCaptureDevice.h>

@implementation SystemPrivilegesTool

+ (void)getMicrophoneAuthorizationSuccess:(AuthorizationSuccess)success failure:(AuthorizationFailure)failure {
    NSString *mediaType = AVMediaTypeAudio;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    NSURL * url = [self appSettingUrl];
    
    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        if (success) {
                            success(@"Have Permission");
                        }
                    } else {
                        if (failure) {
                            failure([self promptMsgWithTypeStr:@"Microphone"], url);
                        }
                    }
                });
            }];
        }
            break;
        case AVAuthorizationStatusDenied:{
            if (failure) {
                
                failure([self promptMsgWithTypeStr:@"Microphone"],url);
            }
        }
            break;
        case AVAuthorizationStatusAuthorized:
            if (success) {
                success(@"Have Permission");
            }
        default:
            break;
    }
}

+ (void)getCameraAuthorizationSuccess:(AuthorizationSuccess)success failure:(AuthorizationFailure)failure {
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    NSURL * url = [self appSettingUrl];
    
    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (granted) {
                        if (success) {
                            success(@"Have Permission");
                        }
                    } else {
                        if (failure) {
                            failure([self promptMsgWithTypeStr:@"Camera"], url);
                        }
                    }
                });
            }];
        }
            break;
        case AVAuthorizationStatusDenied:{
            if (failure) {
                NSString *msg = [self promptMsgWithTypeStr:@"Camera"];
                failure(msg,url);
            }
        }
            break;
        case AVAuthorizationStatusAuthorized:
            if (success) {
                success(@"Have Permission");
            }
        default:
            break;
    }
}

+ (void)getPhotoAlbumAuthorizationSuccess:(AuthorizationSuccess)success failure:(AuthorizationFailure)failure {
    ALAuthorizationStatus author =[ALAssetsLibrary authorizationStatus];
    NSURL * url = [self appSettingUrl];
    
    if (author == ALAuthorizationStatusNotDetermined) {
        if (success) {
            success(@"None Setting");
        }
    } else if (author == AVAuthorizationStatusDenied || author == ALAuthorizationStatusRestricted) {
        if (failure) {
            failure([self promptMsgWithTypeStr:@"Photo Album"],url);
        }
    } else if (author == AVAuthorizationStatusAuthorized) {
        if (success) {
            success(@"Have Permission");
        }
    };
}

+ (NSURL *)appSettingUrl {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    return url;
}

+ (NSString *)promptMsgWithTypeStr:(NSString *)typeStr {
    NSString *msg = [NSString stringWithFormat:@"Please find iPhone\"General-%@-%@\"item，allow %@ access to your %@",[[NSBundle mainBundle]infoDictionary][@"CFBundleDisplayName"],typeStr,[[NSBundle mainBundle]infoDictionary][@"CFBundleDisplayName"],typeStr];
    return msg;
}

@end
