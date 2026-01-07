# MVVM + Repository Pattern

Guía completa del patrón arquitectónico MVVM + Repository usado en LlegoiOS.

## Arquitectura

```
📱 View (SwiftUI)
    ↓ Usuario interactúa
📊 ViewModel (@MainActor, @ObservableObject)
    ↓ Llama métodos del repository
🗄️ Repository
    ↓ Ejecuta queries GraphQL
🌐 ApolloClient → Backend GraphQL
```

## Principios Fundamentales

### 1. Una Repository por Pantalla

**NO por Modelo**. Cada pantalla tiene su propio Repository específico.

- `ProductListRepository` → `ProductListView`
- `ProductDetailRepository` → `ProductDetailView`
- `StoreListRepository` → `StoreListView`
- `CartRepository` → `CartView`

### 2. Separación de Responsabilidades

| Capa | Responsabilidad |
|------|-----------------|
| **View** | Renderiza UI, captura eventos del usuario |
| **ViewModel** | Maneja estado de UI, lógica de presentación, transforma datos |
| **Repository** | Comunicación con backend GraphQL, mapeo de modelos GraphQL |

### 3. Flujo de Datos

```
View → ViewModel.loadData()
ViewModel → Repository.fetchData()
Repository → Apollo → GraphQL Backend
GraphQL Backend → Apollo → Repository (GraphQL Models)
Repository → ViewModel (UI Models)
ViewModel (@Published) → View (re-render)
```

### 4. Modelos de Datos

- **GraphQL Models**: Definidos en Repository (ej: `ProductGraphQL`, `StoreGraphQL`)
- **UI Models**: Definidos en `models/Models.swift` (ej: `Product`, `Store`)
- El **ViewModel** convierte GraphQL Models → UI Models

## Ejemplo Completo: ProductListView

### 1. Repository

**Archivo**: `ui/screens/Product/List/ProductListRepository.swift`

```swift
import Foundation
import Apollo

class ProductListRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    func fetchProducts(
        branchType: String?,
        completion: @escaping @Sendable (Result<[ProductGraphQL], Error>) -> Void
    ) {
        // Capturar client antes del Task
        let client = apolloClient

        Task { @MainActor in
            // Acceder a managers @MainActor
            let jwt = AuthManager.shared.getAccessToken()

            let query = LlegoAPI.GetProductsQuery(
                jwt: jwt.map { .some($0) } ?? .none,
                branchType: branchType.map { .some($0) } ?? .none
            )

            client.fetch(
                query: query,
                cachePolicy: .returnCacheDataAndFetch
            ) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors:")
                        errors.forEach { print("  - \($0)") }
                        completion(.failure(NSError(domain: "GraphQL", code: -1)))
                        return
                    }

                    guard let products = graphQLResult.data?.products else {
                        completion(.success([]))
                        return
                    }

                    let mapped = products.map { product in
                        ProductGraphQL(
                            id: product.id,
                            branchId: product.branchId,
                            name: product.name,
                            description: product.description,
                            weight: product.weight,
                            price: product.price,
                            currency: product.currency,
                            image: product.image,
                            availability: product.availability,
                            createdAt: product.createdAt
                        )
                    }

                    completion(.success(mapped))

                case .failure(let error):
                    print("❌ Network Error: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - GraphQL Model
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

### 2. ViewModel

**Archivo**: `ui/screens/Product/List/ProductListViewModel.swift`

```swift
import Foundation
import SwiftUI

enum ProductListViewState {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class ProductListViewModel: ObservableObject {
    @Published var state: ProductListViewState = .idle
    @Published var products: [Product] = []
    @Published var errorMessage: String?

    private let repository = ProductListRepository()

