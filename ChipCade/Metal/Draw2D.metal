//
//  Draw2D.metal
//  ChipCade
//
//  Created by Markus Moenig on 30/9/24.
//

#include <metal_stdlib>
using namespace metal;

#import "Metal.h"

struct VertexIn {
    float2 position               [[attribute(0)]];
    float2 textureCoordinate      [[attribute(1)]];
    float4 color                  [[attribute(2)]];
};

struct VertexOut {
    float4 position               [[position]];
    float2 textureCoordinate;
    float4 color;
};

typedef struct
{
    float4 clipSpacePosition    [[position]];
    float2 textureCoordinate;
} RasterizerData;

// Quad Vertex Function
vertex VertexOut poly2DVertex(uint vertexID [[ vertex_id ]],
                              VertexIn in [[stage_in]],
                              constant vector_uint2 *viewportSizePointer  [[ buffer(1) ]])
{
    VertexOut out;
    
    float2 viewportSize = float2(*viewportSizePointer);
    
    out.position.xy = in.position / (viewportSize / 2.0);
    out.position.z = 0.0;
    out.position.w = 1.0;
    
    out.textureCoordinate = in.textureCoordinate;
    out.color = in.color;
    return out;
}

fragment float4 poly2DFragment(VertexOut in [[stage_in]],
                               constant RectUniform *data [[ buffer(0) ]],
                               texture2d<float> inTexture [[ texture(1) ]],
                               sampler textureSampler [[sampler(0)]])
{
    float4 color = in.color;
    
    if (data->hasTexture == 1) {
        float2 uv = in.textureCoordinate;
        uv.y = 1 - uv.y;
        color = float4(inTexture.sample(textureSampler, uv));
    }
    
    return color;
}

// --- SDF utilities

float m4mFillMask(float dist)
{
    return clamp(-dist, 0.0, 1.0);
}

float m4mBorderMask(float dist, float width)
{
    dist += 1.0;
    return clamp(dist + width, 0.0, 1.0) - clamp(dist, 0.0, 1.0);
}

float2 m4mRotateCCW(float2 pos, float angle)
{
    float ca = cos(angle), sa = sin(angle);
    return pos * float2x2(ca, sa, -sa, ca);
}

float2 m4mRotateCCWPivot(float2 pos, float angle, float2 pivot)
{
    float ca = cos(angle), sa = sin(angle);
    return pivot + (pos-pivot) * float2x2(ca, sa, -sa, ca);
}

float2 m4mRotateCW(float2 pos, float angle)
{
    float ca = cos(angle), sa = sin(angle);
    return pos * float2x2(ca, -sa, sa, ca);
}

float2 m4mRotateCWPivot(float2 pos, float angle, float2 pivot)
{
    float ca = cos(angle), sa = sin(angle);
    return pivot + (pos-pivot) * float2x2(ca, -sa, sa, ca);
}

float dot2( float2 v ) { return dot(v,v); }
float cross2( float2 a, float2 b ) { return a.x*b.y - a.y*b.x; }

// signed distance to a quadratic bezier, https://www.shadertoy.com/view/MlKcDD
float sdBezier(float2 pos, float2 p0, float2 p1, float2 p2 )
{
    float2 a = p1 - p0;
    float2 b = p0 - 2.0*p1 + p2;
    float2 c = p0 - pos;
    
    float kk = 1.0 / dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(c,b)) / 3.0;
    float kz = kk * dot(c,a);
    
    float2 res;
    
    float p = ky - kx*kx;
    float p3 = p*p*p;
    float q = kx*(2.0*kx*kx - 3.0*ky) + kz;
    float h = q*q + 4.0*p3;
    
    if(h >= 0.0)
    {
        h = sqrt(h);
        float2 x = (float2(h, -h) - q) / 2.0;
        float2 uv = sign(x)*pow(abs(x), float2(1.0/3.0));
        float t = uv.x + uv.y - kx;
        t = clamp( t, 0.0, 1.0 );
        
        // 1 root
        float2 qos = c + (2.0*a + b*t)*t;
        res = float2( length(qos),t);
    } else {
        float z = sqrt(-p);
        float v = acos( q/(p*z*2.0) ) / 3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        float3 t = float3(m + m, -n - m, n - m) * z - kx;
        t = clamp( t, 0.0, 1.0 );
        
        // 3 roots
        float2 qos = c + (2.0*a + b*t.x)*t.x;
        float dis = dot(qos,qos);
        
        res = float2(dis,t.x);
        
        qos = c + (2.0*a + b*t.y)*t.y;
        dis = dot(qos,qos);
        if( dis<res.x ) res = float2(dis,t.y );
        
        qos = c + (2.0*a + b*t.z)*t.z;
        dis = dot(qos,qos);
        if( dis<res.x ) res = float2(dis,t.z );
        
        res.x = sqrt( res.x );
    }
    return res.x;
}

