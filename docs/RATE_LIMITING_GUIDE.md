# Guía de Rate Limiting

## Descripción General

El sistema de rate limiting está implementado para proteger el backend de búsquedas excesivas. El límite actual es de **10-20 búsquedas por minuto** tanto para productos como para tiendas.

## Optimización de Queries (Enero 2026)

### Problema Original
Cada vez que el usuario cambiaba de tab, los ViewModels se recreaban y disparaban nuevas queries:
- ProductListView → 1 query
- StoreListView → 1 query + N queries (una por cada tienda para cargar productos)

### Solución Implementada

1. **ViewModels persistentes a nivel del TabView**: Los ViewModels ahora se crean en `MainAppView` y se pasan a las vistas hijas, evitando recreación.

2. **Flag `hasLoaded`**: Cada ViewModel tiene un flag que evita recargar datos si ya se cargaron previamente.

3. **Carga condicional de productos por tienda**: Solo se cargan productos de tiendas que no tienen datos en caché.

### Archivos Modificados

- `ContentView.swift` - ViewModels creados a nivel de MainAppView
- `ProductListView.swift` - Acepta ViewModel como parámetro opcional
- `StoreListView.swift` - Acepta ViewModel como parámetro opcional
- `ProductListViewModel.swift` - Flag hasLoaded
- `StoreListViewModel.swift` - Flag hasLoaded + carga condicional

## Implementación en iOS

### Detección Automática

El sistema detecta automáticamente cuando el backend retorna un error de rate limit verificando si el mensaje de error contiene "rate limit".

### Manejo de Rate Limit

Cuando se detecta un rate limit, el sistema:

1. **Detecta el error** automáticamente
2. **Registra logs informativos** para el desarrollador
3. **Muestra mensaje al usuario** indicando que debe esperar
4. **No reintenta automáticamente** - el usuario debe esperar y buscar de nuevo

### Logs Informativos

Cuando se detecta rate limiting, verás estos logs:

```
⏱️ RATE LIMIT DETECTED - Backend ha excedido el límite de búsquedas por minuto
⏱️ Límite: 10 búsquedas/minuto
⏱️ Sugerencia: Espera unos segundos antes de realizar otra búsqueda
💡 Recomendación: El usuario debe esperar aproximadamente 1 minuto
```

## Archivos Modificados

### 1. ProductListRepository.swift

- Detección de errores de rate limit en `searchProducts()`
- Logs detallados cuando se detecta rate limit
- Retorna error con código 429 al usuario
- Sin retry automático

### 2. StoreListRepository.swift

- Detección de errores de rate limit en `searchBranches()`
- Misma lógica de detección que productos
- Logs consistentes con productos
- Sin retry automático

### 3. ProductListViewModel.swift

- Manejo de errores de rate limit en el ViewModel
- Actualización del estado con mensaje amigable al usuario
- Log de sugerencias para el desarrollador

### 4. StoreListViewModel.swift

- Manejo de errores de rate limit en búsqueda de tiendas
- Actualización del estado con mensaje amigable
- Logs informativos

## Mensajes al Usuario

Cuando se excede el límite y los reintentos fallan, el usuario ve:

```
"Demasiadas búsquedas. Por favor espera un momento e intenta de nuevo."
```

## Recomendaciones para el Backend

Para mejorar la experiencia del usuario, considera:

1. **Aumentar el límite**: De 10 a 20-30 búsquedas por minuto
2. **Implementar rate limiting por usuario**: En lugar de global
3. **Agregar headers de rate limit**: Para que el cliente sepa cuántas búsquedas quedan
4. **Implementar backoff exponencial**: Sugerir tiempo de espera en la respuesta

## Ejemplo de Headers Sugeridos

```
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 3
X-RateLimit-Reset: 1641234567
```

## Testing

Para probar el rate limiting:

1. Realiza más de 10 búsquedas en menos de 1 minuto
2. Observa los logs informativos en la consola
3. Verifica que el mensaje al usuario es claro
4. Espera 1 minuto y confirma que las búsquedas funcionan de nuevo

## Código de Error

El sistema usa el código de error estándar HTTP:

- **Domain**: "RateLimit"
- **Code**: 429 (Too Many Requests)
- **UserInfo**: Mensaje descriptivo en español
