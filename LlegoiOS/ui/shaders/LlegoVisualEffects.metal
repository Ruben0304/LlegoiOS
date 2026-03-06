#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>

using namespace metal;

static inline float randomNoise(float2 position) {
    return fract(sin(dot(position, float2(12.9898, 78.233))) * 43758.5453);
}

[[ stitchable ]] half4 llegoFilmGrain(float2 position, half4 color) {
    float grain = (randomNoise(position) - 0.5) * 0.035;
    half3 rgb = clamp(color.rgb + half3(grain), half3(0.0), half3(1.0));
    return half4(rgb, color.a);
}

[[ stitchable ]] half4 llegoSoftBloom(float2 position, SwiftUI::Layer layer) {
    constexpr float2 offset = float2(1.0, 1.0);

    half4 center = layer.sample(position);
    half4 blur = (
        layer.sample(position + float2(offset.x, 0.0)) +
        layer.sample(position + float2(-offset.x, 0.0)) +
        layer.sample(position + float2(0.0, offset.y)) +
        layer.sample(position + float2(0.0, -offset.y))
    ) * 0.25;

    half3 bloomed = mix(center.rgb, blur.rgb + center.rgb * 0.08h, 0.28h);
    return half4(clamp(bloomed, half3(0.0), half3(1.0)), center.a);
}

[[ stitchable ]] half4 llegoImagePop(float2 position, half4 color) {
    half luma = dot(color.rgb, half3(0.2126h, 0.7152h, 0.0722h));
    half3 contrasted = (color.rgb - 0.5h) * 1.08h + 0.5h;
    half3 saturated = mix(half3(luma), contrasted, 1.06h);

    float grain = (randomNoise(position * 1.25) - 0.5) * 0.018;
    half3 result = clamp(saturated + half3(grain), half3(0.0), half3(1.0));

    return half4(result, color.a);
}
