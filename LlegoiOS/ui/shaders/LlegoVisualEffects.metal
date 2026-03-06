#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>

using namespace metal;

static inline float randomNoise(float2 position) {
    return fract(sin(dot(position, float2(12.9898, 78.233))) * 43758.5453);
}

[[ stitchable ]] half4 llegoFilmGrain(float2 position, half4 color) {
    float grain = (randomNoise(position) - 0.5) * 0.06;
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

    half3 bloomed = mix(center.rgb, blur.rgb + center.rgb * 0.12h, 0.4h);
    return half4(clamp(bloomed, half3(0.0), half3(1.0)), center.a);
}

[[ stitchable ]] half4 llegoImagePop(float2 position, half4 color) {
    half luma = dot(color.rgb, half3(0.2126h, 0.7152h, 0.0722h));
    half3 contrasted = (color.rgb - 0.5h) * 1.18h + 0.5h;
    half3 saturated = mix(half3(luma), contrasted, 1.18h);

    float grain = (randomNoise(position * 1.25) - 0.5) * 0.024;
    half3 result = clamp(saturated + half3(grain), half3(0.0), half3(1.0));

    return half4(result, color.a);
}

[[ stitchable ]] half4 llegoCardHDR(float2 position, half4 color) {
    // Keep the HDR feel, but reduce intensity in the lower area of the card
    // so text and CTA remain easy to read.
    float bottomMask = smoothstep(190.0, 420.0, position.y);
    half contrastStrength = half(mix(1.16, 1.06, bottomMask));
    half saturationStrength = half(mix(1.12, 1.04, bottomMask));
    half hdrStrength = half(mix(0.34, 0.14, bottomMask));

    half3 lifted = color.rgb + half3(0.026h);
    half3 contrasted = (lifted - 0.5h) * contrastStrength + 0.5h;
    half luma = dot(contrasted, half3(0.2126h, 0.7152h, 0.0722h));
    half3 saturated = mix(half3(luma), contrasted, saturationStrength);

    // Mild highlight rolloff to avoid clipping bright UI elements.
    half3 toneMapped = saturated / (half3(1.0h) + saturated * 0.1h);
    half3 hdr = mix(color.rgb, toneMapped, hdrStrength);

    float grainAmount = mix(0.01, 0.004, bottomMask);
    float grain = (randomNoise(position * 0.95) - 0.5) * grainAmount;
    return half4(clamp(hdr + half3(grain), half3(0.0), half3(1.0)), color.a);
}

[[ stitchable ]] half4 llegoGradientReveal(float2 position, half4 color, float progress) {
    float p = clamp(progress, 0.0, 1.0);

    // Diagonal sweep from top-left to bottom-right in user-space coordinates.
    float sweep = position.x + position.y;
    float softness = 26.0;
    float head = p * 760.0;
    float mask = smoothstep(-softness, softness, head - sweep);

    // Slight highlight at the reveal edge.
    float edge = smoothstep(-8.0, 12.0, head - sweep) - smoothstep(12.0, 34.0, head - sweep);
    half3 edgeGlow = half3(0.08h, 0.07h, 0.05h) * half(max(edge, 0.0));

    // Keep hidden area white instead of black.
    half3 whiteBase = half3(1.0h, 1.0h, 1.0h);
    half3 rgb = mix(whiteBase, color.rgb, half(mask)) + edgeGlow;
    return half4(clamp(rgb, half3(0.0), half3(1.0)), color.a);
}
