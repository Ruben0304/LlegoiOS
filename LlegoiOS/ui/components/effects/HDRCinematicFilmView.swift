import SwiftUI
import MetalKit
import QuartzCore

struct HDRCinematicFilmPalette {
    let deep: Color
    let mid: Color
    let bright: Color
    let flare: Color
    let frame: Color
}

extension HDRCinematicFilmPalette {
    static let emerald = HDRCinematicFilmPalette(
        deep: Color(red: 0.01, green: 0.08, blue: 0.05),
        mid: Color(red: 0.06, green: 0.28, blue: 0.17),
        bright: Color(red: 0.18, green: 0.74, blue: 0.42),
        flare: Color(red: 0.4, green: 1.0, blue: 0.65),
        frame: Color(red: 0.01, green: 0.04, blue: 0.03)
    )
}

struct HDRCinematicFilmView: View {
    let palette: HDRCinematicFilmPalette
    let progress: CGFloat
    let hdrScale: CGFloat

    init(palette: HDRCinematicFilmPalette, progress: CGFloat, hdrScale: CGFloat = 1.0) {
        self.palette = palette
        self.progress = progress
        self.hdrScale = hdrScale
    }

    var body: some View {
        MetalCinematicFilmRepresentable(palette: palette, progress: progress, hdrScale: hdrScale)
            .allowsHitTesting(false)
    }
}

private struct MetalCinematicFilmRepresentable: UIViewRepresentable {
    let palette: HDRCinematicFilmPalette
    let progress: CGFloat
    let hdrScale: CGFloat

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()

        guard let device = MTLCreateSystemDefaultDevice() else {
            print("❌ Metal is not supported on this device")
            return mtkView
        }

