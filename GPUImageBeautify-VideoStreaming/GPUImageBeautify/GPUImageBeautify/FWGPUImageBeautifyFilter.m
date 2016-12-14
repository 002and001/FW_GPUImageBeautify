//
//  GPUImageBeautifyFilter.m
//  FWBeautifyFace
//
//  Created by Administrator on 16/9/13.
//  Copyright © 2016年 FunWay. All rights reserved.
//

#import "FWGPUImageBeautifyFilter.h"
#import "FWGPUImageCombinationFilter.h"

@interface FWGPUImageBeautifyFilter () {
    GPUImageBilateralFilter *_bilateralFilter;
    GPUImageCannyEdgeDetectionFilter *_cannyEdgeFilter;
    GPUImageHSBFilter *_hsbFilter;
    
    FWGPUImageCombinationFilter *_combinationFilter;
}

@end

@implementation FWGPUImageBeautifyFilter

- (id)init {
    if (!(self = [super init])) {
        return nil;
    }
    
    /*
     GPUImageBeautifyFilter绘制流程：
     
                  GPUImageVideoCamera
                            |
                 GPUImageBeautifyFilter
            ---------------------------------
            |               |               |
GPUImageBilateralFilter     |      GPUImageCannyEdgeDetectionFilter
            |               |               |
            ----GPUImageCombinationFilter---|
                            |
                    GPUImageHSBFilter
                            |
                       GPUImageView
                            |
                          UIView
     */
    
    // First pass:face smooth filter 双边滤波（进行磨皮处理）
    _bilateralFilter = [[GPUImageBilateralFilter alloc] init];
    _bilateralFilter.distanceNormalizationFactor = 4.0;
    [self addFilter:_bilateralFilter];
    
    // Second pass:edge detection 边缘检测
    _cannyEdgeFilter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
    [self addFilter:_cannyEdgeFilter];
    
    // Third pass:combination bilateral, edge detection and origin
    //combiantionFilter通过肤色检测和边缘检测，只对皮肤和非边缘部分进行处理
    _combinationFilter = [[FWGPUImageCombinationFilter alloc] init];
    [self addFilter:_combinationFilter];
    
    // Adjust HSB
    _hsbFilter = [[GPUImageHSBFilter alloc] init];
    
    [_bilateralFilter addTarget:_combinationFilter];
    [_cannyEdgeFilter addTarget:_combinationFilter];
    
    [_combinationFilter addTarget:_hsbFilter];
    
    self.initialFilters = [NSArray arrayWithObjects:_bilateralFilter, _cannyEdgeFilter, _combinationFilter, nil];
    self.terminalFilter = _hsbFilter;
    
    return self;
}

#pragma mark - GPUImageInput Protocol
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    for (GPUImageOutput<GPUImageInput> *currentFilter in self.initialFilters) {
        if (currentFilter != self.inputFilterToIgnoreForUpdates) {
            if (currentFilter == _combinationFilter) {
                textureIndex = 2;
            }
            [currentFilter newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex {
    for (GPUImageOutput<GPUImageInput> *currentFilter in self.initialFilters) {
        if (currentFilter == _combinationFilter) {
            textureIndex = 2;
        }
        [currentFilter setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
    }
}

#pragma mark - 属性 Setter 方法
- (void)setIntensity:(CGFloat)intensity {
    _combinationFilter.intensity = intensity;
}

- (void)setBrightness:(float)brightness {
    [_hsbFilter adjustBrightness:brightness];
}

- (void)setSaturation:(float)saturation {
    [_hsbFilter adjustSaturation:saturation];
}

- (void)updateWithImage:(UIImage *)image andImageView:(UIImageView *)imageView {
    dispatch_async(dispatch_get_main_queue(), ^{
        imageView.image = image;
    });
}
@end
