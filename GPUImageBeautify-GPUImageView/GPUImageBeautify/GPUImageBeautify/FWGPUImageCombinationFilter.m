//
//  FWGPUImageCombinationFilter.m
//  FWBeautifyFace
//
//  Created by Administrator on 16/9/23.
//  Copyright © 2016年 FunWay. All rights reserved.
//

#import "FWGPUImageCombinationFilter.h"

@interface FWGPUImageCombinationFilter ()  {
    GLint smoothDegreeUniform;
}

@end

/** OpenGL shader语句字符串化 */
NSString * const kGPUImageBeautifyFragmentShaderString = SHADER_STRING
(
 //变形后的图片坐标
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 varying highp vec2 textureCoordinate3;
 
 //需要变形的图片
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform sampler2D inputImageTexture3;
 
 uniform mediump float smoothDegree;
 
 void main() {
     highp vec4 bilateral = texture2D(inputImageTexture, textureCoordinate);
     highp vec4 canny = texture2D(inputImageTexture2, textureCoordinate2);
     highp vec4 origin = texture2D(inputImageTexture3, textureCoordinate3);
     highp vec4 smooth;
     
     lowp float r = origin.r;
     lowp float g = origin.g;
     lowp float b = origin.b;
     
     if (canny.r < 0.2 && r > 0.372549 && g > 0.156863 && b > 0.078431 && (max(max(r, g), b)-min(min(r, g), b)) > 0.058823 && abs(r - g) > 0.058823 && r > g && r > b) {
         smooth = (1.0 - smoothDegree) * (origin - bilateral) + bilateral;
     } else {
         smooth = origin;
     }
     smooth.r = log(1.0 + 0.5 * smooth.r) / log(1.5);
     smooth.g = log(1.0 + 0.5 * smooth.g) / log(1.5);
     smooth.b = log(1.0 + 0.5 * smooth.b) / log(1.5);
     gl_FragColor = smooth;
 }
 );

@implementation FWGPUImageCombinationFilter

- (id)init {
    if (self = [super initWithFragmentShaderFromString:kGPUImageBeautifyFragmentShaderString]) {
        smoothDegreeUniform = [filterProgram uniformIndex:@"smoothDegree"];
    }
    self.intensity = 0.5f;
    return self;
}

- (void)setIntensity:(CGFloat)intensity {
    _intensity = intensity;
    [self setFloat:intensity forUniform:smoothDegreeUniform program:filterProgram];
}

@end