// Disc
fragment float4 m4mDiscDrawable(RasterizerData in [[stage_in]],
                               constant DiscUniform *data [[ buffer(0) ]],
                               texture2d<float> inTexture [[ texture(1) ]] )
{
    float2 uv = in.textureCoordinate * float2( data->radius * 2 + data->borderSize, data->radius * 2 + data->borderSize);
    uv -= float2( data->radius + data->borderSize / 2 );
    
    float dist = length( uv ) - data->radius + data->onion;
    if (data->onion > 0.0)
        dist = abs(dist) - data->onion;
    
    const float mask = m4mFillMask( dist );
    float4 col = float4( data->fillColor.xyz, data->fillColor.w * mask);
    
    float borderMask = m4mBorderMask(dist, data->borderSize);
    float4 borderColor = data->borderColor;
    borderColor.w *= borderMask;
    col = mix( col, borderColor, borderMask );

    if (data->hasTexture == 1 && col.w > 0.0) {
        constexpr sampler textureSampler (mag_filter::linear,
                                          min_filter::linear);
        
        float2 uv = in.textureCoordinate;
        uv.y = 1 - uv.y;
        uv = m4mRotateCCWPivot(uv, data->rotation, 0.5);

        float4 sample = float4(inTexture.sample(textureSampler, uv));
        
        col.xyz = sample.xyz;
        col.w = col.w * sample.w;
    }
    
    return col;
}

// Box
fragment float4 m4mBoxDrawable(RasterizerData in [[stage_in]],
                               constant BoxUniform *data [[ buffer(0) ]],
                               texture2d<float> inTexture [[ texture(1) ]] )
{
    float2 uv = in.textureCoordinate * ( data->size );
    uv -= float2( data->size / 2.0 );
            
    float2 d = abs( uv ) - data->size / 2 + data->onion + data->round;
    float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
    
    if (data->onion > 0.0)
        dist = abs(dist) - data->onion;
    
    const float mask = m4mFillMask( dist );
    float4 col = float4( data->fillColor.xyz, data->fillColor.w * mask);
    
    if (data->hasTexture == 1 && col.w > 0.0) {
        constexpr sampler textureSampler (mag_filter::linear,
                                          min_filter::linear);
        
        float2 uv = in.textureCoordinate;
        uv.y = 1 - uv.y;
        uv = m4mRotateCCWPivot(uv, data->rotation, 0.5);

        float4 sample = float4(inTexture.sample(textureSampler, uv));
        
        col.xyz = sample.xyz;
        col.w = col.w * sample.w;
    }
    
    float borderMask = m4mBorderMask(dist, data->borderSize);
    float4 borderColor = data->borderColor;
    borderColor.w *= borderMask;
    col = mix( col, borderColor, borderMask );
    
    return col;
}

// Line
fragment float4 m4mLineDrawable(RasterizerData in [[stage_in]],
                               constant LineUniform *data [[ buffer(0) ]])
{
    float2 uv = in.textureCoordinate * ( data->size + data->borderSize / 2.0);
    uv -= float2(data->size / 2.0 + data->borderSize / 2.0);
    
    float2 o = uv - data->sp;
    float2 l = data->ep - data->sp;
    
    float h = clamp( dot(o,l)/dot(l,l), 0.0, 1.0 );
    float dist = -(data->width-distance(o,l*h));
    
    float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, m4mFillMask( dist ) * data->fillColor.w );
    col = mix( col, data->borderColor, m4mBorderMask( dist, data->borderSize ) );
    
    return col;
}

