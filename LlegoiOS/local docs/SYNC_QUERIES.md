# Queries de Sincronización Local

Este documento describe las 3 nuevas queries GraphQL implementadas para permitir la sincronización de datos localmente en las aplicaciones móviles.

## 1. `syncBusinessesWithBranches`

Sincroniza todos los negocios con sus branches (sucursales), **excluyendo datos sensibles**.

### Datos excluidos por seguridad:
- `ownerId` (ID del propietario)
- `managerIds` (IDs de los managers)
- `accounts` (cuentas bancarias)
- `qrPayments` (códigos QR de pago)
- `phones` (números de teléfono de transferencia)
- `wallet` (información de billetera)
- `paymentMethodIds` (métodos de pago)

### Uso:

```graphql
query {
  syncBusinessesWithBranches {
    id
    name
    globalRating
    avatar
    avatarUrl  # URL firmada de S3
    description
    tags
    isActive
    createdAt
    branches {
      id
      businessId
      name
      address
      coordinates {
        type
        coordinates
      }
      phone
      schedule
      isActive
      status
      avatar
      avatarUrl  # URL firmada de S3
      coverImage
      coverUrl  # URL firmada de S3
      socialMedia
      tipos
      useAppMessaging
      vehicles
      deliveryRadius
      createdAt
    }
  }
}
```

### Respuesta de ejemplo:

```json
{
  "data": {
    "syncBusinessesWithBranches": [
      {
        "id": "65a1b2c3d4e5f6g7h8i9j0k1",
        "name": "Pizzería Don Giovanni",
        "globalRating": 4.5,
        "avatar": "businesses/avatar_123.jpg",
        "avatarUrl": "https://s3.amazonaws.com/...",
        "description": "Las mejores pizzas de la ciudad",
        "tags": ["pizza", "italiana", "delivery"],
        "isActive": true,
        "createdAt": "2024-01-15T10:30:00Z",
        "branches": [
          {
            "id": "65b2c3d4e5f6g7h8i9j0k1l2",
            "businessId": "65a1b2c3d4e5f6g7h8i9j0k1",
            "name": "Sucursal Centro",
            "address": "Calle 23 #456, Vedado",
            "coordinates": {
              "type": "Point",
              "coordinates": [-82.383316, 23.135305]
            },
            "phone": "+5355123456",
            "schedule": {
              "mon": ["09:00-22:00"],
              "tue": ["09:00-22:00"]
            },
            "isActive": true,
            "tipos": ["restaurante"],
            "vehicles": ["moto", "bicicleta"],
            "deliveryRadius": 5.0
          }
        ]
      }
    ]
  }
}
```

---

## 2. `syncProducts`

Sincroniza todos los productos con filtros opcionales.

### Filtros disponibles:
- `branchId`: Filtrar por sucursal específica
- `categoryId`: Filtrar por categoría de producto
- `availableOnly`: Solo productos disponibles (default: `false`)

### Uso:

```graphql
query {
  syncProducts(availableOnly: true) {
    id
    branchId
    name
    description
    weight
    price
    currency
    image
    imageUrl  # URL firmada de S3
    availability
    categoryId
    variantListIds
    createdAt
  }
}
```

### Con filtros:

```graphql
query {
  # Solo productos de una sucursal específica
  syncProducts(branchId: "65b2c3d4e5f6g7h8i9j0k1l2") {
    id
    name
    price
    imageUrl
  }
}

query {
  # Solo productos de una categoría
  syncProducts(categoryId: "65c3d4e5f6g7h8i9j0k1l2m3") {
    id
    name
    categoryId
  }
}
```

### Respuesta de ejemplo:

