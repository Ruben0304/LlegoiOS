# Concurrency Patterns - Main Actor y Task

Guía completa sobre concurrencia, Main Actor y Swift 6 strict concurrency en LlegoiOS.

## Problema: Data Races con @MainActor

Los managers `AuthManager` y `BranchTypeManager` están marcados con `@MainActor`, pero los Repositories NO lo están.

### ❌ Incorrecto: Acceso Directo

```swift
class ProductRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    func fetchProducts(completion: @escaping (Result<[Product], Error>) -> Void) {
        // ❌ ERROR: Main actor-isolated property cannot be referenced
        let jwt = AuthManager.shared.getAccessToken()
        let branchType = BranchTypeManager.shared.selectedType.rawValue

        apolloClient.fetch(query: query) { result in
            // ...
        }
    }
}
```

**Error**:
```
Main actor-isolated property 'getAccessToken()' cannot be referenced
from a nonisolated context
```

## Solución: Task @MainActor Pattern

### ✅ Correcto: Capturar en Task @MainActor

```swift
class ProductRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    func fetchProducts(
        completion: @escaping @Sendable (Result<[ProductGraphQL], Error>) -> Void
    ) {
        // 1. Capturar apolloClient ANTES del Task
        let client = apolloClient

        // 2. Task @MainActor para acceder a managers
        Task { @MainActor in
            // 3. Acceder a propiedades @MainActor de forma segura
            let jwt = AuthManager.shared.getAccessToken()
            let branchType = BranchTypeManager.shared.selectedType.rawValue

            let query = LlegoAPI.GetProductsQuery(
                jwt: jwt.map { .some($0) } ?? .none,
                branchType: branchType
            )

            // 4. Usar 'client' (NO 'apolloClient') para evitar capturar self
            client.fetch(query: query, cachePolicy: .returnCacheDataAndFetch) { result in
                switch result {
                case .success(let graphQLResult):
                    // Process result
                    completion(.success(mappedData))

                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}
```

## Razones del Patrón

### 1. Capturar `apolloClient` como `client`

**Por qué**:
- Evita capturar `self` implícitamente dentro del Task
- Previene data races al no acceder a propiedades de instancia

```swift
// ✅ Correcto
let client = apolloClient
Task { @MainActor in
    client.fetch(...)  // No captura self
}

// ❌ Incorrecto
Task { @MainActor in
    apolloClient.fetch(...)  // Captura self implícitamente
}
```

### 2. Usar `Task { @MainActor in }`

**Por qué**:
- Permite acceder de forma segura a propiedades `@MainActor`
- El contexto dentro del Task está aislado al Main Actor

```swift
Task { @MainActor in
    // Acceso seguro a @MainActor managers
    let jwt = AuthManager.shared.getAccessToken()
    let branchType = BranchTypeManager.shared.selectedType.rawValue
}
```

### 3. Evitar Métodos Auxiliares

**❌ NO hacer esto**:

```swift
class ProductRepository {
    func fetchProducts(completion: @escaping @Sendable (Result<[Product], Error>) -> Void) {
        Task { @MainActor in
            await performFetch(completion: completion)  // ❌ Captura self
        }
    }

    private func performFetch(completion: @escaping @Sendable (Result<[Product], Error>) -> Void) {
        // ...
    }
}
```

**✅ Hacer esto**:

```swift
class ProductRepository {
    func fetchProducts(completion: @escaping @Sendable (Result<[Product], Error>) -> Void) {
        let client = apolloClient

        Task { @MainActor in
            // Todo el código aquí directamente
            let jwt = AuthManager.shared.getAccessToken()
            client.fetch(...) { result in
                completion(...)
            }
        }
    }
}
```

### 4. Usar `@Sendable` en Closures

**Por qué**:
- Cumple con las reglas de concurrencia de Swift 6
- Indica que el closure puede ser enviado entre contextos

```swift
func fetchProducts(
    completion: @escaping @Sendable (Result<[ProductGraphQL], Error>) -> Void
) {
    // ...
}
```

## Ejemplos Reales del Proyecto

### Ejemplo 1: ProductListRepository

**Archivo**: `ui/screens/Product/List/ProductListRepository.swift`

