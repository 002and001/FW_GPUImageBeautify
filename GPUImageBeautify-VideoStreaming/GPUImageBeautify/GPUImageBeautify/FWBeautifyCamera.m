//
//  FWBeautifyCamera.m
//  GPUImageBeautify
//
//  Created by Sunniwell on 16/9/28.
//  Copyright © 2016年 FunWay. All rights reserved.
//

#import "FWBeautifyCamera.h"
#import "FWGPUImageBeautifyFilter.h"
#import <sys/sysctl.h>

#define global_queue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

#define Get_CVPixelBufferRef_Directly 1

@interface FWBeautifyCamera () {
    int32_t _frameRate;
}
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) FWGPUImageBeautifyFilter *beautifyFilter;

@property (nonatomic, strong) GPUImageRawDataOutput *output;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, assign) float videoWidth;
@property (nonatomic, assign) float videoHeight;
@end

@implementation FWBeautifyCamera

#pragma mark - 初始化
- (instancetype)initWithSessionPreset:(NSString *)sessionPreset CameraPosition:(AVCaptureDevicePosition)cameraPositoin  andCameraView:(UIView *)cameraView {
    self = [super init];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:cameraView.frame];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [cameraView addSubview:self.imageView];
        
        self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:sessionPreset cameraPosition:cameraPositoin];
        self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
        self.videoCamera.frameRate = [self preferFrameRate];
        
        [self judgementSessionPreset];

        self.output = [[GPUImageRawDataOutput alloc] initWithImageSize:CGSizeMake(self.videoWidth, self.videoHeight) resultsInBGRAFormat:YES];
        
        [self setBeautifyFilter];
        
        [self.videoCamera startCameraCapture];
    }
    return self;
}

#pragma mark - 添加滤镜，实现美颜效果
- (void)setBeautifyFilter {
    [self.videoCamera removeAllTargets]; // 不可省略，否则屏幕会闪烁
    self.beautifyFilter = [[FWGPUImageBeautifyFilter alloc] init];
    [self.beautifyFilter addTarget:self.output];
    
    __weak typeof(self) weakSelf = self;
    [self.beautifyFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        [weakSelf videoStreamingWithBeauty:output];
    }];
    
    [self.videoCamera addTarget:self.beautifyFilter];
}

#pragma mark - 输出带有美颜效果的视频流
- (void)videoStreamingWithBeauty:(GPUImageOutput *)output {
    GPUImageFramebuffer *imageFramebuffer = output.framebufferForOutput;
    
    self.videoWidth = imageFramebuffer.size.width;
    self.videoHeight = imageFramebuffer.size.height;
    
    __weak typeof(self.output) weakOutput = self.output;
    __weak typeof(self) weakSelf = self;
    
#if Get_CVPixelBufferRef_Directly
    
    [self.output setNewFrameAvailableBlock:^{
        __strong GPUImageRawDataOutput *strongOutput = weakOutput;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongOutput lockFramebufferForReading];
        GLubyte *outputBytes = [strongOutput rawBytesForImage];
        NSInteger bytesPerRow = [strongOutput bytesPerRowInOutput];
        CVPixelBufferRef pixelBuffer = NULL;
        
        CVReturn ret = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, strongSelf.videoWidth, strongSelf.videoHeight, kCVPixelFormatType_32BGRA, outputBytes, bytesPerRow, nil, nil, nil, &pixelBuffer);
        if (ret != kCVReturnSuccess) {
            NSLog(@"status %d", ret);
        }
        if (pixelBuffer == NULL) {
            return;
        }

        [strongOutput unlockFramebufferAfterReading];
        
        if (pixelBuffer && [strongSelf.delegate respondsToSelector:@selector(onBeautifyCamera:andPixelBuffer:)]) {
            [strongSelf.delegate onBeautifyCamera:strongSelf andPixelBuffer:pixelBuffer];
        }
        
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, strongOutput.rawBytesForImage, bytesPerRow * strongSelf.videoWidth, NULL);
        
        CGImageRef cgImage = CGImageCreate(strongSelf.videoWidth, strongSelf.videoHeight, 8, 32, bytesPerRow, rgbColorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little, provider, NULL, true, kCGRenderingIntentDefault);
        
        UIImage *image = [[UIImage imageWithCGImage:cgImage] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [strongSelf updateWithImage:image];
        
        CGImageRelease(cgImage);
        CFRelease(pixelBuffer);
    }];
    
#else
    
    [self.output setNewFrameAvailableBlock:^{
        __strong GPUImageRawDataOutput *strongOutput = weakOutput;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongOutput lockFramebufferForReading];
        NSInteger bytesPerRow = [strongOutput bytesPerRowInOutput];
        
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, strongOutput.rawBytesForImage, bytesPerRow * strongSelf.videoWidth, NULL);
        
        CGImageRef cgImage = CGImageCreate(strongSelf.videoWidth, strongSelf.videoHeight, 8, 32, bytesPerRow, rgbColorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little, provider, NULL, true, kCGRenderingIntentDefault);
        
        CVPixelBufferRef pixelBuffer = NULL;
        if (cgImage) {
            pixelBuffer = [strongSelf pixelBufferFromCGImage:cgImage];
        }
        
        if (pixelBuffer && [strongSelf.delegate respondsToSelector:@selector(onBeautifyCamera:andPixelBuffer:)]) {
            [strongSelf.delegate onBeautifyCamera:strongSelf andPixelBuffer:pixelBuffer];
        }
        
        UIImage *image = [[UIImage imageWithCGImage:cgImage] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [strongSelf updateWithImage:image];
        
        if (pixelBuffer) {
            CFRelease(pixelBuffer);
        }
        
        CGImageRelease(cgImage);
    }];

