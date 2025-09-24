#pragma once

#import "AxisLines.h"
#import "BlinnPhongShaders.h"
#import "Boxes.h"
#import "ColorSource.h"
#import "DebugShaders.h"
#import "PBRShaders.h"
#import "Panorama.h"
#import "ParticleEffectsShader.h"
#import "SDFShader.h"
#import "Support.h"
#import "WireframeShader.h"

#ifdef __OBJC__
#import <Foundation/Foundation.h>
@interface NSBundle (Module)
+ (NSBundle *)ultraviolenceExampleShadersBundle;
@end
#endif
