//
//  FWBeautifyCamera.h
//  GPUImageBeautify
//
//  Created by Sunniwell on 16/9/28.
//  Copyright © 2016年 FunWay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class FWBeautifyCamera;
@protocol FWBeautifyCameraDelegate <NSObject>

@optional

/**
 经过处理的帧数据

 @param camera      FWBeautifyCamera
 @param pixelBuffer CVPixelBufferRef对象
 */
- (void)onBeautifyCamera:(FWBeautifyCamera *)camera andPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

@interface FWBeautifyCamera : NSObject

/** FWBeautifyCameraDelegate 代理对象 */
@property (nonatomic, weak) id<FWBeautifyCameraDelegate> delegate;

/** 相机容器视图 */
@property (nonatomic) UIView *cameraView;

/** 改变此值可以修改摄像头分辨率 */
@property (nonatomic, copy) NSString *sessionPreset;

/** 改变此值可以改变画面的帧数 */
@property (nonatomic, assign) int32_t preferFrameRate; // 默认值根据机型设定 iPad类产品 ：15   iPhone5及之前产品 ：20   iPhone5s及之后产品 ：30

/** 改变此值可以改变磨皮的效果, [0, 1] */
@property (nonatomic, assign) CGFloat intensity; // 默认为 0.5,

/** 改变此值可以改变画面的亮度， [0, 2] */
@property (nonatomic, assign) float brightness; // 默认为 1.0

/** 改变此值可以改变画面的饱和度， [0, 2] */
@property (nonatomic, assign) float saturation; // 默认为 1.0

/**
 初始化放方法

 @param sessionPreset  分辨率
 @param cameraPositoin 摄像头方向
 @param cameraView     相机视图
 */
- (instancetype)initWithSessionPreset:(NSString *)sessionPreset CameraPosition:(AVCaptureDevicePosition)cameraPositoin andCameraView:(UIView *)cameraView;

/** 可以通过此方法开关美颜效果 */
- (void)switchBeauty:(BOOL)isOn;

/** 通过此方法，可以切换前后置摄像头 */
- (void)toggleCamera;

/** 开始直播 */
- (void)startRunning;

/** 停止直播 */
- (void)stopRunning;

/** 销毁对象 */
- (void)destory;

@end