/*
// Bezier
fragment float4 m4mBezierDrawable(RasterizerData in [[stage_in]],
                               constant BezierUniform *data [[ buffer(0) ]])
{
    float2 uv = in.textureCoordinate * ( data->size + data->borderSize * 2.0);
    uv -= float2(data->size / 2.0 + data->borderSize / 2.0);
    
    float2 p1 = data->p1;
    float2 p2 = data->p2;
    float2 p3 = data->p3;

    float dist = sdBezier(uv, p1, p2, p3) - data->width;

    float4 col = float4( data->fillColor.x, data->fillColor.y, data->fillColor.z, m4mFillMask( dist ) * data->fillColor.w );
    col = mix( col, data->borderColor, m4mBorderMask( dist, data->borderSize ) );
    
    return col;
}
*/
// Rotated Box
fragment float4 m4mBoxDrawableExt(RasterizerData in [[stage_in]],
                               constant BoxUniform *data [[ buffer(0) ]],
                               texture2d<float> inTexture [[ texture(1) ]] )
{
    float2 uv = in.textureCoordinate * data->screenSize;
    uv.y = data->screenSize.y - uv.y;
    uv -= float2(data->size / 2.0);
    uv -= float2(data->pos.x, data->pos.y);

    uv = m4mRotateCCW(uv, data->rotation);
    
    float2 d = abs( uv ) - data->size / 2.0 + data->onion + data->round;// - data->borderSize;
    float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0) - data->round;
    
    if (data->onion > 0.0)
        dist = abs(dist) - data->onion;

    const float mask = m4mFillMask( dist );//smoothstep(0.0, pixelSize, -dist);
    float4 col = float4( data->fillColor.xyz, data->fillColor.w * mask);
    
    const float borderMask = m4mBorderMask(dist, data->borderSize);
    float4 borderColor = data->borderColor;
    borderColor.w *= borderMask;
    col = mix( col, borderColor, borderMask );
    
    if (data->hasTexture == 1 && col.w > 0.0) {
        constexpr sampler textureSampler (mag_filter::linear,
                                          min_filter::linear);
        
        float2 uv = in.textureCoordinate;
        uv.y = 1 - uv.y;
        
        uv -= data->pos / data->screenSize;
        uv *= data->screenSize / data->size;
        
        uv = m4mRotateCCWPivot(uv, data->rotation, (data->size / 2.0) / data->screenSize * (data->screenSize / data->size));
        
        float4 sample = float4(inTexture.sample(textureSampler, uv));
        
        col.xyz = sample.xyz;
        col.w = col.w * sample.w;
    }

    return col;
}

// --- Box Drawable
fragment float4 m4mBoxPatternDrawable(RasterizerData in [[stage_in]],
                               constant BoxUniform *data [[ buffer(0) ]] )
{
    float2 uv = in.textureCoordinate * ( data->screenSize );
    uv -= float2( data->screenSize / 2.0 );
    
    float2 d = abs( uv ) - data->size / 2.0;
    float dist = length(max(d,float2(0))) + min(max(d.x,d.y),0.0);
    
    float4 checkerColor1 = data->fillColor;
    float4 checkerColor2 = data->borderColor;
    
    //uv = fragCoord;
    //uv -= float2( data->size / 2 );
    
    float4 col = checkerColor1;
    
    float cWidth = 12.0;
    float cHeight = 12.0;
    
    if ( fmod( floor( uv.x / cWidth ), 2.0 ) == 0.0 ) {
        if ( fmod( floor( uv.y / cHeight ), 2.0 ) != 0.0 ) col=checkerColor2;
    } else {
        if ( fmod( floor( uv.y / cHeight ), 2.0 ) == 0.0 ) col=checkerColor2;
    }
    
    return float4( col.xyz, m4mFillMask( dist ) );
}