        mtkView.device = device
        mtkView.delegate = context.coordinator
        mtkView.backgroundColor = UIColor.clear
        mtkView.isOpaque = false
        mtkView.framebufferOnly = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false

        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)

        if #available(iOS 16.0, *) {
            mtkView.colorPixelFormat = .rgba16Float
            mtkView.preferredFramesPerSecond = 120
        } else {
            mtkView.colorPixelFormat = .bgra8Unorm
            mtkView.preferredFramesPerSecond = 120
        }

        context.coordinator.setupMetal(device: device, pixelFormat: mtkView.colorPixelFormat)

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.palette = palette
        context.coordinator.progress = progress
        context.coordinator.hdrScale = hdrScale
        let shouldPause = progress >= 1.0
        uiView.isPaused = shouldPause
        uiView.enableSetNeedsDisplay = shouldPause
        if shouldPause {
            uiView.setNeedsDisplay()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(palette: palette, progress: progress, hdrScale: hdrScale)
    }

    final class Coordinator: NSObject, MTKViewDelegate {
        var device: MTLDevice?
        var commandQueue: MTLCommandQueue?
        var pipelineState: MTLRenderPipelineState?

        var palette: HDRCinematicFilmPalette
        var progress: CGFloat
        var hdrScale: CGFloat
        let startTime: CFTimeInterval

        init(palette: HDRCinematicFilmPalette, progress: CGFloat, hdrScale: CGFloat) {
            self.palette = palette
            self.progress = progress
            self.hdrScale = hdrScale
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
                constant float &time [[buffer(0)]],
                constant float2 &resolution [[buffer(1)]],
                constant float3 &deepColor [[buffer(2)]],
                constant float3 &midColor [[buffer(3)]],
                constant float3 &brightColor [[buffer(4)]],
                constant float3 &flareColor [[buffer(5)]],
                constant float3 &frameColor [[buffer(6)]],
                constant float &progress [[buffer(7)]],
                constant float &hdrScale [[buffer(8)]]
            ) {
                float2 uv = in.texCoord;
                float2 centered = uv - 0.5;
                float aspect = resolution.x / max(resolution.y, 1.0);
                centered.x *= aspect;

                float life = smoothstep(0.0, 0.2, progress);

                float2 driftA = float2(
                    sin(time * 0.14 + uv.y * 3.4),
                    cos(time * 0.12 + uv.x * 2.9)
                ) * 0.06;
                float2 driftB = float2(
                    cos(time * 0.09 + uv.y * 2.2),
                    sin(time * 0.16 + uv.x * 3.1)
                ) * 0.04;
                float2 uvFlow = uv + driftA + driftB * 0.7;

                float revealNoise = noise(uvFlow * 2.4 + time * 0.08);
                float reveal = smoothstep(0.15, 0.9, revealNoise + progress * 0.85);
                float sweep = smoothstep(-0.15, 1.2, uv.x * 0.65 + uv.y * 0.55 + progress * 1.2 - 0.35);
                float filmIntensity = clamp(life * reveal * sweep, 0.0, 1.0);
                filmIntensity = smoothstep(0.0, 0.8, filmIntensity);

                float jitterX = sin(time * 8.5 + uv.y * 30.0) * 0.003 * filmIntensity;
                float jitterY = cos(time * 6.8 + uv.x * 28.0) * 0.0025 * filmIntensity;
                uvFlow += float2(jitterX, jitterY);

                float vertical = smoothstep(0.0, 1.0, uvFlow.y);
                float diagonal = smoothstep(0.0, 1.0, uvFlow.x * 0.65 + uvFlow.y * 0.35);
                float3 base = mix(deepColor, midColor, vertical);
                base = mix(base, brightColor, diagonal * 0.65);

                float vignette = smoothstep(0.25, 0.95, length(centered));
                base *= 0.9 - vignette * 0.25;

                float wave = sin((uvFlow.x * 2.4 + uvFlow.y * 1.7 + time * 0.45) * 3.14159);
                float swirl = noise(uvFlow * 3.4 + time * 0.18);
                float energy = clamp(0.45 + 0.55 * wave + swirl * 0.7, 0.0, 1.0);

                float3 energyColor = mix(midColor, brightColor, smoothstep(0.35, 0.9, energy));
                float hdrPulse = 0.7 + 0.3 * sin(time * 0.9 + uvFlow.x * 2.0);

                float ribbon = smoothstep(0.0, 0.22, 0.22 - abs(uvFlow.y - (0.5 + sin(time * 0.35 + uvFlow.x * 4.0) * 0.12)));
                float ribbonTwo = smoothstep(0.0, 0.25, 0.25 - abs(uvFlow.y - (0.34 + cos(time * 0.28 + uvFlow.x * 3.2) * 0.1)));
                float ribbonMix = max(ribbon, ribbonTwo);
                float3 ribbonColor = flareColor * ribbonMix * (1.2 + 0.6 * sin(time * 0.6));

                float topBar = smoothstep(0.0, 0.1, uvFlow.y);
                float bottomBar = smoothstep(0.0, 0.1, 1.0 - uvFlow.y);
                float bars = topBar * bottomBar;
                float frameMix = mix(1.0, bars, filmIntensity);
                base = mix(frameColor, base, frameMix);

                float scan = 0.985 + 0.015 * sin((uvFlow.y * resolution.y * 1.2) + time * 8.0);
                float glow = smoothstep(0.85, 0.0, length(centered));
                float hdrBoost = mix(1.2, 3.0, smoothstep(0.2, 0.7, progress)) * hdrScale;
                float3 hdrGlow = brightColor * glow * hdrBoost * 0.35;

                float grain = noise(uvFlow * resolution * 0.6 + time * 12.0);
                float grainMix = (grain - 0.5) * 0.05;

                float spectrumMix = 0.35 + 0.35 * sin(time * 0.5 + uvFlow.y * 2.4);
                float3 spectrum = mix(energyColor, flareColor, spectrumMix);
                float3 film = base * scan + (spectrum * hdrPulse + ribbonColor) * hdrBoost + hdrGlow;
                float3 finalColor = film * (0.35 + 0.65 * filmIntensity);
                finalColor += brightColor * 0.08 * filmIntensity;
                finalColor += grainMix * filmIntensity;
                finalColor = max(finalColor, float3(0.0));

                return float4(finalColor, filmIntensity);
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
                pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
                pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
                pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
                pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
                pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add

                self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
                print("✅ HDRCinematicFilmView Metal pipeline created successfully")
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

            var timeValue = Float(CACurrentMediaTime() - startTime)
            var resolution = SIMD2<Float>(Float(max(view.drawableSize.width, 1)), Float(max(view.drawableSize.height, 1)))
            var deepColor = colorToSIMD(palette.deep)
            var midColor = colorToSIMD(palette.mid)
            var brightColor = colorToSIMD(palette.bright)
            var flareColor = colorToSIMD(palette.flare)
            var frameColor = colorToSIMD(palette.frame)
            var progressValue = Float(max(0.0, min(1.0, progress)))
            var hdrScaleValue = Float(max(0.1, min(1.0, hdrScale)))

            renderEncoder.setFragmentBytes(&timeValue, length: MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.stride, index: 1)
            renderEncoder.setFragmentBytes(&deepColor, length: MemoryLayout<SIMD3<Float>>.stride, index: 2)
            renderEncoder.setFragmentBytes(&midColor, length: MemoryLayout<SIMD3<Float>>.stride, index: 3)
            renderEncoder.setFragmentBytes(&brightColor, length: MemoryLayout<SIMD3<Float>>.stride, index: 4)
            renderEncoder.setFragmentBytes(&flareColor, length: MemoryLayout<SIMD3<Float>>.stride, index: 5)
            renderEncoder.setFragmentBytes(&frameColor, length: MemoryLayout<SIMD3<Float>>.stride, index: 6)
            renderEncoder.setFragmentBytes(&progressValue, length: MemoryLayout<Float>.stride, index: 7)
            renderEncoder.setFragmentBytes(&hdrScaleValue, length: MemoryLayout<Float>.stride, index: 8)

            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
