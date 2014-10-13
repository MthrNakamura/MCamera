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
#import <CoreMedia/CoreMedia.h>
#import <CoreGraphics/CoreGraphics.h>


//
// 設定項目
//
enum SettingType {
    PROP_FOCUS = 0,
    PROP_EXPOSURE,
    PROP_ISO,
    PROP_BIAS,
    NUM_PROP
};

//
// カメラパラメータ一覧
//
typedef struct setting {
    
    float exposure;     // 正規化露光時間
    float lense_pos;    // レンズ位置
    float iso;          // ISO値
    float bias;         // バイアス値
    
} CameraSetting;

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
- (BOOL)start:(UIImageView *)preview;
- (BOOL)finish;

// ==============================
// カメラの設定値
// ==============================
@property CameraSetting setting;

//
// カメラの設定値を取得
//
- (CameraSetting)cameraSetting;

//
// カメラの設定値を初期化
//
- (CameraSetting)initCameraSetting;


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
- (float)focusAt:(CGPoint)point;

//
// 自動フォーカス設定
//
- (void)setAutoFocus;

//
// 自動フォーカスモードか
//
// @return  自動フォーカスモードであるか
- (BOOL)isAutoFocus;

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

//
// レンズ位置を取得
//
// @return      レンズ位置(0.0~1.0)
- (float)lensePosition;

// ==============================
// 露光時間調整
// ==============================

#define EXPOSURE_DURATION_POWER 5
@property BOOL isAdjustingExposure;

//
// 露光時間を自動調整
//
- (void)setAutoExposure;

//
// 指定した位置に露光時間を自動調整
//
// @param (position)    露光時間を調整する位置
- (void)setExposureAt:(CGPoint)p;

//
// 自動露光時間調節モードか
//
// @return  自動調節モードである
- (BOOL)isAutoExposure;

//
// 露光時間を固定
//
- (void)lockExposure;


//
// 露光時間の設定が可能か
//
// @return  可能かどうか
- (BOOL)isCustomableExposureDuration;

//
// 露光時間を設定
//
// @param (duration)    設定する露光時間(0~1)
// @return              実際に設定された露光時間[ms]
- (float)setExposureDuration:(float)duration;

//
// 露光時間を取得
//
// @return  露光時間[ms]
- (float)exposureDuration;

//
// 現在の露光時間を0-1の範囲で取得
//
// @return  正規化された露光時間(0~1)
- (float)normalizedExposureDuration;


// ==============================
// ISO調整
// ==============================

//
// 調整可能かどうか
//
// @return  可能かどうか
- (BOOL)isCustomableISO;

//
// ISOを調整
//
// @param (isoValue)    設定するISO値
- (void)setISO:(float)isoValue;

//
// ISO値を取得
//
// @return      現在のISO値
- (float)ISO;

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
