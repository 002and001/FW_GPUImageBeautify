//
//  ViewController.m
//  GPUImageBeautify
//
//  Created by Administrator on 16/9/23.
//  Copyright © 2016年 FunWay. All rights reserved.
//

#import "FWViewController.h"
#import "FWBeautifyCamera.h"

#import <Masonry.h>

@interface FWViewController ()<FWBeautifyCameraDelegate> {
    UILabel *_intensityLabel;
}
@property (nonatomic, strong) FWBeautifyCamera *beautifyCamera;
@end

@implementation FWViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.beautifyCamera = [[FWBeautifyCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 CameraPosition:AVCaptureDevicePositionFront andCameraView:self.view];
    self.beautifyCamera.delegate = self;
    
    // 设置分辨率
//    self.beautifyCamera.sessionPreset = AVCaptureSessionPresetHigh;
    
    // 设置帧数
//    self.beautifyCamera.preferFrameRate = 60;

    // 设置磨皮程度
//    self.beautifyCamera.intensity = 0.65;
    
    // 设置亮度（即美白效果）
//    self.beautifyCamera.brightness = 1.1f;
    
    // 设置饱和度
//    self.beautifyCamera.saturation = 1.1f;

    [self createUI];
}

#pragma mark - 创建UI
- (void)createUI {
    // 切换是否使用美颜功能的开关
    UISwitch *beautifySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(50, 50, 32, 16)];
    beautifySwitch.on = YES;
    [beautifySwitch addTarget:self action:@selector(beautifyOrNot:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:beautifySwitch];
    [beautifySwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.view).offset(-32);
        make.top.equalTo(self.view).offset(32);
        make.width.equalTo(@32);
        make.height.equalTo(@16);
    }];
    
    // 转换前后置摄像头的按钮
    UIButton *toggleCameraButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [toggleCameraButton setTitle:@"前置" forState:UIControlStateSelected];
    [toggleCameraButton setTitle:@"后置" forState:UIControlStateNormal];
    toggleCameraButton.selected = YES;
    toggleCameraButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [toggleCameraButton addTarget:self action:@selector(toggleCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:toggleCameraButton];
    [toggleCameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(32);
        make.leading.equalTo(self.view).offset(16);
        make.width.equalTo(@48);
        make.height.equalTo(@32);
    }];
    
    // 调节 intensity 的滑块，即磨皮程度
    UISlider *intensitySlider = [[UISlider alloc] initWithFrame:self.view.frame];
    intensitySlider.maximumValue = 1.0f;
    intensitySlider.minimumValue = 0.0f;
    intensitySlider.value = 0.5f;
    [intensitySlider addTarget:self action:@selector(intensityValueChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:intensitySlider];
    [intensitySlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-32);
        make.leading.equalTo(self.view).offset(16);
        make.trailing.equalTo(self.view).offset(-16);
    }];
    
    _intensityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 36)];
    _intensityLabel.textColor = [UIColor darkGrayColor];
    _intensityLabel.font = [UIFont boldSystemFontOfSize:24];
    _intensityLabel.text = @"0.50";
    _intensityLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_intensityLabel];
    [_intensityLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(intensitySlider).offset(-32);
        make.centerX.equalTo(intensitySlider);
        make.width.equalTo(@64);
        make.height.equalTo(@32);
    }];
    
    UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:@[@"开始", @"停止"]];
    segmentControl.frame = CGRectMake(0, 0, 30, CGRectGetWidth(self.view.frame));
    segmentControl.selectedSegmentIndex = 0;
    [segmentControl addTarget:self action:@selector(segmentValueChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:segmentControl];
    [segmentControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(32);
        make.centerX.equalTo(intensitySlider);
        make.width.equalTo(@128);
    }];
}

#pragma mark - Action
#pragma mark 切换前后置摄像头
- (void)toggleCamera:(UIButton *)uiButton {
    if (uiButton.isSelected) {
        uiButton.selected = NO;
        [self.beautifyCamera toggleCamera];
    } else {
        uiButton.selected = YES;
        [self.beautifyCamera toggleCamera];
    }
}

#pragma mark 切换是否使用美颜功能
- (void)beautifyOrNot:(UISwitch *)uiSwitch {
    [self.beautifyCamera switchBeauty:uiSwitch.isOn];
    if (uiSwitch.isOn) {
        uiSwitch.on = YES;
    } else {
        uiSwitch.on = NO;
    }
}

#pragma mark 调整磨皮效果(intensity)
- (void)intensityValueChange:(UISlider *)uiSlider {
    self.beautifyCamera.intensity = uiSlider.value;
    _intensityLabel.text = [NSString stringWithFormat:@"%.2f", uiSlider.value];
}

#pragma mark 开关直播
- (void)segmentValueChange:(UISegmentedControl *)uiSegmentedControl {
    if (uiSegmentedControl.selectedSegmentIndex == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.beautifyCamera startRunning];
        });
    } else {
        [self.beautifyCamera stopRunning];
    }
}

#pragma mark - FWBeautifyCameraDelegate
- (void)onBeautifyCamera:(FWBeautifyCamera *)camera andPixelBuffer:(CVPixelBufferRef)pixelBuffer {
  
    NSLog(@"Pixel Buffer Size : %zu - %zu", CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
    // 将 pixelBuffer 用于编码或推流
    /*
     // 示例代码
     OSType formatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
     UIImage *uiImage;
     
     if (formatType == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
     {
     uiImage = [UIImage lsqImageFromPlanarPixelBuffer:pixelBuffer];
     }
     else
     {
     // 注意：iOS 8.x 上无法本地显示，但数据没有问题
     CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
     
     CIContext *temporaryContext = [CIContext contextWithOptions:nil];
     CGImageRef videoImage = [temporaryContext
     createCGImage:ciImage
     fromRect:CGRectMake(0, 0,
     CVPixelBufferGetWidth(pixelBuffer),
     CVPixelBufferGetHeight(pixelBuffer))];
     
     uiImage = [UIImage imageWithCGImage:videoImage];
     CGImageRelease(videoImage);
     
     }
     
     [self performSelectorOnMainThread:@selector(updatePreview:) withObject:uiImage waitUntilDone:NO];
     */
}

/*
- (void)updatePreview:(UIImage *)img
{
    UIImageView *previewView = [[UIImageView alloc] initWithFrame:CGRectMake(30, 60, 160, 200)];
    previewView.contentMode = UIViewContentModeScaleAspectFit;
    previewView.image = img;
    [self.view addSubview:previewView];
    
    [previewView setNeedsDisplay];
}
*/

@end
