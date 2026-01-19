// Ejemplo de implementación en Node.js/Express para Deep Links
// Este código muestra cómo servir el AASA y generar páginas con meta tags

const express = require('express');
const app = express();

// ============================================
// 1. SERVIR APPLE APP SITE ASSOCIATION (AASA)
// ============================================

// Configuración del AASA
const AASA_CONFIG = {
  applinks: {
    apps: [],
    details: [
      {
        appID: "TEAM_ID.com.llego.app", // ⚠️ REEMPLAZAR con tu Team ID y Bundle ID
        paths: [
          "/product/*",
          "/p/*",
          "/store/*",
          "/s/*",
          "/order/*",
          "/o/*",
          "/search",
          "/category/*",
          "/c/*",
          "/"
        ]
      }
    ]
  },
  webcredentials: {
    apps: ["TEAM_ID.com.llego.app"] // ⚠️ REEMPLAZAR
  }
};

// Servir AASA en ambas ubicaciones
app.get('/.well-known/apple-app-site-association', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.json(AASA_CONFIG);
});

app.get('/apple-app-site-association', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.json(AASA_CONFIG);
});

// ============================================
// 2. PÁGINA DE PRODUCTO CON META TAGS
// ============================================

app.get('/product/:id', async (req, res) => {
  const { id } = req.params;
  
  try {
    // Obtener datos del producto desde tu base de datos
    const product = await getProductFromDatabase(id);
    
    if (!product) {
      return res.status(404).send('Producto no encontrado');
    }
    
    // Generar HTML con meta tags
    const html = generateProductHTML(product);
    res.send(html);
    
  } catch (error) {
    console.error('Error loading product:', error);
    res.status(500).send('Error al cargar el producto');
  }
});

// Ruta corta alternativa
app.get('/p/:id', (req, res) => {
  res.redirect(301, `/product/${req.params.id}`);
});

// ============================================
// 3. PÁGINA DE TIENDA CON META TAGS
// ============================================

app.get('/store/:id', async (req, res) => {
  const { id } = req.params;
  
  try {
    // Obtener datos de la tienda desde tu base de datos
    const store = await getStoreFromDatabase(id);
    
    if (!store) {
      return res.status(404).send('Tienda no encontrada');
    }
    
    // Generar HTML con meta tags
    const html = generateStoreHTML(store);
    res.send(html);
    
  } catch (error) {
    console.error('Error loading store:', error);
    res.status(500).send('Error al cargar la tienda');
  }
});

// Ruta corta alternativa
app.get('/s/:id', (req, res) => {
  res.redirect(301, `/store/${req.params.id}`);
});

// ============================================
// 4. FUNCIONES AUXILIARES
// ============================================

// Función para generar HTML de producto
function generateProductHTML(product) {
  const APP_ID = "YOUR_APP_ID"; // ⚠️ REEMPLAZAR con tu App ID
  
  return `
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${escapeHtml(product.name)} - Llego</title>
    
    <!-- Open Graph -->
    <meta property="og:type" content="product">
    <meta property="og:url" content="https://llego.app/product/${product.id}">
    <meta property="og:title" content="${escapeHtml(product.name)}">
    <meta property="og:description" content="${escapeHtml(product.description)}">
    <meta property="og:image" content="${product.imageUrl}">
    <meta property="og:image:width" content="1200">
    <meta property="og:image:height" content="630">
    <meta property="og:site_name" content="Llego">
    
    <!-- Product -->
    <meta property="product:price:amount" content="${product.price}">
    <meta property="product:price:currency" content="${product.currency}">
    <meta property="product:availability" content="in stock">
    
    <!-- Twitter -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="${escapeHtml(product.name)}">
    <meta name="twitter:description" content="${escapeHtml(product.description)}">
    <meta name="twitter:image" content="${product.imageUrl}">
    
    <!-- Apple -->
    <meta name="apple-itunes-app" content="app-id=${APP_ID}, app-argument=llego://product/${product.id}">
    
    <script>
        // Intentar abrir la app automáticamente en iOS
        if (/iPad|iPhone|iPod/.test(navigator.userAgent)) {
            window.location = 'llego://product/${product.id}';
            setTimeout(() => {
                document.getElementById('content').style.display = 'block';
            }, 2000);
        } else {
            document.getElementById('content').style.display = 'block';
        }
    </script>
    
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            text-align: center;
        }
        .product-image {
            max-width: 100%;
            border-radius: 12px;
            margin: 20px 0;
        }
        .price {
            font-size: 32px;
            font-weight: bold;
            color: #667eea;
            margin: 20px 0;
        }
        .btn {
            display: inline-block;
            padding: 15px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            border-radius: 12px;
            font-weight: 600;
            margin: 10px;
        }
    </style>
</head>
<body>
    <div id="content" style="display:none;">
        <h1>${escapeHtml(product.name)}</h1>
        <img src="${product.imageUrl}" alt="${escapeHtml(product.name)}" class="product-image">
        <p>${escapeHtml(product.description)}</p>
        <div class="price">${product.currency} ${product.price}</div>
        <a href="llego://product/${product.id}" class="btn">📱 Abrir en Llego</a>
        <a href="https://apps.apple.com/app/id${APP_ID}" class="btn">⬇️ Descargar App</a>
    </div>
</body>
</html>
  `;
}

