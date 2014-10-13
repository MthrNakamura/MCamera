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
- (BOOL)start:(UIImageView *)preview
{

    NSError *error = nil;
    
    // カメラ設定を初期化
    self.setting = [self initCameraSetting];
    
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
    
    // プレビューを設定
    self.previewImageView = preview;
    
    // 露光時間調整フラグを初期化
    self.isAdjustingExposure = NO;
    
    // セッション開始
    [self.session startRunning];
    
    
    return YES;
}

// ==============================
// カメラ終了処理
// ==============================
- (BOOL)finish
{
    [self.session stopRunning];
    return YES;
}

// ==============================
// カメラの設定値を一括取得
// ==============================

//
// カメラ設定を取得
//
- (CameraSetting)cameraSetting
{
    CameraSetting setting = self.setting;
    
    // フォーカス
    setting.lense_pos = [self lensePosition];
    
    // 露光時間
    setting.exposure = [self normalizedExposureDuration];
    
    // ISO
    setting.iso = [self ISO];
    
    // バイアス
    setting.bias = 0.0;
    
    return setting;
}

//
// カメラの設定値を初期化
//
- (CameraSetting)initCameraSetting
{
    CameraSetting setting;
    
    // 設定値を取得
    setting = [self cameraSetting];
    
    return setting;
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
- (float)focusAt:(CGPoint)point;
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
// 自動フォーカスモードか
//
// @return  自動フォーカスモードであるか
- (BOOL)isAutoFocus
{
    return (self.videoInput.device.focusMode == AVCaptureFocusModeContinuousAutoFocus);
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
    if(![self isLaterVersion:8.0])
        return NO;
    
    [self beginConfiguration];
    
    // レンズ位置を調整
    [self.videoInput.device setFocusModeLockedWithLensPosition:position completionHandler:nil];
    
    [self endConfiguration];
    
    return YES;
}


//
// レンズ位置を取得
//
// @return      レンズ位置(0.0~1.0)
- (float)lensePosition
{
    return ([self isLaterVersion:8.0])? self.videoInput.device.lensPosition:0.0;
}


// ==============================
// 露光時間調整
// ==============================


//
// 露光時間を自動調整
//
- (void)setAutoExposure
{
    [self beginConfiguration];
    [self.videoInput.device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
    [self endConfiguration];
}

//
// 自動露光時間調節モードか
//
// @return  自動調節モードである
- (BOOL)isAutoExposure
{
    return (self.videoInput.device.exposureMode == AVCaptureExposureModeContinuousAutoExposure);
}

//
// 露光時間を固定
//
- (void)lockExposure
{
    [self beginConfiguration];
    [self.videoInput.device setExposureMode:AVCaptureExposureModeLocked];
    [self endConfiguration];
}

//
// 指定した位置に露光時間を自動調整
//
// @param (position)    露光時間を調整する位置
- (void)setExposureAt:(CGPoint)p
{
    [self beginConfiguration];
    
    if ([self.videoInput.device isExposurePointOfInterestSupported] &&
        [self.videoInput.device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        
        self.isAdjustingExposure = YES;
        [self.videoInput.device addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:nil];
        
        self.videoInput.device.exposurePointOfInterest = p;
        self.videoInput.device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        
    }
    [self endConfiguration];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (![keyPath isEqual:@"adjustingExposure"])
        return ;
    
    if (!self.isAdjustingExposure)
        return ;
    
    if ([keyPath isEqualToString:@"adjustingExposure"] &&
        [[change objectForKey:NSKeyValueChangeNewKey]boolValue]==NO) {
        
        self.isAdjustingExposure = NO;
        
        [self beginConfiguration];
        
        AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        [captureDevice setExposureMode:AVCaptureExposureModeLocked];
        
        [self endConfiguration];
        
    }
}

//
// 露光時間の設定が可能か
//
// @return  可能かどうか
- (BOOL)isCustomableExposureDuration
{
    return [self isLaterVersion:8.0];
}

//
// 露光時間を調整
//
// @param (duration)    設定する露光時間(0~1)
// @return              実際に設定された露光時間[ms]
- (float)setExposureDuration:(float)duration
{
    
    if (![self isLaterVersion:8.0])
        return [self exposureDuration];
    
    [self beginConfiguration];
    
    // 露光時間モードを変更
    self.videoInput.device.exposureMode = AVCaptureExposureModeCustom;
    
    // 露光時間を設定
    {
        duration = powf(duration, EXPOSURE_DURATION_POWER);
        float minDurationSeconds = MAX(CMTimeGetSeconds(self.videoInput.device.activeFormat.minExposureDuration), 1.0/1000);
        float maxDurationSeconds = CMTimeGetSeconds(self.videoInput.device.activeFormat.maxExposureDuration);
        float newDurationSeconds = duration * (maxDurationSeconds - minDurationSeconds) + minDurationSeconds;
    
        [self.videoInput.device setExposureModeCustomWithDuration:CMTimeMakeWithSeconds(newDurationSeconds, 1000*1000*1000)
                                                              ISO:AVCaptureISOCurrent completionHandler:nil];
    }
        
    [self endConfiguration];

    return [self exposureDuration];
}

//
// 露光時間を取得
//
// @return  露光時間[ms]
- (float)exposureDuration
{
    return CMTimeGetSeconds([self.videoInput.device exposureDuration])*1000.0;
}

//
// 現在の露光時間を0-1の範囲で取得
//
// @return  正規化された露光時間(0~1)
- (float)normalizedExposureDuration
{
    float minDuration = MAX(CMTimeGetSeconds(self.videoInput.device.activeFormat.minExposureDuration), 1.0/1000);
    float maxDuration = CMTimeGetSeconds(self.videoInput.device.activeFormat.maxExposureDuration);
    float currentDuration = [self exposureDuration] / 1000.0;
    
    return pow((currentDuration - minDuration) / (maxDuration - minDuration), 1.0f/EXPOSURE_DURATION_POWER);
}


// ==============================
// ISO調整
// ==============================

//
// 調整可能かどうか
//
// @return  可能かどうか
- (BOOL)isCustomableISO
{
    return [self isLaterVersion:8.0];
}

//
// ISOを調整
//
// @param (isoValue)    設定するISO値(0~1)
- (void)setISO:(float)isoValue
{
    if (![self isLaterVersion:8.0]) {
        NSLog(@"current ios version(%f) is not supported", [self iOSVersion]);
        return;
    }
    
    [self beginConfiguration];
    
    [self.videoInput.device setExposureMode:AVCaptureExposureModeCustom];
    
    // ISO値を設定
    isoValue = powf(isoValue, EXPOSURE_DURATION_POWER);
    float maxISO = self.videoInput.device.activeFormat.maxISO;
    float minISO = self.videoInput.device.activeFormat.minISO;
    isoValue = (maxISO - minISO) * isoValue + minISO;
    [self.videoInput.device setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:isoValue completionHandler:nil];
    
    [self endConfiguration];
}

//
// ISO値を取得
//
// @return      現在のISO値
- (float)ISO
{
    float iso = self.videoInput.device.ISO;
    float maxISO = self.videoInput.device.activeFormat.maxISO;
    float minISO = self.videoInput.device.activeFormat.minISO;
    return (iso - minISO) / (maxISO - minISO);
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
