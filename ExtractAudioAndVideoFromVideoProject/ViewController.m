//
//  ViewController.m
//  ExtractAudioAndVideoFromVideoProject
//
//  Created by feiniao on 2019/11/19.
//  Copyright © 2019 com.oc.shy. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "SVProgressHUD.h"

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
@property(nonatomic,strong)dispatch_queue_t mQueue;
@property(nonatomic,strong)AVAssetReader *mAssetReader;
@property(nonatomic,strong)AVAssetReaderOutput *mAssetReaderOutput;
@property(nonatomic,strong)AVAssetWriter *mAssetWrite;
@property(nonatomic,strong)AVAssetWriterInput *mAssetWriteInput;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.mQueue = dispatch_queue_create("com.feiniao.queue", DISPATCH_QUEUE_CONCURRENT);
    [self initPlayer];
    
}

- (void)initPlayer
{
    NSString *pathStr = [[NSBundle mainBundle]pathForResource:@"part2" ofType:@"mp4"];
    NSURL *url = [NSURL fileURLWithPath:pathStr];
    self.mAVURLAsset = [AVURLAsset assetWithURL:url];
    self.mPlayerItem = [AVPlayerItem playerItemWithAsset:self.mAVURLAsset];
    self.mAVPlayer = [AVPlayer playerWithPlayerItem:self.mPlayerItem];
    [self.mAVPlayer play];
    
    self.mPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.mAVPlayer];
    self.mPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    CGRect rect = CGRectMake(0.0f, 100, CGRectGetWidth(self.view.frame), 200);
    self.mPlayerLayer.frame = rect;
    [self.view.layer addSublayer:self.mPlayerLayer];
    
    rect.origin.y = CGRectGetMaxY(rect) + 50.0f;
    rect.size.height = 60;
    rect.size.width = CGRectGetWidth(self.view.frame);
    UIButton *extractAudioBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    extractAudioBtn.frame = rect;
    extractAudioBtn.backgroundColor = [UIColor redColor];
    [extractAudioBtn setTitle:@"提取音频" forState:UIControlStateNormal];
    [extractAudioBtn addTarget:self action:@selector(handleClick:) forControlEvents:UIControlEventTouchUpInside];
    extractAudioBtn.tag = ExtractVideoType_Audio;
    [self.view addSubview:extractAudioBtn];
    
    rect.origin.y = CGRectGetMaxY(rect)+20.0f;
    UIButton *extractVideoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    extractVideoBtn.frame = rect;
    extractVideoBtn.backgroundColor = [UIColor redColor];
    [extractVideoBtn setTitle:@"提取视频" forState:UIControlStateNormal];
    [extractVideoBtn addTarget:self action:@selector(handleClick:) forControlEvents:UIControlEventTouchUpInside];
    extractVideoBtn.tag = ExtractVideoType_Video;
    [self.view addSubview:extractVideoBtn];
    
}

- (void)handleClick:(UIButton *)pSender
{
    NSInteger tag = pSender.tag;
    if (tag == ExtractVideoType_Audio)
    {
        //提取音频
        
        [self extractAudioFile];
    }else if (tag == ExtractVideoType_Video)
    {
        //提取视频
        [self extractVideoFile];
    }
}

