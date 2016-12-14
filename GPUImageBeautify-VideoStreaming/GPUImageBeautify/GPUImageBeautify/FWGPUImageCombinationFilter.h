//
//  FWGPUImageCombinationFilter.h
//  FWBeautifyFace
//
//  Created by Administrator on 16/9/23.
//  Copyright © 2016年 FunWay. All rights reserved.
//

#import "GPUImage.h"

@interface FWGPUImageCombinationFilter : GPUImageThreeInputFilter

/** 改变此值可以改变磨皮的效果，[0, 1] */
@property (nonatomic, assign) CGFloat intensity;

@end
