# HDR/EDR Effects - Extended Dynamic Range

## 🌟 ¿Qué es HDR/EDR en iOS?

**Extended Dynamic Range (EDR)** permite renderizar contenido con valores de luminancia que exceden el rango SDR estándar (0-1). En pantallas compatibles (iPhone 12+, iPad Pro con XDR), esto produce brillos reales más intensos.

## 📁 Componentes Implementados

### 1. HDRGlowView
**Archivo:** `HDRGlowView.swift`

Renderiza un glow radial con intensidad HDR usando Metal.

**Uso:**
```swift
HDRGlowView(
    color: .red,        // Color del glow
    intensity: 1.2,     // Intensidad HDR (>1.0 para EDR)
    radius: 0.6         // Radio del glow (0-1)
)
.frame(width: 400, height: 400)
.blur(radius: 40)       // Blur adicional para suavizar
```

**Dónde se usa:**
- `HomeView.swift`: Glow alrededor del modelo 3D que cambia de color según la categoría

**Características:**
- Usa `MTKView` con formato `rgba16Float` para soportar valores > 1.0
- Shader Metal con falloff radial suave
- Blending con alpha para overlay transparente
- Intensidad multiplicada por 2.0 para aprovechar EDR

### 2. HDRHotspotView
**Archivo:** `HDRHotspotView.swift`

Renderiza múltiples puntos brillantes (hotspots) con animación de pulsación.

**Uso:**
```swift
HDRHotspotView(
    hotspots: [
        HDRHotspotView.Hotspot(
            position: CGPoint(x: 0.85, y: 0.15),  // Posición normalizada (0-1)
            color: .orange,
            intensity: 0.8,
            radius: 0.3
        ),
        // ... más hotspots
    ],
    animate: true  // Pulsación sutil
)
.blendMode(.screen)  // Blending aditivo
```

**Dónde se usa:**
- `HomeGradientBackground.swift`: Puntos brillantes en el gradiente de fondo

**Características:**
- Múltiples hotspots acumulativos (blending aditivo)
- Animación de pulsación sincronizada
- Cada hotspot tiene su propio color, intensidad y radio
- Intensidad multiplicada por 3.0 para máximo impacto EDR

## 🎨 Cómo Funciona

### Pipeline Metal

1. **Formato de Pixel:** `rgba16Float`
   - Soporta valores de color > 1.0
   - Necesario para EDR

2. **Vertex Shader:**
   - Renderiza un quad que cubre toda la pantalla
   - Pasa coordenadas de textura (0-1) al fragment shader

3. **Fragment Shader:**
   - Calcula distancia desde el centro/hotspot
   - Aplica falloff radial con `smoothstep` y `pow`
   - Multiplica intensidad por 2-3x para EDR
   - Retorna color con valores > 1.0 en componentes RGB

4. **Blending:**
   - `HDRGlowView`: Alpha blending estándar
   - `HDRHotspotView`: Blending aditivo (acumula luz)

### Compatibilidad

- **iOS 16+**: Formato `rgba16Float` disponible
- **Pantallas HDR**: iPhone 12+, iPad Pro con XDR
- **Fallback**: En pantallas SDR, los valores > 1.0 se clampean pero el efecto sigue viéndose bien

## 🎯 Mejores Prácticas

### 1. Intensidad
- **Valores bajos (0.5-1.0)**: Glow sutil, elegante
- **Valores medios (1.0-2.0)**: Brillo notable, llamativo
- **Valores altos (2.0+)**: Destello intenso, usar con moderación

### 2. Blending
- **Alpha blending**: Para overlays suaves
- **Screen/Additive**: Para acumular luz (múltiples fuentes)

### 3. Blur
- Añadir `.blur()` después del HDRView para suavizar bordes
- Blur de 20-40 funciona bien para glows grandes

### 4. Animación
- Animar `intensity` para pulsaciones
- Animar `color` para transiciones de categoría
- Usar `.animation(.easeInOut)` para transiciones suaves

## 🚀 Ejemplos de Uso

### Glow Dinámico (HomeView)
```swift
HDRGlowView(
    color: glowColorForCategory,  // Cambia con la categoría
    intensity: 1.2,
    radius: 0.6
)
.blur(radius: 40)
.animation(.easeInOut(duration: 0.8), value: glowColorForCategory)
```

### Hotspots Animados (Background)
```swift
HDRHotspotView(
    hotspots: [
        HDRHotspotView.Hotspot(
            position: CGPoint(x: 0.85, y: 0.15),
            color: palette.light,
            intensity: 0.8,
            radius: 0.3
        )
    ],
    animate: true
)
.blendMode(.screen)
.opacity(0.6)
```

## 🔧 Personalización

### Modificar el Shader
Los shaders están inline en el código. Para modificar:

1. Localiza el string `shaderSource` en el `Coordinator`
2. Modifica el fragment shader:
   - Cambiar `pow(glow, 2.5)` para ajustar falloff
   - Cambiar multiplicador de intensidad (2.0, 3.0)
   - Añadir efectos adicionales (noise, distorsión)

### Añadir Nuevos Efectos
Crea un nuevo archivo siguiendo el patrón:
1. `UIViewRepresentable` que envuelve `MTKView`
2. `Coordinator` que implementa `MTKViewDelegate`
3. Setup de Metal con shader personalizado
4. Método `draw(in:)` que renderiza cada frame

## 📊 Performance

- **60 FPS**: Ambos efectos mantienen 60fps en dispositivos modernos
- **Overhead**: Mínimo, Metal es muy eficiente
- **Batería**: Impacto bajo, solo renderiza cuando visible

## 🎨 Ideas Futuras

- **Partículas HDR**: Chispas brillantes con física
- **Trails HDR**: Estelas luminosas que siguen gestos
- **Reflejos HDR**: Highlights especulares en botones glass
- **Bloom HDR**: Post-processing para highlights globales
