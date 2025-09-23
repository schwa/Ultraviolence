#pragma once

#import "ColorSpecifier.h"
#import "Support.h"
#import "Lighting.h"

// long ambientTexture, long ambientSampler
struct BlinnPhongMaterialArgumentBuffer {
    ColorSpecifierArgumentBuffer ambient;
    ColorSpecifierArgumentBuffer diffuse;
    ColorSpecifierArgumentBuffer specular;
    float shininess;
};

