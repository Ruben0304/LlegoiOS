# Design System - LlegoiOS

Sistema de diseño completo: colores, tipografía, componentes y Atomic Design.

## Paleta de Colores

### Colores Principales

**Archivo**: `ui/theme/Theme.swift`

```swift
struct LlegoTheme {
    // Primary
    static let primaryColor = Color(red: 2/255, green: 49/255, blue: 51/255)        // #023133 Dark teal
    static let onPrimaryColor = Color.white

    // Secondary
    static let secondaryColor = Color(red: 225/255, green: 199/255, blue: 142/255) // #E1C78E Warm beige
    static let tertiaryColor = Color(red: 124/255, green: 65/255, blue: 43/255)    // #7C412B Brown

    // Background
    static let backgroundColor = Color(red: 243/255, green: 243/255, blue: 243/255) // #F3F3F3 Light gray
    static let surfaceColor = Color.white

    // Accent
    static let accentColor = Color(red: 178/255, green: 214/255, blue: 154/255)    // #B2D69A Light green
    static let buttonColor = Color(red: 90/255, green: 132/255, blue: 103/255)     // #5A8467 Green
}

extension Color {
    static let llegoPrimary = LlegoTheme.primaryColor
    static let llegoOnPrimary = LlegoTheme.onPrimaryColor
    static let llegoSecondary = LlegoTheme.secondaryColor
    static let llegoTertiary = LlegoTheme.tertiaryColor
    static let llegoBackground = LlegoTheme.backgroundColor
    static let llegoSurface = LlegoTheme.surfaceColor
    static let llegoAccent = LlegoTheme.accentColor
    static let llegoButton = LlegoTheme.buttonColor
}
```

### Uso de Colores

```swift
// Texto principal
Text("Título")
    .foregroundColor(.llegoPrimary)

// Background
Color.llegoBackground.ignoresSafeArea()

// Botón
Button("Acción") { }
    .background(Color.llegoButton)

// Accent
Circle()
    .fill(Color.llegoAccent)
```

## Tipografía

### Estilos de Texto

```swift
// Headers
Text("Header Principal")
    .font(.system(size: 28, weight: .bold, design: .rounded))
    .foregroundColor(.llegoPrimary)

// Subheaders
Text("Subheader")
    .font(.system(size: 20, weight: .semibold, design: .rounded))
    .foregroundColor(.llegoPrimary)

// Body
Text("Texto del cuerpo")
    .font(.system(size: 16, weight: .medium))
    .foregroundColor(.llegoOnBackground)

// Caption
Text("Pequeño texto")
    .font(.system(size: 14, weight: .medium))
    .foregroundColor(.gray)

// Button Text
Text("BUTTON")
    .font(.system(size: 16, weight: .semibold))
    .foregroundColor(.llegoOnPrimary)
```

## Spacing y Layout

### Corner Radius

```swift
// Large cards
.cornerRadius(18)

// Medium elements
.cornerRadius(16)

// Small elements
.cornerRadius(12)

// Buttons (pill shape)
.cornerRadius(28)
```

### Padding

```swift
// Horizontal padding
.padding(.horizontal, 20)

// Vertical padding
.padding(.vertical, 16)

// Card internal padding
.padding(20)

// Section spacing
VStack(spacing: 24) { }

// Item spacing
VStack(spacing: 12) { }
```

### Shadows

```swift
// Standard card shadow
.shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)

// Accent button shadow
.shadow(color: Color.llegoAccent.opacity(0.4), radius: 12, x: 0, y: 6)

// Elevated card
.shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 8)
```

## Atomic Design

### Estructura

```
ui/components/
├── atoms/          # Elementos básicos
├── molecules/      # Componentes compuestos
├── organisms/      # Secciones complejas
├── animations/     # Animaciones Lottie
├── skeletons/      # Loading states
├── shapes/         # Custom shapes
└── background/     # Background components
```

### Atoms (Elementos Básicos)

**Ubicación**: `ui/components/atoms/`

#### CategoryChip

```swift
struct CategoryChip: View {
    let category: String
    let isSelected: Bool

    var body: some View {
        Text(category)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(isSelected ? .white : .llegoPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.llegoPrimary : Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
```

#### LottieView (Loading Indicator)

```swift
import Lottie

struct LottieView: View {
    let name: String
    var loopMode: LottieLoopMode = .loop
    var speed: CGFloat = 1.0

    var body: some View {
        LottieView(animation: .named(name))
            .looping()
            .playbackSpeed(speed)
    }
}

// Uso
LottieView(name: "loading")
    .frame(width: 150, height: 150)
```

### Molecules (Componentes Compuestos)

**Ubicación**: `ui/components/molecules/`

#### ProductCard

```swift
struct ProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            AsyncImage(url: URL(string: product.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(height: 160)
            .clipped()
            .cornerRadius(12)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.llegoPrimary)
                    .lineLimit(2)

                Text(product.weight)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)

                Text(product.price)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.llegoAccent)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}
```

