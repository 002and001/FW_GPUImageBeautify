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

@interface FWBeautifyCamera () {
    int32_t frameRate;
}
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong) FWGPUImageBeautifyFilter *beautifyFilter;
@end

@implementation FWBeautifyCamera

#pragma mark - 初始化
- (instancetype)initWithSessionPreset:(NSString *)sessionPreset CameraPosition:(AVCaptureDevicePosition)cameraPositoin outputImageOrientation:(UIInterfaceOrientation)outputImageOrientation andCameraView:(UIView *)cameraView {
    self = [super init];
    if (self) {
        self.cameraView = cameraView;
        self.sessionPreset = sessionPreset;
        
        self.filterView = [[GPUImageView alloc] initWithFrame:cameraView.frame];
        self.filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
        self.filterView.center = cameraView.center;
        [cameraView addSubview:self.filterView];
        
        self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:sessionPreset cameraPosition:cameraPositoin];
        self.videoCamera.outputImageOrientation = outputImageOrientation;
        self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
        self.videoCamera.horizontallyMirrorRearFacingCamera = NO;
        self.videoCamera.frameRate = [self platformFrameRate]; // 根据根据机型设定默认的frameRate;
        [self.videoCamera removeAllTargets];
        [self.videoCamera addTarget:self.filterView];
        
        [self setBeautifyFilter];
        
        [self.videoCamera startCameraCapture];
}
    return self;
}

#pragma mark - 添加滤镜，实现美颜效果
- (void)setBeautifyFilter {
    [self.videoCamera removeAllTargets]; // 不可省略，否则屏幕会闪烁
    self.beautifyFilter = [[FWGPUImageBeautifyFilter alloc] init];
    [self.beautifyFilter addTarget:self.filterView];
    
    __weak typeof(self) weakSelf = self;
    [self.beautifyFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        [weakSelf processVideo:output];
    }];
    
    [self.videoCamera addTarget:self.beautifyFilter];
}

// 转换 CVPixelBufferRef 对象
- (void)processVideo:(GPUImageOutput *)output {
    __weak typeof(self) weakSelf = self;
    @autoreleasepool {
        GPUImageFramebuffer *imageFramebuffer = output.framebufferForOutput;
        
        CGFloat width = ceil(imageFramebuffer.size.width / 16) * 16; // 必须被 16 整除
        CGFloat height = imageFramebuffer.size.height;
        
        CVPixelBufferRef pixelBuffer = NULL;
        CVReturn ret = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, [imageFramebuffer byteBuffer], width * 4, nil, NULL, NULL, &pixelBuffer);
        NSParameterAssert(ret == kCVReturnSuccess && pixelBuffer != NULL);
        
        if(pixelBuffer && weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(onBeautifyCamera:andPixelBuffer:)]){
            [weakSelf.delegate onBeautifyCamera:weakSelf andPixelBuffer:pixelBuffer];
        }
        
        CVPixelBufferRelease(pixelBuffer);
    }
}

#pragma mark - 判断机型，设置 preferFrameRate
- (int32_t)frameRate {
    if (frameRate == 0) {
        frameRate = [self platformFrameRate];
    }
    return frameRate;
}

- (int32_t )platformFrameRate {
    NSString *phoneModel = [[UIDevice currentDevice] model];
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

#pragma mark - 重写属性 Setter 方法
#pragma mark 设置镜头分辨率
- (void)setSessionPreset:(NSString *)sessionPreset {
    self.videoCamera.captureSessionPreset = sessionPreset;
}

#pragma mark 设置帧数
- (void)setPreferFrameRate:(int32_t)preferFrameRate {
    self.videoCamera.frameRate = preferFrameRate;
}

#pragma mark 设置磨皮程度
- (void)setIntensity:(CGFloat)intensity {
    self.beautifyFilter.intensity = intensity;
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
        [self.videoCamera addTarget:self.beautifyFilter];
    } else {
        [self.videoCamera removeAllTargets];
        [self.videoCamera addTarget:self.filterView];
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
    self.filterView = nil;
    self.beautifyFilter = nil;
    self.videoCamera = nil;
}

@end
