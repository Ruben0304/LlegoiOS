import SwiftUI
import MetalKit

/// Vista HDR que renderiza hotspots (puntos brillantes) con Extended Dynamic Range
/// Usado para añadir puntos de luz brillante en gradientes
struct HDRHotspotView: View {
    let hotspots: [Hotspot]
    let animate: Bool
    
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        MetalHotspotRepresentable(hotspots: hotspots, animationPhase: animationPhase)
            .allowsHitTesting(false)
            .onAppear {
                if animate {
                    withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                        animationPhase = 1.0
                    }
                }
            }
    }
    
    struct Hotspot {
        let position: CGPoint // Normalizado 0-1
        let color: Color
        let intensity: CGFloat
        let radius: CGFloat
    }
}

/// UIViewRepresentable que envuelve MTKView para renderizar hotspots HDR
private struct MetalHotspotRepresentable: UIViewRepresentable {
    let hotspots: [HDRHotspotView.Hotspot]
    let animationPhase: CGFloat
    
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
        
        // Configurar clear color para currentRenderPassDescriptor
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        // Configuración EDR
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
        context.coordinator.hotspots = hotspots
        context.coordinator.animationPhase = animationPhase
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(hotspots: hotspots, animationPhase: animationPhase)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var device: MTLDevice?
        var commandQueue: MTLCommandQueue?
        var pipelineState: MTLRenderPipelineState?
        
        var hotspots: [HDRHotspotView.Hotspot]
        var animationPhase: CGFloat
        
        init(hotspots: [HDRHotspotView.Hotspot], animationPhase: CGFloat) {
            self.hotspots = hotspots
            self.animationPhase = animationPhase
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
            
            struct Hotspot {
                float2 position;
                float3 color;
                float intensity;
                float radius;
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
            
            fragment float4 fragmentShader(VertexOut in [[stage_in]],
                                          constant Hotspot *hotspots [[buffer(0)]],
                                          constant int &hotspotCount [[buffer(1)]],
                                          constant float &animPhase [[buffer(2)]]) {
                float3 finalColor = float3(0.0);
                float totalAlpha = 0.0;
                
                // Acumular contribución de cada hotspot
                for (int i = 0; i < hotspotCount; i++) {
                    Hotspot spot = hotspots[i];
                    
                    // Animación sutil de pulsación
                    float pulse = 1.0 + sin(animPhase * 6.28318 + float(i) * 2.0) * 0.15;
                    
                    // Distancia desde el hotspot
                    float dist = distance(in.texCoord, spot.position);
                    
                    // Glow con falloff suave
                    float glow = 1.0 - smoothstep(0.0, spot.radius, dist);
                    glow = pow(glow, 3.0); // Falloff pronunciado
                    
                    // Aplicar intensidad HDR con pulsación
                    float hdrIntensity = spot.intensity * 3.0 * pulse; // Multiplicador EDR
                    float3 contribution = spot.color * glow * hdrIntensity;
                    
                    finalColor += contribution;
                    totalAlpha += glow * 0.6;
                }
                
                // Clamp alpha pero no el color (para EDR)
                totalAlpha = clamp(totalAlpha, 0.0, 1.0);
                
                return float4(finalColor, totalAlpha);
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
                
                // Blending aditivo para acumular luz
                pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
                pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
                pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
                pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
                pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
                pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
                pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
                
                self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
                print("✅ HDRHotspotView Metal pipeline created successfully")
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
                  !hotspots.isEmpty else {
                return
            }
            
            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) else {
                return
            }
            
            renderEncoder.setRenderPipelineState(pipelineState)
            
            // Convertir hotspots a formato Metal con SIMD3
            struct MetalHotspot {
                var position: SIMD2<Float>
                var color: SIMD3<Float>
                var intensity: Float
                var radius: Float
            }
            
            var metalHotspots = hotspots.map { spot -> MetalHotspot in
                let uiColor = UIColor(spot.color)
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
                uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                
                return MetalHotspot(
                    position: SIMD2<Float>(Float(spot.position.x), Float(spot.position.y)),
                    color: SIMD3<Float>(Float(r), Float(g), Float(b)),
                    intensity: Float(spot.intensity),
                    radius: Float(spot.radius)
                )
            }
            
            var hotspotCount = Int32(hotspots.count)
            var animPhase = Float(animationPhase)
            
            renderEncoder.setFragmentBytes(&metalHotspots, length: MemoryLayout<MetalHotspot>.stride * hotspots.count, index: 0)
            renderEncoder.setFragmentBytes(&hotspotCount, length: MemoryLayout<Int32>.stride, index: 1)
            renderEncoder.setFragmentBytes(&animPhase, length: MemoryLayout<Float>.stride, index: 2)
            
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
