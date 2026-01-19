# 🔗 Deep Links - Resumen de Implementación

## ✅ Lo que se ha implementado

### 1. Configuración de URL Schemes
- ✅ URL scheme personalizado: `llego://`
- ✅ Configurado en `Info.plist`
- ✅ Soporta productos, tiendas, pedidos, búsqueda y categorías

### 2. Configuración de Universal Links
- ✅ Dominio configurado: `llego.app` y `www.llego.app`
- ✅ Configurado en `LlegoiOS.entitlements`
- ✅ Soporte para rich previews en iMessage

### 3. Manejador de Deep Links
- ✅ `DeepLinkManager.swift` - Maneja todos los deep links
- ✅ Soporta navegación automática
- ✅ Genera URLs para compartir

### 4. Helper para Compartir
- ✅ `ShareHelper.swift` - Facilita compartir contenido
- ✅ Métodos para productos, tiendas y pedidos
- ✅ Integración con el share sheet nativo de iOS

### 5. Integración en la App
- ✅ `iOSApp.swift` actualizado para manejar URLs
- ✅ `ContentView.swift` con navegación por deep links
- ✅ Botones de compartir en vistas de productos y tiendas

## 📱 Patrones de URLs Soportados

### URL Schemes (funcionan inmediatamente)
```
llego://product/123      → Ver producto
llego://store/456        → Ver tienda
llego://order/789        → Ver pedido
llego://search?q=pizza   → Buscar
llego://category/abc     → Ver categoría
llego://home             → Ir al inicio
```

### Universal Links (requieren configuración del servidor)
```
https://llego.app/product/123  o  /p/123   → Ver producto
https://llego.app/store/456    o  /s/456   → Ver tienda
https://llego.app/order/789    o  /o/789   → Ver pedido
https://llego.app/search?q=pizza           → Buscar
https://llego.app/category/abc o  /c/abc   → Ver categoría
https://llego.app/                         → Ir al inicio
```

## 🚀 Cómo Usar

### Compartir un Producto
```swift
ShareHelper.shareProduct(
    id: product.id,
    name: product.name,
    description: product.description,
    imageURL: product.imageUrl,
    price: product.price,
    currency: product.currency
)
```

### Compartir una Tienda
```swift
ShareHelper.shareStore(
    id: store.id,
    name: store.name,
    description: store.description,
    imageURL: store.logoUrl
)
```

### Generar URL para Compartir
```swift
let url = DeepLinkManager.generateShareURL(for: .product(id: "123"))
// Resultado: https://llego.app/product/123
```

## 🧪 Testing

### En el Simulador o Dispositivo

1. **URL Schemes** (funcionan inmediatamente):
   - Abre Safari o Notes
   - Escribe: `llego://product/123`
   - Presiona Enter

2. **Universal Links** (requieren servidor configurado):
   - Envía el link por iMessage: `https://llego.app/product/123`
   - O en Safari: long press → "Open in Llego"

## ⚙️ Configuración Pendiente en el Backend

Para que los Universal Links funcionen y se vean bien en iMessage, necesitas:

### 1. Archivo AASA (Apple App Site Association)

Crea el archivo `apple-app-site-association` (sin extensión) y súbelo a tu servidor:

**Ubicación:**
```
https://llego.app/.well-known/apple-app-site-association
https://llego.app/apple-app-site-association
```

**Contenido:** (ver `docs/apple-app-site-association.example.json`)
```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "TEAM_ID.com.llego.app",
      "paths": ["/product/*", "/p/*", "/store/*", "/s/*", ...]
    }]
  }
}
```

**Importante:**
- Reemplaza `TEAM_ID` con tu Apple Team ID
- Reemplaza `com.llego.app` con tu Bundle ID real
- Debe servirse con `Content-Type: application/json`
- Debe ser accesible vía HTTPS
- No debe requerir autenticación

### 2. Meta Tags Open Graph

Para rich previews en iMessage, agrega meta tags en tus páginas web:

**Para Productos:** (ver `docs/product-page-example.html`)
```html
<meta property="og:title" content="Nombre del Producto" />
<meta property="og:description" content="Descripción" />
<meta property="og:image" content="https://llego.app/images/product.jpg" />
<meta property="og:url" content="https://llego.app/product/123" />
<meta property="product:price:amount" content="19.99" />
<meta property="product:price:currency" content="USD" />
```

