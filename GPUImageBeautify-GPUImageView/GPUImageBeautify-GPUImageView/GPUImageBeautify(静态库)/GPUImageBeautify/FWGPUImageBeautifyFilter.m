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
    GPUImageBilateralFilter *bilateralFilter;
    GPUImageCannyEdgeDetectionFilter *cannyEdgeFilter;
    GPUImageHSBFilter *hsbFilter;
    
    FWGPUImageCombinationFilter *combinationFilter;
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
    bilateralFilter = [[GPUImageBilateralFilter alloc] init];
    bilateralFilter.distanceNormalizationFactor = 4.0;
    [self addFilter:bilateralFilter];
    
    // Second pass:edge detection 边缘检测
    cannyEdgeFilter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
    [self addFilter:cannyEdgeFilter];
    
    // Third pass:combination bilateral, edge detection and origin
    //combiantionFilter通过肤色检测和边缘检测，只对皮肤和非边缘部分进行处理
    combinationFilter = [[FWGPUImageCombinationFilter alloc] init];
    [self addFilter:combinationFilter];
    
    // Adjust HSB
    hsbFilter = [[GPUImageHSBFilter alloc] init];
    
    [bilateralFilter addTarget:combinationFilter];
    [cannyEdgeFilter addTarget:combinationFilter];
    
    [combinationFilter addTarget:hsbFilter];
    
    self.initialFilters = [NSArray arrayWithObjects:bilateralFilter, cannyEdgeFilter, combinationFilter, nil];
    self.terminalFilter = hsbFilter;
    
    return self;
}

#pragma mark - GPUImageInput Protocol
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    for (GPUImageOutput<GPUImageInput> *currentFilter in self.initialFilters) {
        if (currentFilter != self.inputFilterToIgnoreForUpdates) {
            if (currentFilter == combinationFilter) {
                textureIndex = 2;
            }
            [currentFilter newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex {
    for (GPUImageOutput<GPUImageInput> *currentFilter in self.initialFilters) {
        if (currentFilter == combinationFilter) {
            textureIndex = 2;
        }
        [currentFilter setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
    }
}

#pragma mark - 属性 Setter 方法
- (void)setIntensity:(CGFloat)intensity {
    combinationFilter.intensity = intensity;
}

- (void)setBrightness:(float)brightness {
    [hsbFilter adjustBrightness:brightness];
}

- (void)setSaturation:(float)saturation {
    [hsbFilter adjustSaturation:saturation];
}

@end