```json
{
  "data": {
    "syncProducts": [
      {
        "id": "65c3d4e5f6g7h8i9j0k1l2m3",
        "branchId": "65b2c3d4e5f6g7h8i9j0k1l2",
        "name": "Pizza Margarita",
        "description": "Salsa de tomate, mozzarella, albahaca fresca",
        "weight": "400g",
        "price": 12.99,
        "currency": "USD",
        "image": "products/pizza_123.jpg",
        "imageUrl": "https://s3.amazonaws.com/...",
        "availability": true,
        "categoryId": "65d4e5f6g7h8i9j0k1l2m3n4",
        "variantListIds": ["65e5f6g7h8i9j0k1l2m3n4o5"],
        "createdAt": "2024-01-20T14:00:00Z"
      }
    ]
  }
}
```

---

## 3. `syncImages`

Sincroniza imágenes con URLs para diferentes calidades (baja, buena, mejor).

### Parámetros:
- `entityType`: Filtrar por tipo de entidad (`"business"`, `"branch"`, `"product"`)
- `entityIds`: Lista de IDs específicos para sincronizar
- `qualities`: Niveles de calidad a incluir (`[BAJA, BUENA, MEJOR]`)

### Niveles de calidad:
- **BAJA** (`baja`): Miniatura de baja calidad (100x100px) - ideal para listados y caché local
- **ORIGINAL** (`original`): Calidad original completa - ideal para vistas de detalle y zoom

### Uso:

```graphql
query {
  syncImages(qualities: [BAJA, ORIGINAL]) {
    entityId
    entityType
    imagePath
    urls {
      baja
      original
    }
  }
}
```

### Filtrar por tipo:

```graphql
query {
  # Solo imágenes de productos
  syncImages(entityType: "product", qualities: [BAJA]) {
    entityId
    entityType
    urls {
      baja
    }
  }
}

query {
  # Solo imágenes de negocios específicos
  syncImages(
    entityType: "business"
    entityIds: ["65a1b2c3d4e5f6g7h8i9j0k1"]
    qualities: [ORIGINAL]
  ) {
    entityId
    urls {
      original
    }
  }
}
```

### Respuesta de ejemplo:

```json
{
  "data": {
    "syncImages": [
      {
        "entityId": "65a1b2c3d4e5f6g7h8i9j0k1",
        "entityType": "business",
        "imagePath": "businesses/avatar_123.jpg",
        "urls": {
          "baja": "https://s3.amazonaws.com/.../product_123_thumbnail.jpg",
          "original": "https://s3.amazonaws.com/.../product_123.jpg"
        }
      },
      {
        "entityId": "65c3d4e5f6g7h8i9j0k1l2m3",
        "entityType": "product",
        "imagePath": "products/pizza_123.jpg",
        "urls": {
          "baja": "https://s3.amazonaws.com/...",
          "buena": null,
          "mejor": null
        }
      }
    ]
  }
}
```

---

## ✅ Implementación de Thumbnails Automáticos

### Cómo Funciona

El sistema **genera automáticamente** thumbnails de 100x100px al subir imágenes usando Pillow (PIL).

### Convención de Nombres

Cuando subes una imagen, se crean 2 archivos:
```
products/pizza_123_1234567890.jpg            # Original
products/pizza_123_1234567890_thumbnail.jpg  # Thumbnail 100x100
```

### Código Implementado

La función `upload_file()` en `utils/s3.py` automáticamente:
1. Sube la imagen original
2. Genera un thumbnail de 100x100px con Pillow
3. Sube el thumbnail con sufijo `_thumbnail`

```python
# Ejemplo de uso al subir una imagen
from utils.s3 import upload_file

# Esto automáticamente crea original + thumbnail
image_path = await upload_file(
    file_content=image_bytes,
    folder="products",
    entity_id="123",
    extension=".jpg",
    generate_thumbnails=True  # Default
)
# Resultado: products/123_1234567890.jpg + products/123_1234567890_thumbnail.jpg
```

### Características del Thumbnail