// Función para generar HTML de tienda
function generateStoreHTML(store) {
  const APP_ID = "YOUR_APP_ID"; // ⚠️ REEMPLAZAR con tu App ID
  
  return `
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${escapeHtml(store.name)} - Llego</title>
    
    <!-- Open Graph -->
    <meta property="og:type" content="business.business">
    <meta property="og:url" content="https://llego.app/store/${store.id}">
    <meta property="og:title" content="${escapeHtml(store.name)}">
    <meta property="og:description" content="${escapeHtml(store.description || '')}">
    <meta property="og:image" content="${store.bannerUrl || store.logoUrl}">
    <meta property="og:image:width" content="1200">
    <meta property="og:image:height" content="630">
    <meta property="og:site_name" content="Llego">
    
    <!-- Business -->
    <meta property="business:contact_data:street_address" content="${escapeHtml(store.address)}">
    
    <!-- Twitter -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="${escapeHtml(store.name)}">
    <meta name="twitter:description" content="${escapeHtml(store.description || '')}">
    <meta name="twitter:image" content="${store.bannerUrl || store.logoUrl}">
    
    <!-- Apple -->
    <meta name="apple-itunes-app" content="app-id=${APP_ID}, app-argument=llego://store/${store.id}">
    
    <script>
        if (/iPad|iPhone|iPod/.test(navigator.userAgent)) {
            window.location = 'llego://store/${store.id}';
            setTimeout(() => {
                document.getElementById('content').style.display = 'block';
            }, 2000);
        } else {
            document.getElementById('content').style.display = 'block';
        }
    </script>
    
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            text-align: center;
        }
        .banner {
            width: 100%;
            max-height: 200px;
            object-fit: cover;
            border-radius: 12px;
            margin-bottom: 20px;
        }
        .logo {
            width: 100px;
            height: 100px;
            border-radius: 20px;
            margin: -50px auto 20px;
            border: 5px solid white;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .rating {
            color: #ffc107;
            font-size: 20px;
            margin: 10px 0;
        }
        .btn {
            display: inline-block;
            padding: 15px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            border-radius: 12px;
            font-weight: 600;
            margin: 10px;
        }
    </style>
</head>
<body>
    <div id="content" style="display:none;">
        ${store.bannerUrl ? `<img src="${store.bannerUrl}" alt="${escapeHtml(store.name)}" class="banner">` : ''}
        ${store.logoUrl ? `<img src="${store.logoUrl}" alt="${escapeHtml(store.name)}" class="logo">` : ''}
        <h1>${escapeHtml(store.name)}</h1>
        ${store.rating ? `<div class="rating">${'⭐'.repeat(Math.round(store.rating))}</div>` : ''}
        ${store.description ? `<p>${escapeHtml(store.description)}</p>` : ''}
        <p>📍 ${escapeHtml(store.address)}</p>
        <a href="llego://store/${store.id}" class="btn">🛍️ Ver menú en Llego</a>
        <a href="https://apps.apple.com/app/id${APP_ID}" class="btn">⬇️ Descargar App</a>
    </div>
</body>
</html>
  `;
}

// Función para escapar HTML y prevenir XSS
function escapeHtml(text) {
  if (!text) return '';
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

// ============================================
// 5. FUNCIONES DE BASE DE DATOS (EJEMPLO)
// ============================================

// Estas son funciones de ejemplo - reemplaza con tu lógica real
async function getProductFromDatabase(id) {
  // Ejemplo con MongoDB
  // const product = await Product.findById(id);
  
  // Ejemplo con PostgreSQL
  // const result = await pool.query('SELECT * FROM products WHERE id = $1', [id]);
  // const product = result.rows[0];
  
  // Ejemplo de datos mock para testing
  return {
    id: id,
    name: "Pizza Margarita",
    description: "Deliciosa pizza con tomate, mozzarella y albahaca fresca",
    imageUrl: "https://example.com/pizza.jpg",
    price: 12.99,
    currency: "USD",
    storeName: "Pizzería Don Giovanni",
    storeId: "store123"
  };
}

async function getStoreFromDatabase(id) {
  // Ejemplo de datos mock para testing
  return {
    id: id,
    name: "Pizzería Don Giovanni",
    description: "Las mejores pizzas artesanales de la ciudad",
    logoUrl: "https://example.com/logo.jpg",
    bannerUrl: "https://example.com/banner.jpg",
    address: "Calle Principal 123, Ciudad",
    rating: 4.8,
    deliveryTime: "30-40 min"
  };
}

// ============================================
// 6. RUTAS ADICIONALES
// ============================================

// Búsqueda
app.get('/search', (req, res) => {
  const query = req.query.q || '';
  res.redirect(`llego://search?q=${encodeURIComponent(query)}`);
});

// Pedido
app.get('/order/:id', (req, res) => {
  res.redirect(`llego://order/${req.params.id}`);
});

app.get('/o/:id', (req, res) => {
  res.redirect(301, `/order/${req.params.id}`);
});

// Categoría
app.get('/category/:id', (req, res) => {
  res.redirect(`llego://category/${req.params.id}`);
});

app.get('/c/:id', (req, res) => {
  res.redirect(301, `/category/${req.params.id}`);
});

// Home
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
        <title>Llego - Delivery App</title>
        <meta name="apple-itunes-app" content="app-id=YOUR_APP_ID">
    </head>
    <body>
        <h1>Bienvenido a Llego</h1>
        <a href="https://apps.apple.com/app/idYOUR_APP_ID">Descargar App</a>
    </body>
    </html>
  `);
});

// ============================================
// 7. INICIAR SERVIDOR
// ============================================

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📱 AASA available at: http://localhost:${PORT}/.well-known/apple-app-site-association`);
});

// ============================================
// 8. TESTING
// ============================================

// Para probar localmente:
// 1. npm install express
// 2. node backend-example.js
// 3. Visita: http://localhost:3000/.well-known/apple-app-site-association
// 4. Visita: http://localhost:3000/product/123
// 5. Visita: http://localhost:3000/store/456
