//
//  GPUImageBeautifyFilter.h
//  FWBeautifyFace
//
//  Created by Administrator on 16/9/13.
//  Copyright © 2016年 FunWay. All rights reserved.
//

#import "GPUImage.h"

@interface FWGPUImageBeautifyFilter : GPUImageFilterGroup 

/** 磨皮程度 */
@property (nonatomic, assign) CGFloat intensity;

/** 亮度 */
@property (nonatomic, assign) float brightness;

/** 饱和度 */
@property (nonatomic, assign) float saturation;

@end
