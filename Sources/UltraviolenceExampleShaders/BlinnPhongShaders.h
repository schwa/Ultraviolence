#pragma once

#import "ColorSource.h"
#import "Support.h"
#import "Lighting.h"

// long ambientTexture, long ambientSampler
struct BlinnPhongMaterialArgumentBuffer {
    ColorSourceArgumentBuffer ambient;
    ColorSourceArgumentBuffer diffuse;
    ColorSourceArgumentBuffer specular;
    float shininess;
};