#endif
}

- (void)updateWithImage:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = image;
    });
}

#pragma mark 根据CGImageRef对象返回CVPixelBufferRef
- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image {
    NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey, [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    CVPixelBufferRef pixelBuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);
    
    CVReturn ret = CVPixelBufferCreate(kCFAllocatorDefault, frameWidth, frameHeight, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)option, &pixelBuffer);
    NSParameterAssert(ret == kCVReturnSuccess && pixelBuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *pixelData = CVPixelBufferGetBaseAddress(pixelBuffer);
    NSParameterAssert(pixelData != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pixelData, frameWidth, frameHeight, 8, CVPixelBufferGetBytesPerRow(pixelBuffer), rgbColorSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0, 0, frameWidth, frameWidth), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}


#pragma mark - 判断机型，设置 preferFrameRate
- (int32_t)frameRate {
    if (_frameRate == 0) {
        _frameRate = [self platformFrameRate];
    }
    return _frameRate;
}

- (int32_t )platformFrameRate {
    NSString* phoneModel = [[UIDevice currentDevice] model];
    // iPhone 以外的设备，设置为 15
    if ([phoneModel rangeOfString:@"iPhone"].length <= 0) {
        return 15;
    }
    
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    
    // iPhone 5s 以下设置为 20，以上设置为 30
    if ([platform isEqualToString:@"iPhone1,1"]     // iPhone 2G (A1203)
        || [platform isEqualToString:@"iPhone1,2"]  // iPhone 3G (A1241/A1324)
        || [platform isEqualToString:@"iPhone2,1"]  // iPhone 3GS (A1303/A1325)
        || [platform isEqualToString:@"iPhone3,1"]  // iPhone 4 (A1332)
        || [platform isEqualToString:@"iPhone3,2"]  // iPhone 4 (A1332)
        || [platform isEqualToString:@"iPhone3,3"]  // iPhone 4 (A1349)
        || [platform isEqualToString:@"iPhone4,1"]  // iPhone 4S (A1387/A1431)
        || [platform isEqualToString:@"iPhone5,1"]  // iPhone 5 (A1428)
        || [platform isEqualToString:@"iPhone5,2"]  // iPhone 5 (A1429/A1442)
        || [platform isEqualToString:@"iPhone5,3"]  // iPhone 5c (A1456/A1532)
        || [platform isEqualToString:@"iPhone5,4"]) // iPhone 5c (A1507/A1516/A1526/A1529)
        return 20;
    else
        return 30;
}

#pragma mark
- (void)judgementSessionPreset {
    if (self.videoCamera.captureSessionPreset == AVCaptureSessionPreset352x288) {
        self.videoWidth = 288;
        self.videoHeight = 352;
    } else if (self.videoCamera.captureSessionPreset == AVCaptureSessionPreset640x480) {
        self.videoHeight = 640;
        self.videoWidth = 480;
    } else if (self.videoCamera.captureSessionPreset== AVCaptureSessionPreset1280x720) {
        self.videoWidth = 720;
        self.videoHeight = 1280;
    } else if (self.videoCamera.captureSessionPreset == AVCaptureSessionPreset1920x1080) {
        self.videoHeight = 1920;
        self.videoWidth = 1080;
    } else if (self.videoCamera.captureSessionPreset == AVCaptureSessionPreset3840x2160) {
        self.videoWidth = 2160;
        self.videoHeight = 3840;
    } else {
        self.videoHeight = 640;
        self.videoWidth = 480;
    }
}

#pragma mark - 重写属性 Setter 方法
#pragma mark 设置镜头分辨率
- (void)setSessionPreset:(NSString *)sessionPreset {
    self.videoCamera.captureSessionPreset = sessionPreset;
}

#pragma mark 设置磨皮程度
- (void)setIntensity:(CGFloat)intensity {
    self.beautifyFilter.intensity = intensity;
}

#pragma mark 设置帧数
- (void)setPreferFrameRate:(int32_t)preferFrameRate {
    self.videoCamera.frameRate = preferFrameRate;
}

#pragma mark 设置亮度
- (void)setBrightness:(float)brightness {
    self.beautifyFilter.brightness = brightness;
}

#pragma mark 设置饱和度
- (void)setSaturation:(float)saturation {
    self.beautifyFilter.saturation = saturation;
}

#pragma mark - 开关美颜效果
- (void)switchBeauty:(BOOL)isOn {
    if (isOn) {
        [self.videoCamera removeAllTargets];
        [self.beautifyFilter addTarget:self.output];
        [self.videoCamera addTarget:self.beautifyFilter];
    } else {
        [self.videoCamera removeAllTargets];
        [self.videoCamera addTarget:self.output];
    }
}

#pragma mark - 切换前后置摄像头
- (void)toggleCamera {
    dispatch_async(global_queue, ^{
        [self.videoCamera rotateCamera];
    });
}

#pragma mark - 开始直播
- (void)startRunning {
    dispatch_async(global_queue, ^{
        [self.beautifyFilter addTarget:self.output];
        [self.videoCamera startCameraCapture];
    });
}

#pragma mark - 停止直播
- (void)stopRunning {
    dispatch_async(global_queue, ^{
        [self.videoCamera stopCameraCapture];
    });
}

#pragma mark - 销毁对象
- (void)destory {    
    self.beautifyFilter = nil;
    self.videoCamera = nil;
    self.imageView = nil;
}

@end
