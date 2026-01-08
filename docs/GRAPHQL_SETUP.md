# GraphQL Setup - Apollo iOS

Guía completa para configurar y usar Apollo iOS 2.0.0 en el proyecto LlegoiOS.

## Instalación

### 1. Apollo iOS via SPM

En Xcode:
1. File → Add Package Dependencies
2. URL: `https://github.com/apollographql/apollo-ios.git`
3. Versión: **2.0.0**
4. Seleccionar paquetes:
   - Apollo
   - ApolloAPI
   - ApolloSQLite
   - ApolloWebSocket

### 2. Apollo iOS CLI

El proyecto incluye el ejecutable `apollo-ios-cli` en la raíz.

**Ubicación**:
```
/Users/suncar/projects/Llego Org/LlegoiOS/apollo-ios-cli
```

**Comando de generación**:
```bash
# Desde la raíz del proyecto
./apollo-ios-cli generate
```

## Configuración

### `apollo-codegen-config.json`

```json
{
  "schemaNamespace": "LlegoAPI",
  "input": {
    "operationSearchPaths": ["**/*.graphql"],
    "schemaSearchPaths": ["schema.graphqls"]
  },
  "output": {
    "testMocks": {
      "none": {}
    },
    "schemaTypes": {
      "path": "./LlegoiOS/GraphQL",
      "moduleType": {
        "embeddedInTarget": {
          "name": "LlegoiOS",
          "accessModifier": "public"
        }
      }
    },
    "operations": {
      "inSchemaModule": {}
    }
  }
}
```

### Cliente Apollo

**Archivo**: `network/ApolloClientManager.swift`

```swift
import Foundation
import Apollo
import ApolloSQLite

final class ApolloClientManager: @unchecked Sendable {
    nonisolated(unsafe) static let shared = ApolloClientManager()

    private(set) lazy var apollo: ApolloClient = {
        let url = URL(string: "https://llegobackend-production.up.railway.app/graphql")!
        let store = ApolloStore(cache: cache)
        return ApolloClient(url: url)
    }()

    private lazy var cache: SQLiteNormalizedCache = {
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true
        ).first!
        let documentsURL = URL(fileURLWithPath: documentsPath)
        let sqliteFileURL = documentsURL.appendingPathComponent("llego_apollo_cache.sqlite")

        do {
            let sqliteCache = try SQLiteNormalizedCache(fileURL: sqliteFileURL)
            return sqliteCache
        } catch {
            fatalError("Failed to create SQLite cache: \(error)")
        }
    }()

    private init() {}
}
```

## Flujo de Trabajo

### 1. Crear Query GraphQL

**Ejemplo**: `GetProducts.graphql`

```graphql
query GetProducts($branchType: String) {
  products(branchType: $branchType) {
    id
    branchId
    name
    description
    weight
    price
    currency
    image
    availability
    createdAt
  }
}
```

### 2. Generar Código Swift

```bash
./apollo-ios-cli generate
```

Esto genera archivos en `LlegoiOS/GraphQL/Operations/Queries/`:
- `GetProductsQuery.graphql.swift`

### 3. Usar en Repository

```swift
import Foundation
import Apollo

class ProductListRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    func fetchProducts(
        branchType: String?,
        completion: @escaping @Sendable (Result<[ProductGraphQL], Error>) -> Void
    ) {
        let query = LlegoAPI.GetProductsQuery(
            branchType: branchType.map { .some($0) } ?? .none
        )

        apolloClient.fetch(
            query: query,
            cachePolicy: .returnCacheDataAndFetch
        ) { result in
            switch result {
            case .success(let graphQLResult):
                if let errors = graphQLResult.errors {
                    completion(.failure(NSError(domain: "GraphQL", code: -1)))
                    return
                }

                guard let products = graphQLResult.data?.products else {
                    completion(.success([]))
                    return
                }

                let mapped = products.map { /* map to ProductGraphQL */ }
                completion(.success(mapped))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
```

## Custom Scalars

### DateTime

**Archivo**: `GraphQL/DateTime.swift`

