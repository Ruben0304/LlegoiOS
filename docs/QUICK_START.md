# 🚀 Quick Start - Deep Links

## ✅ Ya está implementado en iOS

Todo el código necesario ya está en tu proyecto. Solo necesitas configurar el backend.

## 📱 Probar Ahora Mismo (Sin Backend)

### 1. Compila y ejecuta la app en tu dispositivo

### 2. Abre Safari o Notes y escribe:

```
llego://product/6777f74afe6bab27db6c4aa0
```

### 3. Presiona Enter

La app debería abrirse y navegar al producto.

## 🌐 Para Habilitar Universal Links y Rich Previews

### Paso 1: Obtén tu Apple Team ID

1. Ve a https://developer.apple.com/account
2. Copia tu **Team ID** (10 caracteres)

### Paso 2: Obtén tu Bundle ID

1. Abre el proyecto en Xcode
2. Selecciona el target "LlegoiOS"
3. Ve a "Signing & Capabilities"
4. Copia el **Bundle Identifier** (ej: `com.llego.app`)

### Paso 3: Actualiza el archivo AASA

1. Abre `docs/apple-app-site-association.example.json`
2. Reemplaza `TEAM_ID` con tu Team ID
3. Reemplaza `com.llego.app` con tu Bundle ID
4. Guarda como `apple-app-site-association` (sin extensión)

### Paso 4: Sube el AASA a tu servidor

El archivo debe estar accesible en:
```
https://llego.app/.well-known/apple-app-site-association
https://llego.app/apple-app-site-association
```

**Importante:**
- Debe servirse con `Content-Type: application/json`
- Debe ser HTTPS (no HTTP)
- No debe requerir autenticación

### Paso 5: Verifica que funcione

```bash
curl https://llego.app/.well-known/apple-app-site-association
```

Deberías ver el JSON del AASA.

### Paso 6: Crea páginas web con meta tags

Usa los ejemplos en:
- `docs/product-page-example.html`
- `docs/store-page-example.html`
- `docs/backend-example.js` (implementación completa)

### Paso 7: Publica tu app

Los Universal Links solo funcionan con apps publicadas en:
- TestFlight
- App Store

### Paso 8: Prueba

1. Envía este link por iMessage: `https://llego.app/product/123`
2. Deberías ver un rich preview con imagen y descripción
3. Al tocar el link, debería abrir tu app

## 🎯 Uso en el Código

### Compartir un producto:

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

### Compartir una tienda:

```swift
ShareHelper.shareStore(
    id: store.id,
    name: store.name,
    description: store.description,
    imageURL: store.logoUrl
)
```

## 📚 Más Información

- `DEEP_LINKS_RESUMEN.md` - Resumen completo en español
- `DEEP_LINKS_SETUP.md` - Guía detallada de configuración
- `DEEP_LINKS_USAGE.md` - Ejemplos de uso
- `backend-example.js` - Implementación completa del backend

## ⚠️ Troubleshooting

### Los URL Schemes no funcionan
- Reinstala la app
- Verifica que escribiste bien el URL

### Los Universal Links no funcionan
- Verifica que el AASA esté accesible
- Verifica Team ID y Bundle ID
- Desinstala y reinstala la app
- Espera unos minutos (Apple cachea el AASA)

### Los Rich Previews no aparecen
- Verifica los meta tags Open Graph
- Verifica que las imágenes sean HTTPS
- Limpia el caché de iMessage

## 🆘 ¿Necesitas Ayuda?

1. Revisa los logs en Xcode
2. Usa el validador de Apple: https://search.developer.apple.com/appsearch-validation-tool/
3. Revisa la documentación completa en `docs/`