- **Tamaño**: 100x100px (mantiene aspect ratio)
- **Formato**: JPEG con optimización
- **Calidad**: 85% (balance entre tamaño y calidad)
- **Conversión**: RGBA → RGB automática para compatibilidad
- **Compresión**: Optimizada para web

### Sincronización con GraphQL

La query `sync_images` devuelve automáticamente las URLs correctas:
- `baja`: URL al thumbnail (`_thumbnail.jpg`)
- `original`: URL a la imagen original

```graphql
query {
  syncImages(qualities: [BAJA, ORIGINAL]) {
    entityId
    urls {
      baja      # → products/123_456_thumbnail.jpg
      original  # → products/123_456.jpg
    }
  }
}
```

### Eliminación Automática

Al borrar una imagen con `delete_file()`, se eliminan **automáticamente**:
- La imagen original
- Su thumbnail (si existe)

---

## Casos de Uso

### 1. Sincronización Inicial de la App

```graphql
query InitialSync {
  businesses: syncBusinessesWithBranches {
    id
    name
    branches {
      id
      name
      tipos
    }
  }

  products: syncProducts(availableOnly: true) {
    id
    name
    price
  }

  images: syncImages(qualities: [BAJA]) {
    entityId
    entityType
    urls {
      baja
    }
  }
}
```

### 2. Actualización de Imágenes en Alta Calidad

```graphql
query DownloadHighQualityImages {
  syncImages(
    entityType: "product"
    qualities: [MEJOR]
  ) {
    entityId
    urls {
      mejor
    }
  }
}
```

### 3. Sincronización por Negocio Específico

```graphql
query SyncSpecificBusiness($businessId: String!) {
  # Obtener el negocio y sus branches
  businesses: syncBusinessesWithBranches {
    id
    name
    branches {
      id
      name
    }
  }

  # Filtrar productos del negocio (via branchId)
  # Nota: Necesitarías hacer múltiples queries o usar @export directive
}
```

---

## Notas de Seguridad

- ✅ No se exponen `managerIds` ni `ownerId`
- ✅ No se exponen datos de pago (`accounts`, `qrPayments`, `phones`)
- ✅ No se exponen balances de wallet
- ✅ Las URLs de S3 son firmadas (presigned) y expiran en 1 hora
- ✅ JWT opcional para autenticación (recomendado en producción)

## Ejemplo de Implementación en Cliente (Swift/Kotlin)

```swift
// Swift example
struct SyncManager {
    func syncAll() async {
        // 1. Sincronizar negocios y branches
        let businesses = try await apolloClient.fetch(query: SyncBusinessesWithBranchesQuery())
        await localDatabase.save(businesses)

        // 2. Sincronizar productos
        let products = try await apolloClient.fetch(query: SyncProductsQuery(availableOnly: true))
        await localDatabase.save(products)

        // 3. Descargar miniaturas
        let images = try await apolloClient.fetch(query: SyncImagesQuery(qualities: [.baja]))
        await downloadImages(images)
    }
}
```

---

## Performance Tips

1. **Paginación**: Para grandes volúmenes, considera agregar paginación:
   ```graphql
   syncProducts(first: 100, after: "cursor123")
   ```

2. **Caché**: Las URLs presigned se cachean por 50 minutos

3. **Sincronización Incremental**: Usa `createdAt` para obtener solo datos nuevos:
   ```graphql
   syncProducts(availableOnly: true) {
     id
     createdAt
   }
   # Cliente: filtrar solo items con createdAt > lastSync
   ```

4. **Imágenes**: Descarga primero `BAJA`, luego `BUENA` en background

---

## Próximos Pasos

- [ ] Implementar generación de thumbnails en diferentes calidades
- [ ] Agregar paginación para grandes volúmenes de datos
- [ ] Implementar delta sync (solo cambios desde última sincronización)
- [ ] Agregar webhooks para notificar cambios en tiempo real
- [ ] Considerar GraphQL Subscriptions para actualizaciones en vivo