```swift
import ApolloAPI

public typealias DateTime = String

extension DateTime: CustomScalarType {
    public init(_jsonValue value: JSONValue) throws {
        guard let stringValue = value as? String else {
            throw JSONDecodingError.couldNotConvert(value: value, to: String.self)
        }
        self = stringValue
    }

    public var _jsonValue: JSONValue {
        return self
    }
}
```

### JSON

**Archivo**: `GraphQL/JSON.swift`

```swift
import ApolloAPI

public typealias JSON = [String: Any]

extension JSON: CustomScalarType {
    public init(_jsonValue value: JSONValue) throws {
        guard let dict = value as? [String: Any] else {
            throw JSONDecodingError.couldNotConvert(value: value, to: [String: Any].self)
        }
        self = dict
    }

    public var _jsonValue: JSONValue {
        return self
    }
}
```

## Cache Policy

El proyecto usa `.returnCacheDataAndFetch` en todas las queries:

**Beneficios**:
1. Muestra datos cacheados inmediatamente
2. Actualiza con datos frescos del servidor
3. Funciona offline con datos previos

```swift
apolloClient.fetch(
    query: query,
    cachePolicy: .returnCacheDataAndFetch
) { result in
    // Handle result
}
```

## Actualizar Schema

```bash
# Descargar schema actualizado del backend
npx --yes @apollo/rover graph introspect \
  https://llegobackend-production.up.railway.app/graphql \
  > schema.graphqls
```

## Troubleshooting

### Regenerar Código Apollo

```bash
# 1. Limpiar archivos generados
rm -rf LlegoiOS/GraphQL/Operations

# 2. Regenerar
./apollo-ios-cli generate

# 3. Limpiar build en Xcode
# Product → Clean Build Folder (Cmd+Shift+K)
```

### Error: "Cannot find LlegoAPI in scope"

1. Regenerar código Apollo
2. Verificar `embeddedInTarget` en config
3. Clean Build Folder en Xcode

### Queries no se generan

1. Verificar que `.graphql` esté en raíz del proyecto
2. Confirmar sintaxis GraphQL correcta
3. Ejecutar `./apollo-ios-cli generate` de nuevo

---

## 🚨 Errores Comunes en Repositories y ViewModels

Esta sección documenta errores frecuentes al trabajar con Apollo iOS y cómo evitarlos.

### 1. MainActor Isolation en Callbacks de Apollo

**Error:**
```
Call to main actor-isolated instance method 'mapToModel' in a synchronous nonisolated context
```

**Causa:** Los callbacks de Apollo (`fetch`, `perform`) se ejecutan en un hilo de background, pero los métodos del Repository marcados con `@MainActor` solo pueden llamarse desde el MainActor.

**Solución:** Envolver el callback en `Task { @MainActor in }`:

```swift
// ❌ INCORRECTO
client.fetch(query: query) { result in
    let mapped = self.mapToModel(result) // Error: mapToModel es @MainActor
    completion(.success(mapped))
}

// ✅ CORRECTO
client.fetch(query: query) { [weak self] result in
    Task { @MainActor in
        guard let self = self else { return }
        let mapped = self.mapToModel(result)
        completion(.success(mapped))
    }
}
```

### 2. Tipos Int vs Int32 en GraphQL

**Error:**
```
Cannot convert value of type 'Int' to expected argument type 'Int32'
```

**Causa:** Apollo iOS genera tipos `Int32` para campos `Int` de GraphQL, pero Swift usa `Int` por defecto.

**Solución:** Convertir explícitamente a `Int32`:

```swift
// ❌ INCORRECTO
let query = LlegoAPI.GetOrdersQuery(limit: limit, offset: offset)

// ✅ CORRECTO
let query = LlegoAPI.GetOrdersQuery(limit: .some(Int32(limit)), offset: .some(Int32(offset)))
```

### 3. Optional Chaining en Tipos No Opcionales

**Error:**
```
Cannot use optional chaining on non-optional value of type 'SomeType'
```

**Causa:** El schema GraphQL define el campo como requerido (`!`), pero el código usa `?.` como si fuera opcional.

**Solución:** Verificar el archivo `.graphql.swift` generado para ver si el tipo es opcional:

