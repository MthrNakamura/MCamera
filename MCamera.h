//
//  MCamera.h
//  MCamera
//
//  Created by MotohiroNAKAMURA on 2014/10/03.
//  Copyright (c) 2014年 MotohiroNAKAMURA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>
#import <CoreGraphics/CoreGraphics.h>

@interface MCamera : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>

// ******************************
// ビデオ入出力
// ******************************
@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOutput;

// ******************************
// 撮影セッション
// ******************************
@property (strong, nonatomic) AVCaptureSession *session;

// ******************************
// 画像のプレビューレイヤー
// ******************************
@property (strong, nonatomic) UIImageView *previewImageView;


// ==============================
// カメラ初期化・終了処理
// ==============================
- (BOOL)setup;
- (BOOL)finish;


// ==============================
// カメラ撮影処理
// ==============================
- (UIImage *)capture;

// ==============================
// ユーティリティ
// ==============================
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)SampleBuffer;

@end