/*
// --- Grid Drawable
fragment float4 m4mGridDrawable(RasterizerData in [[stage_in]],
                               constant GridUniform *data [[ buffer(0) ]] )
{
    float2 uv = in.textureCoordinate * ( data->screenSize );
//    uv -= float2( data->screenSize / 2.0 );
    
    float4 col = data->backColor;
    
    float tile_half_x = data->gridSize / 2.0;
    float tile_half_y = data->gridSize / 4.0;

    float offset_from_0_x = uv.x - (data->screenSize.x / 2.0 + data->offset.x);
    float offset_from_0_y = uv.y - (data->screenSize.y / 2.0 + data->offset.y);

    float grid_x = offset_from_0_x / tile_half_x;
    float grid_y = offset_from_0_y / tile_half_y;

    float grid_x_screen = grid_x * tile_half_x;
    float grid_y_screen = grid_y * tile_half_y;

    float map_x = grid_x_screen / data->gridSize * 2.0;
    float map_y = grid_y_screen / data->gridSize * 2.0;
    
    float c_x = cos(map_x * M_PI_F * 2.0);
    float c_y = cos(map_y * M_PI_F * 2.0);
    float v = smoothstep(0.99, 1.0, max(c_x,c_y));

//    float2 coord = cos(M_PI_F/data->gridSize * uv);
//    float v = smoothstep(0.999, 1.0, max(coord.x, coord.y));
//    col = mix(col, data->gridColor, v);

    col = mix(col, data->gridColor, v);
    
    return float4( col );
}*/

// Copy texture
fragment float4 m4mCopyTextureDrawable(VertexOut in [[stage_in]],
                                constant TextureUniform *data [[ buffer(0) ]],
                                texture2d<half, access::read> inTexture [[ texture(1) ]])
{
    float2 uv = in.textureCoordinate * data->size;
    uv.y = data->size.y - uv.y;

    const half4 colorSample = inTexture.read(uint2(uv));
    float4 sample = float4( colorSample );

    sample.w *= data->globalAlpha;
    return float4(sample.x / sample.w, sample.y / sample.w, sample.z / sample.w, sample.w);
}

fragment float4 m4mTextureDrawable(RasterizerData in [[stage_in]],
                                constant TextureUniform *data [[ buffer(0) ]],
                                texture2d<half> inTexture [[ texture(1) ]])
{
    //constexpr sampler textureSampler (mag_filter::linear,
    //                                  min_filter::linear);
    
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    float2 uv = in.textureCoordinate;
    uv.y = 1 - uv.y;
    
    uv.x *= data->size.x;
    uv.y *= data->size.y;

    uv.x += data->pos.x;
    uv.y += data->pos.y;
    
    float4 sample = float4(inTexture.sample(textureSampler, uv));
    sample.w *= data->globalAlpha;

    return sample;
}

float m4mMedian(float r, float g, float b) {
    return max(min(r, g), min(max(r, g), b));
}

fragment float4 m4mTextDrawable(VertexOut in [[stage_in]],
                                constant TextUniform *data [[ buffer(0) ]],
                                texture2d<float> inTexture [[ texture(1) ]])
{
    float4 color = in.color;

    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    
    float2 uv = in.textureCoordinate;
    uv.y = 1 - uv.y;

    uv /= data->atlasSize / data->fontSize;
    uv += data->fontPos / data->atlasSize;

    float4 sample = inTexture.sample(textureSampler, uv );
        
    float d = m4mMedian(sample.r, sample.g, sample.b) - 0.5;
    float w = clamp(d/fwidth(d) + 0.5, 0.0, 1.0);
    
    color.w *= w;
    
    return color;
}

kernel void makeCGIImage(
texture2d<half, access::write>          outTexture  [[texture(0)]],
texture2d<half, access::read>           inTexture [[texture(2)]],
uint2 gid                               [[thread_position_in_grid]])
{
    //float2 size = float2( outTexture.get_width(), outTexture.get_height() );
    half4 color = inTexture.read(gid).zyxw;
    color.xyz = pow(color.xyz, 2.2);
    outTexture.write(color, gid);
}
