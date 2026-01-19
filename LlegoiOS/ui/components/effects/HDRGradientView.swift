import SwiftUI
import MetalKit

/// Gradiente HDR que renderiza con valores de luminancia extendidos
/// Permite tener zonas del gradiente con brillo > 1.0 (HDR real)
struct HDRGradientView: View {
    let colors: [HDRColor]
    let locations: [Float]
    let center: CGPoint
    let startRadius: CGFloat
    let endRadius: CGFloat
    let type: GradientType
    
    enum GradientType {
        case radial
        case linear(startPoint: CGPoint, endPoint: CGPoint)
    }
    
    struct HDRColor {
        let color: Color
        let intensity: Float  // 1.0 = SDR normal, >1.0 = HDR brillante
    }
    
    var body: some View {
        MetalHDRGradientRepresentable(
            colors: colors,
            locations: locations,
            center: center,
            startRadius: startRadius,
            endRadius: endRadius,
            type: type
        )
        .allowsHitTesting(false)
    }
}

private struct MetalHDRGradientRepresentable: UIViewRepresentable {
    let colors: [HDRGradientView.HDRColor]
    let locations: [Float]
    let center: CGPoint
    let startRadius: CGFloat
    let endRadius: CGFloat
    let type: HDRGradientView.GradientType
    
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
            mtkView.preferredFramesPerSecond = 60
        } else {
            mtkView.colorPixelFormat = .bgra8Unorm
        }
        
        context.coordinator.setupMetal(device: device, pixelFormat: mtkView.colorPixelFormat)
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.colors = colors
        context.coordinator.locations = locations
        context.coordinator.center = center
        context.coordinator.startRadius = startRadius
        context.coordinator.endRadius = endRadius
        context.coordinator.type = type
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(colors: colors, locations: locations, center: center, startRadius: startRadius, endRadius: endRadius, type: type)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var device: MTLDevice?
        var commandQueue: MTLCommandQueue?
        var pipelineState: MTLRenderPipelineState?
        
        var colors: [HDRGradientView.HDRColor]
        var locations: [Float]
        var center: CGPoint
        var startRadius: CGFloat
        var endRadius: CGFloat
        var type: HDRGradientView.GradientType
        
        init(colors: [HDRGradientView.HDRColor], locations: [Float], center: CGPoint, startRadius: CGFloat, endRadius: CGFloat, type: HDRGradientView.GradientType) {
            self.colors = colors
            self.locations = locations
            self.center = center
            self.startRadius = startRadius
            self.endRadius = endRadius
            self.type = type
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
            
            struct ColorStop {
                float3 color;
                float intensity;
                float location;
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
            
            // Interpolación suave entre color stops
            float3 interpolateColor(float t, constant ColorStop *stops, int stopCount) {
                if (t <= stops[0].location) {
                    return stops[0].color * stops[0].intensity;
                }
                if (t >= stops[stopCount - 1].location) {
                    return stops[stopCount - 1].color * stops[stopCount - 1].intensity;
                }
                
                for (int i = 0; i < stopCount - 1; i++) {
                    if (t >= stops[i].location && t <= stops[i + 1].location) {
                        float localT = (t - stops[i].location) / (stops[i + 1].location - stops[i].location);
                        localT = smoothstep(0.0, 1.0, localT); // Suavizado
                        
                        float3 color1 = stops[i].color * stops[i].intensity;
                        float3 color2 = stops[i + 1].color * stops[i + 1].intensity;
                        
                        return mix(color1, color2, localT);
                    }
                }
                
                return stops[0].color * stops[0].intensity;
            }
            
            fragment float4 fragmentShader(VertexOut in [[stage_in]],
                                          constant ColorStop *colorStops [[buffer(0)]],
                                          constant int &stopCount [[buffer(1)]],
                                          constant float2 &center [[buffer(2)]],
                                          constant int &gradientType [[buffer(3)]],
                                          constant float &startRadius [[buffer(4)]],
                                          constant float &endRadius [[buffer(5)]]) {
                float t;
                
                if (gradientType == 0) {
                    // Radial gradient - replicar comportamiento de SwiftUI
                    // Calcular distancia en píxeles (aproximado)
                    float2 viewSize = float2(1.0, 1.0); // Normalizado
                    float2 delta = (in.texCoord - center) * viewSize;
                    float dist = length(delta) * 1000.0; // Escalar a "píxeles"
                    
                    // Mapear distancia a t usando startRadius y endRadius
                    t = clamp((dist - startRadius) / (endRadius - startRadius), 0.0, 1.0);
                } else {
                    // Linear gradient (simplificado: top-left to bottom-right)
                    t = (in.texCoord.x + in.texCoord.y) * 0.5;
                }
                
                float3 finalColor = interpolateColor(t, colorStops, stopCount);
                
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
                print("✅ HDRGradientView Metal pipeline created successfully")
            } catch {
                print("❌ Error creating Metal pipeline: \(error)")
            }
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let rpd = view.currentRenderPassDescriptor,
                  let pipelineState = pipelineState,
                  let commandQueue = commandQueue,
                  !colors.isEmpty else {
                return
            }
            
            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) else {
                return
            }
            
            renderEncoder.setRenderPipelineState(pipelineState)
            
            // Convertir color stops a formato Metal
            struct MetalColorStop {
                var color: SIMD3<Float>
                var intensity: Float
                var location: Float
            }
            
            var metalStops = zip(colors, locations).map { (hdrColor, location) -> MetalColorStop in
                let uiColor = UIColor(hdrColor.color)
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
                uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                
                return MetalColorStop(
                    color: SIMD3<Float>(Float(r), Float(g), Float(b)),
                    intensity: hdrColor.intensity,
                    location: location
                )
            }
            
            var stopCount = Int32(colors.count)
            var centerPoint = SIMD2<Float>(Float(center.x), Float(center.y))
            var startRad = Float(startRadius)
            var endRad = Float(endRadius)
            var gradientType: Int32 = 0 // 0 = radial, 1 = linear
            
            switch type {
            case .radial:
                gradientType = 0
            case .linear:
                gradientType = 1
            }
            
            renderEncoder.setFragmentBytes(&metalStops, length: MemoryLayout<MetalColorStop>.stride * colors.count, index: 0)
            renderEncoder.setFragmentBytes(&stopCount, length: MemoryLayout<Int32>.stride, index: 1)
            renderEncoder.setFragmentBytes(&centerPoint, length: MemoryLayout<SIMD2<Float>>.stride, index: 2)
            renderEncoder.setFragmentBytes(&gradientType, length: MemoryLayout<Int32>.stride, index: 3)
            renderEncoder.setFragmentBytes(&startRad, length: MemoryLayout<Float>.stride, index: 4)
            renderEncoder.setFragmentBytes(&endRad, length: MemoryLayout<Float>.stride, index: 5)
            
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
