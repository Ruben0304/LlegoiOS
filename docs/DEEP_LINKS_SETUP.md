# Configuración de Deep Links y Universal Links

## 📱 Implementación Completada en iOS

### URL Schemes Configurados
- `llego://` - URL scheme personalizado para deep links
- Soporta los siguientes patrones:
  - `llego://product/{id}` - Abrir producto
  - `llego://store/{id}` - Abrir tienda
  - `llego://order/{id}` - Abrir pedido
  - `llego://search?q={query}` - Búsqueda
  - `llego://category/{id}` - Categoría
  - `llego://home` - Inicio

### Universal Links Configurados
- Dominio: `llego.app` y `www.llego.app`
- Patrones soportados:
  - `https://llego.app/product/{id}` o `/p/{id}`
  - `https://llego.app/store/{id}` o `/s/{id}`
  - `https://llego.app/order/{id}` o `/o/{id}`
  - `https://llego.app/search?q={query}`
  - `https://llego.app/category/{id}` o `/c/{id}`

## 🌐 Configuración Requerida en el Backend

### 1. Apple App Site Association (AASA)

Debes crear un archivo `apple-app-site-association` (sin extensión) en tu servidor web y servirlo en:

```
https://llego.app/.well-known/apple-app-site-association
https://llego.app/apple-app-site-association
```

**Contenido del archivo:**

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.llego.app",
        "paths": [
          "/product/*",
          "/p/*",
          "/store/*",
          "/s/*",
          "/order/*",
          "/o/*",
          "/search",
          "/category/*",
          "/c/*"
        ]
      }
    ]
  },
  "webcredentials": {
    "apps": ["TEAM_ID.com.llego.app"]
  }
}
```

**Importante:**
- Reemplaza `TEAM_ID` con tu Apple Team ID (lo encuentras en tu cuenta de desarrollador)
- Reemplaza `com.llego.app` con tu Bundle ID real
- El archivo debe servirse con `Content-Type: application/json`
- Debe ser accesible vía HTTPS (no HTTP)
- No debe requerir autenticación
- No debe tener redirecciones

### 2. Configuración del Servidor Web

#### Nginx
```nginx
location /.well-known/apple-app-site-association {
    default_type application/json;
    add_header Content-Type application/json;
    return 200 '{ "applinks": { ... } }';
}

location /apple-app-site-association {
    default_type application/json;
    add_header Content-Type application/json;
    return 200 '{ "applinks": { ... } }';
}
```

#### Apache
```apache
<Files "apple-app-site-association">
    Header set Content-Type "application/json"
</Files>
```

### 3. Meta Tags para Rich Previews en iMessage

Para que los links se vean bien en iMessage, WhatsApp, etc., agrega Open Graph meta tags en tus páginas:

#### Para Productos
```html
<!DOCTYPE html>
<html>
<head>
    <meta property="og:title" content="Nombre del Producto" />
    <meta property="og:description" content="Descripción del producto" />
    <meta property="og:image" content="https://llego.app/images/product.jpg" />
    <meta property="og:url" content="https://llego.app/product/123" />
    <meta property="og:type" content="product" />
    <meta property="product:price:amount" content="19.99" />
    <meta property="product:price:currency" content="USD" />
    
    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content="Nombre del Producto" />
    <meta name="twitter:description" content="Descripción del producto" />
    <meta name="twitter:image" content="https://llego.app/images/product.jpg" />
    
    <!-- Apple -->
    <meta name="apple-itunes-app" content="app-id=YOUR_APP_ID, app-argument=llego://product/123" />
</head>
<body>
    <!-- Contenido de la página -->
</body>
</html>
```

#### Para Tiendas
```html
<!DOCTYPE html>
<html>
<head>
    <meta property="og:title" content="Nombre de la Tienda" />
    <meta property="og:description" content="Descripción de la tienda" />
    <meta property="og:image" content="https://llego.app/images/store.jpg" />
    <meta property="og:url" content="https://llego.app/store/456" />
    <meta property="og:type" content="business.business" />
    
    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content="Nombre de la Tienda" />
    <meta name="twitter:description" content="Descripción de la tienda" />
    <meta name="twitter:image" content="https://llego.app/images/store.jpg" />
    
    <!-- Apple -->
    <meta name="apple-itunes-app" content="app-id=YOUR_APP_ID, app-argument=llego://store/456" />
</head>
<body>
    <!-- Contenido de la página -->
