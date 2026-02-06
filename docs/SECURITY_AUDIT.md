# 🔍 Reporte de Inspección - LlegoiOS

## 🚨 PROBLEMAS CRÍTICOS DE SEGURIDAD

### 1. Exposición de JWT Tokens en Logs
**Ubicación**: Múltiples archivos
**Severidad**: 🔴 CRÍTICA

```swift
// ❌ PROBLEMA - Logs en producción
print("🔐 Feed request with JWT: \(String(token.prefix(20)))...")
print("🔑 SearchRepository - JWT: \(jwt != nil ? "presente (\(jwt!.prefix(20))...)" : "NO presente")")
```

**Archivos afectados**:
- `SearchRepository.swift:26,103`
- `ProductFeedRepository.swift:197,305`
- `ConversationalSearchRepository.swift:30-35`

**Riesgo**: Los tokens JWT pueden ser capturados en logs de crash reports, analytics, o durante debugging. Aunque solo muestran 20 caracteres, esto revela información sobre la longitud y formato del token.

**Recomendación**: Eliminar TODOS los logs de tokens en producción. Usar logs condicionales solo para DEBUG.

---

### 2. Datos de Usuario en UserDefaults sin Encriptar
**Ubicación**: `AuthManager.swift:66,201`
**Severidad**: 🔴 ALTA

```swift
// ❌ PROBLEMA - Usuario en UserDefaults (sin encriptar)
UserDefaults.standard.set(data, forKey: sessionKey) // Guarda user completo
UserDefaults.standard.set(session.user.id, forKey: userIdKey)
```

**Riesgo**: UserDefaults NO está encriptado. Si el dispositivo es jailbroken o se hace un backup, esta información es accesible.

**Recomendación**: Mover TODA la información sensible (user data, userId) al Keychain.

---

### 3. KeychainHelper con Seguridad Reducida
**Ubicación**: `KeychainHelper.swift:20`
**Severidad**: 🟡 MEDIA

```swift
// ⚠️ PROBLEMA - Accesibilidad menos segura
kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
```

**Riesgo**: Los tokens son accesibles después del primer unlock del dispositivo, incluso si está bloqueado.

**Recomendación**: Cambiar a `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` para mayor seguridad.

---

### 4. URL Hardcodeada del Backend
**Ubicación**: `ApolloClientManager.swift:9`
**Severidad**: 🟡 MEDIA

```swift
// ⚠️ PROBLEMA - URL hardcodeada
static let baseURL = "https://llegobackend-production.up.railway.app"
```

**Riesgo**: No permite cambiar entre entornos (dev/staging/prod). Dificulta testing y deploys.

**Recomendación**: Usar configuraciones por entorno (Debug/Release) o variables de entorno.

---

## ⚡ PROBLEMAS DE PERFORMANCE

### 5. StoreListViewModel - Código Legacy Redundante ✅ CORREGIDO
**Ubicación**: `StoreListViewModel.swift:205-207`
**Severidad**: 🟡 MEDIA → ✅ **RESUELTO**

**Acción tomada**:
- ✅ Eliminada función `loadProductsForStore()` completa
- ✅ Los productos ya vienen anidados en `loadStores()` y `loadMoreStores()`
- ✅ No hay código que llame a esta función (fue verificado)

**Antes**:
```swift
// ❌ Código redundante eliminado
func loadProductsForStore(storeId: String) {
    repository.fetchBranchProducts(branchId: storeId, limit: 4) { ... }
}
```

**Después**:
```swift
// ✅ Comentario explicativo
// REMOVED: loadProductsForStore() - Products are now loaded with nested queries
```

---

### 6. StoreListViewModel.searchStores() - Sin Optimización ✅ CORREGIDO
**Ubicación**: `StoreListViewModel.swift:238-280`
**Severidad**: 🟡 MEDIA → ✅ **RESUELTO**

**Acción tomada**:
- ✅ Actualizado `StoreListRepository.searchBranches()` para mapear productos anidados
- ✅ Actualizado `StoreListViewModel.searchStores()` para poblar `storeProducts` con productos de búsqueda
- ✅ Query `SearchBranches.graphql` ya incluía productos (lines 21-28) - solo faltaba el mapeo

**Antes**:
```swift
// ❌ No mapeaba productos anidados
let mappedBranches = data.searchBranches.edges.map { edge in
    BranchGraphQL(...) // Sin productos
}
```

**Después**:
```swift
// ✅ Ahora mapea productos anidados
let mappedProducts = edge.node.products.map { product in
    BranchProductGraphQL(...)
}
return BranchGraphQL(..., products: mappedProducts)
```

---

### 7. ProductFeedRepository - Múltiples Queries Secuenciales ✅ DEPRECADO
**Ubicación**: `ProductFeedRepository.swift:380-406`
**Severidad**: 🟡 MEDIA → ✅ **DEPRECADO**

**Acción tomada**:
- ✅ Marcado `fetchFeedData()` como `@available(*, deprecated, ...)`
- ✅ Marcado `fetchMoreProducts()` como deprecated
- ✅ Agregados mensajes informativos sobre el impacto de performance
- ✅ `fetchCompleteFeed()` ya existe y está optimizado (1 query vs 5)

