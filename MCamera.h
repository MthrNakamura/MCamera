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
- (BOOL)start;
- (BOOL)finish;


// ==============================
// カメラ撮影処理
// ==============================

//
// 写真を撮影
//
// @return  撮影した画像
- (UIImage *)capture;


// ==============================
// フォーカス調整
// ==============================

//
// 指定した位置にフォーカスを合わせる
//
// @param (point)       フォーカスを合わせる位置
// @param (drawRect)    フォーカス位置に矩形を描画するか
- (float)focus:(CGPoint)point;

//
// 自動フォーカス設定
//
- (void)setAutoFocus;

//
// フォーカスを固定
//
- (void)lockFocus;

//
// レンズ位置を調整
//
// @param (position)    レンズ位置(0.0~1.0)
// @return              レンズ位置調整に対応しているか
- (BOOL)setLensePosition:(float)position;

// ==============================
// ユーティリティ
// ==============================

//
// SampleBufferからUIImageを取得
//
// @param (SampleBuffer)    バッファに入った撮影した画像
// @return                  撮影した画像のUIImage
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)SampleBuffer;

//
// 設定開始前処理
//
// @return  処理成功か
- (BOOL)beginConfiguration;

//
// 設定終了処理
//
- (void)endConfiguration;


//
// iOSのバージョンを取得
//
- (float)iOSVersion;

//
// iOSのバージョンが指定したバージョンよりも後か
//
// @param (version) 確認するバージョン番号
// @return          指定したバージョンよりも後
- (BOOL)isLaterVersion:(float)version;

@end
