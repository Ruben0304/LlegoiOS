import SwiftUI
import MetalKit

/// Vista HDR con acabado metálico para tarjetas premium
/// Simula reflejos metálicos dinámicos con anisotropía
struct HDRMetallicCardView: View {
    let baseColor: Color
    let metallicIntensity: CGFloat
    let roughness: CGFloat
    
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        MetalMetallicRepresentable(
            baseColor: baseColor,
            metallicIntensity: metallicIntensity,
            roughness: roughness,
            animationPhase: animationPhase
        )
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
                animationPhase = 1.0
            }
        }
    }
}

private struct MetalMetallicRepresentable: UIViewRepresentable {
    let baseColor: Color
    let metallicIntensity: CGFloat
    let roughness: CGFloat
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
        context.coordinator.baseColor = baseColor
        context.coordinator.metallicIntensity = metallicIntensity
        context.coordinator.roughness = roughness
        context.coordinator.animationPhase = animationPhase
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            baseColor: baseColor,
            metallicIntensity: metallicIntensity,
            roughness: roughness,
            animationPhase: animationPhase
        )
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var device: MTLDevice?
        var commandQueue: MTLCommandQueue?
        var pipelineState: MTLRenderPipelineState?
        
        var baseColor: Color
        var metallicIntensity: CGFloat
        var roughness: CGFloat
        var animationPhase: CGFloat
        
        init(baseColor: Color, metallicIntensity: CGFloat, roughness: CGFloat, animationPhase: CGFloat) {
            self.baseColor = baseColor
            self.metallicIntensity = metallicIntensity
            self.roughness = roughness
            self.animationPhase = animationPhase
        }
        
        func setupMetal(device: MTLDevice, pixelFormat: MTLPixelFormat) {
            self.device = device
            self.commandQueue = device.makeCommandQueue()
            
            // Shader avanzado para simular superficie metálica con PBR simplificado
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
            
            // Función de Fresnel simplificada
            float fresnel(float3 viewDir, float3 normal, float f0) {
                float cosTheta = max(dot(viewDir, normal), 0.0);
                return f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0);
            }
            
            // Distribución GGX simplificada para especular
            float ggxDistribution(float3 normal, float3 halfVector, float roughness) {
                float a = roughness * roughness;
                float a2 = a * a;
                float NdotH = max(dot(normal, halfVector), 0.0);
                float NdotH2 = NdotH * NdotH;
                
                float denom = (NdotH2 * (a2 - 1.0) + 1.0);
                denom = 3.14159265 * denom * denom;
                
                return a2 / max(denom, 0.001);
            }
            
            // Ruido procedural para variación de superficie
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
            
            fragment float4 fragmentShader(VertexOut in [[stage_in]],
                                          constant float3 &baseColor [[buffer(0)]],
                                          constant float &metallic [[buffer(1)]],
                                          constant float &roughness [[buffer(2)]],
                                          constant float &animPhase [[buffer(3)]]) {
                // Coordenadas centradas
                float2 uv = in.texCoord;
                float2 centeredUV = uv - 0.5;
                
                // Normal de superficie (ligeramente perturbada)
                float noiseVal = noise(uv * 20.0 + animPhase * 0.5) * 0.1;
                float3 normal = normalize(float3(noiseVal, noiseVal, 1.0));
                
                // Dirección de vista (simulada)
                float3 viewDir = normalize(float3(centeredUV.x * 0.5, centeredUV.y * 0.5, 1.0));
                
                // Múltiples fuentes de luz para simular ambiente
                float3 lightDir1 = normalize(float3(0.5 + sin(animPhase * 6.28) * 0.3, 0.3, 1.0));
                float3 lightDir2 = normalize(float3(-0.5, 0.5, 0.8));
                float3 lightDir3 = normalize(float3(0.0, -0.3, 0.9));
                
                // Colores de luz (HDR)
                float3 lightColor1 = float3(1.5, 1.5, 1.8); // Luz principal fría
                float3 lightColor2 = float3(1.2, 1.3, 1.4); // Luz de relleno
                float3 lightColor3 = float3(0.8, 0.9, 1.0); // Luz ambiental
                
                // Cálculo de especular para cada luz
                float3 specular = float3(0.0);
                
                // Luz 1
                float3 halfVector1 = normalize(lightDir1 + viewDir);
                float spec1 = ggxDistribution(normal, halfVector1, roughness);
                specular += lightColor1 * spec1 * metallic;
                
                // Luz 2
                float3 halfVector2 = normalize(lightDir2 + viewDir);
                float spec2 = ggxDistribution(normal, halfVector2, roughness);
                specular += lightColor2 * spec2 * metallic * 0.6;
                
                // Luz 3
                float3 halfVector3 = normalize(lightDir3 + viewDir);
                float spec3 = ggxDistribution(normal, halfVector3, roughness);
                specular += lightColor3 * spec3 * metallic * 0.4;
                
                // Fresnel para reflejos en los bordes
                float fresnelFactor = fresnel(viewDir, normal, 0.04);
                
                // Reflexión ambiental (simulada con gradiente)
                float envReflection = smoothstep(0.3, 0.7, uv.y) * metallic;
                float3 envColor = float3(0.8, 0.9, 1.2) * envReflection * fresnelFactor;
                
                // Anisotropía (líneas horizontales sutiles)
                float aniso = abs(sin(uv.y * 100.0 + animPhase * 2.0)) * 0.05 * metallic;
                
                // Combinar todo
                float3 diffuse = baseColor * (1.0 - metallic * 0.8);
                float3 finalColor = diffuse + specular + envColor + aniso;
                
                // Variación de brillo en los bordes
                float edgeGlow = smoothstep(0.9, 1.0, length(centeredUV * 2.0)) * metallic * 0.5;
                finalColor += edgeGlow;
                
                // Alpha suave en los bordes
                float alpha = 1.0 - smoothstep(0.4, 0.5, length(centeredUV));
                alpha = mix(0.3, 1.0, alpha);
                
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
                
                // Blending para overlay metálico
                pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
                pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
                pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
                pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
                pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
                
                self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
                print("✅ HDRMetallicCardView Metal pipeline created successfully")
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
            
            // Convertir parámetros
            let uiColor = UIColor(baseColor)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
            uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            
            var color = SIMD3<Float>(Float(r), Float(g), Float(b))
            var metallic = Float(metallicIntensity)
            var rough = Float(roughness)
            var animPhase = Float(animationPhase)
            
            renderEncoder.setFragmentBytes(&color, length: MemoryLayout<SIMD3<Float>>.stride, index: 0)
            renderEncoder.setFragmentBytes(&metallic, length: MemoryLayout<Float>.stride, index: 1)
            renderEncoder.setFragmentBytes(&rough, length: MemoryLayout<Float>.stride, index: 2)
            renderEncoder.setFragmentBytes(&animPhase, length: MemoryLayout<Float>.stride, index: 3)
            
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        VStack(spacing: 40) {
            // Tarjeta azul metálica
            HDRMetallicCardView(
                baseColor: Color(red: 0.2, green: 0.4, blue: 0.8),
                metallicIntensity: 0.9,
                roughness: 0.2
            )
            .frame(width: 350, height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            
            // Tarjeta dorada metálica
            HDRMetallicCardView(
                baseColor: Color(red: 0.8, green: 0.6, blue: 0.2),
                metallicIntensity: 0.95,
                roughness: 0.15
            )
            .frame(width: 350, height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
    .ignoresSafeArea()
}