- (void)extractAudioFile
{
    NSLog(@"extractAudioFile");
    [SVProgressHUD show];
    NSError *error;
    self.mAssetReader = [AVAssetReader assetReaderWithAsset:self.mAVURLAsset error:&error];
    AVAssetTrack *track = [[self.mAVURLAsset tracksWithMediaType:AVMediaTypeAudio]firstObject];
    AudioChannelLayout acl;
    bzero(&acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    NSData *data = [NSData dataWithBytes:&acl length:sizeof(acl)];
    NSDictionary *readerDict = @{AVFormatIDKey:@(kAudioFormatLinearPCM),
                                 AVSampleRateKey:@(44100),
                                 AVNumberOfChannelsKey:@(2),
                                 AVLinearPCMBitDepthKey:@(16),
                                 AVLinearPCMIsBigEndianKey:@(false),
                                 AVLinearPCMIsFloatKey:@(false),
                                 AVLinearPCMIsNonInterleaved:@(false),
                                 AVChannelLayoutKey:data
                                 };
    
    self.mAssetReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:readerDict];
    if ([self.mAssetReader canAddOutput:self.mAssetReaderOutput])
    {
        [self.mAssetReader addOutput:self.mAssetReaderOutput];
    }
    
    //提高性能
    self.mAssetReaderOutput.alwaysCopiesSampleData = NO;
    
    NSString *outputPathStr = [NSHomeDirectory() stringByAppendingString:@"/Documents/output.m4a"];
    NSLog(@"outputPath:%@",outputPathStr);
    unlink([outputPathStr UTF8String]);
    NSURL *outPutUrl = [NSURL fileURLWithPath:outputPathStr];
    self.mAssetWrite = [AVAssetWriter assetWriterWithURL:outPutUrl fileType:AVFileTypeAppleM4A error:&error];
    
    NSDictionary *writeDict = @{AVFormatIDKey:@(kAudioFormatMPEG4AAC),
                                AVSampleRateKey:@(44100),
                                AVNumberOfChannelsKey:@(2),
                                AVEncoderBitRateKey:@(128000),
                                AVChannelLayoutKey:data
                                };
    self.mAssetWriteInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:writeDict];
    if ([self.mAssetWrite canAddInput:self.mAssetWriteInput])
    {
        [self.mAssetWrite addInput:self.mAssetWriteInput];
    }
    [self exportFile];
}

- (void)extractVideoFile
{
    NSError *error;
    self.mAssetReader = [AVAssetReader assetReaderWithAsset:self.mAVURLAsset error:&error];
    AVAssetTrack *assetTrack = [[self.mAVURLAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    NSDictionary *readerDict = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32ARGB)};
    self.mAssetReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetTrack outputSettings:readerDict];
    if ([self.mAssetReader canAddOutput:self.mAssetReaderOutput])
    {
        [self.mAssetReader addOutput:self.mAssetReaderOutput];
    }
    
    NSString *pathStr = [NSHomeDirectory() stringByAppendingString:@"/Documents/output.mp4"];
    NSLog(@"outputFile:%@",pathStr);
    unlink([pathStr UTF8String]);
    NSURL *url = [NSURL fileURLWithPath:pathStr];
    self.mAssetWrite = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:&error];
    CGSize naturalSize = assetTrack.naturalSize;
    NSDictionary *writeDict = @{AVVideoCodecKey:AVVideoCodecTypeH264,
                                AVVideoWidthKey:@(naturalSize.width),
                                AVVideoHeightKey:@(naturalSize.height)
                                };
    self.mAssetWriteInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:writeDict];
    if ([self.mAssetWrite canAddInput:self.mAssetWriteInput])
    {
        [self.mAssetWrite addInput:self.mAssetWriteInput];
    }
    [self exportFile];
    
}

- (void)exportFile
{
    [SVProgressHUD show];
    
    [self.mAssetReader startReading];
    [self.mAssetWrite startWriting];
    [self.mAssetWrite startSessionAtSourceTime:kCMTimeZero];
    
    [self.mAssetWriteInput requestMediaDataWhenReadyOnQueue:self.mQueue usingBlock:^{
        while (self.mAssetWriteInput.isReadyForMoreMediaData)
        {
            CMSampleBufferRef sampleBuffer = [self.mAssetReaderOutput copyNextSampleBuffer];
            if (sampleBuffer)
            {
                [self.mAssetWriteInput appendSampleBuffer:sampleBuffer];
                CMSampleBufferIsValid(sampleBuffer);
                CFRelease(sampleBuffer);
            }else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                });
                [self.mAssetWriteInput markAsFinished];
                [self.mAssetReader cancelReading];
                [self.mAssetWrite finishWritingWithCompletionHandler:^{
                    AVAssetWriterStatus status = self.mAssetWrite.status;
                    if (status == AVAssetWriterStatusCompleted)
                    {
                        NSLog(@"提取成功");
                    }else
                    {
                        NSLog(@"提取失败:%@",self.mAssetWrite.error);
                    }
                }];
                
                break;
            }
        }
    }];
}



@end