</body>
</html>
```

### 4. Endpoint de API para Generar Meta Tags Dinámicos

Ejemplo en Node.js/Express:

```javascript
app.get('/product/:id', async (req, res) => {
  const { id } = req.params;
  
  // Obtener datos del producto desde tu base de datos
  const product = await getProduct(id);
  
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta property="og:title" content="${product.name}" />
      <meta property="og:description" content="${product.description}" />
      <meta property="og:image" content="${product.imageUrl}" />
      <meta property="og:url" content="https://llego.app/product/${id}" />
      <meta property="og:type" content="product" />
      <meta property="product:price:amount" content="${product.price}" />
      <meta property="product:price:currency" content="${product.currency}" />
      
      <meta name="twitter:card" content="summary_large_image" />
      <meta name="twitter:title" content="${product.name}" />
      <meta name="twitter:description" content="${product.description}" />
      <meta name="twitter:image" content="${product.imageUrl}" />
      
      <meta name="apple-itunes-app" content="app-id=YOUR_APP_ID, app-argument=llego://product/${id}" />
      
      <script>
        // Redirigir a la app si está instalada
        window.location = 'llego://product/${id}';
        
        // Si no se abre en 2 segundos, mostrar la página web
        setTimeout(() => {
          document.getElementById('content').style.display = 'block';
        }, 2000);
      </script>
    </head>
    <body>
      <div id="content" style="display:none;">
        <h1>${product.name}</h1>
        <img src="${product.imageUrl}" alt="${product.name}" />
        <p>${product.description}</p>
        <p>Precio: ${product.currency} ${product.price}</p>
        <a href="https://apps.apple.com/app/idYOUR_APP_ID">Descargar App</a>
      </div>
    </body>
    </html>
  `;
  
  res.send(html);
});
```

## 🧪 Testing

### 1. Verificar AASA
```bash
# Verificar que el archivo es accesible
curl -I https://llego.app/.well-known/apple-app-site-association

# Verificar el contenido
curl https://llego.app/.well-known/apple-app-site-association
```

### 2. Validador de Apple
Usa el validador oficial de Apple:
https://search.developer.apple.com/appsearch-validation-tool/

### 3. Testing en el Dispositivo

#### URL Schemes (funcionan inmediatamente)
```swift
// En Safari o Notes, escribe:
llego://product/123
llego://store/456
```

#### Universal Links (requieren configuración del servidor)
```swift
// En Safari, Messages, Mail, etc:
https://llego.app/product/123
https://llego.app/store/456
```

**Nota:** Los Universal Links NO funcionan si:
- Abres el link desde Safari directamente (usa long press → "Open in Llego")
- El AASA no está configurado correctamente
- La app no está instalada

## 📲 Uso en la App

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
    imageURL: store.imageUrl
)
```

### Generar URL para Compartir
```swift
// Universal Link (para compartir)
let url = DeepLinkManager.generateShareURL(for: .product(id: "123"))

// URL Scheme (para uso interno)
let url = DeepLinkManager.generateSchemeURL(for: .product(id: "123"))
```

## 🎨 Rich Previews en iMessage

Para que los links se vean como tarjetas ricas en iMessage:

1. ✅ Configura los meta tags Open Graph en tu web
2. ✅ Asegúrate de que las imágenes sean accesibles (HTTPS)
3. ✅ Usa imágenes de al menos 1200x630px
4. ✅ Configura el `apple-itunes-app` meta tag
5. ✅ Publica tu app en el App Store

## 🔧 Troubleshooting

### Los Universal Links no funcionan
1. Verifica que el AASA esté accesible y tenga el formato correcto
2. Verifica que el Team ID y Bundle ID sean correctos
3. Desinstala y reinstala la app
4. Espera unos minutos (Apple cachea el AASA)
5. Verifica en Settings → Developer → Universal Links

### Los URL Schemes no funcionan
1. Verifica que el URL scheme esté registrado en Info.plist
2. Verifica que no haya typos en el scheme

### Los Rich Previews no aparecen
1. Verifica los meta tags Open Graph
2. Usa el debugger de Facebook: https://developers.facebook.com/tools/debug/
3. Verifica que las imágenes sean accesibles
4. Limpia el caché de iMessage (puede tomar tiempo)

## 📚 Referencias

- [Apple Universal Links Documentation](https://developer.apple.com/ios/universal-links/)
- [Open Graph Protocol](https://ogp.me/)
- [Twitter Cards](https://developer.twitter.com/en/docs/twitter-for-websites/cards/overview/abouts-cards)
- [AASA Validator](https://search.developer.apple.com/appsearch-validation-tool/)
