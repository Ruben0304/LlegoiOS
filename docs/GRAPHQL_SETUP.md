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

## Backend

- **URL**: `https://llegobackend-production.up.railway.app/graphql`
- **Schema**: `schema.graphqls`
- **Queries**: `*.graphql` en raíz del proyecto
