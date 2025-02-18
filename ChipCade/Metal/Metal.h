//
//  Metal.h
//  ChipCade
//
//  Created by Markus Moenig on 29/9/24.
//

#ifndef Metal_h
#define Metal_h

#include <simd/simd.h>

typedef struct Rectangle {
    float x;                // Rectangle top-left corner position x
    float y;                // Rectangle top-left corner position y
    float width;            // Rectangle width
    float height;           // Rectangle height
} Rectangle;

typedef struct
{
    int             hasTexture;
} RectUniform;

typedef struct
{
    vector_float2   position;
    vector_float2   textureCoordinate;
} VertexUniform;

typedef struct
{
    vector_float2   screenSize;
    vector_float2   pos;
    vector_float2   size;
    float           globalAlpha;

} TextureUniform;

typedef struct
{
    vector_float4   fillColor;
    vector_float4   borderColor;
    float           radius;
    float           borderSize;
    float           rotation;
    float           onion;
    
    int             hasTexture;
    vector_float2   textureSize;
} DiscUniform;

typedef struct
{
    vector_float2   screenSize;
    vector_float2   pos;
    vector_float2   size;
    float           round;
    float           borderSize;
    vector_float4   fillColor;
    vector_float4   borderColor;
    float           rotation;
    float           onion;
    
    int             hasTexture;
    vector_float2   textureSize;

} BoxUniform;

typedef struct
{
    vector_float2   size;
    vector_float2   sp, ep;
    float           width, borderSize;
    vector_float4   fillColor;
    vector_float4   borderColor;
    
} LineUniform;

typedef struct
{
    vector_float2   size;
    vector_float2   offset;
    float           gridSize;
    vector_float4   fillColor;
    vector_float4   borderColor;
    
} GridUniform;

typedef struct
{
    vector_float2   atlasSize;
    vector_float2   fontPos;
    vector_float2   fontSize;
    vector_float4   color;
    int             rotated;

} TextUniform;

typedef struct
{
    float           time;
    unsigned int    frame;
} MetalData;

#endif /* Metal_h */