#### StoreCard

```swift
struct StoreCard: View {
    let store: Store

    var body: some View {
        HStack(spacing: 16) {
            // Logo
            AsyncImage(url: URL(string: store.logoUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(store.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.llegoPrimary)

                Text(store.address)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)

                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text("\(store.etaMinutes) min")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.llegoAccent)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}
```

### Organisms (Secciones Complejas)

**Ubicación**: `ui/components/organisms/`

#### ProductSection

```swift
struct ProductSection: View {
    let products: [Product]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Productos Destacados")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)

                Spacer()

                Button("Ver todo") {
                    // Navigation
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.llegoAccent)
            }
            .padding(.horizontal, 20)

            // Products Grid
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(products) { product in
                        ProductCard(product: product)
                            .frame(width: 180)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
```

#### Model3DCarousel

```swift
struct Model3DCarousel: View {
    let models: [String]
    @State private var selectedIndex = 0

    var body: some View {
        VStack(spacing: 20) {
            // 3D Model Display
            TabView(selection: $selectedIndex) {
                ForEach(models.indices, id: \.self) { index in
                    Animated3DModelView(modelName: models[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 300)

            // Indicators
            HStack(spacing: 8) {
                ForEach(models.indices, id: \.self) { index in
                    Circle()
                        .fill(index == selectedIndex ? Color.llegoPrimary : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding()
        .background(Color.llegoSurface)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}
```

## Animaciones

### Spring Animations

```swift
.animation(.spring(response: 0.6, dampingFraction: 0.8), value: isSelected)
```

### Easing

```swift
withAnimation(.easeInOut(duration: 0.3)) {
    // State changes
}
```

### Staggered Lists

```swift
ForEach(items.indices, id: \.self) { index in
    ItemView(item: items[index])
        .animation(
            .easeInOut(duration: 0.3).delay(Double(index) * 0.1),
            value: isVisible
        )
}
```

## Custom Shapes

**Ubicación**: `ui/theme/shapes/` y `ui/components/shapes/`

### CurvedBottomShape

```swift
struct CurvedBottomShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: rect.height - 50))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.height - 50),
            control: CGPoint(x: rect.width / 2, y: rect.height + 20)
        )
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.closeSubpath()
        return path
    }
}
```

## Loading States

### ✅ USAR: LottieView

```swift
// Loading
VStack(spacing: 20) {
    LottieView(name: "loading")
        .frame(width: 150, height: 150)

    Text("Cargando...")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.gray)
}
```

### ❌ NO USAR: ProgressView

```swift
// NO usar esto
ProgressView()
    .scaleEffect(1.5)
```

## Skeletons

**Ubicación**: `ui/components/skeletons/`

### ProductCardSkeleton

```swift
struct ProductCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 160)
                .cornerRadius(12)
                .shimmer(isAnimating: isAnimating)

            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 16)
                    .cornerRadius(4)

                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 14)
                    .cornerRadius(4)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .onAppear {
            isAnimating = true
        }
    }
}
```

## Best Practices

### ✅ DO

- Usar colores del theme (`.llegoPrimary`, `.llegoAccent`, etc.)
- Aplicar corner radius consistente (12, 16, 18)
- Usar shadows estándar (`.shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)`)
- Usar `LottieView` para loading states
- Seguir Atomic Design (atoms → molecules → organisms)
- Reutilizar componentes existentes

### ❌ DON'T

- Hardcodear colores (`Color.red`, `Color.blue`)
- Usar `ProgressView` nativo para loading
- Crear componentes duplicados
- Ignorar spacing guidelines
- Usar corner radius inconsistente

## Referencia Rápida

### Colores

```swift
.llegoPrimary       // #023133 Dark teal
.llegoSecondary     // #E1C78E Warm beige
.llegoTertiary      // #7C412B Brown
.llegoAccent        // #B2D69A Light green
.llegoBackground    // #F3F3F3 Light gray
.llegoSurface       // #FFFFFF White
.llegoButton        // #5A8467 Green
```

### Typography

```swift
.font(.system(size: 28, weight: .bold, design: .rounded))   // Header
.font(.system(size: 20, weight: .semibold, design: .rounded)) // Subheader
.font(.system(size: 16, weight: .medium))                    // Body
.font(.system(size: 14, weight: .medium))                    // Caption
```

### Spacing

```swift
.padding(.horizontal, 20)  // Screen horizontal padding
.padding(.vertical, 16)    // Screen vertical padding
VStack(spacing: 24) { }    // Section spacing
VStack(spacing: 12) { }    // Item spacing
```

### Corner Radius

```swift
.cornerRadius(18)  // Large cards
.cornerRadius(16)  // Medium elements
.cornerRadius(12)  // Small elements
.cornerRadius(28)  // Pill buttons
```
