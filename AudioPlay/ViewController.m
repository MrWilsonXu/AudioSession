//
//  ViewController.m
//  AudioPlay
//
//  Created by Wilson on 06/02/2018.
//  Copyright © 2018 Wilson. All rights reserved.
//

#import "ViewController.h"

#import "SystemPrivilegesTool.h"

#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, VoicePlayState){
    VoicePlayStateNone = 0,
    VoicePlayStateLoding = 1,
    VoicePlayStateReady = 2,
    VoicePlayStateBuffering = 3,
    VoicePlayStateBufferEnd = 4,
    VoicePlayStatePlaying = 5,
    VoicePlayStateSuspend = 6,
    VoicePlayStateStop = 7,
    VoicePlayStateFinish = 8,
    VoicePlayStateError = 9
};

@interface ViewController ()<AVAssetResourceLoaderDelegate>

/**
 *  Play tool
 */
@property (strong, nonatomic) AVPlayer *avPlayer;
@property (strong, nonatomic) id playerTimeObserver;

@property (assign, nonatomic) VoicePlayState playState;

@property (weak, nonatomic) IBOutlet UIProgressView *playProgress;
@property (weak, nonatomic) IBOutlet UIButton *playAction;
@property (weak, nonatomic) IBOutlet UILabel *progressLab;
@property (weak, nonatomic) IBOutlet UILabel *sessionType;

@end

#define AudioUrlStr @"http://resources.newgs.net/mp3/2017/09/04/21/1504530539175.mp3?OSSAccessKeyId=0qzfiBreffBeNSjN&Expires=1820126864&Signature=OC8IlmjChFaWtHi%2FyXvtD6TDIdU%3D"
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initAudioPlay];
    [self customAddNotification];
}

- (void)customAddNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioRouteChangeListenerCallback:)
                                                 name:AVAudioSessionRouteChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(otherAppAudioSessionCallBack:)
                                                 name:AVAudioSessionSilenceSecondaryAudioHintNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(systermAudioSessionCallBack:)
                                                 name:AVAudioSessionInterruptionNotification object:nil];
}

- (void)initAudioPlay {

    AVPlayerItem *playerItem  = [self creatAVPlayerItemWithUrlStr:AudioUrlStr];
    self.playState = VoicePlayStateLoding;
    
    if (self.avPlayer != nil && self.avPlayer.status == AVPlayerStatusReadyToPlay) {
        [self.avPlayer replaceCurrentItemWithPlayerItem:playerItem];
    } else {
        self.avPlayer = [AVPlayer playerWithPlayerItem:playerItem];
    }
    if (@available(iOS 10.0, *)) {
        self.avPlayer.automaticallyWaitsToMinimizeStalling = NO;
    }
    
    [self setSessionLabType:@"SoloAmbient"];
    [self addAudioProgressObserve];
}

- (AVPlayerItem *)creatAVPlayerItemWithUrlStr:(NSString *)urlStr {
    NSURL *url = [NSURL URLWithString:urlStr];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    return playerItem;
}

#pragma mark - Helper

/**
 *   Observe To Audio Player Progress
 */
- (void)addAudioProgressObserve {
    
    if (self.avPlayer) {
        AVPlayerItem *playerItem = self.avPlayer.currentItem;
        
        typeof(self) __weak weakSelf = self;
        self.playerTimeObserver = [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
                                        float current = CMTimeGetSeconds(time);
                                        float total = CMTimeGetSeconds([playerItem duration]);
                                        if (current) {
                                            float progressValue = current/total;
                                            [weakSelf setUIWithProgress:progressValue];
                                        }
                                        if (total - current < 1) {
                                            [weakSelf setAudioPlayComplete];
                                        }
                                    }];
    }
    
}

- (void)removeAudioProgressObserve {
    if (self.avPlayer && self.playerTimeObserver) {
        [self.avPlayer removeTimeObserver:self.playerTimeObserver];
        self.playerTimeObserver = nil;
    }
}

/**
 *  SetAVAudioSessionCategory
 */
- (void)setAVAudioSessionCategory:(NSString *)category
                          options:(AVAudioSessionCategoryOptions)options {
    NSError *error = nil;
    BOOL success = [[AVAudioSession sharedInstance] setCategory:category withOptions:options error:&error];
    
    if (!success) {
        NSLog(@"SetCategory error：%@ ",error.description);
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL ret = [audioSession setActive:YES error:&error];
    
    if (!ret) {
        NSLog(@"%s - activate audio session failed with error %@", __func__,[error description]);
    }
}

/**
 *  Show Progress On The Label
 */
- (void)setUIWithProgress:(float)progress {
    [self.playProgress setProgress:progress animated:YES];
    self.progressLab.text = [NSString stringWithFormat:@"%.1f%%",progress*100];
}

/**
 *  Complete Progress On The Label
 */
- (void)setAudioPlayComplete {
    [self.playProgress setProgress:0 animated:YES];
    self.progressLab.text = [NSString stringWithFormat:@"%d%%",0];
}

/**
 *  Show AudioSessionCategory On The Label
 */
- (void)setSessionLabType:(NSString *)type {
    self.sessionType.text = [NSString stringWithFormat:@"AudioSessionCategory：%@",type];
}

/**
 *  Show action text
 */
- (void)setPlayButtonText:(NSString *)text {
    [self.playAction setTitle:text forState:UIControlStateNormal];
}

#pragma mark - delegate
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    return YES;
}