```swift
class ProductListRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    func fetchProducts(
        branchType: String?,
        completion: @escaping @Sendable (Result<[ProductGraphQL], Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()
            let branchTypeValue = BranchTypeManager.shared.selectedType.rawValue

            let query = LlegoAPI.GetProductsQuery(
                jwt: jwt.map { .some($0) } ?? .none,
                branchType: branchType ?? branchTypeValue
            )

            client.fetch(query: query, cachePolicy: .returnCacheDataAndFetch) { result in
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

                    let mapped = products.map { /* mapping */ }
                    completion(.success(mapped))

                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}
```

### Ejemplo 2: StoreListRepository

**Archivo**: `ui/screens/Store/List/StoreListRepository.swift`

```swift
class StoreListRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    func searchBranches(
        query: String,
        completion: @escaping @Sendable (Result<[StoreGraphQL], Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()
            let branchType = BranchTypeManager.shared.selectedType.rawValue
            let userLocation = UserLocationManager.shared.currentLocation

            let graphQLQuery = LlegoAPI.SearchBranchesQuery(
                query: query,
                jwt: jwt.map { .some($0) } ?? .none,
                branchType: branchType,
                latitude: userLocation?.latitude.map { .some($0) } ?? .none,
                longitude: userLocation?.longitude.map { .some($0) } ?? .none
            )

            client.fetch(query: graphQLQuery, cachePolicy: .returnCacheDataAndFetch) { result in
                // Handle result
            }
        }
    }
}
```

## Reglas Generales

### ✅ DO

1. Capturar `apolloClient` como `let client = apolloClient` antes del Task
2. Envolver código en `Task { @MainActor in }`
3. Capturar valores de Main Actor dentro del Task
4. Usar `client` (no `apolloClient`) en closures de Apollo
5. Marcar closures de completion como `@Sendable`
6. Usar `[weak self]` en closures que capturan self

### ❌ DON'T

1. Acceder directamente a `AuthManager` o `BranchTypeManager` fuera de Task @MainActor
2. Crear métodos auxiliares que capturen `self` desde dentro del Task
3. Llamar `await self.method()` desde dentro del Task
4. Olvidar marcar closures como `@Sendable`
5. Usar `apolloClient` directamente en closures (usar `client` en su lugar)

## Sendable Compliance

### Structs Sendable

Todos los modelos GraphQL deben ser `Sendable`:

```swift
struct ProductGraphQL: Identifiable, Sendable {
    let id: String
    let branchId: String
    let name: String
    let description: String
    let weight: String
    let price: Double
    let currency: String
    let image: String
    let availability: Bool
    let createdAt: String
}
```

### Closures Sendable

```swift
func fetchData(
    completion: @escaping @Sendable (Result<Data, Error>) -> Void
) {
    // ...
}
```

## ViewModel y Main Actor

Los ViewModels SIEMPRE deben estar en el Main Actor:

```swift
@MainActor
class ProductListViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    @Published var products: [Product] = []

    private let repository = ProductListRepository()

    func loadProducts() {
        state = .loading

        repository.fetchProducts { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let productsGraphQL):
                    self.products = productsGraphQL.map { /* map to UI model */ }
                    self.state = .success

                case .failure(let error):
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
}
```

## Debugging Concurrency Issues

### Habilitar Swift 6 Strict Concurrency

En Xcode:
1. Build Settings
2. Buscar "Strict Concurrency Checking"
3. Cambiar a **Complete**

Esto mostrará todos los warnings de concurrencia.

### Errores Comunes

#### Error 1: "Capture of 'self' with non-sendable type"

```swift
// ❌ Problema
Task {
    self.someMethod()  // Error si Repository no es Sendable
}

// ✅ Solución
let client = apolloClient
Task { @MainActor in
    client.fetch(...)  // No captura self
}
```

#### Error 2: "Main actor-isolated property cannot be referenced"

```swift
// ❌ Problema
let jwt = AuthManager.shared.getAccessToken()  // Fuera de Main Actor

// ✅ Solución
Task { @MainActor in
    let jwt = AuthManager.shared.getAccessToken()  // Dentro de Main Actor
}
```

## Referencias

- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Main Actor](https://developer.apple.com/documentation/swift/mainactor)
- [MVVM_REPOSITORY_PATTERN.md](MVVM_REPOSITORY_PATTERN.md)
