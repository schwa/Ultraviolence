#pragma once

#import "ColorSource.h"
#import "Lighting.h"
#import "Support.h"

// long ambientTexture, long ambientSampler
struct BlinnPhongMaterialArgumentBuffer {
    ColorSourceArgumentBuffer ambient;
    ColorSourceArgumentBuffer diffuse;
    ColorSourceArgumentBuffer specular;
    float shininess;
};
