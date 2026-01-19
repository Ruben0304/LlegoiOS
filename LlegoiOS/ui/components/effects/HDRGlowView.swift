import SwiftUI
import MetalKit

/// Vista HDR que renderiza un glow con Extended Dynamic Range
/// Usado para efectos de brillo intenso que aprovechan pantallas HDR
struct HDRGlowView: View {
    let color: Color
    let intensity: CGFloat
    let radius: CGFloat
    
    var body: some View {
        MetalGlowRepresentable(color: color, intensity: intensity, radius: radius)
            .allowsHitTesting(false)
    }
}

/// UIViewRepresentable que envuelve MTKView para renderizar glow HDR
private struct MetalGlowRepresentable: UIViewRepresentable {
    let color: Color
    let intensity: CGFloat
    let radius: CGFloat
    
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
        
        // Configuración EDR (Extended Dynamic Range)
        if #available(iOS 16.0, *) {
            mtkView.colorPixelFormat = .rgba16Float // Formato que soporta valores > 1.0
            mtkView.preferredFramesPerSecond = 60
        } else {
            mtkView.colorPixelFormat = .bgra8Unorm // Fallback para iOS < 16
        }
        
        context.coordinator.setupMetal(device: device, pixelFormat: mtkView.colorPixelFormat)
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.color = color
        context.coordinator.intensity = intensity
        context.coordinator.radius = radius
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(color: color, intensity: intensity, radius: radius)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var device: MTLDevice?
        var commandQueue: MTLCommandQueue?
        var pipelineState: MTLRenderPipelineState?
        
        var color: Color
        var intensity: CGFloat
        var radius: CGFloat
        
        init(color: Color, intensity: CGFloat, radius: CGFloat) {
            self.color = color
            self.intensity = intensity
            self.radius = radius
        }
        
        func setupMetal(device: MTLDevice, pixelFormat: MTLPixelFormat) {
            self.device = device
            self.commandQueue = device.makeCommandQueue()
            
            // Shader source - renderiza un glow radial con valores HDR
            let shaderSource = """
            #include <metal_stdlib>
            using namespace metal;
            
            struct VertexOut {
                float4 position [[position]];
                float2 texCoord;
            };
            
            vertex VertexOut vertexShader(uint vertexID [[vertex_id]]) {
                // Quad que cubre toda la pantalla
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
                                          constant float3 &glowColor [[buffer(0)]],
                                          constant float &intensity [[buffer(1)]],
                                          constant float &radius [[buffer(2)]]) {
                // Distancia desde el centro
                float2 center = float2(0.5, 0.5);
                float dist = distance(in.texCoord, center);
                
                // Glow radial con falloff suave usando radius
                float glow = 1.0 - smoothstep(0.0, radius, dist);
                glow = pow(glow, 2.5); // Falloff más pronunciado
                
                // Aplicar intensidad HDR (valores > 1.0 para EDR)
                float hdrIntensity = intensity * 2.0; // Multiplicador para EDR
                float3 finalColor = glowColor * glow * hdrIntensity;
                
                // Alpha basado en el glow
                float alpha = glow * 0.8;
                
                return float4(finalColor, alpha);
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
                
                // Blending para overlay
                pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
                pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
                pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
                pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
                pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
                
                self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
                print("✅ HDRGlowView Metal pipeline created successfully")
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
            
            // Convertir color a SIMD3<Float> (memoria contigua segura)
            let uiColor = UIColor(color)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
            uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            
            var glowColor = SIMD3<Float>(Float(r), Float(g), Float(b))
            var intensityValue = Float(intensity)
            var radiusValue = Float(radius)
            
            renderEncoder.setFragmentBytes(&glowColor, length: MemoryLayout<SIMD3<Float>>.stride, index: 0)
            renderEncoder.setFragmentBytes(&intensityValue, length: MemoryLayout<Float>.stride, index: 1)
            renderEncoder.setFragmentBytes(&radiusValue, length: MemoryLayout<Float>.stride, index: 2)
            
            // Dibujar quad
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
