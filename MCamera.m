//
//  MCamera.m
//  MCamera
//
//  Created by MotohiroNAKAMURA on 2014/10/03.
//  Copyright (c) 2014年 MotohiroNAKAMURA. All rights reserved.
//

#import "MCamera.h"


@implementation MCamera

// ==============================
// カメラ初期化処理
// ==============================
- (BOOL)start
{

    NSError *error = nil;
    
    // 入力と出力からキャプチャーセッションを作成
    self.session = [[AVCaptureSession alloc] init];
    
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
    
    // カメラからの入力を作成
    AVCaptureDevice *camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // カメラからの入力を作成し、セッションに追加
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
    [self.session addInput:self.videoInput];
    
    // 画像への出力を作成し、セッションに追加
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.session addOutput:self.videoDataOutput];
    
    // ビデオ出力のキャプチャの画像情報のキューを設定
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:TRUE];
    [self.videoDataOutput setSampleBufferDelegate:self queue:queue];
    
    // ビデオへの出力の画像は、BGRAで出力
    self.videoDataOutput.videoSettings = @{
                                           (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                           };
    
    [self.session startRunning];
    
    
    return YES;
}

// ==============================
// カメラ終了処理
// ==============================
- (BOOL)finish
{
    return YES;
}


// ==============================
// カメラ撮影処理
// ==============================

//
// 写真を撮影
//
// @return  撮影した画像
- (UIImage *)capture
{ 
    return self.previewImageView.image;
}


// ===============================
// フォーカス設定
// ===============================

//
// 指定した位置にフォーカスを合わせる
//
// @param (point)       フォーカスを合わせる位置
// @param (drawRect)    フォーカス位置に矩形を描画するか
// @return              レンズ位置(0.0~1.0)
- (float)focus:(CGPoint)point;
{
    
    [self beginConfiguration];
    
    // フォーカス設定がサポートされているか
    if ([self.videoInput.device isFocusPointOfInterestSupported] &&
        [self.videoInput.device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        
        // フォーカスする位置を設定
        self.videoInput.device.focusPointOfInterest =
        CGPointMake(point.y / self.previewImageView.bounds.size.height,
                    1.0 - point.x / self.previewImageView.bounds.size.width);
        self.videoInput.device.focusMode = AVCaptureFocusModeAutoFocus;
        
    }
    
    [self endConfiguration];
    
    return ([self isLaterVersion:8.0])? self.videoInput.device.lensPosition:0.0;

}

//
// 自動フォーカス設定
//
- (void)setAutoFocus
{
    if (![self beginConfiguration]) return ;
    
    // 自動フォーカスを設定
    self.videoInput.device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    
    [self endConfiguration];
}

//
// フォーカスを固定
//
- (void)lockFocus
{
    if (![self beginConfiguration]) return ;
        
    // フォーカスを固定
    [self.videoInput.device setFocusMode:AVCaptureFocusModeLocked];
    
    [self endConfiguration];
}

//
// レンズ位置を調整
//
// @param (position)    レンズ位置(0.0~1.0)
// @return              レンズ位置調整に対応しているか
- (BOOL)setLensePosition:(float)position
{
    // iOS8.0以前のバージョンには未対応
    float iOSVersion = [self iOSVersion];
    if(iOSVersion < 8.0)
        return NO;
    
    [self beginConfiguration];
    
    // レンズ位置を調整
    [self.videoInput.device setFocusModeLockedWithLensPosition:position completionHandler:nil];
    
    [self endConfiguration];
    
    return YES;
}

// ==============================
// ユーティリティ
// ==============================


//
// SampleBufferからUIImageを取得
//
// @param (SampleBuffer)    バッファに入った撮影した画像
// @return                  撮影した画像のUIImage
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // ピクセルバッファのベースアドレスをロックする
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get information of the image
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // RGBの色空間
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress,
                                                    width,
                                                    height,
                                                    8,
                                                    bytesPerRow,
                                                    colorSpace,
                                                    kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(newContext);
    
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];
    
    CGImageRelease(cgImage);
    
    return image;
}


//
// 設定開始前処理
//
// @return  処理成功か
- (BOOL)beginConfiguration
{
    NSError *error;
    if (![self.videoInput.device lockForConfiguration:&error]) {
        NSLog(@"error: %@", error);
        return NO;
    }
    [self.session beginConfiguration];
    
    return YES;
}

//
// 設定終了処理
//
- (void)endConfiguration
{
    [self.session commitConfiguration];
    [self.videoInput.device unlockForConfiguration];
}

//
// iOSのバージョンを取得
//
- (float)iOSVersion
{
    return [[[UIDevice currentDevice] systemVersion] floatValue];
}

//
// iOSのバージョンが指定したバージョンよりも後か
//
// @param (version) 確認するバージョン番号
// @return          指定したバージョンよりも後
- (BOOL)isLaterVersion:(float)version
{
    NSLog(@"current version: %f", [self iOSVersion]);
    return version <= [self iOSVersion];
}

// *******************************************************
//  AVCaptureVideoDataOutputSampleBufferDelegateのメソッド
// *******************************************************

// ==========================
// 画像をプレビューに表示
// ==========================
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // キャプチャしたフレームからCGImageを作成
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    
    // 画像を画面に表示
    dispatch_async(dispatch_get_main_queue(), ^{
        self.previewImageView.image = image;
    });
}


@end