**Para Tiendas:** (ver `docs/store-page-example.html`)
```html
<meta property="og:title" content="Nombre de la Tienda" />
<meta property="og:description" content="Descripción" />
<meta property="og:image" content="https://llego.app/images/store.jpg" />
<meta property="og:url" content="https://llego.app/store/456" />
```

### 3. Configuración del Servidor Web

#### Nginx
```nginx
location /.well-known/apple-app-site-association {
    default_type application/json;
    add_header Content-Type application/json;
}
```

#### Apache
```apache
<Files "apple-app-site-association">
    Header set Content-Type "application/json"
</Files>
```

## 📋 Checklist de Implementación

### En iOS (✅ Completado)
- [x] Configurar URL scheme en Info.plist
- [x] Configurar Universal Links en entitlements
- [x] Crear DeepLinkManager
- [x] Crear ShareHelper
- [x] Integrar en iOSApp.swift
- [x] Integrar en ContentView.swift
- [x] Agregar botones de compartir en vistas

### En el Backend (⏳ Pendiente)
- [ ] Subir archivo AASA al servidor
- [ ] Configurar servidor web para servir AASA
- [ ] Crear páginas web con meta tags Open Graph
- [ ] Implementar endpoint dinámico para productos
- [ ] Implementar endpoint dinámico para tiendas
- [ ] Verificar con el validador de Apple

### En Apple Developer (⏳ Pendiente)
- [ ] Verificar Team ID
- [ ] Verificar Bundle ID
- [ ] Configurar Associated Domains
- [ ] Publicar app en TestFlight o App Store

## 🔍 Verificación

### 1. Verificar AASA
```bash
curl -I https://llego.app/.well-known/apple-app-site-association
curl https://llego.app/.well-known/apple-app-site-association
```

### 2. Validador de Apple
https://search.developer.apple.com/appsearch-validation-tool/

### 3. Debugger de Facebook (para Open Graph)
https://developers.facebook.com/tools/debug/

## 📚 Documentación Adicional

- `DEEP_LINKS_SETUP.md` - Guía completa de configuración
- `DEEP_LINKS_USAGE.md` - Guía de uso y ejemplos
- `apple-app-site-association.example.json` - Ejemplo de AASA
- `product-page-example.html` - Ejemplo de página de producto
- `store-page-example.html` - Ejemplo de página de tienda

## 🎯 Próximos Pasos

1. **Obtener tu Apple Team ID:**
   - Ve a https://developer.apple.com/account
   - Copia tu Team ID

2. **Configurar el servidor:**
   - Sube el archivo AASA
   - Configura los meta tags Open Graph
   - Verifica que todo funcione

3. **Publicar la app:**
   - Sube a TestFlight o App Store
   - Los Universal Links solo funcionan con apps publicadas

4. **Probar:**
   - Comparte un producto por iMessage
   - Verifica que se vea el rich preview
   - Toca el link y verifica que abra la app

## ⚠️ Notas Importantes

1. **URL Schemes** funcionan inmediatamente sin configuración adicional
2. **Universal Links** requieren:
   - Servidor configurado con AASA
   - App publicada en TestFlight o App Store
   - Dominio verificado
3. Los Universal Links NO funcionan si:
   - Se abren directamente desde Safari (usar long press)
   - El AASA no está configurado correctamente
   - La app no está instalada
4. Para testing local, usa URL Schemes
5. Para producción, usa Universal Links

## 🆘 Troubleshooting

### Los URL Schemes no funcionan
- Verifica que el scheme esté en Info.plist
- Reinstala la app
- Verifica que no haya typos

### Los Universal Links no funcionan
- Verifica que el AASA esté accesible
- Verifica Team ID y Bundle ID
- Desinstala y reinstala la app
- Espera unos minutos (Apple cachea el AASA)
- Verifica en Settings → Developer → Universal Links

### Los Rich Previews no aparecen
- Verifica los meta tags Open Graph
- Usa el debugger de Facebook
- Verifica que las imágenes sean accesibles (HTTPS)
- Limpia el caché de iMessage

## 📞 Soporte

Si tienes problemas:
1. Revisa los logs en Xcode
2. Verifica la documentación en `docs/`
3. Usa el validador de Apple para AASA
4. Verifica los meta tags con el debugger de Facebook
