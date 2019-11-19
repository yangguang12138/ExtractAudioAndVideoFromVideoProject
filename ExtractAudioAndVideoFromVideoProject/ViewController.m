//
//  ViewController.m
//  ExtractAudioAndVideoFromVideoProject
//
//  Created by feiniao on 2019/11/19.
//  Copyright © 2019 com.oc.shy. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

NS_ENUM(NSInteger,ExtractVideoType)
{
    ExtractVideoType_Audio = 100,//提取音频
    ExtractVideoType_Video,//提取视频
};

@interface ViewController ()

@property(nonatomic,strong)AVPlayer *mAVPlayer;
@property(nonatomic,strong)AVPlayerItem *mPlayerItem;
@property(nonatomic,strong)AVPlayerLayer *mPlayerLayer;
@property(nonatomic,strong)AVURLAsset *mAVURLAsset;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initPlayer];
    通过AVAssetReader和AVAssetWriter提取视频中的音频和视频文件
    AVAssetReader *assetReader;
    AVAssetWriter *assetWriter;
}

- (void)initPlayer
{
    NSString *pathStr = [[NSBundle mainBundle]pathForResource:@"part2" ofType:@"mp4"];
    NSURL *url = [NSURL fileURLWithPath:pathStr];
    self.mAVURLAsset = [AVURLAsset assetWithURL:url];
    self.mPlayerItem = [AVPlayerItem playerItemWithAsset:self.mAVURLAsset];
    self.mAVPlayer = [AVPlayer playerWithPlayerItem:self.mPlayerItem];
    
    self.mPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.mAVPlayer];
    self.mPlayerLayer.frame = CGRectMake(0.0f, 100, CGRectGetWidth(self.view.frame), 200);
    [self.view.layer addSublayer:self.mPlayerLayer];
    self.mAVPlayer
    
}

- (void)handleClick:(UIButton *)pSender
{
    NSInteger tag = pSender.tag;
    if (tag == ExtractVideoType_Audio)
    {
        //提取音频
    }else if (tag == ExtractVideoType_Video)
    {
        //提取视频
    }
}


@end
