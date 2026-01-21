import SwiftUI
import MetalKit
import QuartzCore

struct HDRAnimatedGradientPalette {
    let dark: Color
    let medium: Color
    let light: Color
    let veryLight: Color
    let overlay: Color
}

struct HDRAnimatedGradientView: View {
    let fromPalette: HDRAnimatedGradientPalette
    let toPalette: HDRAnimatedGradientPalette
    let transitionProgress: CGFloat
    let center: CGPoint
    let isExpanded: Bool

    var body: some View {
        MetalAnimatedGradientRepresentable(
            fromPalette: fromPalette,
            toPalette: toPalette,
            transitionProgress: transitionProgress,
            center: center,
            expansion: isExpanded ? 1.0 : 0.0
        )
        .allowsHitTesting(false)
    }
}

private struct MetalAnimatedGradientRepresentable: UIViewRepresentable {
    let fromPalette: HDRAnimatedGradientPalette
    let toPalette: HDRAnimatedGradientPalette
    let transitionProgress: CGFloat
    let center: CGPoint
    let expansion: CGFloat

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()

        guard let device = MTLCreateSystemDefaultDevice() else {
            print("❌ Metal is not supported on this device")
            return mtkView
        }

        mtkView.device = device
        mtkView.delegate = context.coordinator
        mtkView.backgroundColor = .clear
        mtkView.isOpaque = false
        mtkView.framebufferOnly = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false

        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)

        if #available(iOS 16.0, *) {
            mtkView.colorPixelFormat = .rgba16Float
        } else {
            mtkView.colorPixelFormat = .bgra8Unorm
        }
        mtkView.preferredFramesPerSecond = 120

        context.coordinator.setupMetal(device: device, pixelFormat: mtkView.colorPixelFormat)

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.fromPalette = fromPalette
        context.coordinator.toPalette = toPalette
        context.coordinator.transitionProgress = transitionProgress
        context.coordinator.center = center
        context.coordinator.expansion = expansion
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            fromPalette: fromPalette,
            toPalette: toPalette,
            transitionProgress: transitionProgress,
            center: center,
            expansion: expansion
        )
    }

    final class Coordinator: NSObject, MTKViewDelegate {
        var device: MTLDevice?
        var commandQueue: MTLCommandQueue?
        var pipelineState: MTLRenderPipelineState?

        var fromPalette: HDRAnimatedGradientPalette
        var toPalette: HDRAnimatedGradientPalette
        var transitionProgress: CGFloat
        var center: CGPoint
        var expansion: CGFloat
        let startTime: CFTimeInterval

        init(
            fromPalette: HDRAnimatedGradientPalette,
            toPalette: HDRAnimatedGradientPalette,
            transitionProgress: CGFloat,
            center: CGPoint,
            expansion: CGFloat
        ) {
            self.fromPalette = fromPalette
            self.toPalette = toPalette
            self.transitionProgress = transitionProgress
            self.center = center
            self.expansion = expansion
            self.startTime = CACurrentMediaTime()
        }

        func setupMetal(device: MTLDevice, pixelFormat: MTLPixelFormat) {
            self.device = device
            self.commandQueue = device.makeCommandQueue()

            let shaderSource = """
            #include <metal_stdlib>
            using namespace metal;

            struct VertexOut {
                float4 position [[position]];
                float2 texCoord;
            };

            vertex VertexOut vertexShader(uint vertexID [[vertex_id]]) {
                float2 positions[6] = {
                    float2(-1, -1), float2(1, -1), float2(-1, 1),
                    float2(-1, 1), float2(1, -1), float2(1, 1)
                };

                VertexOut out;
                out.position = float4(positions[vertexID], 0, 1);
                out.texCoord = (positions[vertexID] + 1.0) * 0.5;
                return out;
            }

            float hash(float2 p) {
                float h = dot(p, float2(127.1, 311.7));
                return fract(sin(h) * 43758.5453123);
            }

            float noise(float2 p) {
                float2 i = floor(p);
                float2 f = fract(p);
                f = f * f * (3.0 - 2.0 * f);

                float a = hash(i);
                float b = hash(i + float2(1.0, 0.0));
                float c = hash(i + float2(0.0, 1.0));
                float d = hash(i + float2(1.0, 1.0));

                return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
            }

            fragment float4 fragmentShader(
                VertexOut in [[stage_in]],
                constant float3 &fromDark [[buffer(0)]],
                constant float3 &fromMedium [[buffer(1)]],
                constant float3 &fromLight [[buffer(2)]],
                constant float3 &fromVeryLight [[buffer(3)]],
                constant float3 &fromOverlay [[buffer(4)]],
                constant float3 &toDark [[buffer(5)]],
                constant float3 &toMedium [[buffer(6)]],
                constant float3 &toLight [[buffer(7)]],
                constant float3 &toVeryLight [[buffer(8)]],
                constant float3 &toOverlay [[buffer(9)]],
                constant float2 &baseCenter [[buffer(10)]],
                constant float &expansion [[buffer(11)]],
                constant float &transition [[buffer(12)]],
                constant float &phase [[buffer(13)]]
            ) {
                float time = phase * 6.2831853;

                float2 baseCenterFlipped = float2(baseCenter.x, 1.0 - baseCenter.y);
                float2 transitionCenter = clamp(baseCenterFlipped, float2(0.7, 0.65), float2(0.95, 0.95));
                float transitionRadius = mix(-0.2, 1.45, transition);
                float transitionNoise = noise(in.texCoord * 3.2 + float2(time * 0.08, time * 0.06));
                float transitionWave = sin((in.texCoord.x * 2.6 + in.texCoord.y * 2.1 + time * 0.25) * 3.14159);
                float transitionEdge = 1.0 - smoothstep(
                    transitionRadius - 0.22,
                    transitionRadius + 0.22,
                    distance(in.texCoord, transitionCenter) + transitionNoise * 0.08 + transitionWave * 0.05
                );
                float paletteBlend = clamp(transitionEdge, 0.0, 1.0);

                float3 darkColor = mix(fromDark, toDark, paletteBlend);
                float3 mediumColor = mix(fromMedium, toMedium, paletteBlend);
                float3 lightColor = mix(fromLight, toLight, paletteBlend);
                float3 veryLightColor = mix(fromVeryLight, toVeryLight, paletteBlend);
                float3 overlayColor = mix(fromOverlay, toOverlay, paletteBlend);

                float2 drift = float2(
                    sin(time * 0.22 + 1.4),
                    cos(time * 0.18 + 0.3)
                ) * (0.02 + expansion * 0.01);

                float2 center = clamp(baseCenterFlipped + drift, float2(0.7, 0.65), float2(0.95, 0.95));
                float dist = distance(in.texCoord, center);
                float radius = mix(0.78, 1.08, expansion);
                float t = clamp(dist / radius, 0.0, 1.0);

                float t1 = smoothstep(0.0, 0.3, t);
                float t2 = smoothstep(0.3, 0.65, t);
                float t3 = smoothstep(0.65, 1.0, t);

                float3 colorA = mix(darkColor, mediumColor, t1);
                float3 colorB = mix(lightColor, veryLightColor, t3 * 0.65);
                float3 base = mix(colorA, colorB, t2);

                float yFlipped = 1.0 - in.texCoord.y;
                float diagonal = 1.0 - clamp(((1.0 - in.texCoord.x) + yFlipped) / 1.2, 0.0, 1.0);

                float luma = dot(base, float3(0.2126, 0.7152, 0.0722));
                float3 saturated = mix(float3(luma), base, 1.18);
                float3 contrast = (saturated - 0.5) * 1.22 + 0.5;
                float shadowMask = 1.0 - smoothstep(0.18, 0.65, luma);
                base = contrast * (0.93 - shadowMask * 0.04);

                float2 noiseUV = in.texCoord * (2.0 + expansion * 0.35)
                    + float2(time * 0.06, time * 0.045);
                float grain = noise(noiseUV);

                float wave = sin((in.texCoord.x * 2.8 + in.texCoord.y * 2.2 + time * 0.22) * 3.14159);
                float sheen = smoothstep(0.18, 0.92,
                    in.texCoord.x + (1.0 - in.texCoord.y) * 0.75 + wave * 0.09
                );

                float3 hsv = float3(0.0);
                float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                float4 p = mix(float4(base.bg, K.wz), float4(base.gb, K.xy), step(base.b, base.g));
                float4 q = mix(float4(p.xyw, base.r), float4(base.r, p.yzx), step(p.x, base.r));
                float d = q.x - min(q.w, q.y);
                float e = 1e-8;
                hsv.x = abs(q.z + (q.w - q.y) / (6.0 * d + e));
                hsv.y = d / (q.x + e);
                hsv.z = q.x;

                float hueShift = (sin(time * 0.2 + in.texCoord.x * 2.8 + in.texCoord.y * 2.1) * 0.012)
                    + (transitionNoise - 0.5) * 0.008;
                hsv.x = fract(hsv.x + hueShift);

                float4 K2 = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p2 = abs(fract(hsv.xxx + K2.xyz) * 6.0 - K2.www);
                base = hsv.z * mix(K2.xxx, clamp(p2 - K2.xxx, 0.0, 1.0), hsv.y);

                float highlightMask = smoothstep(0.52, 0.92, sheen)
                    * (0.55 + 0.45 * (1.0 - t))
                    * (0.7 + 0.3 * diagonal);

                float overlayAmount = mix(0.03, 0.1, sheen) * (0.62 + diagonal * 0.4) + grain * 0.02;
                float3 overlay = overlayColor * overlayAmount;

                float warmMask = smoothstep(0.03, 0.18, base.r - max(base.g, base.b));
                float warmSheen = (0.55 + 0.45 * diagonal) * (0.65 + 0.35 * sheen);
                float3 warmBoost = float3(0.26, 0.09, 0.03) * warmMask * warmSheen;

                float zoneNoise = noise(in.texCoord * 3.1 + float2(time * 0.09, time * 0.07));
                float zoneWave = sin((in.texCoord.x * 3.2 + in.texCoord.y * 2.6 + time * 0.42) * 3.14159);
                float zonePulse = clamp(0.55 + zoneWave * 0.25 + zoneNoise * 0.35, 0.0, 1.0);

                float bloom = (1.0 - smoothstep(0.18, 0.6, dist)) * (0.04 + 0.03 * sin(time + dist * 6.0));
                bloom *= 0.7 + diagonal * 0.2;
                float3 highlightBoost = veryLightColor * (0.22 + 0.18 * diagonal) * highlightMask * (0.7 + 0.6 * zonePulse);
                float3 hdrLift = veryLightColor * bloom * (0.55 + 0.25 * zonePulse) + warmBoost + highlightBoost;

                float hdrBoost = 1.0 + (grain * 0.03) + (sheen * 0.06) + (diagonal * 0.04) + (highlightMask * 0.12) + (zonePulse * 0.08);
                float3 finalColor = base * hdrBoost + overlay + hdrLift;

                return float4(finalColor, 1.0);
            }
            """

            do {
                let library = try device.makeLibrary(source: shaderSource, options: nil)
                guard let vertexFunction = library.makeFunction(name: "vertexShader"),
                      let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
                    print("❌ Failed to create shader functions")
                    return
                }

                let pipelineDescriptor = MTLRenderPipelineDescriptor()
                pipelineDescriptor.vertexFunction = vertexFunction
                pipelineDescriptor.fragmentFunction = fragmentFunction
                pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
                pipelineDescriptor.colorAttachments[0].isBlendingEnabled = false

                self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
                print("✅ HDRAnimatedGradientView Metal pipeline created successfully")
            } catch {
                print("❌ Error creating Metal pipeline: \(error)")
            }
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let rpd = view.currentRenderPassDescriptor,
                  let pipelineState = pipelineState,
                  let commandQueue = commandQueue else {
                return
            }

            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) else {
                return
            }

            renderEncoder.setRenderPipelineState(pipelineState)

            func colorToSIMD(_ color: Color) -> SIMD3<Float> {
                let uiColor = UIColor(color)
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
                uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                return SIMD3<Float>(Float(r), Float(g), Float(b))
            }

            var fromDark = colorToSIMD(fromPalette.dark)
            var fromMedium = colorToSIMD(fromPalette.medium)
            var fromLight = colorToSIMD(fromPalette.light)
            var fromVeryLight = colorToSIMD(fromPalette.veryLight)
            var fromOverlay = colorToSIMD(fromPalette.overlay)
            var toDark = colorToSIMD(toPalette.dark)
            var toMedium = colorToSIMD(toPalette.medium)
            var toLight = colorToSIMD(toPalette.light)
            var toVeryLight = colorToSIMD(toPalette.veryLight)
            var toOverlay = colorToSIMD(toPalette.overlay)
            var centerPoint = SIMD2<Float>(Float(center.x), Float(center.y))
            var expansionValue = Float(expansion)
            var transitionValue = Float(max(0.0, min(1.0, transitionProgress)))
            let elapsed = CACurrentMediaTime() - startTime
            let cycle: Double = 24.0
            var phaseValue = Float((elapsed / cycle).truncatingRemainder(dividingBy: 1.0))

            renderEncoder.setFragmentBytes(&fromDark, length: MemoryLayout<SIMD3<Float>>.stride, index: 0)
            renderEncoder.setFragmentBytes(&fromMedium, length: MemoryLayout<SIMD3<Float>>.stride, index: 1)
            renderEncoder.setFragmentBytes(&fromLight, length: MemoryLayout<SIMD3<Float>>.stride, index: 2)
            renderEncoder.setFragmentBytes(&fromVeryLight, length: MemoryLayout<SIMD3<Float>>.stride, index: 3)
            renderEncoder.setFragmentBytes(&fromOverlay, length: MemoryLayout<SIMD3<Float>>.stride, index: 4)
            renderEncoder.setFragmentBytes(&toDark, length: MemoryLayout<SIMD3<Float>>.stride, index: 5)
            renderEncoder.setFragmentBytes(&toMedium, length: MemoryLayout<SIMD3<Float>>.stride, index: 6)
            renderEncoder.setFragmentBytes(&toLight, length: MemoryLayout<SIMD3<Float>>.stride, index: 7)
            renderEncoder.setFragmentBytes(&toVeryLight, length: MemoryLayout<SIMD3<Float>>.stride, index: 8)
            renderEncoder.setFragmentBytes(&toOverlay, length: MemoryLayout<SIMD3<Float>>.stride, index: 9)
            renderEncoder.setFragmentBytes(&centerPoint, length: MemoryLayout<SIMD2<Float>>.stride, index: 10)
            renderEncoder.setFragmentBytes(&expansionValue, length: MemoryLayout<Float>.stride, index: 11)
            renderEncoder.setFragmentBytes(&transitionValue, length: MemoryLayout<Float>.stride, index: 12)
            renderEncoder.setFragmentBytes(&phaseValue, length: MemoryLayout<Float>.stride, index: 13)

            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