```swift
// Si el schema dice: branch: BranchType! (requerido)
// El código generado será: public var branch: Branch { ... }

// ❌ INCORRECTO
let name = order.branch?.name ?? "Default"

// ✅ CORRECTO
let name = order.branch.name
```

**Tip:** Revisa siempre el archivo generado en `GraphQL/Operations/` para ver los tipos exactos.

### 4. Import Combine Faltante en ViewModels

**Error:**
```
Type 'MyViewModel' does not conform to protocol 'ObservableObject'
Initializer 'init(wrappedValue:)' is not available due to missing import of defining module 'Combine'
```

**Causa:** `@Published` y `ObservableObject` requieren `import Combine`.

**Solución:** Siempre importar Combine en ViewModels:

```swift
// ❌ INCORRECTO
import Foundation

@MainActor
final class MyViewModel: ObservableObject {
    @Published var data: [Item] = [] // Error
}

// ✅ CORRECTO
import Foundation
import Combine

@MainActor
final class MyViewModel: ObservableObject {
    @Published var data: [Item] = []
}
```

### 5. Redeclaración de Structs/Views

**Error:**
```
Invalid redeclaration of 'MyComponent'
```

**Causa:** El mismo struct/view está definido en múltiples archivos.

**Solución:** 
- Buscar duplicados con `Cmd+Shift+F` en Xcode
- Mantener componentes reutilizables en `ui/components/`
- No duplicar componentes dentro de archivos de View

### 6. Mapeo de Enums GraphQL

**Error:**
```
Value of type 'GraphQLEnum<LlegoAPI.SomeEnum>' has no member 'rawValue'
```

**Causa:** Los enums de Apollo están envueltos en `GraphQLEnum<>`.

**Solución:** Usar switch con `.case()`:

```swift
// ❌ INCORRECTO
let status = order.status.rawValue

// ✅ CORRECTO
func mapStatus(_ status: GraphQLEnum<LlegoAPI.OrderStatusEnum>) -> OrderStatusEnum {
    switch status {
    case .case(let value):
        switch value {
        case .pending: return .pending
        case .completed: return .completed
        // ... otros casos
        }
    case .unknown:
        return .pending // valor por defecto
    }
}
```

### 7. Coordenadas GeoJSON

**Causa:** MongoDB/GraphQL usa formato GeoJSON donde `coordinates = [longitude, latitude]` (invertido respecto a iOS).

**Solución:** Invertir al crear `CLLocationCoordinate2D`:

```swift
// GeoJSON: [longitude, latitude]
// iOS CLLocationCoordinate2D: (latitude, longitude)

let coords = order.coordinates.coordinates // [lng, lat]
let coordinate: CLLocationCoordinate2D? = coords.count >= 2
    ? CLLocationCoordinate2D(latitude: coords[1], longitude: coords[0])
    : nil
```

### 8. Parseo de Fechas ISO8601

**Solución estándar para parsear fechas del backend:**

```swift
private func parseDate(_ dateString: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    // Intentar con fracciones de segundo primero
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: dateString) {
        return date
    }
    // Fallback sin fracciones
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: dateString)
}
```

---

## Checklist para Nuevos Repositories

Al crear un nuevo Repository, verificar:

- [ ] `import Apollo` incluido
- [ ] `@MainActor` en la clase
- [ ] Callbacks de Apollo envueltos en `Task { @MainActor in }`
- [ ] `[weak self]` en closures para evitar retain cycles
- [ ] Tipos `Int` convertidos a `Int32` donde sea necesario
- [ ] Verificar si campos son opcionales en el código generado
- [ ] Mapeo correcto de enums con `GraphQLEnum<>`
- [ ] Coordenadas invertidas (GeoJSON → iOS)

## Checklist para Nuevos ViewModels

Al crear un nuevo ViewModel, verificar:

- [ ] `import Foundation` e `import Combine` incluidos
- [ ] `@MainActor` en la clase
- [ ] Hereda de `ObservableObject`
- [ ] Propiedades reactivas con `@Published`
- [ ] Repository inicializado correctamente

## Backend

- **URL**: `https://llegobackend-production.up.railway.app/graphql`
- **Schema**: `schema.graphqls`
- **Queries**: `*.graphql` en raíz del proyecto
