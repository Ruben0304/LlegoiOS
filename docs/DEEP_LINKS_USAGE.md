# Guía de Uso de Deep Links

## 🚀 Uso Rápido

### Compartir desde la App

#### Compartir un Producto
```swift
// Desde cualquier vista con acceso al producto
ShareHelper.shareProduct(
    id: product.id,
    name: product.name,
    description: product.description,
    imageURL: product.imageUrl,
    price: product.price,
    currency: product.currency
)
```

#### Compartir una Tienda
```swift
// Desde cualquier vista con acceso a la tienda
ShareHelper.shareStore(
    id: store.id,
    name: store.name,
    description: store.description,
    imageURL: store.logoUrl
)
```

#### Compartir un Pedido
```swift
// Desde la vista de detalle de pedido
ShareHelper.shareOrder(
    id: order.id,
    storeName: order.storeName,
    total: order.total,
    currency: order.currency
)
```

### Generar URLs Manualmente

#### Para Compartir (Universal Links)
```swift
// Genera: https://llego.app/product/123
let url = DeepLinkManager.generateShareURL(for: .product(id: "123"))

// Genera: https://llego.app/store/456
let url = DeepLinkManager.generateShareURL(for: .store(id: "456"))

// Genera: https://llego.app/search?q=pizza
let url = DeepLinkManager.generateShareURL(for: .search(query: "pizza"))
```

#### Para Uso Interno (URL Schemes)
```swift
// Genera: llego://product/123
let url = DeepLinkManager.generateSchemeURL(for: .product(id: "123"))

// Genera: llego://store/456
let url = DeepLinkManager.generateSchemeURL(for: .store(id: "456"))
```

## 📱 Testing en el Dispositivo

### 1. URL Schemes (Funcionan Inmediatamente)

Abre Safari o Notes y escribe:

```
llego://product/123
llego://store/456
llego://order/789
llego://search?q=pizza
llego://home
```

### 2. Universal Links (Requieren Configuración del Servidor)

Envía estos links por iMessage, Mail, o Notes:

```
https://llego.app/product/123
https://llego.app/store/456
https://llego.app/order/789
https://llego.app/search?q=pizza
```

**Nota:** Para probar Universal Links desde Safari:
1. Long press en el link
2. Selecciona "Open in Llego"

## 🎯 Ejemplos de Integración

### Agregar Botón de Compartir en una Vista

```swift
struct ProductDetailView: View {
    let product: Product
    
    var body: some View {
        VStack {
            // ... contenido de la vista
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: shareProduct) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
    
    private func shareProduct() {
        ShareHelper.shareProduct(
            id: product.id,
            name: product.name,
            description: product.description,
            imageURL: product.imageUrl,
            price: product.price,
            currency: product.currency
        )
    }
}
```

### Componente de Botón de Compartir Reutilizable

```swift
// Ya incluido en ShareHelper.swift
ShareButton(action: {
    ShareHelper.shareProduct(...)
})
```

### Manejar Deep Links Personalizados

Si necesitas agregar nuevos tipos de deep links:

1. Agrega el caso en `DeepLinkDestination`:
```swift
enum DeepLinkDestination: Equatable {
    case home
    case product(id: String)
    case store(id: String)
    case order(id: String)
    case search(query: String)
    case category(id: String)
    case newDestination(id: String) // ← Nuevo
}
```

2. Actualiza `handleCustomScheme` y `handleUniversalLink` en `DeepLinkManager`:
```swift
case "newdestination":
    if let id = pathComponents.first {
        navigate(to: .newDestination(id: id))
        return true
    }
```

3. Actualiza `generateShareURL` y `generateSchemeURL`:
```swift
case .newDestination(let id):
    return URL(string: "\(baseURL)/newdestination/\(id)")
```

4. Agrega la vista de destino en `ContentView.swift`:
```swift
@ViewBuilder
private func destinationView(for destination: DeepLinkDestination) -> some View {
    switch destination {
    // ... casos existentes
    case .newDestination(let id):
        NewDestinationView(id: id)
    }
}
```

## 🔍 Debugging

### Ver Logs de Deep Links

Los deep links imprimen logs en la consola:

```
🔗 Handling deep link: llego://product/123
✅ Navigating to: product(id: "123")
```

### Verificar si un Deep Link fue Manejado

```swift
let handled = DeepLinkManager.shared.handleURL(url)
if handled {
    print("Deep link manejado correctamente")
} else {
    print("Deep link no reconocido")
}
```

### Observar Cambios de Navegación

```swift
@EnvironmentObject var deepLinkManager: DeepLinkManager

var body: some View {
    Text("Current destination: \(String(describing: deepLinkManager.destination))")
        .onChange(of: deepLinkManager.destination) { newDestination in
            print("Navegando a: \(String(describing: newDestination))")
        }
}
```

## 📊 Patrones de URLs Soportados

### URL Schemes (llego://)
| Patrón | Ejemplo | Descripción |
|--------|---------|-------------|
| `llego://home` | `llego://home` | Ir al inicio |
| `llego://product/{id}` | `llego://product/123` | Ver producto |
| `llego://store/{id}` | `llego://store/456` | Ver tienda |
| `llego://order/{id}` | `llego://order/789` | Ver pedido |
| `llego://search?q={query}` | `llego://search?q=pizza` | Buscar |
| `llego://category/{id}` | `llego://category/abc` | Ver categoría |

### Universal Links (https://llego.app)
| Patrón | Ejemplo | Descripción |
|--------|---------|-------------|
| `/` | `https://llego.app/` | Ir al inicio |
| `/product/{id}` o `/p/{id}` | `https://llego.app/p/123` | Ver producto |
| `/store/{id}` o `/s/{id}` | `https://llego.app/s/456` | Ver tienda |
| `/order/{id}` o `/o/{id}` | `https://llego.app/o/789` | Ver pedido |
| `/search?q={query}` | `https://llego.app/search?q=pizza` | Buscar |
| `/category/{id}` o `/c/{id}` | `https://llego.app/c/abc` | Ver categoría |

## 🎨 Rich Previews

Para que los links compartidos se vean bien en iMessage, WhatsApp, etc., el backend debe:

1. Servir el archivo `apple-app-site-association`
2. Incluir meta tags Open Graph en las páginas
3. Servir imágenes de alta calidad (mínimo 1200x630px)

Ver `DEEP_LINKS_SETUP.md` para más detalles.

## ⚠️ Notas Importantes

1. **URL Schemes** funcionan inmediatamente sin configuración adicional
2. **Universal Links** requieren:
   - Configuración del servidor (AASA file)
   - Dominio verificado en Apple Developer
   - App publicada o en TestFlight
3. Los Universal Links NO funcionan si:
   - Se abren directamente desde Safari (usar long press)
   - El AASA no está configurado
   - La app no está instalada
4. Para testing local, usa URL Schemes
5. Para producción, usa Universal Links para mejor experiencia

## 🚀 Próximos Pasos

1. ✅ Implementación en iOS completada
2. ⏳ Configurar servidor web con AASA
3. ⏳ Agregar meta tags Open Graph
4. ⏳ Publicar app en TestFlight/App Store
5. ⏳ Verificar Universal Links con el validador de Apple