    func loadProducts(branchType: String? = nil) {
        state = .loading
        errorMessage = nil

        repository.fetchProducts(branchType: branchType) { [weak self] result in
            guard let self = self else { return }

            Task { @MainActor in
                switch result {
                case .success(let productsGraphQL):
                    // Map GraphQL → UI Models
                    self.products = productsGraphQL.map { graphQL in
                        Product(
                            id: Int(graphQL.id.hashValue),
                            name: graphQL.name,
                            shop: "Store",
                            weight: graphQL.weight,
                            price: self.formatPrice(
                                price: graphQL.price,
                                currency: graphQL.currency
                            ),
                            imageUrl: graphQL.image
                        )
                    }
                    self.state = .success

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }

    private func formatPrice(price: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }
}
```

### 3. View

**Archivo**: `ui/screens/Product/List/ProductListView.swift`

```swift
import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel = ProductListViewModel()
    @State private var selectedBranchType: String?

    var body: some View {
        ZStack {
            Color.llegoBackground.ignoresSafeArea()

            switch viewModel.state {
            case .idle:
                EmptyView()

            case .loading:
                VStack(spacing: 20) {
                    LottieView(name: "loading")
                        .frame(width: 150, height: 150)
                    Text("Cargando productos...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }

            case .success:
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.products) { product in
                            ProductCard(product: product)
                        }
                    }
                    .padding()
                }

            case .error(let message):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text(message)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    Button("Reintentar") {
                        viewModel.loadProducts(branchType: selectedBranchType)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadProducts(branchType: selectedBranchType)
        }
    }
}
```

## Crear una Nueva Pantalla

### Paso 1: Crear Query GraphQL

**Archivo**: `GetStoreDetail.graphql`

```graphql
query GetStoreDetail($id: String!, $jwt: String) {
  branch(id: $id, jwt: $jwt) {
    id
    businessId
    name
    address
    coordinates {
      type
      coordinates
    }
    phone
    status
    createdAt
  }
}
```

### Paso 2: Generar Código Apollo

```bash
./apollo-ios-cli generate
```

### Paso 3: Crear Repository

**Archivo**: `ui/screens/Store/Detail/StoreDetailRepository.swift`

```swift
import Foundation
import Apollo

class StoreDetailRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    func fetchStoreDetail(
        id: String,
        completion: @escaping @Sendable (Result<StoreGraphQL, Error>) -> Void
    ) {
        let client = apolloClient

        Task { @MainActor in
            let jwt = AuthManager.shared.getAccessToken()

            let query = LlegoAPI.GetStoreDetailQuery(
                id: id,
                jwt: jwt.map { .some($0) } ?? .none
            )

            client.fetch(query: query, cachePolicy: .returnCacheDataAndFetch) { result in
                // Handle result
            }
        }
    }
}

struct StoreGraphQL: Identifiable, Sendable {
    let id: String
    let businessId: String
    let name: String
    let address: String
    let phone: String
    let status: String
    let createdAt: String
}
```

### Paso 4: Crear ViewModel

**Archivo**: `ui/screens/Store/Detail/StoreDetailViewModel.swift`

```swift
import Foundation

@MainActor
class StoreDetailViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    @Published var store: Store?

    private let repository = StoreDetailRepository()

    func loadStore(id: String) {
        state = .loading

        repository.fetchStoreDetail(id: id) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let storeGraphQL):
                    // Map to UI model
                case .failure(let error):
                    // Handle error
                }
            }
        }
    }
}
```

### Paso 5: Crear View

**Archivo**: `ui/screens/Store/Detail/StoreDetailView.swift`

```swift
import SwiftUI

struct StoreDetailView: View {
    let storeId: String
    @StateObject private var viewModel = StoreDetailViewModel()

    var body: some View {
        // UI implementation
    }

    .onAppear {
        viewModel.loadStore(id: storeId)
    }
}
```

## Best Practices

### ✅ DO

- Una Repository por pantalla
- Definir GraphQL Models en Repository
- Convertir GraphQL → UI Models en ViewModel
- Usar `@MainActor` en ViewModel
- Marcar closures como `@Sendable`
- Usar estados enum (`idle`, `loading`, `success`, `error`)

### ❌ DON'T

- Compartir Repositories entre pantallas
- Acceder a Apollo directamente desde ViewModel
- Usar modelos GraphQL en la View
- Olvidar el `@MainActor` en ViewModel
- Capturar `self` en Tasks sin `[weak self]`

## Referencias

- [CONCURRENCY_PATTERNS.md](CONCURRENCY_PATTERNS.md) - Main Actor y Task
- [GRAPHQL_SETUP.md](GRAPHQL_SETUP.md) - Apollo iOS setup
