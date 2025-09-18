#pragma once

#import "BlinnPhongShaders.h"
#import "Support.h"
#import "DebugShaders.h"
#import "AxisLines.h"
#import "Boxes.h"
#import "PBRShaders.h"
#import "SDFShader.h"
#import "ParticleEffectsShader.h"

#ifdef __OBJC__
#import <Foundation/Foundation.h>
@interface NSBundle (Module)
+ (NSBundle *)ultraviolenceExampleShadersBundle;
@end
#endif
