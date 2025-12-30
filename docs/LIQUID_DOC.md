# Liquid Glass Effect - Guía de Botones iOS 18+

## Introducción

iOS 26 introdujo nuevos estilos de botones con efecto **"liquid glass"** (vidrio líquido), que proporcionan un acabado translúcido y moderno sin necesidad de diseño adicional como sombras, gradientes o bordes personalizados.

Los botones liquid glass se integran naturalmente con el sistema de diseño de iOS, adaptándose automáticamente al modo claro/oscuro y proporcionando feedback visual consistente.

---

## Estilos Disponibles

### 1. `.glass` - Efecto Glass Sin Color

Botón con efecto de vidrio translúcido **sin color de fondo prominente**. Ideal para acciones secundarias o botones que no deben dominar visualmente la interfaz.

**Características:**
- Fondo translúcido sin color específico
- Efecto de desenfoque (blur) sutil
- Se adapta al contexto visual
- No requiere `.tint()` adicional

**Uso:**
```swift
Button(action: {
    // Acción
}) {
    HStack(spacing: 8) {
        Image(systemName: "creditcard")
            .font(.system(size: 16, weight: .bold))
        Text("Método de pago")
            .font(.system(size: 14, weight: .bold))
    }
    .frame(maxWidth: .infinity)
    .frame(height: 40)
}
.buttonStyle(.glass)
```

**Ejemplos en la app:**
- **CartView**: Botón "Pagar con [método]" (línea 233)
- Selector de método de pago
- Toolbar items en HomeView

---

### 2. `.glassProminent` - Efecto Glass Con Color

Botón con efecto de vidrio translúcido **con color de fondo prominente**. Ideal para acciones primarias o CTAs (Call To Action).

**Características:**
- Fondo translúcido con tinte de color
- Requiere `.tint(Color)` para especificar el color
- Mayor contraste visual que `.glass`
- Destaca como acción principal

**Uso:**
```swift
Button(action: {
    // Acción principal
}) {
    HStack(spacing: 4) {
        Text("Pagar")
            .font(.system(size: 16, weight: .bold, design: .rounded))
        Text("$125.00")
            .font(.system(size: 14, weight: .bold, design: .rounded))
    }
    .frame(maxWidth: .infinity)
    .frame(height: 40)
}
.buttonStyle(.glassProminent)
.tint(.llegoPrimary)  // Color del tema
```

**Ejemplos en la app:**
- **CartView**: Botón "Pagar" (línea 252)
- Botones de confirmación en CheckoutView
- CTAs principales

---

## Principios de Diseño

### 1. **Sin Decoración Adicional**
Los botones liquid glass **NO deben tener**:
- ❌ `.shadow()` personalizado
- ❌ `.background()` con gradientes
- ❌ `.overlay()` con bordes personalizados
- ❌ `.cornerRadius()` explícito (se maneja automáticamente)

```swift
// ❌ INCORRECTO - Decoración excesiva
Button("Pagar") { }
    .buttonStyle(.glassProminent)
    .tint(.llegoPrimary)
    .shadow(radius: 10)           // ❌ No añadir sombra
    .background(Color.blue)       // ❌ No añadir background
    .cornerRadius(12)             // ❌ Radius automático

// ✅ CORRECTO - Minimalismo
Button("Pagar") { }
    .buttonStyle(.glassProminent)
    .tint(.llegoPrimary)
```

### 2. **Jerarquía Visual**
Usa los estilos según la importancia de la acción:

```swift
HStack(spacing: 12) {
    // Acción secundaria
    Button("Cancelar") { }
        .buttonStyle(.glass)

    // Acción primaria
    Button("Confirmar") { }
        .buttonStyle(.glassProminent)
        .tint(.llegoPrimary)
}
```

### 3. **Estados Deshabilitados**
Los botones liquid glass manejan automáticamente estados deshabilitados:

```swift
Button("Pagar") { }
    .buttonStyle(.glassProminent)
    .tint(.llegoPrimary)
    .disabled(selectedPaymentMethod == nil)
    .opacity(selectedPaymentMethod == nil ? 0.5 : 1.0)
```

---

## Casos de Uso

### Toolbar Items (HomeView)
Los toolbar items en iOS 18 también pueden usar el efecto glass implícitamente:

```swift
.toolbar {
    ToolbarItem(placement: .topBarLeading) {
        Button(action: { navigateToWallet = true }) {
            HStack(spacing: 4) {
                Image("cerdito")
                    .resizable()
                    .frame(width: 20, height: 20)

                Text("$\(String(format: "%.2f", balance))")
                    .font(.system(size: 14, weight: .medium))
            }
        }
    }

    ToolbarItem(placement: .topBarTrailing) {
        Button(action: { navigateToCart = true }) {
            Image(systemName: "cart.fill")
        }
        .badge(totalCartItems)
    }
}
```

Los toolbar items heredan automáticamente el efecto glass del sistema.

---

### Botones en Bottom Bar (CartView)

**Patrón común**: Dos botones horizontales en la parte inferior