**Antes**:
```swift
// ❌ 5 queries secuenciales (5x latencia)
func fetchFeedData(...) async -> Result<FeedData, Error>
```

**Después**:
```swift
// ✅ Deprecated con mensaje claro
@available(*, deprecated, message: "Use fetchCompleteFeed() instead. This method makes 5 sequential queries vs 1, causing 5x higher latency.")
func fetchFeedData(...) async -> Result<FeedData, Error>
```

**Nota**: Ningún código actualmente usa `fetchFeedData()`, por lo que no hay migración necesaria.

---

## 🐛 PROBLEMAS POTENCIALES DE ERRORES

### 8. AuthManager - Publishing Changes en Getter
**Ubicación**: `AuthManager.swift:108-129`
**Severidad**: 🟡 MEDIA

```swift
// ⚠️ PROBLEMA - Modifica @Published en un getter
func getAccessToken() -> String? {
    if let token = accessToken {
        let normalized = normalizeAccessToken(token, tokenType: tokenType)
        if normalized != token {
            accessToken = normalized // ← Modificando @Published
        }
        return normalized
    }
    // ...
}
```

**Riesgo**: Puede causar el warning "Publishing changes from within view updates" si se llama desde una View.

**Recomendación**: Separar la normalización de la obtención. Normalizar solo al guardar, no al leer.

---

### 9. StoreListRepository.searchBranches() - Lógica Compleja de Retry
**Ubicación**: `StoreListRepository.swift:285-434`
**Severidad**: 🟡 BAJA

**Problema**: Función de ~150 líneas con lógica anidada de retry, rate limiting y fallback. Difícil de mantener y testear.

**Recomendación**: Refactorizar en funciones más pequeñas:
- `handleRateLimitError()`
- `retryWithTextSearch()`
- `mapBranchResults()`

---

### 10. Falta de Manejo de Errores Consistente
**Ubicación**: Múltiples repositories
**Severidad**: 🟡 BAJA

**Problema**: Algunos repositories devuelven arrays vacíos en error, otros lanzan NSError. No hay un patrón consistente.

**Ejemplos**:

```swift
// SearchRepository - devuelve array vacío en error
completion(.success([]))

// ProductFeedRepository - lanza NSError
completion(.failure(NSError(...)))
```

**Recomendación**: Establecer un patrón consistente (preferir `Result<T, Error>` con errores tipados).

---

### 11. Thread Safety en Managers Singleton
**Ubicación**: `CartManager.swift`, `FavoritesManager.swift`
**Severidad**: 🟢 BAJA

```swift
// ⚠️ POSIBLE PROBLEMA - apolloClient no es necesariamente MainActor
@MainActor
class CartManager: ObservableObject {
    private let apolloClient = ApolloClientManager.shared.apollo
    // ¿apolloClient es thread-safe desde MainActor?
}
```

**Riesgo**: Aunque `CartManager` es `@MainActor`, llama a `apolloClient` que puede no estar aislado al MainActor.

**Estado**: Probablemente OK porque Apollo maneja sus propias colas, pero vale la pena verificar.

---

## 📦 CÓDIGO MUERTO / LEGACY

### 12. Código Deprecated Aún en Uso
**Severidad**: 🟢 INFO

- `ProductFeedRepository.fetchFeed()` - Marcado como deprecated (línea 299)
- `ProductFeedRepository.fetchFeedData()` - Legacy (línea 380)

**Recomendación**: Buscar usos de estos métodos y migrarlos a `fetchCompleteFeed()`.

---

## 📊 RESUMEN DE HALLAZGOS

| Categoría | Crítico | Alto | Medio | Bajo | Total |
|-----------|---------|------|-------|------|-------|
| 🔒 Seguridad | 1 | 1 | 2 | 0 | 4 |
| ⚡ Performance | 0 | 0 | 3 | 0 | 3 |
| 🐛 Errores | 0 | 0 | 2 | 2 | 4 |
| 📦 Legacy | 0 | 0 | 0 | 1 | 1 |
| **TOTAL** | **1** | **1** | **7** | **3** | **12** |

---

## 🎯 PRIORIDADES DE ACCIÓN

### Inmediatas (Esta Semana)
1. **Eliminar logs de JWT tokens** (#1)
2. **Migrar datos de usuario al Keychain** (#2)

### Corto Plazo (Este Mes)
3. **Actualizar KeychainHelper security** (#3)
4. **Implementar configuración de entornos** (#4)
5. **Migrar a fetchCompleteFeed()** (#7)

### Mediano Plazo (Próximo Sprint)
6. **Optimizar searchStores()** (#6)
7. **Refactorizar AuthManager.getAccessToken()** (#8)
8. **Limpiar código legacy** (#5, #12)

### Bajo Prioridad (Backlog)
9. **Refactorizar StoreListRepository.searchBranches()** (#9)
10. **Establecer patrón de manejo de errores** (#10)
11. **Revisar thread safety en managers** (#11)

---

**Última actualización**: Febrero 2025
**Auditor**: Claude AI
**Versión del código**: main branch (commit 822f6de)