#pragma mark - 监听 插／拔耳机

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    // AVAudioSessionRouteChangeReasonKey：change reason
    
    switch (routeChangeReason) {
            // new device available
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:{
            NSLog(@"headset input");
            break;
        }
            // device unavailable
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:{
            NSLog(@"pause play when headset output");
            [self.avPlayer pause];
            break;
        }
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
    }
}

#pragma mark - 监听音频系统中断响应

- (void)otherAppAudioSessionCallBack:(NSNotification *)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger interuptType = [[interuptionDict valueForKey:AVAudioSessionSilenceSecondaryAudioHintTypeKey] integerValue];
    
    switch (interuptType) {
        case AVAudioSessionSilenceSecondaryAudioHintTypeBegin:{
            [self.avPlayer pause];
            NSLog(@"pause play when other app occupied session");
            break;
        }
        case AVAudioSessionSilenceSecondaryAudioHintTypeEnd:{
            NSLog(@"occupied session");
            break;
        }
        default:
            break;
    }
}

// phone call or alarm
- (void)systermAudioSessionCallBack:(NSNotification *)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger interuptType = [[interuptionDict valueForKey:AVAudioSessionInterruptionTypeKey] integerValue];

    switch (interuptType) {
            // That interrupted the start, we should pause playback and collection
        case AVAudioSessionInterruptionTypeBegan:{
            [self.avPlayer pause];
            NSLog(@"pause play when phone call or alarm ");
            break;
        }
            // That interrupted the end, we can continue to play and capture
        case AVAudioSessionInterruptionTypeEnded:{
            break;
        }
        default:
            break;
    }
}

#pragma mark - Action

- (IBAction)playAudio:(UIButton *)sender {
    
    if (self.playState == VoicePlayStatePlaying) {
        [self.avPlayer pause];
        self.playState = VoicePlayStateSuspend;
        [self setPlayButtonText:@"Play"];
    } else if (self.playState == VoicePlayStateLoding) {
        [self.avPlayer play];
        self.playState = VoicePlayStatePlaying;
        [self setPlayButtonText:@"Pause"];
    } else if (self.playState == VoicePlayStateSuspend) {
        [self.avPlayer play];
        self.playState = VoicePlayStatePlaying;
        [self setPlayButtonText:@"Pause"];
    }
    
}

- (IBAction)resetPlayAudio:(UIButton *)sender {
    [self.avPlayer pause];
    self.playState = VoicePlayStateSuspend;
    [self setPlayButtonText:@"Play"];
    [self removeAudioProgressObserve];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setAudioPlayComplete];
    });
    
    AVPlayerItem *playerItem  = [self creatAVPlayerItemWithUrlStr:AudioUrlStr];
    if (self.avPlayer != nil && self.avPlayer.status == AVPlayerStatusReadyToPlay) {
        [self.avPlayer replaceCurrentItemWithPlayerItem:playerItem];
    } else {
        self.avPlayer = [AVPlayer playerWithPlayerItem:playerItem];
    }
    
    [self addAudioProgressObserve];
}


/**
 *  This category type continue play or record on background mode
 *  This category type interupt other app audio
 *  support multi audio export
 */
- (IBAction)MultiRoute:(UIButton *)sender {
    [self setAVAudioSessionCategory:AVAudioSessionCategoryMultiRoute options:AVAudioSessionCategoryOptionAllowBluetooth];
    [self setSessionLabType:@"MultiRoute"];
}

/**
 *  Default - AVAudioSessionCategorySoloAmbient
 *  This category type will mute for the following situations:
 1: lock screen
 2: turn on mute button
 3: background mode
 *  This category type will interupt other app audio !!!
 */
- (IBAction)SoloAmbient:(UIButton *)sender {
    [self setAVAudioSessionCategory:AVAudioSessionCategorySoloAmbient options:AVAudioSessionCategoryOptionMixWithOthers];
    [self setSessionLabType:@"SoloAmbient"];
}

/**
 *  This category type will mute for the following situations:
 1: lock screen
 2: turn on mute button
 3: background mode
 *  This category type not interupt other app audio !!!
 */
- (IBAction)Ambient:(UIButton *)sender {
    [self setAVAudioSessionCategory:AVAudioSessionCategoryAmbient options:AVAudioSessionCategoryOptionMixWithOthers];
    [self setSessionLabType:@"Ambient"];
}

/**
 *  This category type continue play on background mode
 *  This category type interupt other app audio
 */
- (IBAction)Playback:(UIButton *)sender {
    [self setAVAudioSessionCategory:AVAudioSessionCategoryPlayback options:AVAudioSessionCategoryOptionMixWithOthers];
    [self setSessionLabType:@"Playback"];
}

/**
 *  Record mode
 *  This category type will mute audio execpt for phone ring / alarm clock / calender remind etc.
 */
- (IBAction)Record:(UIButton *)sender {
    [self setAVAudioSessionCategory:AVAudioSessionCategoryRecord options:AVAudioSessionCategoryOptionMixWithOthers];
    [self setSessionLabType:@"Record"];
}

/**
 *  Handset mode
 *  This category type audio export is Handset by default
 */
- (IBAction)PlayAndRecord:(UIButton *)sender {
    [self setAVAudioSessionCategory:AVAudioSessionCategoryPlayAndRecord options:AVAudioSessionCategoryOptionMixWithOthers];
    [self setSessionLabType:@"PlayAndRecord"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