```swift
HStack(spacing: 12) {
    // Botón secundario - Sin color
    Button(action: { showPaymentMethodPicker = true }) {
        HStack(spacing: 8) {
            Image(systemName: "creditcard")
                .font(.system(size: 16, weight: .bold))
            Text("Método de pago")
                .font(.system(size: 14, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
    }
    .buttonStyle(.glass)

    // Botón primario - Con color
    Button(action: { processPayment() }) {
        HStack(spacing: 4) {
            Text("Pagar")
                .font(.system(size: 16, weight: .bold, design: .rounded))
            Text(formattedTotal)
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
    }
    .disabled(selectedPaymentMethod == nil)
    .opacity(selectedPaymentMethod == nil ? 0.5 : 1.0)
    .buttonStyle(.glassProminent)
    .tint(.llegoPrimary)
}
```

---

## Colores Recomendados para `.tint()`

Usa los colores del tema de Llego:

```swift
// Acción primaria
.tint(.llegoPrimary)      // Verde oscuro (#023133)

// Acción de éxito/confirmación
.tint(.llegoAccent)       // Verde claro (#B2D69A)

// Acción de pago
.tint(.llegoSecondary)    // Dorado (#E1C78E)

// Acción de alerta
.tint(.red)               // Rojo sistema

// Acción neutral
.tint(.gray)              // Gris sistema
```

---

## Migración desde Botones Antiguos

### Antes (iOS 15-17)
```swift
Button(action: { }) {
    Text("Pagar")
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, height: 50)
}
.background(
    RoundedRectangle(cornerRadius: 12)
        .fill(Color.llegoPrimary)
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
)
```

### Después (iOS 18+)
```swift
Button(action: { }) {
    Text("Pagar")
        .font(.system(size: 16, weight: .bold))
        .frame(maxWidth: .infinity, height: 50)
}
.buttonStyle(.glassProminent)
.tint(.llegoPrimary)
```

**Ventajas:**
- ✅ Menos código
- ✅ Adaptación automática a modo oscuro
- ✅ Animaciones nativas consistentes
- ✅ Mejor accesibilidad
- ✅ Rendimiento optimizado

---

## Checklist de Implementación

Cuando crees un nuevo botón liquid glass:

- [ ] Usar `.buttonStyle(.glass)` para acciones secundarias
- [ ] Usar `.buttonStyle(.glassProminent)` + `.tint()` para acciones primarias
- [ ] **NO** añadir `.shadow()`, `.background()` ni `.overlay()` personalizados
- [ ] Establecer `.frame()` para tamaño consistente (altura recomendada: 40-50pt)
- [ ] Manejar estados deshabilitados con `.disabled()` y `.opacity()`
- [ ] Usar fuentes del sistema con peso apropiado (`.bold` o `.semibold`)
- [ ] Probar en modo claro y oscuro

---

## Ejemplos Completos

### Botón Simple
```swift
Button("Explorar") { }
    .buttonStyle(.glass)
```

### Botón con Icono
```swift
Button(action: { }) {
    HStack(spacing: 8) {
        Image(systemName: "cart.fill")
        Text("Añadir al carrito")
    }
}
.buttonStyle(.glassProminent)
.tint(.llegoAccent)
```

### Botón Full Width
```swift
Button(action: { }) {
    Text("Confirmar pedido")
        .font(.system(size: 18, weight: .bold))
        .frame(maxWidth: .infinity)
}
.frame(height: 56)
.buttonStyle(.glassProminent)
.tint(.llegoPrimary)
```

### Grupo de Botones
```swift
VStack(spacing: 12) {
    Button("Continuar como invitado") { }
        .frame(maxWidth: .infinity, height: 50)
        .buttonStyle(.glass)

    Button("Iniciar sesión") { }
        .frame(maxWidth: .infinity, height: 50)
        .buttonStyle(.glassProminent)
        .tint(.llegoPrimary)
}
```

---

## Notas Importantes

### Compatibilidad
- **Mínimo**: iOS 18.0+
- Para versiones anteriores, usar `@available(iOS 18.0, *)` o implementar fallback

```swift
if #available(iOS 18.0, *) {
    Button("Pagar") { }
        .buttonStyle(.glassProminent)
        .tint(.llegoPrimary)
} else {
    // Fallback para iOS 17 y anteriores
    Button("Pagar") { }
        .buttonStyle(.borderedProminent)
        .tint(.llegoPrimary)
}
```

### Accesibilidad
Los botones liquid glass incluyen automáticamente:
- VoiceOver labels
- Dynamic Type support
- Contrast adaptable
- Feedback háptico

### Performance
El efecto glass usa optimizaciones nativas de iOS:
- Renderizado GPU acelerado
- Blur effect eficiente
- Sin overhead de vistas personalizadas

---

## Referencias en el Proyecto

**Archivos con implementación:**
- [`CartView.swift`](LlegoiOS/ui/screens/Cart/CartView.swift) - Líneas 233, 252
- [`CheckoutView.swift`](LlegoiOS/ui/screens/Checkout/CheckoutView.swift)
- [`HomeView.swift`](LlegoiOS/ui/screens/Home/HomeView.swift) - Toolbar items (líneas 373-411)

---

*Última actualización: Octubre 2024*
*iOS 18.0+ - Liquid Glass Button Styles*
