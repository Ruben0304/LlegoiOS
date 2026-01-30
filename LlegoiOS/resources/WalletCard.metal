#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// Simple vertex shader to render a full-quad
vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
    // 2 triangles forming a quad: (-1, -1) to (1, 1)
    float2 positions[6] = {
        float2(-1.0, -1.0), float2( 1.0, -1.0), float2(-1.0,  1.0),
        float2( 1.0, -1.0), float2( 1.0,  1.0), float2(-1.0,  1.0)
    };
    
    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    // Map [-1, 1] to [0, 1] for UV
    out.uv = positions[vertexID] * 0.5 + 0.5;
    return out;
}

// Helper noise function
float hash12(float2 p) {
    float3 p3  = fract(float3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Brushed metal effect
fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant float &time [[buffer(0)]],
                              constant float2 &resolution [[buffer(1)]],
                              constant int &type [[buffer(2)]]) { // 0 = USD (Magnesium/Silver), 1 = CUP (Bronze/Gold)
    
    float2 uv = in.uv;
    
    // 1. Base Gradient (Vertical sheen)
    // Darker at top/bottom, lighter in middle for cylindrical reflection look
    float sheen = 1.0 - abs(uv.y - 0.5) * 0.5;
    
    // 2. Brushed Metal Noise
    // High frequency noise over X axis, stretched over Y
    float noiseScale = 300.0;
    float n = hash12(float2(uv.x * noiseScale, floor(uv.y * 5.0) / 5.0)); // subtle stretch
    // Actually brushed metal is usually noise along one axis.
    float brush = hash12(float2(uv.x * 2000.0, uv.y * 2.0)); 
    
    // Soften the brush
    brush = mix(0.4, 0.6, brush);
    
    // 3. Dynamic Light / Anisotropy
    // Moving light band
    float lightPos = 0.5 + 0.1 * sin(time * 0.5);
    float lightWidth = 0.2;
    float highlight = smoothstep(lightPos - lightWidth, lightPos, uv.x) - smoothstep(lightPos, lightPos + lightWidth, uv.x);
    highlight *= 0.15; // Subtle highlight strength
    
    // 4. Color Assembly
    float3 baseColor;
    float3 highlightColor;
    
    if (type == 0) {
        // USD: Modern Dark Platinum / Tactical Grey
        baseColor = float3(0.12, 0.13, 0.14); // Very dark slate
        highlightColor = float3(0.6, 0.7, 0.8); // Cold bluish highlight
    } else {
        // CUP: Ancient Gold / Bronze
        baseColor = float3(0.25, 0.15, 0.05); // Deep brown/bronze
        highlightColor = float3(1.0, 0.8, 0.4); // Golden highlight
    }
    
    // Compose
    float3 finalColor = baseColor * sheen * brush;
    
    // Add dynamic highlight (specular)
    finalColor += highlightColor * highlight;
    
    // Add a very subtle vignette
    float vignette = 1.0 - length(uv - 0.5) * 0.5;
    finalColor *= vignette;
    
    // Add "hdr" edge glow (internal) - requested "hdr details"
    float dist = length(uv - 0.5);
    // float glow = smoothstep(0.4, 0.5, dist);
    // finalColor += highlightColor * glow * 0.5;

    return float4(finalColor, 1.0);
}
